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
    Q_PROPERTY(QString mode READ mode NOTIFY modeChanged)
    Q_PROPERTY(bool inputEmpty READ inputEmpty NOTIFY inputChanged)
    Q_PROPERTY(bool scientificNotation READ scientificNotation NOTIFY scientificNotationChanged)
    Q_PROPERTY(bool secondFunction READ secondFunction WRITE setSecondFunction NOTIFY secondFunctionChanged)
    Q_PROPERTY(int radix READ radix NOTIFY radixChanged)
    Q_PROPERTY(int wordWidth READ wordWidth NOTIFY wordWidthChanged)
    Q_PROPERTY(QStringList radixDisplays READ radixDisplays NOTIFY radixDisplaysChanged)

public:
    explicit CalculationSession(QObject *parent = nullptr);
    QString display() const { return m_display; }
    QString expression() const { return m_expression; }
    bool error() const { return m_error; }
    QString language() const { return m_language; }
    void setLanguage(const QString &language);
    QString mode() const { return m_mode; }
    bool inputEmpty() const { return !m_manager || m_manager->IsInputEmpty(); }
    bool scientificNotation() const { return m_scientificNotation; }
    bool secondFunction() const { return m_secondFunction; }
    void setSecondFunction(bool enabled);
    int radix() const { return m_radix; }
    QStringList radixDisplays() const { return m_radixDisplays; }
    int wordWidth() const { return m_wordWidth; }
    Q_INVOKABLE void selectWordWidth(int width);
    Q_INVOKABLE void selectRadix(int radix);
    Q_INVOKABLE void send(const QString &command);
    Q_INVOKABLE void copyResult();
    Q_INVOKABLE void selectMode(const QString &mode);

signals:
    void scientificNotationChanged();
    void secondFunctionChanged();
    void languageChanged();
    void modeChanged();
    void radixChanged();
    void wordWidthChanged();
    void radixDisplaysChanged();
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
    void setScientificNotation(bool enabled);
    void updateRadixDisplays();
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

    bool m_scientificNotation = false;
    bool m_secondFunction = false;
    int m_wordWidth = 64;
    int m_radix = 10;
    QStringList m_radixDisplays { "0", "0", "0", "0" };
    QString m_mode = QStringLiteral("standard");
    QString m_display = QStringLiteral("0");
    QString m_expression;
    bool m_error = false;
    std::vector<std::pair<std::wstring, int>> m_tokens;
    std::vector<std::shared_ptr<IExpressionCommand>> m_expressionCommands;
    QString m_language;
    EngineResources m_resources;
    std::unique_ptr<CalculationManager::CalculatorManager> m_manager;
};
