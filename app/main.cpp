#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("FluentCalculator");
    QCoreApplication::setApplicationName("Calculator");
    QGuiApplication::setDesktopFileName("fluent-calculator");
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/icons/fluent-calculator.png")));
    QQuickStyle::setStyle("FluentWinUI3");
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("Calculator", "MainWindow");
    return app.exec();
}
