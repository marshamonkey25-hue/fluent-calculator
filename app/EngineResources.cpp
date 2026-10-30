#include "EngineResources.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>

EngineResources::EngineResources()
{
    setLanguage(QLocale().language() == QLocale::Chinese ? QStringLiteral("zh-CN") : QStringLiteral("en-US"));
}

void EngineResources::setLanguage(const QString &language)
{
    m_strings.clear();
    // Localized RESW tables contain only overrides; retain the pinned English
    // operation symbols and captions just as Windows resource fallback does.
    QStringList languages { QStringLiteral("en-US") };
    if (language == "zh-CN")
        languages.append(QStringLiteral("zh-CN"));
    for (const auto &language : languages) {
        QFile file(QStringLiteral(":/engine/%1.json").arg(language));
        if (!file.open(QIODevice::ReadOnly))
            qFatal("Cannot load Microsoft Calculator engine resources");
        QJsonParseError error;
        const auto document = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.isObject())
            qFatal("Invalid Microsoft Calculator engine resources");
        const auto object = document.object();
        for (auto it = object.begin(); it != object.end(); ++it)
            m_strings.insert(it.key(), it.value().toString());
    }
    // Both supported UI locales use the Win32 decimal grouping pattern 3;0.
    m_strings.insert(QStringLiteral("sDecimal"), QStringLiteral("."));
    m_strings.insert(QStringLiteral("sThousand"), QStringLiteral(","));
    m_strings.insert(QStringLiteral("sGrouping"), QStringLiteral("3;0"));
}

std::wstring EngineResources::GetCEngineString(std::wstring_view id)
{
    return m_strings.value(QString::fromWCharArray(id.data(), qsizetype(id.size()))).toStdWString();
}
