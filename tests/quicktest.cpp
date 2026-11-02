#include "SystemPreferences.h"
#include "ControlledCurrencySource.h"
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
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QKeySequence>
#include <cstdio>

class ControlledSystemPreferences final : public SystemPreferences
{
    Q_OBJECT
    QString m_language = QStringLiteral("en-US");
    QString m_theme = QStringLiteral("light");
    QString m_preference = QStringLiteral("system");
public:
    using SystemPreferences::SystemPreferences;
    QString language() const override { return m_language; }
    QString theme() const override { return m_theme; }
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
        emit themeChanged();
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
        QStringList copyBindings;
        for (const auto &binding : QKeySequence::keyBindings(QKeySequence::Copy))
            copyBindings.append(binding.toString(QKeySequence::PortableText));
        engine->rootContext()->setContextProperty("testCopyBindings", copyBindings);
        engine->rootContext()->setContextProperty("testCurrencySource", new ControlledCurrencySource(engine));
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
        QLocale::setDefault(QLocale(qEnvironmentVariable("CALCULATOR_TEST_LOCALE",
            qEnvironmentVariable("CALCULATOR_TEST_LANGUAGE") == "zh-CN" ? "zh_CN" : "en_US")));
        QGuiApplication::styleHints()->setColorScheme(
            qEnvironmentVariable("CALCULATOR_TEST_THEME") == "dark" ? Qt::ColorScheme::Dark : Qt::ColorScheme::Light);
        QQuickStyle::setStyle("FluentWinUI3");
    }
};

static bool hasIsolatedEnvironment()
{
    const auto root = QDir::fromNativeSeparators(qEnvironmentVariable("CALCULATOR_TEST_ISOLATION_ROOT"));
    if (root.isEmpty() || !QDir(root).exists()
        || QDir::fromNativeSeparators(qEnvironmentVariable("DBUS_SYSTEM_BUS_ADDRESS")) != "unix:path=" + root + "/runtime/no-system-bus"
        || qEnvironmentVariable("QT_IM_MODULE") != "compose"
        || qEnvironmentVariable("QT_QPA_PLATFORM") != "offscreen"
        || qEnvironmentVariable("QT_QPA_PLATFORMTHEME") != "generic"
        || qEnvironmentVariable("QT_QUICK_BACKEND") != "software"
        || qEnvironmentVariable("QSG_RHI_BACKEND") != "software"
        || qEnvironmentVariable("NO_AT_BRIDGE") != "1"
        || qEnvironmentVariable("QT_QUICK_CONTROLS_STYLE") != "FluentWinUI3")
        return false;
    for (const auto name : {"DISPLAY", "WAYLAND_DISPLAY", "INPUT_METHOD", "XMODIFIERS", "GTK_IM_MODULE",
                           "QT_IM_MODULES", "DBUS_SESSION_BUS_PID", "DBUS_STARTER_ADDRESS", "DBUS_STARTER_BUS_TYPE",
                           "AT_SPI_BUS_ADDRESS", "QT_LINUX_ACCESSIBILITY_ALWAYS_ON", "QT_STYLE_OVERRIDE", "QT_QUICK_CONTROLS_CONF"}) {
        if (qEnvironmentVariableIsSet(name))
            return false;
    }
    for (const auto &entry : {qMakePair("XDG_RUNTIME_DIR", "/runtime"), qMakePair("XDG_CONFIG_HOME", "/config"),
                              qMakePair("XDG_CACHE_HOME", "/cache"), qMakePair("XDG_DATA_HOME", "/data")}) {
        if (QDir::fromNativeSeparators(qEnvironmentVariable(entry.first)) != root + entry.second)
            return false;
    }
#ifdef Q_OS_LINUX
    if (!qEnvironmentVariable("DBUS_SESSION_BUS_ADDRESS").startsWith("unix:path=" + root + "/runtime/bus"))
        return false;
#endif
    return true;
}

int main(int argc, char **argv)
{
    // This guard runs before setup and, crucially, before QuickTest creates
    // QGuiApplication (where platform/IME plugins and session-bus access start).
    if (!hasIsolatedEnvironment()) {
        if (qEnvironmentVariable("CALCULATOR_TEST_RELAUNCH_ATTEMPT") == "1") {
            std::fprintf(stderr, "Isolation validation failed after relaunch; refusing repeated launch.\n");
            return 2;
        }
        auto executable = QFileInfo(QString::fromLocal8Bit(argv[0])).absoluteFilePath();
        if (!QFileInfo::exists(executable))
            executable = QStandardPaths::findExecutable(QString::fromLocal8Bit(argv[0]));
        QStringList arguments {QStringLiteral(CALCULATOR_TEST_LAUNCHER), executable};
        for (int index = 1; index < argc; ++index)
            arguments.append(QString::fromLocal8Bit(argv[index]));
        QProcess launcher;
        auto environment = QProcessEnvironment::systemEnvironment();
        environment.insert("CALCULATOR_TEST_RELAUNCH_ATTEMPT", "1");
        launcher.setProcessEnvironment(environment);
        launcher.setProcessChannelMode(QProcess::ForwardedChannels);
        launcher.start(QStringLiteral(CALCULATOR_TEST_PYTHON), arguments);
        if (!launcher.waitForStarted() || !launcher.waitForFinished(-1)) {
            std::fprintf(stderr, "Cannot start isolated UI test launcher; refusing an unisolated run.\n");
            return 2;
        }
        return launcher.exitStatus() == QProcess::NormalExit ? launcher.exitCode() : 2;
    }
    if (argc == 2 && QByteArray(argv[1]) == "--isolation-probe") {
        const auto result = QJsonDocument(QJsonObject {
            {"root", qEnvironmentVariable("CALCULATOR_TEST_ISOLATION_ROOT")},
            {"platform", qEnvironmentVariable("QT_QPA_PLATFORM")},
            {"ime", qEnvironmentVariable("QT_IM_MODULE")},
            {"bus", qEnvironmentVariable("DBUS_SESSION_BUS_ADDRESS")},
            {"desktopVariablesRemoved", true}
        }).toJson(QJsonDocument::Compact);
        std::fwrite(result.constData(), 1, size_t(result.size()), stdout);
        std::fputc('\n', stdout);
        return 0;
    }
    QTEST_SET_MAIN_SOURCE_PATH
    CalculatorTestSetup setup;
    return quick_test_main_with_setup(argc, argv, "calculator_ui", QUICK_TEST_SOURCE_DIR, &setup);
}
#include "quicktest.moc"
