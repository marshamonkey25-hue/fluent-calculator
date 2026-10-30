#include "SystemPreferences.h"
#include <QEvent>
#include <QGuiApplication>
#include <QLocale>
#include <QStyleHints>

SystemPreferences::SystemPreferences(QObject *parent) : QObject(parent)
{
    qApp->installEventFilter(this);
}

QString SystemPreferences::language() const
{
    const auto languages = QLocale::system().uiLanguages();
    return languages.isEmpty() ? QStringLiteral("en-US") : languages.first();
}

void SystemPreferences::applyTheme(const QString &preference)
{
    QGuiApplication::styleHints()->setColorScheme(
        preference == "dark" ? Qt::ColorScheme::Dark :
        preference == "light" ? Qt::ColorScheme::Light : Qt::ColorScheme::Unknown);
}

bool SystemPreferences::eventFilter(QObject *object, QEvent *event)
{
    if (object == qApp && (event->type() == QEvent::LocaleChange || event->type() == QEvent::ApplicationActivate))
        emit languageChanged();
    return QObject::eventFilter(object, event);
}
