#pragma once

#include "UnitConverter.h"
#include <algorithm>
#include <iterator>

// Each catalog supplies factors in its own base unit, in the same order as units.
// Temperature's offset conversions deliberately use their explicit pair table.
template<typename FactorAt>
std::unordered_map<UnitConversionManager::Unit, UnitConversionManager::ConversionData, UnitConversionManager::UnitHash>
loadProportionalRatios(const UnitConversionManager::Unit &unit,
                       const std::vector<UnitConversionManager::Unit> &units, FactorAt factorAt)
{
    using namespace UnitConversionManager;
    std::unordered_map<Unit, ConversionData, UnitHash> ratios;
    const auto source = std::find(units.begin(), units.end(), unit);
    if (source == units.end())
        return ratios;
    const double sourceFactor = factorAt(std::distance(units.begin(), source));
    for (size_t index = 0; index < units.size(); ++index)
        ratios.emplace(units[index], ConversionData(sourceFactor / factorAt(index), 0, false));
    return ratios;
}
