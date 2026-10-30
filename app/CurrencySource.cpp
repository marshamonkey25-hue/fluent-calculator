#include "CurrencySource.h"
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>

CurrencySource::CurrencySource(QObject *parent) : QObject(parent) {}

QDateTime CurrencySource::now() const { return QDateTime::currentDateTimeUtc(); }

void CurrencySource::request(quint64 requestId, const QString &path)
{
    QNetworkRequest request(QUrl(QStringLiteral("https://api.frankfurter.dev/v2/") + path));
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "FluentCalculator/0.1");
    request.setTransferTimeout(15000);
    auto reply = m_network.get(request);
    // Also bound the total request time, including a stalled connect/TLS phase.
    QTimer::singleShot(20000, reply, [reply] { if (!reply->isFinished()) reply->abort(); });
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestId] {
        const auto status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        emit completed(requestId, reply->readAll(), reply->error() == QNetworkReply::NoError && status == 200);
        reply->deleteLater();
    });
}
