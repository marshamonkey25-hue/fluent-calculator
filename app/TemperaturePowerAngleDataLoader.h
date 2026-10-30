#pragma once

#include "UnitConverter.h"
#include <memory>

std::shared_ptr<UnitConversionManager::IConverterDataLoader> createTemperatureDataLoader();
std::shared_ptr<UnitConversionManager::IConverterDataLoader> createPowerDataLoader();
std::shared_ptr<UnitConversionManager::IConverterDataLoader> createAngleDataLoader();
