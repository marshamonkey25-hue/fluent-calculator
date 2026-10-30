#pragma once

#include <QJsonObject>
#include "SystemPreferences.h"
#include <QObject>
#include <QTranslator>
#include <QQmlParserStatus>
#include <QtQml/qqmlregistration.h>

// Uses Qt's context/source translation lookup, so every page can keep using
// qsTr. The small JSON catalog avoids requiring Linguist tools at build time.
class UiTranslator final : public QTranslator
{
public:
    void setLanguage(const QString &language);
    bool isEmpty() const override { return m_catalog.isEmpty(); }
    QString translate(const char *context, const char *sourceText,
                      const char *disambiguation = nullptr, int n = -1) const override;
private:
    QJsonObject m_catalog;
};

// Application-owned preferences shared by all pages; calculations remain in the
// independent session while appearance changes in place.
class AppPreferences : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    QML_ELEMENT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(SystemPreferences *systemPreferences READ systemPreferences WRITE setSystemPreferences NOTIFY systemPreferencesChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString effectiveLanguage READ effectiveLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString lastMode READ lastMode WRITE setLastMode NOTIFY lastModeChanged)
public:
    explicit AppPreferences(QObject *parent = nullptr);
    ~AppPreferences() override;
    void classBegin() override {}
    void componentComplete() override;
    SystemPreferences *systemPreferences() const { return m_systemPreferences; }
    void setSystemPreferences(SystemPreferences *preferences);
    QString theme() const { return m_theme; }
    QString language() const { return m_language; }
    QString effectiveLanguage() const { return m_effectiveLanguage; }
    QString lastMode() const { return m_lastMode; }
    void setLastMode(const QString &mode);
    void setTheme(const QString &theme);
    void setLanguage(const QString &language);
signals:
    void systemPreferencesChanged();
    void themeChanged();
    void languageChanged();
    void lastModeChanged();
private:
    void applyLanguage();
    SystemPreferences m_nativeSystemPreferences;
    SystemPreferences *m_systemPreferences = &m_nativeSystemPreferences;
    QString m_theme = QStringLiteral("system");
    QString m_language = QStringLiteral("system");
    QString m_effectiveLanguage;
    QString m_lastMode = QStringLiteral("standard");
    UiTranslator m_translator;
};
