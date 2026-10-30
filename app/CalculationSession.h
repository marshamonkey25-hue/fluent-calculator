#pragma once

#include "EngineResources.h"
#include "CalculatorManager.h"
#include <QObject>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

// One session per application. The upstream Ratpack constants are process-global;
// dispatch commands serially on the GUI thread and keep this manager across pages.
class CalculationSession : public QObject, private ICalcDisplay
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString display READ display NOTIFY displayChanged)
    Q_PROPERTY(QString expression READ expression NOTIFY expressionChanged)
    Q_PROPERTY(bool error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    explicit CalculationSession(QObject *parent = nullptr);
    QString display() const { return m_display; }
    QString expression() const { return m_expression; }
    bool error() const { return m_error; }
    QString language() const { return m_language; }
    void setLanguage(const QString &language);
    Q_INVOKABLE void send(const QString &command);

signals:
    void languageChanged();
    void displayChanged();
    void expressionChanged();
    void errorChanged();
    void parenthesisNumberChanged(uint count);
    void noRightParenthesisAdded();
    void maxDigitsReached();
    void binaryOperatorReceived();
    void historyItemAdded(uint index);
    void memorizedNumbersChanged(const QStringList &numbers);
    void memoryItemChanged(uint index);
    void inputChanged();

private:
    void SetPrimaryDisplay(const std::wstring &text, bool isError) override;
    void SetIsInError(bool isError) override;
    void SetExpressionDisplay(
        const std::shared_ptr<std::vector<std::pair<std::wstring, int>>> &tokens,
        const std::shared_ptr<std::vector<std::shared_ptr<IExpressionCommand>>> &commands) override;
    void SetParenthesisNumber(unsigned int count) override;
    void OnNoRightParenAdded() override;
    void MaxDigitsReached() override;
    void BinaryOperatorReceived() override;
    void OnHistoryItemAdded(unsigned int index) override;
    void SetMemorizedNumbers(const std::vector<std::wstring> &numbers) override;
    void MemoryItemChanged(unsigned int index) override;
    void InputChanged() override;

    QString m_display = QStringLiteral("0");
    QString m_expression;
    bool m_error = false;
    std::vector<std::pair<std::wstring, int>> m_tokens;
    std::vector<std::shared_ptr<IExpressionCommand>> m_expressionCommands;
    QString m_language;
    EngineResources m_resources;
    std::unique_ptr<CalculationManager::CalculatorManager> m_manager;
};
