#include "SystemPreferences.h"
#include <QtQuickTest/quicktest.h>
#include <QDir>
#include <QGuiApplication>
#include <QLocale>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QSettings>
#include <QStandardPaths>
#include <QStyleHints>
#include <QTemporaryDir>

class ControlledSystemPreferences final : public SystemPreferences
{
    Q_OBJECT
    QString m_language = QStringLiteral("en-US");
    QString m_theme = QStringLiteral("light");
    QString m_preference = QStringLiteral("system");
public:
    using SystemPreferences::SystemPreferences;
    QString language() const override { return m_language; }
    void applyTheme(const QString &preference) override
    {
        m_preference = preference;
        SystemPreferences::applyTheme(preference == "system" ? m_theme : preference);
    }
    Q_INVOKABLE void setSystemLanguage(const QString &language)
    {
        m_language = language;
        emit languageChanged();
    }
    Q_INVOKABLE void setSystemTheme(const QString &theme)
    {
        m_theme = theme;
        applyTheme(m_preference);
    }
};

class CalculatorTestSetup : public QObject
{
    Q_OBJECT
    QTemporaryDir m_dataRoot { QDir::currentPath() + "/calculator-test-data-XXXXXX" };
public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        auto system = new ControlledSystemPreferences(engine);
        if (qEnvironmentVariableIsEmpty("CALCULATOR_TEST_RESTART_STAGE"))
            QSettings().clear();
        if (qEnvironmentVariable("CALCULATOR_TEST_RESTART_STAGE") == "invalid") {
            QSettings settings;
            settings.setValue("appearance/theme", "ultraviolet");
            settings.setValue("appearance/language", "xx-XX");
            settings.setValue("navigation/lastMode", "unavailable-mode");
            settings.sync();
        }
        engine->rootContext()->setContextProperty("restartStage", qEnvironmentVariable("CALCULATOR_TEST_RESTART_STAGE"));
        system->setSystemLanguage(qEnvironmentVariable("CALCULATOR_TEST_LANGUAGE", "en-US"));
        system->setSystemTheme(qEnvironmentVariable("CALCULATOR_TEST_THEME", "light"));
        engine->rootContext()->setContextProperty("testSystemPreferences", system);
    }

    void applicationAvailable()
    {
        QCoreApplication::setOrganizationName("CalculatorTests");
        QCoreApplication::setApplicationName("StandardMode");
        if (!m_dataRoot.isValid())
            qFatal("Cannot create isolated test data directory");
        const auto externalRoot = qEnvironmentVariable("CALCULATOR_TEST_DATA_ROOT");
        const auto dataRoot = externalRoot.isEmpty() ? m_dataRoot.path() : externalRoot;
        qputenv("XDG_CONFIG_HOME", (dataRoot + "/config").toUtf8());
        qputenv("XDG_DATA_HOME", (dataRoot + "/data").toUtf8());
        qputenv("XDG_CACHE_HOME", (dataRoot + "/cache").toUtf8());
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, dataRoot + "/config");
        QSettings::setPath(QSettings::IniFormat, QSettings::SystemScope, dataRoot + "/system-config");
        QStandardPaths::setTestModeEnabled(true);
        QLocale::setDefault(qEnvironmentVariable("CALCULATOR_TEST_LANGUAGE") == "zh-CN"
                            ? QLocale(QLocale::Chinese, QLocale::China)
                            : QLocale(QLocale::English, QLocale::UnitedStates));
        QGuiApplication::styleHints()->setColorScheme(
            qEnvironmentVariable("CALCULATOR_TEST_THEME") == "dark" ? Qt::ColorScheme::Dark : Qt::ColorScheme::Light);
        QQuickStyle::setStyle("FluentWinUI3");
    }
};

QUICK_TEST_MAIN_WITH_SETUP(calculator_ui, CalculatorTestSetup)
#include "quicktest.moc"
