#pragma once

#include <QDateTime>
#include <QNetworkAccessManager>
#include <QObject>
#include <QQmlEngine>

// External HTTPS/time boundary. Tests replace only this source, not conversion.
class CurrencySource : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit CurrencySource(QObject *parent = nullptr);
    virtual void request(quint64 requestId, const QString &path);
    virtual QDateTime now() const;
signals:
    void completed(quint64 requestId, const QByteArray &body, bool success);
private:
    QNetworkAccessManager m_network;
};
