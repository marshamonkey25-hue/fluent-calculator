#include "CurrencyRates.h"
#include <QDate>
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
}

CurrencyRates::CurrencyRates(QObject *parent) : QObject(parent) { setSource(&m_defaultSource); }

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
        QVariantList catalog;
        QSet<QString> seen;
        static const QRegularExpression iso(QStringLiteral("^[A-Z]{3}$"));
        if (validJson) {
            for (const auto &value : document.array()) {
                const auto row = value.toObject();
                const auto code = row.value("iso_code").toString();
                const auto name = row.value("name").toString().trimmed();
                if (!value.isObject() || !iso.match(code).hasMatch() || name.isEmpty() || seen.contains(code)) {
                    catalog.clear();
                    break;
                }
                seen.insert(code);
                catalog.append(QVariantMap {{"id", currencyId(code)}, {"code", code}, {"name", name}, {"symbol", row.value("symbol").toString()}});
            }
        }
        if (catalog.isEmpty()) { m_state = "failed"; emit changed(); return; }
        std::sort(catalog.begin(), catalog.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap().value("code").toString() < b.toMap().value("code").toString();
        });
        m_catalog = catalog;
        emit dataChanged();
        return;
    }
    m_rateRequest = 0;
    // A specific-pair request must return exactly that pair, not a nearby or
    // partially matching quote. Never substitute download time for observation.
    if (!validJson || document.array().size() != 1) { m_state = success ? "invalid" : "failed"; emit changed(); return; }
    const auto row = document.array().first().toObject();
    const auto dateText = row.value("date").toString();
    const auto date = QDate::fromString(dateText, Qt::ISODate);
    const auto rate = row.value("rate").toDouble(0);
    if (row.value("base").toString() != m_base || row.value("quote").toString() != m_quote
        || !date.isValid() || date.toString(Qt::ISODate) != dateText
        || !row.value("rate").isDouble() || !std::isfinite(rate) || rate <= 0) {
        m_state = "invalid";
        emit changed();
        return;
    }
    m_rate = rate;
    m_date = dateText;
    m_state = "ready";
    emit dataChanged();
    emit changed();
}

std::unordered_map<Unit, ConversionData, UnitHash> CurrencyRates::LoadOrderedRatios(const Unit &unit)
{
    std::unordered_map<Unit, ConversionData, UnitHash> ratios;
    if (!available()) return ratios;
    const auto units = GetOrderedUnits({});
    for (const auto &target : units) {
        const auto from = code(unit.id), to = code(target.id);
        if (from == m_base && to == m_quote) ratios.emplace(target, ConversionData(m_rate, 0, false));
        else if (from == m_quote && to == m_base && std::isfinite(1.0 / m_rate))
            ratios.emplace(target, ConversionData(1.0 / m_rate, 0, false));
    }
    return ratios;
}
