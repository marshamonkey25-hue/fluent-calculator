// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
// Metadata ported from pinned 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128:
// Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs and Resources.resw.
// Category serialization IDs (4 volume, 6 weight, 9 area) come from Common/NavCategory.cs.
#include "MeasurementDataLoader.h"
#include <QLocale>
#include "ProportionalRatios.h"
#include <iterator>

using namespace UnitConversionManager;

namespace {
struct MeasurementUnit
{
    int id;
    const wchar_t *name;
    const wchar_t *abbreviation;
    double factor;
    bool whimsical;
};
const MeasurementUnit volumeUnits[] {
    {75, L"Milliliters", L"mL", 1, false},
    {64, L"Cubic centimeters", L"cm³", 1, false},
    {74, L"Liters", L"L", 1000, false},
    {67, L"Cubic meters", L"m³", 1000000, false},
    {79, L"Teaspoons (US)", L"tsp. (US)", 4.92892159375, false},
    {78, L"Tablespoons (US)", L"tbsp. (US)", 14.78676478125, false},
    {71, L"Fluid ounces (US)", L"fl oz (US)", 29.5735295625, false},
    {69, L"Cups (US)", L"cup (US)", 236.588237, false},
    {77, L"Pints (US)", L"pt (US)", 473.176473, false},
    {81, L"Quarts (US)", L"qt (US)", 946.352946, false},
    {73, L"Gallons (US)", L"gal (US)", 3785.411784, false},
    {66, L"Cubic inches", L"in³", 16.387064, false},
    {65, L"Cubic feet", L"ft³", 28316.846592, false},
    {68, L"Cubic yards", L"yd³", 764554.857984, false},
    {115, L"Teaspoons (UK)", L"tsp. (UK)", 5.91938802083333333333, false},
    {116, L"Tablespoons (UK)", L"tbsp. (UK)", 17.7581640625, false},
    {70, L"Fluid ounces (UK)", L"fl oz (UK)", 28.4130625, false},
    {76, L"Pints (UK)", L"pt (UK)", 568.26125, false},
    {80, L"Quarts (UK)", L"qt (UK)", 1136.5225, false},
    {72, L"Gallons (UK)", L"gal (UK)", 4546.09, false},
    {124, L"coffee cups", L"coffee cups", 236.5882, true},
    {111, L"bathtubs", L"bathtubs", 378541.2, true},
    {125, L"swimming pools", L"swimming pools", 3750000000, true},
};

const MeasurementUnit areaUnits[] {
    {9, L"Square millimeters", L"mm²", 0.000001, false},
    {3, L"Square centimeters", L"cm²", 0.0001, false},
    {7, L"Square meters", L"m²", 1, false},
    {2, L"Hectares", L"ha", 10000, false},
    {6, L"Square kilometers", L"km²", 1000000, false},
    {5, L"Square inches", L"in²", 0.00064516, false},
    {4, L"Square feet", L"ft²", 0.09290304, false},
    {10, L"Square yards", L"yd²", 0.83612736, false},
    {1, L"Acres", L"ac", 4046.8564224, false},
    {8, L"Square miles", L"mi²", 2589988.110336, false},
    {118, L"hands", L"hands", 0.012516104, true},
    {127, L"sheets of paper", L"sheets of paper", 0.06032246, true},
    {99, L"soccer fields", L"soccer fields", 10869.66, true},
    {128, L"castles", L"castles", 100000, true},
    {165, L"Pyeong", L"Pyeong", 400.0 / 121.0, false},
};

const MeasurementUnit weightUnits[] {
    {82, L"Carats", L"CD", 0.0002, false},
    {90, L"Milligrams", L"mg", 0.000001, false},
    {83, L"Centigrams", L"cg", 0.00001, false},
    {84, L"Decigrams", L"dg", 0.0001, false},
    {86, L"Grams", L"g", 0.001, false},
    {85, L"Dekagrams", L"dag", 0.01, false},
    {87, L"Hectograms", L"hg", 0.1, false},
    {88, L"Kilograms", L"kg", 1, false},
    {95, L"Metric tonnes", L"t", 1000, false},
    {91, L"Ounces", L"oz", 0.028349523125, false},
    {92, L"Pounds", L"lb", 0.45359237, false},
    {94, L"Stone", L"st", 6.35029318, false},
    {93, L"Short tons (US)", L"ton (US)", 907.18474, false},
    {89, L"Long tons (UK)", L"ton (UK)", 1016.0469088, false},
    {113, L"snowflakes", L"snowflakes", 0.000002, true},
    {133, L"soccer balls", L"soccer balls", 0.4325, true},
    {114, L"elephants", L"elephants", 4000, true},
    {123, L"whales", L"whales", 90000, true},
};

class MeasurementDataLoader final : public IConverterDataLoader
{
    Category m_category;
    std::vector<MeasurementUnit> m_definitions;
    std::vector<Unit> m_units;
public:
    explicit MeasurementDataLoader(int categoryId)
        : m_category(categoryId, categoryId == 9 ? L"Area" : categoryId == 6 ? L"Weight and Mass" : L"Volume", false)
    {
        const auto region = QLocale().territory();
        const bool customary = region == QLocale::UnitedStates || region == QLocale::Micronesia
            || region == QLocale::MarshallIslands || region == QLocale::Palau || region == QLocale::Liberia;
        if (categoryId == 9) {
            m_definitions.assign(std::begin(areaUnits), std::end(areaUnits));
            const bool pyeong = region == QLocale::Japan || region == QLocale::Taiwan
                || region == QLocale::NorthKorea || region == QLocale::SouthKorea;
            // Pyeong follows all other units in the pinned ordering.
            if (!pyeong)
                m_definitions.pop_back();
        } else if (categoryId == 6) {
            m_definitions.assign(std::begin(weightUnits), std::end(weightUnits));
        } else {
            m_definitions.assign(std::begin(volumeUnits), std::end(volumeUnits));
        }
        const int source = categoryId == 9 ? (customary ? 7 : 4)
            : categoryId == 6 ? (customary ? 88 : 92) : (customary ? 75 : 79);
        const int target = categoryId == 9 ? (customary ? 4 : 7)
            : categoryId == 6 ? (customary ? 92 : 88) : (customary ? 79 : 75);
        for (const auto &definition : m_definitions)
            m_units.emplace_back(definition.id, definition.name, definition.abbreviation,
                                 definition.id == source,
                                 definition.id == target, definition.whimsical);
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

std::shared_ptr<IConverterDataLoader> createMeasurementDataLoader(int categoryId)
{
    return std::make_shared<MeasurementDataLoader>(categoryId);
}
