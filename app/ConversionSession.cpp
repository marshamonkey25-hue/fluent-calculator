#include "ConversionSession.h"
#include "Command.h"
#include "LengthDataLoader.h"
#include <QClipboard>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QHash>
#include <QLocale>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>

using namespace UnitConversionManager;

namespace {
QString grouped(QString value)
{
    // Preserve engine decimal text, trailing zeroes and scientific mantissas.
    if (value.contains('e'))
        return value;
    const auto decimal = value.indexOf('.');
    const auto end = decimal < 0 ? value.size() : decimal;
    const auto first = value.startsWith('-') ? 1 : 0;
    for (auto index = end - 3; index > first; index -= 3)
        value.insert(index, ',');
    return value;
}
}

QString ConversionSession::value1() const { return grouped(m_value1); }
QString ConversionSession::value2() const { return grouped(m_value2); }

void ConversionSession::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void ConversionSession::MaxDigitsReached() { setStatus(QStringLiteral("limit")); }

ConversionSession::ConversionSession(QObject *parent) : QObject(parent)
{
    m_converter = std::make_shared<UnitConverter>(createLengthDataLoader());
    const auto selection = m_converter->SetCurrentCategory(m_converter->GetCategories().front());
    m_units = std::get<0>(selection);
    m_unit1 = std::get<1>(selection).id;
    m_unit2 = std::get<2>(selection).id;
    // The QObject owns the converter and outlives its non-owning callback.
    m_converter->SetViewModelCallback(std::shared_ptr<IUnitConverterVMCallback>(static_cast<IUnitConverterVMCallback *>(this), [](auto *) {}));
    selectUnits();
}

void ConversionSession::setLanguage(const QString &language)
{
    if (m_language == language)
        return;
    m_language = language;
    emit languageChanged();
}

QVariantList ConversionSession::units() const
{
    QVariantList rows;
    for (const auto &unit : m_units) {
        if (unit.isWhimsical)
            continue;
        const auto name = QString::fromStdWString(unit.name).toUtf8();
        rows.append(QVariantMap {{"id", unit.id}, {"name", QCoreApplication::translate("ConverterUnits", name.constData())}});
    }
    return rows;
}

void ConversionSession::setUnit1(int id)
{
    if (m_unit1 == id || std::none_of(m_units.begin(), m_units.end(), [id](const Unit &unit) { return unit.id == id; }))
        return;
    m_unit1 = id;
    selectUnits();
    emit unitsChanged();
}

void ConversionSession::setUnit2(int id)
{
    if (m_unit2 == id || std::none_of(m_units.begin(), m_units.end(), [id](const Unit &unit) { return unit.id == id; }))
        return;
    m_unit2 = id;
    selectUnits();
    emit unitsChanged();
}

void ConversionSession::selectUnits()
{
    const auto find = [this](int id) {
        return *std::find_if(m_units.begin(), m_units.end(), [id](const Unit &unit) { return unit.id == id; });
    };
    m_converter->SetCurrentUnitTypes(find(m_activeSide == 1 ? m_unit1 : m_unit2),
                                     find(m_activeSide == 1 ? m_unit2 : m_unit1));
}

void ConversionSession::activate(int side)
{
    if ((side != 1 && side != 2) || side == m_activeSide)
        return;
    m_activeSide = side;
    m_converter->SwitchActive((side == 1 ? m_value1 : m_value2).toStdWString());
    emit activeSideChanged();
}

void ConversionSession::send(const QString &command)
{
    static const QHash<QString, Command> commands {
        {"0", Command::Zero}, {"1", Command::One}, {"2", Command::Two}, {"3", Command::Three},
        {"4", Command::Four}, {"5", Command::Five}, {"6", Command::Six}, {"7", Command::Seven},
        {"8", Command::Eight}, {"9", Command::Nine}, {"decimal", Command::Decimal},
        {"clear", Command::Clear}, {"backspace", Command::Backspace}
    };
    const auto entry = commands.constFind(command);
    if (entry != commands.cend()) {
        if (!m_status.isEmpty() && m_status != "limit")
            m_converter->SendCommand(Command::Clear);
        setStatus({});
        m_converter->SendCommand(entry.value());
    }
}

void ConversionSession::copy()
{
    QGuiApplication::clipboard()->setText(m_activeSide == 1 ? m_value1 : m_value2);
}

void ConversionSession::paste()
{
    auto input = QGuiApplication::clipboard()->text().trimmed();
    if (input.startsWith('-')) {
        setStatus(QStringLiteral("negative"));
        return;
    }
    static const QRegularExpression decimal(QStringLiteral(R"(^[+]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$)"));
    if (!decimal.match(input).hasMatch()) {
        setStatus(QStringLiteral("invalid"));
        return;
    }
    bool parsed = false;
    const auto value = QLocale::c().toDouble(input, &parsed);
    if (!parsed || !std::isfinite(value)) {
        setStatus(QStringLiteral("unavailable"));
        return;
    }
    if (input.startsWith('+'))
        input.remove(0, 1);
    const auto point = input.indexOf('.');
    const auto integerEnd = point < 0 ? input.size() : point;
    auto firstNonzero = 0;
    while (firstNonzero + 1 < integerEnd && input[firstNonzero] == '0')
        ++firstNonzero;
    input.remove(0, firstNonzero);
    if (input.startsWith('.'))
        input.prepend('0');
    if (input.size() - (input.contains('.') ? 1 : 0) > 15) {
        setStatus(QStringLiteral("limit"));
        return;
    }
    send(QStringLiteral("clear"));
    for (const auto character : input)
        send(character == '.' ? QStringLiteral("decimal") : QString(character));
}

void ConversionSession::DisplayCallback(const std::wstring &from, const std::wstring &to)
{
    m_value1 = QString::fromStdWString(m_activeSide == 1 ? from : to);
    m_value2 = QString::fromStdWString(m_activeSide == 1 ? to : from);
    emit displayChanged();
}
