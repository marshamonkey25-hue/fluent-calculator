#include "ConversionSession.h"
#include "Command.h"
#include "LengthDataLoader.h"
#include "TemperaturePowerAngleDataLoader.h"
#include "MeasurementDataLoader.h"
#include "EnergySpeedTimePressureDataLoader.h"
#include <QClipboard>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QHash>
#include <QLocale>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>

using namespace UnitConversionManager;

namespace {
// Keep the category/unit state in the real converter across page navigation.
class ConverterDataLoader final : public IConverterDataLoader
{
    std::vector<std::shared_ptr<IConverterDataLoader>> m_loaders {
        createLengthDataLoader(), createMeasurementDataLoader(4), createMeasurementDataLoader(9),
        createMeasurementDataLoader(6), createEnergySpeedTimePressureDataLoader("energy"),
        createEnergySpeedTimePressureDataLoader("speed"), createEnergySpeedTimePressureDataLoader("time"),
        createEnergySpeedTimePressureDataLoader("pressure"),
        createTemperatureDataLoader(), createPowerDataLoader(), createAngleDataLoader()
    };
public:
    explicit ConverterDataLoader(const std::shared_ptr<CurrencyRates> &currency) { m_loaders.push_back(currency); }
    void LoadData() override {}
    std::vector<Category> GetOrderedCategories() override
    {
        std::vector<Category> categories;
        for (const auto &loader : m_loaders) {
            const auto items = loader->GetOrderedCategories();
            categories.insert(categories.end(), items.begin(), items.end());
        }
        return categories;
    }
    std::vector<Unit> GetOrderedUnits(const Category &category) override
    {
        for (const auto &loader : m_loaders)
            if (loader->SupportsCategory(category))
                return loader->GetOrderedUnits(category);
        return {};
    }
    bool IsCurrencyCategory(const Category &category) const override
    {
        return std::any_of(m_loaders.begin(), m_loaders.end(),
                           [&category](const auto &loader) { return loader->IsCurrencyCategory(category); });
    }
    bool SupportsCategory(const Category &category) override
    {
        return std::any_of(m_loaders.begin(), m_loaders.end(),
                           [&category](const auto &loader) { return loader->SupportsCategory(category); });
    }
    std::unordered_map<Unit, ConversionData, UnitHash> LoadOrderedRatios(const Unit &unit) override
    {
        for (const auto &loader : m_loaders) {
            for (const auto &category : loader->GetOrderedCategories()) {
                const auto units = loader->GetOrderedUnits(category);
                if (std::find(units.begin(), units.end(), unit) != units.end())
                    return loader->LoadOrderedRatios(unit);
            }
        }
        return {};
    }
};

QString grouped(QString value)
{
    // Preserve engine decimal text, trailing zeroes and scientific mantissas.
    if (value.contains('e'))
        return value;
    const auto decimal = value.indexOf('.');
    const auto end = decimal < 0 ? value.size() : decimal;
    const auto first = value.startsWith('-') ? 1 : 0;
    for (auto index = end - 3; index > first; index -= 3)
        value.insert(index, ',');
    return value;
}
}

QString ConversionSession::value1() const { return m_value1.isEmpty() || (m_category == "currency" && !m_currency->available() && m_activeSide != 1) ? QStringLiteral("—") : grouped(m_value1); }
QString ConversionSession::value2() const { return m_value2.isEmpty() || (m_category == "currency" && !m_currency->available() && m_activeSide != 2) ? QStringLiteral("—") : grouped(m_value2); }

void ConversionSession::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void ConversionSession::MaxDigitsReached() { setStatus(QStringLiteral("limit")); }

ConversionSession::ConversionSession(QObject *parent) : QObject(parent)
{
    m_currency = std::make_shared<CurrencyRates>();
    initializeConverter(std::make_shared<ConverterDataLoader>(m_currency));
    connect(m_currency.get(), &CurrencyRates::changed, this, &ConversionSession::displayChanged);
    connect(m_currency.get(), &CurrencyRates::dataChanged, this, [this] {
        m_converter->RefreshData();
        if (m_category == "currency") {
            const auto selection = m_converter->SetCurrentCategory({3, L"Currency", false});
            m_units = std::get<0>(selection);
            m_unit1 = (m_activeSide == 1 ? std::get<1>(selection) : std::get<2>(selection)).id;
            m_unit2 = (m_activeSide == 1 ? std::get<2>(selection) : std::get<1>(selection)).id;
            selectUnits();
            emit unitCatalogChanged();
            emit unitsChanged();
        }
    });
}

void ConversionSession::setCurrencySource(CurrencySource *source)
{
    if (source == m_currencySource) return;
    m_currencySource = source;
    m_currency->setSource(source);
    emit currencySourceChanged();
}

void ConversionSession::initializeConverter(std::shared_ptr<IConverterDataLoader> loader)
{
    m_converter = std::make_shared<UnitConverter>(std::move(loader));
    m_activeSide = 1;
    const auto selection = m_converter->SetCurrentCategory(m_converter->GetCategories().front());
    m_units = std::get<0>(selection);
    m_unit1 = std::get<1>(selection).id;
    m_unit2 = std::get<2>(selection).id;
    // The QObject owns the converter and outlives its non-owning callback.
    m_converter->SetViewModelCallback(std::shared_ptr<IUnitConverterVMCallback>(static_cast<IUnitConverterVMCallback *>(this), [](auto *) {}));
    selectUnits();
}

void ConversionSession::setCategory(const QString &category)
{
    if (category == m_category)
        return;
    static const QHash<QString, int> categories {
        {"currency", 3}, {"length", 5}, {"volume", 4}, {"area", 9}, {"weight", 6}, {"energy", 8}, {"speed", 10}, {"time", 11}, {"pressure", 14},
        {"temperature", 7}, {"power", 12}, {"angle", 15}
    };
    const auto id = categories.constFind(category);
    if (id == categories.cend())
        return;
    const auto available = m_converter->GetCategories();
    const auto selected = std::find_if(available.begin(), available.end(),
                                       [id](const Category &item) { return item.id == id.value(); });
    if (selected == available.end())
        return;
    m_category = category;
    const auto selection = m_converter->SetCurrentCategory(*selected);
    m_units = std::get<0>(selection);
    m_unit1 = (m_activeSide == 1 ? std::get<1>(selection) : std::get<2>(selection)).id;
    m_unit2 = (m_activeSide == 1 ? std::get<2>(selection) : std::get<1>(selection)).id;
    selectUnits();
    setStatus({});
    emit categoryChanged();
    emit unitCatalogChanged();
    emit unitsChanged();
    emit activeSideChanged();
}

void ConversionSession::setLanguage(const QString &language)
{
    if (m_language == language)
        return;
    m_language = language;
    emit languageChanged();
    emit unitCatalogChanged();
}

QVariantList ConversionSession::units() const
{
    if (m_category == "currency") return m_currency->units(m_language);
    QVariantList rows;
    for (const auto &unit : m_units) {
        if (unit.isWhimsical)
            continue;
        const auto name = QString::fromStdWString(unit.name).toUtf8();
        rows.append(QVariantMap {{"id", unit.id}, {"name", QCoreApplication::translate("ConverterUnits", name.constData())}});
    }
    return rows;
}

void ConversionSession::setUnit1(int id)
{
    if (m_unit1 == id || std::none_of(m_units.begin(), m_units.end(), [id](const Unit &unit) { return unit.id == id; }))
        return;
    m_unit1 = id;
    selectUnits();
    emit unitsChanged();
}

void ConversionSession::setUnit2(int id)
{
    if (m_unit2 == id || std::none_of(m_units.begin(), m_units.end(), [id](const Unit &unit) { return unit.id == id; }))
        return;
    m_unit2 = id;
    selectUnits();
    emit unitsChanged();
}

void ConversionSession::selectUnits()
{
    if (m_units.empty())
        return;
    const auto find = [this](int id) {
        return *std::find_if(m_units.begin(), m_units.end(), [id](const Unit &unit) { return unit.id == id; });
    };
    if (m_category == "currency") m_currency->selectPair(m_unit1, m_unit2);
    m_converter->SetCurrentUnitTypes(find(m_activeSide == 1 ? m_unit1 : m_unit2),
                                     find(m_activeSide == 1 ? m_unit2 : m_unit1));
}

void ConversionSession::activate(int side)
{
    if ((side != 1 && side != 2) || side == m_activeSide || (m_category == "currency" && (!m_currency->available() || (side == 1 ? m_value1 : m_value2).isEmpty())))
        return;
    m_activeSide = side;
    m_converter->SwitchActive((side == 1 ? m_value1 : m_value2).toStdWString());
    emit activeSideChanged();
}

void ConversionSession::send(const QString &command)
{
    static const QHash<QString, Command> commands {
        {"0", Command::Zero}, {"1", Command::One}, {"2", Command::Two}, {"3", Command::Three},
        {"4", Command::Four}, {"5", Command::Five}, {"6", Command::Six}, {"7", Command::Seven},
        {"8", Command::Eight}, {"9", Command::Nine}, {"decimal", Command::Decimal},
        {"clear", Command::Clear}, {"backspace", Command::Backspace}, {"negate", Command::Negate}
    };
    const auto entry = commands.constFind(command);
    if (entry != commands.cend()) {
        if (!m_status.isEmpty() && m_status != "limit")
            m_converter->SendCommand(Command::Clear);
        setStatus({});
        m_converter->SendCommand(entry.value());
    }
}

void ConversionSession::copy()
{
    QGuiApplication::clipboard()->setText(m_activeSide == 1 ? m_value1 : m_value2);
}

void ConversionSession::paste()
{
    auto input = QGuiApplication::clipboard()->text().trimmed();
    const bool negative = input.startsWith('-');
    if (negative && !supportsNegative()) {
        setStatus(QStringLiteral("negative"));
        return;
    }
    static const QRegularExpression decimal(QStringLiteral(R"(^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$)"));
    if (!decimal.match(input).hasMatch()) {
        setStatus(QStringLiteral("invalid"));
        return;
    }
    bool parsed = false;
    const auto value = QLocale::c().toDouble(input, &parsed);
    if (!parsed || !std::isfinite(value)) {
        setStatus(QStringLiteral("unavailable"));
        return;
    }
    if (negative || input.startsWith('+'))
        input.remove(0, 1);
    const auto point = input.indexOf('.');
    const auto integerEnd = point < 0 ? input.size() : point;
    auto firstNonzero = 0;
    while (firstNonzero + 1 < integerEnd && input[firstNonzero] == '0')
        ++firstNonzero;
    input.remove(0, firstNonzero);
    if (input.startsWith('.'))
        input.prepend('0');
    if (input.size() - (input.contains('.') ? 1 : 0) > 15) {
        setStatus(QStringLiteral("limit"));
        return;
    }
    send(QStringLiteral("clear"));
    for (const auto character : input)
        send(character == '.' ? QStringLiteral("decimal") : QString(character));
    if (negative)
        send(QStringLiteral("negate"));
}

void ConversionSession::DisplayCallback(const std::wstring &from, const std::wstring &to)
{
    m_value1 = QString::fromStdWString(m_activeSide == 1 ? from : to);
    m_value2 = QString::fromStdWString(m_activeSide == 1 ? to : from);
    if (m_category == "currency" && m_currency->available()) {
        if ((m_activeSide == 1 ? m_value2 : m_value1).isEmpty())
            setStatus(QStringLiteral("unavailable"));
        else if (m_status == "unavailable")
            setStatus({});
    }
    emit displayChanged();
}
