#include "AppPreferences.h"
#include <QFile>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QLocale>
#include <QQmlEngine>
#include <QSettings>

void UiTranslator::setLanguage(const QString &language)
{
    m_catalog = {};
    if (language == "zh-CN") {
        QFile file(QStringLiteral(":/ui/zh-CN.json"));
        if (!file.open(QIODevice::ReadOnly))
            qFatal("Cannot load calculator UI translations");
        QJsonParseError error;
        const auto document = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.isObject())
            qFatal("Invalid calculator UI translations");
        m_catalog = document.object();
    }
}

QString UiTranslator::translate(const char *context, const char *sourceText, const char *, int) const
{
    return m_catalog.value(QString::fromUtf8(context)).toObject()
        .value(QString::fromUtf8(sourceText)).toString();
}

AppPreferences::AppPreferences(QObject *parent) : QObject(parent)
{
    QSettings settings;
    const auto theme = settings.value("appearance/theme", "system").toString();
    m_theme = theme == "light" || theme == "dark" ? theme : QStringLiteral("system");
    const auto language = settings.value("appearance/language", "system").toString();
    m_language = language == "en-US" || language == "zh-CN" ? language : QStringLiteral("system");
    m_lastMode = settings.value("navigation/lastMode", "standard").toString();
    m_systemPreferences->applyTheme(m_theme);
    connect(m_systemPreferences, &SystemPreferences::languageChanged, this, &AppPreferences::applyLanguage);
    applyLanguage();
}
AppPreferences::~AppPreferences() { QCoreApplication::removeTranslator(&m_translator); }

void AppPreferences::componentComplete()
{
    if (auto engine = qmlEngine(this))
        engine->retranslate();
}

void AppPreferences::setSystemPreferences(SystemPreferences *preferences)
{
    if (!preferences || preferences == m_systemPreferences)
        return;
    disconnect(m_systemPreferences, nullptr, this, nullptr);
    m_systemPreferences = preferences;
    connect(m_systemPreferences, &SystemPreferences::languageChanged, this, &AppPreferences::applyLanguage);
    m_systemPreferences->applyTheme(m_theme);
    applyLanguage();
    emit systemPreferencesChanged();
}

void AppPreferences::setTheme(const QString &theme)
{
    const auto normalized = theme == "light" || theme == "dark" ? theme : QStringLiteral("system");
    if (normalized == m_theme)
        return;
    m_theme = normalized;
    QSettings settings;
    settings.setValue("appearance/theme", m_theme);
    settings.sync();
    m_systemPreferences->applyTheme(m_theme);
    emit themeChanged();
}

void AppPreferences::setLanguage(const QString &language)
{
    const auto normalized = language == "en-US" || language == "zh-CN" ? language : QStringLiteral("system");
    if (normalized == m_language)
        return;
    m_language = normalized;
    QSettings settings;
    settings.setValue("appearance/language", m_language);
    settings.sync();
    applyLanguage();
}

void AppPreferences::setLastMode(const QString &mode)
{
    m_lastMode = mode;
    QSettings settings;
    settings.setValue("navigation/lastMode", mode);
    settings.sync();
    emit lastModeChanged();
}

void AppPreferences::applyLanguage()
{
    const QLocale systemLocale(m_systemPreferences->language());
    m_effectiveLanguage = m_language == "system"
        ? (systemLocale.language() == QLocale::Chinese && systemLocale.script() == QLocale::SimplifiedChineseScript
            ? QStringLiteral("zh-CN") : QStringLiteral("en-US"))
        : m_language;
    QCoreApplication::removeTranslator(&m_translator);
    m_translator.setLanguage(m_effectiveLanguage);
    QCoreApplication::installTranslator(&m_translator);
    if (auto engine = qmlEngine(this))
        engine->retranslate();
    emit languageChanged();
}
