#pragma once

#include <QObject>
#include <QDate>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class DateCalculation : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString fromDate READ fromDate WRITE setFromDate NOTIFY datesChanged)
    Q_PROPERTY(QString toDate READ toDate WRITE setToDate NOTIFY datesChanged)
    Q_PROPERTY(int totalDays READ totalDays NOTIFY datesChanged)
    Q_PROPERTY(QVariantMap difference READ difference NOTIFY datesChanged)
public:
    explicit DateCalculation(QObject *parent = nullptr);
    QString fromDate() const { return m_fromDate.toString(Qt::ISODate); }
    QString toDate() const { return m_toDate.toString(Qt::ISODate); }
    void setFromDate(const QString &date);
    void setToDate(const QString &date);
    int totalDays() const;
    QVariantMap difference() const;
    Q_INVOKABLE QString formattedDate(const QString &date, const QString &language) const;
signals:
    void datesChanged();
private:
    QDate m_fromDate = QDate::currentDate();
    QDate m_toDate = m_fromDate;
};
