#pragma once

#include "UnitConverter.h"
#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <memory>

// One noncurrency converter session; numeric values cross QML as text only.
class ConversionSession : public QObject, private UnitConversionManager::IUnitConverterVMCallback
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
    Q_PROPERTY(QVariantList units READ units NOTIFY unitsChanged)
    Q_PROPERTY(int unit1 READ unit1 WRITE setUnit1 NOTIFY unitsChanged)
    Q_PROPERTY(int unit2 READ unit2 WRITE setUnit2 NOTIFY unitsChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(int activeSide READ activeSide NOTIFY activeSideChanged)
    Q_PROPERTY(QString value1 READ value1 NOTIFY displayChanged)
    Q_PROPERTY(QString value2 READ value2 NOTIFY displayChanged)
public:
    explicit ConversionSession(QObject *parent = nullptr);
    QString language() const { return m_language; }
    void setLanguage(const QString &language);
    QString category() const { return m_category; }
    void setCategory(const QString &category);
    QVariantList units() const;
    int unit1() const { return m_unit1; }
    int unit2() const { return m_unit2; }
    void setUnit1(int id);
    void setUnit2(int id);
    QString value1() const;
    QString value2() const;
    QString status() const { return m_status; }
    int activeSide() const { return m_activeSide; }
    Q_INVOKABLE void activate(int side);
    Q_INVOKABLE void paste();
    Q_INVOKABLE void copy();
    Q_INVOKABLE void send(const QString &command);
signals:
    void categoryChanged();
    void languageChanged();
    void unitsChanged();
    void activeSideChanged();
    void statusChanged();
    void displayChanged();
private:
    void initializeConverter(std::shared_ptr<UnitConversionManager::IConverterDataLoader> loader);
    void selectUnits();
    void DisplayCallback(const std::wstring &from, const std::wstring &to) override;
    void SuggestedValueCallback(const std::vector<std::tuple<std::wstring, UnitConversionManager::Unit>> &) override {}
    void MaxDigitsReached() override;
    void setStatus(const QString &status);
    QString m_category = QStringLiteral("length");
    QString m_language = QStringLiteral("en-US");
    QString m_status;
    QString m_value1 = QStringLiteral("0");
    QString m_value2 = QStringLiteral("0");
    int m_activeSide = 1;
    int m_unit1 = 32;
    int m_unit2 = 30;
    std::vector<UnitConversionManager::Unit> m_units;
    std::shared_ptr<UnitConversionManager::UnitConverter> m_converter;
};
