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
