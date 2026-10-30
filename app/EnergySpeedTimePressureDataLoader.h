#pragma once

#include "UnitConverter.h"
#include <QString>
#include <memory>

std::shared_ptr<UnitConversionManager::IConverterDataLoader> createEnergySpeedTimePressureDataLoader(const QString &category);
