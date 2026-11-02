#pragma once
#include "CurrencySource.h"
#include <QHash>
#include <QTimer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>

class ControlledCurrencySource final : public CurrencySource
{
    Q_OBJECT
    struct Response { QByteArray body; int delay; bool success; };
    QHash<QString, Response> m_responses;
    QDateTime m_now = QDateTime::fromString(QStringLiteral("2026-04-15T12:34:56Z"), Qt::ISODate);
public:
    using CurrencySource::CurrencySource;
    Q_INVOKABLE void reset()
    {
        m_responses.clear();
        // Storage is an external boundary. Each ordinary test starts with no
        // cache; restart tests deliberately keep their private storage root.
        const auto directory = QFileInfo(QSettings().fileName()).dir();
        QFile::remove(directory.filePath("currency-rates-v1.json"));
        QFile::remove(directory.filePath("currency-rates-v1.json.partial"));
    }
    Q_INVOKABLE bool setCacheWritable(bool writable)
    {
        const auto directory = QFileInfo(QSettings().fileName()).absolutePath();
        return QFile::setPermissions(directory, QFile::ReadOwner | QFile::ExeOwner
            | (writable ? QFile::WriteOwner : QFile::Permissions()));
    }
    Q_INVOKABLE void writeCacheFixture(const QString &contents, bool incomplete = false)
    {
        const auto directory = QFileInfo(QSettings().fileName()).dir();
        QDir().mkpath(directory.absolutePath());
        QFile file(directory.filePath(incomplete ? "currency-rates-v1.json.partial" : "currency-rates-v1.json"));
        if (!file.open(QIODevice::WriteOnly) || file.write(contents.toUtf8()) < 0)
            qFatal("Cannot write private currency cache fixture");
    }
    Q_INVOKABLE void setResponse(const QString &path, const QString &body, int delay = 10, bool success = true)
    { m_responses.insert(path, {body.toUtf8(), delay, success}); }
    Q_INVOKABLE void setNow(const QString &now) { m_now = QDateTime::fromString(now, Qt::ISODate); }
    QDateTime now() const override { return m_now; }
    void request(quint64 requestId, const QString &path) override
    {
        const auto response = m_responses.value(path, {{}, 10, false});
        QTimer::singleShot(response.delay, this, [this, requestId, response] {
            emit completed(requestId, response.body, response.success);
        });
    }
};
