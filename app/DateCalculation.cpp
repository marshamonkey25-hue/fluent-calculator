// Calendar difference behavior adapted from Microsoft Calculator (MIT),
// revision 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128:
// Calculator.ViewModels/Common/DateCalculator.cs. See third_party/microsoft-calculator/LICENSE.
#include "DateCalculation.h"
#include <QLocale>
#include <algorithm>
#include <cstdlib>

DateCalculation::DateCalculation(QObject *parent) : QObject(parent) {}

void DateCalculation::setFromDate(const QString &text)
{
    const auto date = QDate::fromString(text, Qt::ISODate);
    if (!date.isValid() || date.year() < 1601 || date.year() > 9999
        || date.toString(Qt::ISODate) != text || date == m_fromDate)
        return;
    m_fromDate = date;
    emit datesChanged();
}

void DateCalculation::setToDate(const QString &text)
{
    const auto date = QDate::fromString(text, Qt::ISODate);
    if (!date.isValid() || date.year() < 1601 || date.year() > 9999
        || date.toString(Qt::ISODate) != text || date == m_toDate)
        return;
    m_toDate = date;
    emit datesChanged();
}

void DateCalculation::setStartDate(const QString &text)
{
    const auto date = QDate::fromString(text, Qt::ISODate);
    if (!date.isValid() || date.year() < 1601 || date.year() > 9999
        || date.toString(Qt::ISODate) != text || date == m_startDate)
        return;
    m_startDate = date;
    emit startDateChanged();
}

QString DateCalculation::adjustedDate(const QString &start, bool add, int years, int months, int days) const
{
    const auto date = QDate::fromString(start, Qt::ISODate);
    if (!date.isValid() || date.year() < 1601 || date.year() > 9999
        || date.toString(Qt::ISODate) != start
        || years < 0 || years > 999 || months < 0 || months > 999 || days < 0 || days > 999)
        return {};
    // Pinned AddDuration applies larger units first; SubtractDuration reverses
    // that order. Each step clips a missing day to the destination month's end.
    const auto result = add ? date.addYears(years).addMonths(months).addDays(days)
                            : date.addDays(-days).addMonths(-months).addYears(-years);
    if (!result.isValid() || result.year() < 1601 || result.year() > 9999)
        return {};
    return result.toString(Qt::ISODate);
}

int DateCalculation::totalDays() const
{
    return static_cast<int>(std::abs(m_fromDate.daysTo(m_toDate)));
}

QVariantMap DateCalculation::difference() const
{
    // Pinned DateCalculationEngine.TryGetDateDifference: normalize order,
    // advance complete calendar years, then months, then weeks and days.
    // QDate keeps this independent of time zones and daylight saving time.
    auto pivot = std::min(m_fromDate, m_toDate);
    const auto end = std::max(m_fromDate, m_toDate);
    int years = end.year() - pivot.year();
    if (pivot.addYears(years) > end)
        --years;
    pivot = pivot.addYears(years);
    int months = (end.year() - pivot.year()) * 12 + end.month() - pivot.month();
    if (pivot.addMonths(months) > end)
        --months;
    pivot = pivot.addMonths(months);
    const int remainingDays = static_cast<int>(pivot.daysTo(end));
    return {{"years", years}, {"months", months}, {"weeks", remainingDays / 7}, {"days", remainingDays % 7}};
}

QString DateCalculation::formattedDate(const QString &date, const QString &language) const
{
    const QLocale locale(language);
    // The pinned picker requests "day month year", without a weekday.
    const auto format = locale.language() == QLocale::Chinese
        ? QStringLiteral("yyyy年M月d日") : QStringLiteral("MMMM d, yyyy");
    return locale.toString(QDate::fromString(date, Qt::ISODate), format);
}

QString DateCalculation::formattedResultDate(const QString &date, const QString &language) const
{
    // Pinned DateCalculatorViewModel uses "longdate" for results; the picker
    // separately requests day/month/year without a weekday.
    return QLocale(language).toString(QDate::fromString(date, Qt::ISODate), QLocale::LongFormat);
}
