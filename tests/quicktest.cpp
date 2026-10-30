#include <QtQuickTest/quicktest.h>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QLocale>
#include <QDir>
#include <QGuiApplication>
#include <QStyleHints>
#include <QTemporaryDir>

class CalculatorTestSetup : public QObject
{
    Q_OBJECT
    QTemporaryDir m_dataRoot { QDir::currentPath() + "/calculator-test-data-XXXXXX" };
public slots:
    void applicationAvailable()
    {
        QCoreApplication::setOrganizationName("CalculatorTests");
        QCoreApplication::setApplicationName("StandardMode");
        if (!m_dataRoot.isValid())
            qFatal("Cannot create isolated test data directory");
        qputenv("XDG_CONFIG_HOME", (m_dataRoot.path() + "/config").toUtf8());
        qputenv("XDG_DATA_HOME", (m_dataRoot.path() + "/data").toUtf8());
        qputenv("XDG_CACHE_HOME", (m_dataRoot.path() + "/cache").toUtf8());
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
