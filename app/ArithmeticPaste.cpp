// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
// Clipboard rules and command replay adapted from Microsoft Calculator,
// pinned 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128:
// CopyPasteManager.cs and StandardCalculatorViewModel.OnPaste.
#include "ArithmeticPaste.h"
#include <QRegularExpression>
#include <limits>

using CalculationManager::Command;

namespace {
bool appendOperand(QString operand, bool negative, bool programmer, int radix, int wordWidth,
                   int precision, std::vector<Command> &commands)
{
    QString digits = operand;
    if (programmer) {
        const QString prefix = radix == 16 ? "0[xX]" : radix == 10 ? "0[nN]"
            : radix == 8 ? "0[oOtT]" : "0[bByY]";
        const QString alphabet = radix == 16 ? "0-9a-fA-F" : radix == 10 ? "0-9" : radix == 8 ? "0-7" : "01";
        const QString number = "[" + alphabet + "]+(?:[_'`][" + alphabet + "]+)*";
        const QString suffix = radix == 16 ? "[hH]?" : radix == 2 ? "[bB]?" : "";
        const QRegularExpression pattern("^(?:" + prefix + ")?(" + number + ")(?:[uU]?[lL]{0,2}|" + suffix + ")$");
        const auto match = pattern.match(operand);
        if (!match.hasMatch() || (negative && radix != 10))
            return false;
        digits = match.captured(1);
        digits.remove(QRegularExpression("[_'`]"));
        bool parsed = false;
        const auto value = digits.toULongLong(&parsed, radix);
        const auto maxValue = radix == 10 ? (quint64(1) << (wordWidth - 1)) - 1
            : std::numeric_limits<quint64>::max() >> (64 - wordWidth);
        if (!parsed || digits.size() > QString::number(maxValue, radix).size()
            || value > maxValue + (negative ? quint64(1) : quint64(0)))
            return false;
    } else {
        static const QRegularExpression pattern("^(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:e[+-]?[0-9]{1,4})?$");
        if (!pattern.match(operand).hasMatch())
            return false;
        auto mantissa = operand.section('e', 0, 0);
        if (mantissa.startsWith("0."))
            mantissa.remove(0, 2);
        else
            mantissa.remove('.');
        if (mantissa.size() > precision)
            return false;
    }

    bool negate = negative;
    for (qsizetype index = 0; index < digits.size(); ++index) {
        const auto character = digits[index].toUpper();
        if (character == '.') {
            commands.push_back(Command::CommandPNT);
        } else if (!programmer && character == 'E') {
            commands.push_back(Command::CommandEXP);
            if (index + 1 < digits.size() && (digits[index + 1] == '-' || digits[index + 1] == '+')) {
                if (digits[++index] == '-')
                    commands.push_back(Command::CommandSIGN);
            }
        } else {
            const int digit = QStringLiteral("0123456789ABCDEF").indexOf(character);
            commands.push_back(static_cast<Command>(static_cast<int>(Command::Command0) + digit));
            // Sending the sign before the final digit admits the signed minimum
            // (-2^(width-1)) without first overflowing its positive magnitude.
            if (negate && digit != 0) {
                commands.push_back(Command::CommandSIGN);
                negate = false;
            }
        }
    }
    return true;
}
}

std::optional<std::vector<Command>> arithmeticPasteCommands(
    const QString &text, const QString &mode, int radix, int wordWidth)
{
    if (text.size() > 512)
        return std::nullopt;
    QString input;
    const QString ignored = QString::fromUtf8(",\"¥¤₵$₡₩₪₦₹£€\u202a\u202b\u202c\u202d");
    for (const auto character : text) {
        if (character.isSpace() || ignored.contains(character))
            continue;
        if (character.digitValue() >= 0)
            input += QChar('0' + character.digitValue());
        else
            input += character;
    }
    const bool programmer = mode == "programmer";
    if (!programmer)
        input = input.toLower();
    const bool equals = input.endsWith('=');
    if (equals)
        input.chop(1);
    std::vector<Command> commands;
    std::vector<bool> parentheses;
    bool expectOperand = true;
    int operands = 0;
    qsizetype index = 0;
    while (index < input.size()) {
        if (expectOperand) {
            bool negative = false;
            if (input[index] == '-' || input[index] == '+') {
                negative = input[index] == '-';
                if (++index == input.size())
                    return std::nullopt;
            }
            if (input[index] == '(' && mode != "standard") {
                parentheses.push_back(negative);
                commands.push_back(Command::CommandOPENP);
                ++index;
                continue;
            }
            const auto start = index;
            while (index < input.size()) {
                const auto character = input[index];
                if (QStringLiteral("+-*/^%()=").contains(character)) {
                    if (!programmer && (character == '+' || character == '-') && index > start && input[index - 1] == 'e') {
                        ++index;
                        continue;
                    }
                    break;
                }
                ++index;
            }
            if (++operands > 100 || !appendOperand(input.mid(start, index - start), negative, programmer,
                                                   radix, wordWidth, mode == "scientific" ? 32 : 16, commands))
                return std::nullopt;
            expectOperand = false;
        } else {
            const auto character = input[index++];
            if (character == ')' && !parentheses.empty()) {
                commands.push_back(Command::CommandCLOSEP);
                if (parentheses.back())
                    commands.push_back(Command::CommandSIGN);
                parentheses.pop_back();
                continue;
            }
            switch (character.unicode()) {
            case '+': commands.push_back(Command::CommandADD); break;
            case '-': commands.push_back(Command::CommandSUB); break;
            case '*': commands.push_back(Command::CommandMUL); break;
            case '/': commands.push_back(Command::CommandDIV); break;
            case '^':
                if (mode != "scientific") return std::nullopt;
                commands.push_back(Command::CommandPWR); break;
            case '%':
                if (mode == "standard") return std::nullopt;
                commands.push_back(Command::CommandMOD); break;
            default: return std::nullopt;
            }
            expectOperand = true;
        }
    }
    if (expectOperand)
        return std::nullopt;
    if (equals)
        commands.push_back(Command::CommandEQU);
    return commands;
}
