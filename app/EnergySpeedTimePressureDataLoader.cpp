// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
// Metadata ported from microsoft/calculator 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128:
// Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs and Resources.resw.
#include "EnergySpeedTimePressureDataLoader.h"
#include "ProportionalRatios.h"
#include <QLocale>
#include <utility>

using namespace UnitConversionManager;

namespace {
struct ReferenceUnit
{
    int id;
    const wchar_t *name;
    const wchar_t *abbreviation;
    double factor;
    bool source = false;
    bool target = false;
    bool whimsical = false;
};

class ReferenceDataLoader final : public IConverterDataLoader
{
    Category m_category;
    std::vector<ReferenceUnit> m_definitions;
    std::vector<Unit> m_units;
public:
    ReferenceDataLoader(Category category, std::vector<ReferenceUnit> definitions)
        : m_category(std::move(category)), m_definitions(std::move(definitions))
    {
        for (const auto &unit : m_definitions)
            m_units.emplace_back(unit.id, unit.name, unit.abbreviation, unit.source, unit.target, unit.whimsical);
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

std::shared_ptr<IConverterDataLoader> createEnergySpeedTimePressureDataLoader(const QString &category)
{
    if (category == "energy") {
        // Joule is the first source flagged in pinned order (kWh is flagged too).
        return std::make_shared<ReferenceDataLoader>(Category {8, L"Energy", false}, std::vector<ReferenceUnit> {
            {25, L"Electron volts", L"eV", 1.602176565e-19},
            {27, L"Joules", L"J", 1, true},
            {29, L"Kilojoules", L"kJ", 1000},
            {24, L"Thermal calories", L"cal", 4.184},
            {28, L"Food calories", L"kcal", 4184, false, true},
            {26, L"Foot-pounds", L"ft•lb", 1.3558179483314},
            {23, L"British thermal units", L"BTU", 1055.056},
            {103, L"batteries", L"batteries", 9000, false, false, true},
            {129, L"bananas", L"bananas", 439614, false, false, true},
            {130, L"slices of cake", L"slices of cake", 1046700, false, false, true},
            {166, L"Kilowatt-hours", L"kWh", 3600000, true}
        });
    }
    if (category == "speed") {
        const auto region = QLocale().territory();
        const bool customary = region == QLocale::UnitedStates || region == QLocale::Micronesia
            || region == QLocale::MarshallIslands || region == QLocale::Palau || region == QLocale::Liberia;
        // Pinned base is cm/s; mph and knots deliberately retain upstream rounding.
        return std::make_shared<ReferenceDataLoader>(Category {10, L"Speed", false}, std::vector<ReferenceUnit> {
            {57, L"Centimeters per second", L"cm/s", 1},
            {62, L"Meters per second", L"m/s", 100},
            {59, L"Kilometers per hour", L"km/h", 27.777777777777777777778, customary, !customary},
            {58, L"Feet per second", L"ft/s", 30.48},
            {63, L"Miles per hour", L"mph", 44.7, !customary, customary},
            {60, L"Knots", L"kn", 51.44},
            {61, L"Mach", L"M", 34030},
            {121, L"turtles", L"turtles", 8.94, false, false, true},
            {126, L"horses", L"horses", 2011.5, false, false, true},
            {122, L"jets", L"jets", 24585, false, false, true}
        });
    }
    if (category == "time") {
        return std::make_shared<ReferenceDataLoader>(Category {11, L"Time", false}, std::vector<ReferenceUnit> {
            {51, L"Microseconds", L"µs", 0.000001},
            {52, L"Milliseconds", L"ms", 0.001},
            {54, L"Seconds", L"s", 1},
            {53, L"Minutes", L"min", 60, false, true},
            {50, L"Hours", L"hr", 3600, true},
            {49, L"Days", L"d", 86400},
            {55, L"Weeks", L"wk", 604800},
            {56, L"Years", L"yr", 31557600}
        });
    }
    if (category == "pressure") {
        return std::make_shared<ReferenceDataLoader>(Category {14, L"Pressure", false}, std::vector<ReferenceUnit> {
            {137, L"Atmospheres", L"atm", 1, true},
            {138, L"Bars", L"ba", 0.9869232667160128, false, true},
            {139, L"Kilopascals", L"kPa", 0.0098692326671601},
            // Resolve the real RESW key without the loader's stray trailing space.
            {140, L"Millimeters of mercury", L"mmHg", 0.0013155687145324},
            {141, L"Pascals", L"Pa", 9.869232667160128e-6},
            {142, L"Pounds per square inch", L"psi", 0.068045961016531}
        });
    }
    return {};
}
