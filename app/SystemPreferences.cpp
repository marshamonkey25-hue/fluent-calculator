#include "SystemPreferences.h"
#include <QEvent>
#include <QGuiApplication>
#include <QLocale>
#include <QStyleHints>

SystemPreferences::SystemPreferences(QObject *parent) : QObject(parent)
{
    qApp->installEventFilter(this);
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, &SystemPreferences::themeChanged);
}

QString SystemPreferences::language() const
{
    const auto languages = QLocale::system().uiLanguages();
    return languages.isEmpty() ? QStringLiteral("en-US") : languages.first();
}

QString SystemPreferences::theme() const
{
    // Keep Unknown observable; AppPreferences owns the app's fallback choice.
    const auto scheme = QGuiApplication::styleHints()->colorScheme();
    return scheme == Qt::ColorScheme::Dark ? QStringLiteral("dark")
         : scheme == Qt::ColorScheme::Light ? QStringLiteral("light") : QStringLiteral("unknown");
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
