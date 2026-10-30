#include "CalculationSession.h"
#include "Command.h"
#include <QClipboard>
#include <QGuiApplication>

using CalculationManager::Command;

CalculationSession::CalculationSession(QObject *parent) : QObject(parent)
{
    m_manager = std::make_unique<CalculationManager::CalculatorManager>(static_cast<ICalcDisplay *>(this), &m_resources);
    m_manager->SetStandardMode();
}

void CalculationSession::setLanguage(const QString &language)
{
    if (language == m_language)
        return;
    m_language = language;
    m_resources.setLanguage(language);
    m_manager->RefreshResources();
    emit languageChanged();
}

void CalculationSession::selectMode(const QString &mode)
{
    if (mode == m_mode)
        return;
    if (mode != "scientific" && mode != "standard" && mode != "programmer")
        return;
    if (m_mode == "scientific")
        setScientificNotation(false);
    if (mode == QStringLiteral("scientific"))
        m_manager->SetScientificMode();
    else if (mode == QStringLiteral("standard"))
        m_manager->SetStandardMode();
    else if (mode == QStringLiteral("programmer")) {
        m_manager->SetProgrammerMode();
        m_manager->SendCommand(Command::CommandQword);
        m_wordWidth = 64;
        emit wordWidthChanged();
        m_radix = 10;
        emit radixChanged();
    } else
        return;
    m_mode = mode;
    updateRadixDisplays();
    emit modeChanged();
    emit inputChanged();
}

void CalculationSession::setScientificNotation(bool enabled)
{
    if (m_scientificNotation == enabled)
        return;
    // CEngine ignores FE while in error. Clear that state before resetting
    // notation for a mode change so the engine and the toggle stay in sync.
    if (m_error)
        m_manager->SendCommand(Command::CommandCLEAR);
    m_manager->SendCommand(Command::CommandFE);
    m_scientificNotation = enabled;
    emit scientificNotationChanged();
}

void CalculationSession::setSecondFunction(bool enabled)
{
    if (m_secondFunction == enabled)
        return;
    m_secondFunction = enabled;
    emit secondFunctionChanged();
}

void CalculationSession::selectAngleUnit(const QString &unit)
{
    if (m_mode != QStringLiteral("scientific") || m_error)
        return;
    static const QHash<QString, Command> units {
        {"DEG", Command::CommandDEG}, {"RAD", Command::CommandRAD}, {"GRAD", Command::CommandGRAD}
    };
    const auto command = units.constFind(unit);
    if (command == units.cend() || unit == m_angleUnit)
        return;
    // The Scientific engine retains its angle setting across Clear and mode
    // changes. Keep the visible unit with that engine, rather than with a page.
    m_manager->SendCommand(command.value());
    m_angleUnit = unit;
    emit angleUnitChanged();
}

void CalculationSession::selectWordWidth(int width)
{
    if (m_mode != "programmer" || m_error)
        return;
    Command command;
    switch (width) {
    case 64: command = Command::CommandQword; break;
    case 32: command = Command::CommandDword; break;
    case 16: command = Command::CommandWord; break;
    case 8: command = Command::CommandByte; break;
    default: return;
    }
    m_manager->SendCommand(command);
    m_wordWidth = width;
    emit wordWidthChanged();
    updateRadixDisplays();
}

void CalculationSession::selectRadix(int radix)
{
    if (m_mode != "programmer" || m_error)
        return;
    Command command;
    switch (radix) {
    case 16: command = Command::CommandHex; break;
    case 10: command = Command::CommandDec; break;
    case 8: command = Command::CommandOct; break;
    case 2: command = Command::CommandBin; break;
    default: return;
    }
    m_manager->SendCommand(command);
    m_radix = radix;
    emit radixChanged();
    updateRadixDisplays();
}

void CalculationSession::toggleBit(int position)
{
    if (m_mode != "programmer" || m_error || position < 0 || position >= m_wordWidth)
        return;
    m_manager->SendCommand(static_cast<Command>(static_cast<int>(Command::CommandBINPOS0) + position));
    updateRadixDisplays();
}

void CalculationSession::updateRadixDisplays()
{
    if (m_mode != "programmer")
        return;
    m_radixDisplays.clear();
    for (const auto radix : {16, 10, 8, 2})
        m_radixDisplays.append(m_error ? QString{} : QString::fromStdWString(m_manager->GetResultForRadix(radix, 64, true)));
    m_binaryBits = m_error ? QString(64, QLatin1Char('0'))
                          : QString::fromStdWString(m_manager->GetResultForRadix(2, 64, false)).rightJustified(64, QLatin1Char('0'));
    emit radixDisplaysChanged();
}

void CalculationSession::send(const QString &command)
{
    if (command == "scientificNotation") {
        if (m_mode == "scientific" && !m_error)
            setScientificNotation(!m_scientificNotation);
        return;
    }
    static const QHash<QString, Command> scientificCommands {
        {"openParenthesis", Command::CommandOPENP}, {"closeParenthesis", Command::CommandCLOSEP},
        {"cube", Command::CommandCUB}, {"cubeRoot", Command::CommandCUBEROOT},
        {"power", Command::CommandPWR}, {"root", Command::CommandROOT},
        {"powerTen", Command::CommandPOW10}, {"powerTwo", Command::CommandPOW2},
        {"log", Command::CommandLOG}, {"logBase", Command::CommandLogBaseY},
        {"ln", Command::CommandLN}, {"powerE", Command::CommandPOWE},
        {"factorial", Command::CommandFAC},
        {"pi", Command::CommandPI}, {"euler", Command::CommandEuler},
        {"exp", Command::CommandEXP},
        {"abs", Command::CommandAbs}, {"floor", Command::CommandFloor},
        {"ceil", Command::CommandCeil}, {"rand", Command::CommandRand},
        {"dms", Command::CommandDMS}, {"degrees", Command::CommandDegrees},
    };
    static const QHash<QString, Command> trigonometryCommands {
        {"sin", Command::CommandSIN}, {"cos", Command::CommandCOS}, {"tan", Command::CommandTAN},
        {"sec", Command::CommandSEC}, {"csc", Command::CommandCSC}, {"cot", Command::CommandCOT},
        {"asin", Command::CommandASIN}, {"acos", Command::CommandACOS}, {"atan", Command::CommandATAN},
        {"asec", Command::CommandASEC}, {"acsc", Command::CommandACSC}, {"acot", Command::CommandACOT},
        {"sinh", Command::CommandSINH}, {"cosh", Command::CommandCOSH}, {"tanh", Command::CommandTANH},
        {"sech", Command::CommandSECH}, {"csch", Command::CommandCSCH}, {"coth", Command::CommandCOTH},
        {"asinh", Command::CommandASINH}, {"acosh", Command::CommandACOSH}, {"atanh", Command::CommandATANH},
        {"asech", Command::CommandASECH}, {"acsch", Command::CommandACSCH}, {"acoth", Command::CommandACOTH}
    };
    const auto trigonometry = trigonometryCommands.constFind(command);
    if (trigonometry != trigonometryCommands.cend()) {
        if (m_mode == QStringLiteral("scientific") && !m_error)
            m_manager->SendCommand(trigonometry.value());
        return;
    }
    static const QHash<QString, Command> bitwiseCommands {
        {"and", Command::CommandAnd}, {"or", Command::CommandOR},
        {"not", Command::CommandNot}, {"nand", Command::CommandNand},
        {"nor", Command::CommandNor}, {"xor", Command::CommandXor},
        {"shiftLeft", Command::CommandLSHF}, {"shiftRight", Command::CommandRSHF},
        {"shiftRightLogical", Command::CommandRSHFL},
        {"rotateLeft", Command::CommandROL}, {"rotateRight", Command::CommandROR},
        {"rotateCarryLeft", Command::CommandROLC}, {"rotateCarryRight", Command::CommandRORC}
    };
    const auto bitwise = bitwiseCommands.constFind(command);
    if (bitwise != bitwiseCommands.cend()) {
        if (m_mode == "programmer" && !m_error)
            m_manager->SendCommand(bitwise.value());
        updateRadixDisplays();
        return;
    }
    static const QHash<QString, Command> commands {
        {"0", Command::Command0}, {"1", Command::Command1},
        {"2", Command::Command2}, {"3", Command::Command3},
        {"4", Command::Command4}, {"5", Command::Command5},
        {"6", Command::Command6}, {"7", Command::Command7},
        {"8", Command::Command8}, {"9", Command::Command9},
        {"A", Command::CommandA}, {"B", Command::CommandB},
        {"C", Command::CommandC}, {"D", Command::CommandD},
        {"E", Command::CommandE}, {"F", Command::CommandF},
        {"decimal", Command::CommandPNT}, {"add", Command::CommandADD},
        {"subtract", Command::CommandSUB}, {"multiply", Command::CommandMUL},
        {"divide", Command::CommandDIV}, {"equals", Command::CommandEQU},
        {"clear", Command::CommandCLEAR}, {"percent", Command::CommandPERCENT},
        {"sign", Command::CommandSIGN}, {"square", Command::CommandSQR},
        {"squareRoot", Command::CommandSQRT}, {"reciprocal", Command::CommandREC},
        {"clearEntry", Command::CommandCENTR}, {"backspace", Command::CommandBACK},
        {"negate", Command::CommandSIGN}, {"open", Command::CommandOPENP},
        {"close", Command::CommandCLOSEP}, {"mod", Command::CommandMOD}
    };
    if (command.size() == 1) {
        const int digit = QStringLiteral("0123456789ABCDEF").indexOf(command);
        const int base = m_mode == "programmer" ? m_radix : 10;
        if (digit >= base)
            return;
    }
    if (m_mode == "programmer" && command == "decimal")
        return;
    Command opcode;
    const auto scientific = scientificCommands.constFind(command);
    if (scientific != scientificCommands.cend()) {
        if (m_mode != "scientific")
            return;
        opcode = scientific.value();
    } else {
        const auto entry = commands.constFind(command);
        if (entry == commands.cend())
            return;
        opcode = entry.value();
    }

    // Match StandardCalculatorViewModel.OnButtonPressed: a digit or decimal
    // restarts input after an error; other enabled keys only clear the error.
    if (m_error && m_mode != "programmer") {
        m_manager->SendCommand(Command::CommandCLEAR);
        if (opcode != Command::CommandPNT
            && !(opcode >= Command::Command0 && opcode <= Command::Command9))
            return;
    }
    if (m_mode == "scientific" && (command == "clear" || command == "clearEntry"))
        setScientificNotation(false);
    m_manager->SendCommand(opcode);
    updateRadixDisplays();
}

void CalculationSession::copyResult()
{
    // The reference copies ungrouped numeric text, or the localized error text.
    // Keep digits as strings, including values beyond JavaScript's exact range.
    QString text = m_display;
    if (!m_error)
        text.remove(QString::fromStdWString(m_resources.GetCEngineString(L"sThousand")));
    QGuiApplication::clipboard()->setText(text);
}

void CalculationSession::SetPrimaryDisplay(const std::wstring &text, bool isError)
{
    m_display = QString::fromStdWString(text);
    SetIsInError(isError);
    emit displayChanged();
}

void CalculationSession::SetIsInError(bool isError)
{
    if (m_error != isError) {
        m_error = isError;
        emit errorChanged();
    }
}

void CalculationSession::SetExpressionDisplay(
    const std::shared_ptr<std::vector<std::pair<std::wstring, int>>> &tokens,
    const std::shared_ptr<std::vector<std::shared_ptr<IExpressionCommand>>> &commands)
{
    // The history collector mutates its vectors; retain a snapshot and the native
    // command objects so history replay does not need to parse formatted numbers.
    m_tokens = tokens ? *tokens : std::vector<std::pair<std::wstring, int>>{};
    m_expressionCommands = commands ? *commands : std::vector<std::shared_ptr<IExpressionCommand>>{};
    m_expression.clear();
    for (const auto &token : m_tokens) {
        const auto text = QString::fromStdWString(token.first);
        if (!m_expression.isEmpty() && !m_expression.endsWith(QLatin1Char('('))
            && !text.startsWith(QLatin1Char(')')))
            m_expression += QLatin1Char(' ');
        m_expression += text;
    }
    m_expression = m_expression.simplified();
    emit expressionChanged();
}

void CalculationSession::SetParenthesisNumber(unsigned int count) { emit parenthesisNumberChanged(count); }
void CalculationSession::OnNoRightParenAdded() { emit noRightParenthesisAdded(); }
void CalculationSession::MaxDigitsReached() { emit maxDigitsReached(); }
void CalculationSession::BinaryOperatorReceived() { emit binaryOperatorReceived(); }
void CalculationSession::OnHistoryItemAdded(unsigned int index) { emit historyItemAdded(index); }
void CalculationSession::MemoryItemChanged(unsigned int index) { emit memoryItemChanged(index); }
void CalculationSession::InputChanged() { emit inputChanged(); }
void CalculationSession::SetMemorizedNumbers(const std::vector<std::wstring> &numbers)
{
    QStringList strings;
    for (const auto &number : numbers)
        strings.append(QString::fromStdWString(number));
    emit memorizedNumbersChanged(strings);
}
