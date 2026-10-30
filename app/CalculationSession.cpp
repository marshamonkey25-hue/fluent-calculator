#include "CalculationSession.h"
#include "Command.h"

using CalculationManager::Command;

CalculationSession::CalculationSession(QObject *parent) : QObject(parent)
{
    m_manager = std::make_unique<CalculationManager::CalculatorManager>(static_cast<ICalcDisplay *>(this), &m_resources);
    m_manager->SetStandardMode();
}

void CalculationSession::selectMode(const QString &mode)
{
    if (mode == m_mode)
        return;
    if (mode == QStringLiteral("scientific"))
        m_manager->SetScientificMode();
    else if (mode == QStringLiteral("standard"))
        m_manager->SetStandardMode();
    else
        return;
    m_mode = mode;
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
        {"decimal", Command::CommandPNT}, {"add", Command::CommandADD},
        {"subtract", Command::CommandSUB}, {"multiply", Command::CommandMUL},
        {"divide", Command::CommandDIV}, {"equals", Command::CommandEQU},
        {"clear", Command::CommandCLEAR}
    };
    const auto entry = commands.constFind(command);
    if (entry != commands.cend())
        m_manager->SendCommand(entry.value());
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
