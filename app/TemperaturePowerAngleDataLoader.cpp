// Metadata from Microsoft Calculator, MIT licensed, pinned revision
// 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128, UnitConverterDataLoader.cs:
// temperature ordering/defaults (375–378) and explicit offsets (668–688).
#include "TemperaturePowerAngleDataLoader.h"
#include <QLocale>
#include "ProportionalRatios.h"

using namespace UnitConversionManager;

namespace {
class TemperatureDataLoader final : public IConverterDataLoader
{
    std::vector<Unit> m_units;
public:
    TemperatureDataLoader()
    {
        const auto region = QLocale().territory();
        const bool fahrenheit = region == QLocale::UnitedStates || region == QLocale::Micronesia
            || region == QLocale::MarshallIslands || region == QLocale::Palau || region == QLocale::Bahamas
            || region == QLocale::CaymanIslands || region == QLocale::Liberia;
        m_units = {{46, L"Celsius", L"°C", fahrenheit, !fahrenheit, false},
                   {47, L"Fahrenheit", L"°F", !fahrenheit, fahrenheit, false},
                   {48, L"Kelvin", L"K", false, false, false}};
    }
    void LoadData() override {}
    std::vector<Category> GetOrderedCategories() override { return {{7, L"Temperature", true}}; }
    std::vector<Unit> GetOrderedUnits(const Category &) override { return m_units; }
    bool SupportsCategory(const Category &category) override { return category.id == 7; }
    std::unordered_map<Unit, ConversionData, UnitHash> LoadOrderedRatios(const Unit &unit) override
    {
        const ConversionData pairs[3][3] {
            {{1, 0, false}, {1.8, 32, false}, {1, 273.15, false}},
            {{0.55555555555555555555555555555556, -32, true}, {1, 0, false},
             {0.55555555555555555555555555555556, 459.67, true}},
            {{1, -273.15, true}, {1.8, -459.67, false}, {1, 0, false}}
        };
        std::unordered_map<Unit, ConversionData, UnitHash> ratios;
        for (size_t index = 0; index < m_units.size(); ++index)
            ratios.emplace(m_units[index], pairs[unit.id - 46][index]);
        return ratios;
    }
};
}

std::shared_ptr<IConverterDataLoader> createTemperatureDataLoader()
{
    return std::make_shared<TemperatureDataLoader>();
}

namespace {
struct ProportionalUnit
{
    int id;
    const wchar_t *name;
    const wchar_t *abbreviation;
    double factor;
    bool whimsical = false;
};

class ProportionalDataLoader final : public IConverterDataLoader
{
    Category m_category;
    std::vector<ProportionalUnit> m_definitions;
    std::vector<Unit> m_units;
public:
    ProportionalDataLoader(Category category, std::vector<ProportionalUnit> definitions, int source, int target)
        : m_category(std::move(category)), m_definitions(std::move(definitions))
    {
        for (const auto &unit : m_definitions)
            m_units.emplace_back(unit.id, unit.name, unit.abbreviation, unit.id == source, unit.id == target, unit.whimsical);
    }
    void LoadData() override {}
    std::vector<Category> GetOrderedCategories() override { return {m_category}; }
    std::vector<Unit> GetOrderedUnits(const Category &) override { return m_units; }
    bool SupportsCategory(const Category &category) override { return category.id == m_category.id; }
    std::unordered_map<Unit, ConversionData, UnitHash> LoadOrderedRatios(const Unit &unit) override
    {
        return loadProportionalRatios(unit, m_units, [this](size_t index) { return m_definitions[index].factor; });
    }
};
}

// Pinned UnitConverterDataLoader.cs: 365–373, 569–579; sorted by its order field.
std::shared_ptr<IConverterDataLoader> createPowerDataLoader()
{
    const bool watts = QLocale().territory() == QLocale::UnitedKingdom;
    return std::make_shared<ProportionalDataLoader>(Category {12, L"Power", true},
        std::vector<ProportionalUnit> {
            {45, L"Watts", L"W", 1},
            {44, L"Kilowatts", L"kW", 1000},
            {43, L"Horsepower (US)", L"hp (US)", 745.69987158227022},
            {42, L"Foot-pounds/minute", L"ft•lb/min", 0.0225969658055233},
            {41, L"BTUs/minute", L"BTU/min", 17.58426666666667},
            {108, L"light bulbs", L"light bulbs", 60, true},
            {109, L"horses", L"horses", 745.7, true},
            {132, L"train engines", L"train engines", 2982799.486329081, true}
        }, watts ? 45 : 44, 43);
}

// Pinned UnitConverterDataLoader.cs: 455–458, 651–656; base unit is degrees.
std::shared_ptr<IConverterDataLoader> createAngleDataLoader()
{
    return std::make_shared<ProportionalDataLoader>(Category {15, L"Angle", true},
        std::vector<ProportionalUnit> {
            {134, L"Degrees", L"deg", 1},
            {135, L"Radians", L"rad", 57.29577951308233},
            {136, L"Gradians", L"grad", 0.9}
        }, 134, 135);
}
