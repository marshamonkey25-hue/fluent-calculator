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
    emit historyChanged();
}

QVariantList CalculationSession::history() const
{
    QVariantList rows;
    if (m_mode != "standard" && m_mode != "scientific")
        return rows;
    const auto &items = m_manager->GetHistoryItems();
    for (auto it = items.rbegin(); it != items.rend(); ++it) {
        const auto &item = (*it)->historyItemVector;
        rows.append(QVariantMap{{"expression", QString::fromStdWString(item.expression).simplified()},
                                {"result", QString::fromStdWString(item.result)}});
    }
    return rows;
}

void CalculationSession::removeHistory(int index)
{
    if (m_mode != "standard" && m_mode != "scientific")
        return;
    const auto count = m_manager->GetHistoryItems().size();
    if (index < 0 || static_cast<size_t>(index) >= count)
        return;
    m_manager->RemoveHistoryItem(static_cast<unsigned int>(count - 1 - index));
    emit historyChanged();
}

void CalculationSession::reuseHistory(int index)
{
    if (m_mode != "standard" && m_mode != "scientific")
        return;
    const auto &items = m_manager->GetHistoryItems();
    if (index < 0 || static_cast<size_t>(index) >= items.size())
        return;
    const auto item = items[items.size() - 1 - index]->historyItemVector;
    std::vector<int> replay;
    // Match the pinned StandardCalculatorViewModel.GetCommandsFromExpressionCommands.
    // Replay native operand commands; parsing displayed results would lose precision.
    for (const auto &command : *item.spCommands) {
        switch (command->GetCommandType()) {
        case CalculationManager::CommandType::UnaryCommand: {
            const auto &codes = *static_cast<IUnaryCommand *>(command.get())->GetCommands();
            replay.insert(replay.end(), codes.begin(), codes.end());
            break;
        }
        case CalculationManager::CommandType::BinaryCommand:
            replay.push_back(static_cast<IBinaryCommand *>(command.get())->GetCommand());
            break;
        case CalculationManager::CommandType::Parentheses:
            replay.push_back(static_cast<IParenthesisCommand *>(command.get())->GetCommand());
            break;
        case CalculationManager::CommandType::OperandCommand: {
            const auto operand = static_cast<IOpndCommand *>(command.get());
            bool needsSign = operand->IsNegative();
            for (const int code : *operand->GetCommands()) {
                replay.push_back(code);
                if (needsSign && code != static_cast<int>(Command::Command0)) {
                    replay.push_back(static_cast<int>(Command::CommandSIGN));
                    needsSign = false;
                }
            }
            break;
        }
        }
    }
    const auto degree = m_manager->GetCurrentDegreeMode();
    m_manager->SetInHistoryItemLoadMode(true);
    m_manager->Reset(false);
    if (m_mode == "scientific")
        m_manager->SetScientificMode();
    m_manager->SendCommand(degree);
    for (const int code : replay)
        m_manager->SendCommand(static_cast<Command>(code));
    // The reference forces evaluation by toggling F-E twice; '=' would add history.
    m_manager->SendCommand(Command::CommandFE);
    m_manager->SendCommand(Command::CommandFE);
    m_manager->SetInHistoryItemLoadMode(false);
    SetExpressionDisplay(item.spTokens, item.spCommands);
    SetPrimaryDisplay(item.result, false);
}

void CalculationSession::clearHistory()
{
    if (m_mode != "standard" && m_mode != "scientific")
        return;
    m_manager->ClearHistory();
    emit historyChanged();
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

void CalculationSession::updateRadixDisplays()
{
    if (m_mode != "programmer")
        return;
    m_radixDisplays.clear();
    for (const auto radix : {16, 10, 8, 2})
        m_radixDisplays.append(m_error ? QString{} : QString::fromStdWString(m_manager->GetResultForRadix(radix, 64, true)));
    emit radixDisplaysChanged();
}

void CalculationSession::send(const QString &command)
{
    static const QHash<QString, Command> parenthesisCommands {
        {"openParenthesis", Command::CommandOPENP}, {"closeParenthesis", Command::CommandCLOSEP}
    };
    const auto parenthesis = parenthesisCommands.constFind(command);
    if (m_mode == QStringLiteral("scientific") && parenthesis != parenthesisCommands.cend()) {
        m_manager->SendCommand(parenthesis.value());
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
    const auto entry = commands.constFind(command);
    if (entry == commands.cend())
        return;

    // Match StandardCalculatorViewModel.OnButtonPressed: a digit or decimal
    // restarts input after an error; other enabled keys only clear the error.
    if (m_error && m_mode != "programmer") {
        m_manager->SendCommand(Command::CommandCLEAR);
        const auto opcode = entry.value();
        if (opcode != Command::CommandPNT
            && !(opcode >= Command::Command0 && opcode <= Command::Command9))
            return;
    }
    m_manager->SendCommand(entry.value());
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
void CalculationSession::OnHistoryItemAdded(unsigned int index)
{
    emit historyItemAdded(index);
    emit historyChanged();
}
void CalculationSession::MemoryItemChanged(unsigned int index) { emit memoryItemChanged(index); }
void CalculationSession::InputChanged() { emit inputChanged(); }
void CalculationSession::SetMemorizedNumbers(const std::vector<std::wstring> &numbers)
{
    QStringList strings;
    for (const auto &number : numbers)
        strings.append(QString::fromStdWString(number));
    emit memorizedNumbersChanged(strings);
}
