// Length metadata derived from Microsoft Calculator, MIT licensed.
// Pinned 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128:
// Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs, lines 348–363,
// 551–568 (unit IDs, ordering, defaults, metre factors and whimsical suggestions).
#include "LengthDataLoader.h"
#include <QLocale>
#include "ProportionalRatios.h"

using namespace UnitConversionManager;

namespace {
struct LengthUnit
{
    int id;
    const wchar_t *name;
    const wchar_t *abbreviation;
    double meters;
    bool whimsical = false;
};
const LengthUnit definitions[] {
    {168, L"Angstroms", L"A", 1e-10},
    {38, L"Nanometers", L"nm", 1e-9},
    {35, L"Microns", L"µm", 1e-6},
    {37, L"Millimeters", L"mm", 0.001},
    {30, L"Centimeters", L"cm", 0.01},
    {34, L"Meters", L"m", 1},
    {33, L"Kilometers", L"km", 1000},
    {32, L"Inches", L"in", 0.0254},
    {31, L"Feet", L"ft", 0.3048},
    {40, L"Yards", L"yd", 0.9144},
    {36, L"Miles", L"mi", 1609.344},
    {39, L"Nautical miles", L"nmi", 1852},
    {105, L"paperclips", L"paperclips", 0.035052, true},
    {131, L"hands", L"hands", 0.18669, true},
    {107, L"jumbo jets", L"jumbo jets", 76, true}
};

class LengthDataLoader final : public IConverterDataLoader
{
    std::vector<Unit> m_units;
public:
    LengthDataLoader()
    {
        const auto region = QLocale().territory();
        const bool customary = region == QLocale::UnitedStates || region == QLocale::Micronesia
            || region == QLocale::MarshallIslands || region == QLocale::Palau || region == QLocale::Liberia;
        for (const auto &definition : definitions)
            m_units.emplace_back(definition.id, definition.name, definition.abbreviation,
                                 definition.id == (customary ? 30 : 32),
                                 definition.id == (customary ? 32 : 30), definition.whimsical);
    }
    void LoadData() override {}
    std::vector<Category> GetOrderedCategories() override { return {{5, L"Length", false}}; }
    std::vector<Unit> GetOrderedUnits(const Category &) override { return m_units; }
    bool SupportsCategory(const Category &category) override { return category.id == 5; }
    std::unordered_map<Unit, ConversionData, UnitHash> LoadOrderedRatios(const Unit &unit) override
    {
        return loadProportionalRatios(unit, m_units, [](size_t index) { return definitions[index].meters; });
    }
};
}

std::shared_ptr<IConverterDataLoader> createLengthDataLoader()
{
    return std::make_shared<LengthDataLoader>();
}
