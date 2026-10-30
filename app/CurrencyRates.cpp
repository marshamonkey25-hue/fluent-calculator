#include "CurrencyRates.h"
#include <QCoreApplication>
#include <QDate>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QSettings>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QRegularExpression>
#include <QSet>
#include <algorithm>
#include <cmath>

using namespace UnitConversionManager;

namespace {
int currencyId(const QString &code)
{
    return 10000 + (code[0].unicode() - 'A') * 26 * 26 + (code[1].unicode() - 'A') * 26 + code[2].unicode() - 'A';
}

QString cachePath()
{
    // Resolve a filesystem settings path even on platforms whose native
    // QSettings backend is a registry. Tests redirect this same INI root.
    QSettings settings(QSettings::IniFormat, QSettings::UserScope,
                       QCoreApplication::organizationName(), QCoreApplication::applicationName());
    return QFileInfo(settings.fileName()).dir().filePath("currency-rates-v1.json");
}

QVariantList parseCatalog(const QJsonArray &items)
{
    QVariantList catalog;
    QSet<QString> seen;
    static const QRegularExpression iso(QStringLiteral("^[A-Z]{3}$"));
    for (const auto &value : items) {
        const auto row = value.toObject();
        const auto code = row.value("iso_code").toString();
        const auto name = row.value("name").toString().trimmed();
        if (!value.isObject() || !iso.match(code).hasMatch() || name.isEmpty() || seen.contains(code))
            return {};
        seen.insert(code);
        catalog.append(QVariantMap {{"id", currencyId(code)}, {"code", code}, {"name", name}, {"symbol", row.value("symbol").toString()}});
    }
    std::sort(catalog.begin(), catalog.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value("code").toString() < b.toMap().value("code").toString();
    });
    return catalog;
}

bool validObservation(const QJsonObject &row, const QString &base, const QString &quote)
{
    const auto dateText = row.value("date").toString();
    const auto date = QDate::fromString(dateText, Qt::ISODate);
    const auto rate = row.value("rate").toDouble(0);
    return row.value("base").toString() == base && row.value("quote").toString() == quote
        && date.isValid() && date.toString(Qt::ISODate) == dateText
        && row.value("rate").isDouble() && std::isfinite(rate) && rate > 0;
}
}

CurrencyRates::CurrencyRates(QObject *parent) : QObject(parent)
{
    loadCache();
    setSource(&m_defaultSource);
}

void CurrencyRates::loadCache()
{
    QFile file(cachePath());
    if (!file.open(QIODevice::ReadOnly)) return;
    const auto root = QJsonDocument::fromJson(file.readAll()).object();
    if (root.value("version").toInt() != 1 || root.value("source").toString() != "https://api.frankfurter.dev/v2/"
        || !root.value("currencies").isArray() || !root.value("observations").isArray()) return;
    const auto catalog = parseCatalog(root.value("currencies").toArray());
    if (catalog.isEmpty()) return;
    QSet<QString> codes;
    for (const auto &item : catalog) codes.insert(item.toMap().value("code").toString());
    QHash<QString, QJsonObject> observations;
    for (const auto &value : root.value("observations").toArray()) {
        const auto row = value.toObject();
        const auto base = row.value("base").toString(), quote = row.value("quote").toString();
        const auto key = base + "/" + quote;
        const auto refreshed = row.value("refreshedAt").toString();
        if (!codes.contains(base) || !codes.contains(quote) || observations.contains(key)
            || !validObservation(row, base, quote) || !QDateTime::fromString(refreshed, Qt::ISODate).isValid()) return;
        observations.insert(key, row);
    }
    m_catalog = catalog;
    m_observations = observations;
}

void CurrencyRates::saveCache()
{
    QJsonArray catalog, observations;
    for (const auto &item : m_catalog) {
        const auto row = item.toMap();
        catalog.append(QJsonObject {{"iso_code", row.value("code").toString()}, {"name", row.value("name").toString()},
                                    {"symbol", row.value("symbol").toString()}});
    }
    for (const auto &row : m_observations) observations.append(row);
    const auto bytes = QJsonDocument(QJsonObject {{"version", 1}, {"source", "https://api.frankfurter.dev/v2/"},
                                                 {"currencies", catalog}, {"observations", observations}}).toJson();
    QDir().mkpath(QFileInfo(cachePath()).absolutePath());
    QSaveFile file(cachePath());
    // QSaveFile's default forbids direct-write fallback: a failed or interrupted
    // write must leave the last complete cache intact.
    m_cacheWriteFailed = true;
    if (!file.open(QIODevice::WriteOnly)) return;
    if (file.write(bytes) != bytes.size()) { file.cancelWriting(); return; }
    m_cacheWriteFailed = !file.commit();
}

void CurrencyRates::setSource(CurrencySource *source)
{
    if (!source) source = &m_defaultSource;
    if (source == m_source) return;
    if (m_source) disconnect(m_source, nullptr, this, nullptr);
    m_source = source;
    m_catalogRequest = m_rateRequest = 0;
    ++m_generation;
    connect(source, &CurrencySource::completed, this, &CurrencyRates::receive);
}

std::vector<Category> CurrencyRates::GetOrderedCategories() { return {{3, L"Currency", false}}; }

std::vector<Unit> CurrencyRates::GetOrderedUnits(const Category &)
{
    std::vector<Unit> units;
    const auto hasCode = [this](const QString &value) {
        return std::any_of(m_catalog.begin(), m_catalog.end(), [&value](const QVariant &item) {
            return item.toMap().value("code").toString() == value;
        });
    };
    const bool hasEuro = hasCode("EUR"), hasDollar = hasCode("USD");
    for (qsizetype index = 0; index < m_catalog.size(); ++index) {
        const auto row = m_catalog[index].toMap();
        const auto code = row.value("code").toString();
        units.emplace_back(row.value("id").toInt(), code.toStdWString(), code.toStdWString(),
                           hasEuro ? code == "EUR" : index == 0,
                           hasDollar ? code == "USD" : index == std::min<qsizetype>(1, m_catalog.size() - 1), false);
    }
    return units;
}

QVariantList CurrencyRates::units(const QString &language) const
{
    QVariantList rows;
    // ISO codes remain unambiguous; names supplied by the service are source data.
    // Qt supplies localized names for currencies represented by a current territory.
    QHash<QString, QString> names;
    if (language == "zh-CN") {
        for (const auto &locale : QLocale::matchingLocales(QLocale::AnyLanguage, QLocale::AnyScript, QLocale::AnyTerritory)) {
            const auto iso = locale.currencySymbol(QLocale::CurrencyIsoCode);
            if (!names.contains(iso)) {
                const QLocale chinese(QLocale::Chinese, QLocale::SimplifiedChineseScript, locale.territory());
                if (chinese.currencySymbol(QLocale::CurrencyIsoCode) == iso)
                    names.insert(iso, chinese.currencySymbol(QLocale::CurrencyDisplayName));
            }
        }
    }
    for (const auto &item : m_catalog) {
        const auto row = item.toMap();
        const auto iso = row.value("code").toString();
        rows.append(QVariantMap {{"id", row.value("id")}, {"name", iso + " — " + names.value(iso, row.value("name").toString())}, {"symbol", row.value("symbol")}});
    }
    return rows;
}

QString CurrencyRates::code(int id) const
{
    for (const auto &item : m_catalog) {
        const auto row = item.toMap();
        if (row.value("id").toInt() == id) return row.value("code").toString();
    }
    return {};
}

void CurrencyRates::selectPair(int first, int second)
{
    const auto base = code(first), quote = code(second);
    if (base == m_base && quote == m_quote) return;
    m_base = base;
    m_quote = quote;
    m_rateRequest = 0;
    m_rate = 0;
    m_date.clear();
    m_refreshedAt.clear();
    const auto cached = m_observations.value(m_base + "/" + m_quote);
    m_usingCached = !cached.isEmpty();
    if (!cached.isEmpty()) {
        m_rate = cached.value("rate").toDouble();
        m_date = cached.value("date").toString();
        m_refreshedAt = cached.value("refreshedAt").toString();
    }
    requestRate();
}

void CurrencyRates::refresh()
{
    if (!m_source) { m_state = "failed"; emit changed(); return; }
    if (m_catalog.isEmpty()) {
        m_state = "loading";
        m_catalogRequest = ++m_generation;
        emit changed();
        m_source->request(m_catalogRequest, QStringLiteral("currencies"));
    } else requestRate();
}

void CurrencyRates::requestRate()
{
    if (!m_source || m_base.isEmpty() || m_quote.isEmpty()) {
        m_state = "unavailable";
        emit changed();
        return;
    }
    m_rateRequest = ++m_generation;
    m_state = "loading";
    m_usingCached = available();
    emit changed();
    m_source->request(m_rateRequest, "rates?base=" + m_base + "&quotes=" + m_quote);
}

void CurrencyRates::receive(quint64 requestId, const QByteArray &body, bool success)
{
    if (requestId != m_catalogRequest && requestId != m_rateRequest) return;
    m_refreshedAt = m_source ? m_source->now().toUTC().toString(Qt::ISODate) : QString();
    QJsonParseError error;
    const auto document = QJsonDocument::fromJson(body, &error);
    const bool validJson = success && error.error == QJsonParseError::NoError && document.isArray();
    if (requestId == m_catalogRequest) {
        m_catalogRequest = 0;
        const auto catalog = validJson ? parseCatalog(document.array()) : QVariantList();
        if (catalog.isEmpty()) { m_state = "failed"; emit changed(); return; }
        m_catalog = catalog;
        saveCache();
        emit dataChanged();
        return;
    }
    m_rateRequest = 0;
    // A specific-pair request must return exactly that pair, not a nearby or
    // partially matching quote. Never substitute download time for observation.
    if (!validJson || document.array().size() != 1) { m_state = success ? "invalid" : "failed"; emit changed(); return; }
    const auto row = document.array().first().toObject();
    if (!validObservation(row, m_base, m_quote)) {
        m_state = "invalid";
        emit changed();
        return;
    }
    m_rate = row.value("rate").toDouble();
    m_date = row.value("date").toString();
    auto observation = row;
    observation.insert("refreshedAt", m_refreshedAt);
    m_observations.insert(m_base + "/" + m_quote, observation);
    saveCache();
    m_state = "ready";
    m_usingCached = false;
    emit dataChanged();
    emit changed();
}

std::unordered_map<Unit, ConversionData, UnitHash> CurrencyRates::LoadOrderedRatios(const Unit &unit)
{
    std::unordered_map<Unit, ConversionData, UnitHash> ratios;
    if (!available()) return ratios;
    const bool forward = unit.id == currencyId(m_base);
    if (!forward && unit.id != currencyId(m_quote)) return ratios;
    const double ratio = forward ? m_rate : 1.0 / m_rate;
    if (!std::isfinite(ratio)) return ratios;
    const int targetId = currencyId(forward ? m_quote : m_base);
    for (const auto &target : GetOrderedUnits({})) {
        if (target.id == targetId) {
            ratios.emplace(target, ConversionData(ratio, 0, false));
            break;
        }
    }
    return ratios;
}
