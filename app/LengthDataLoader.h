#pragma once

#include "UnitConverter.h"
#include <memory>

std::shared_ptr<UnitConversionManager::IConverterDataLoader> createLengthDataLoader();
