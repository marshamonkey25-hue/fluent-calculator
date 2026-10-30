#pragma once

#include "Command.h"
#include <QString>
#include <optional>
#include <vector>

// Validate the complete clipboard expression before changing the engine's input.
// Numeric operands stay text; only bounded Programmer integers use integer parsing.
std::optional<std::vector<CalculationManager::Command>> arithmeticPasteCommands(
    const QString &text, const QString &mode, int radix, int wordWidth);
