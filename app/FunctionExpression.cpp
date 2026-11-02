#include "FunctionExpression.h"
#include <QHash>
#include <QRegularExpression>
#include <cmath>
#include <functional>
#include <limits>

bool FunctionExpression::compile(const QString &expression)
{
    m_program.clear();
    if (expression.size() > 512)
        return false;
    qsizetype position = 0;
    int depth = 0;
    bool valid = true;
    auto skipSpace = [&] { while (position < expression.size() && expression[position].isSpace()) ++position; };
    auto take = [&](QChar symbol) {
        skipSpace();
        if (position < expression.size() && expression[position] == symbol) { ++position; return true; }
        return false;
    };
    std::function<void()> sum, product, unary, power, primary;
    primary = [&] {
        if (++depth > 64) { valid = false; --depth; return; }
        skipSpace();
        if (take('(')) { sum(); if (!take(')')) valid = false; }
        else if (position < expression.size() && expression[position].isLetter()) {
            const auto start = position;
            while (position < expression.size() && expression[position].isLetter()) ++position;
            const auto name = expression.mid(start, position - start);
            if (name == QStringLiteral("x")) m_program.push_back({Operation::Variable});
            else if (name == QStringLiteral("pi")) m_program.push_back({Operation::Number, std::acos(-1.0)});
            else if (name == QStringLiteral("e")) m_program.push_back({Operation::Number, std::exp(1.0)});
            else {
                static const QHash<QString, Operation> functions {
                    {"sin", Operation::Sin}, {"cos", Operation::Cos}, {"tan", Operation::Tan},
                    {"sqrt", Operation::Sqrt}, {"abs", Operation::Abs}, {"ln", Operation::Ln},
                    {"log", Operation::Log}, {"exp", Operation::Exp}
                };
                const auto function = functions.constFind(name);
                if (function == functions.cend() || !take('(')) valid = false;
                else {
                    sum();
                    if (!take(')')) valid = false;
                    m_program.push_back({function.value()});
                }
            }
        }
        else {
            static const QRegularExpression number(QStringLiteral(R"((?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)"));
            const auto match = number.match(expression, position, QRegularExpression::NormalMatch,
                                             QRegularExpression::AnchorAtOffsetMatchOption);
            bool ok = false;
            const double value = match.captured().toDouble(&ok);
            if (!match.hasMatch() || !ok || !std::isfinite(value)) valid = false;
            else { position += match.capturedLength(); m_program.push_back({Operation::Number, value}); }
        }
        --depth;
    };
    power = [&] {
        primary();
        if (valid && take('^')) { unary(); m_program.push_back({Operation::Power}); }
    };
    unary = [&] {
        if (++depth > 64) { valid = false; --depth; return; }
        if (take('+')) unary();
        else if (take('-')) { unary(); m_program.push_back({Operation::Negate}); }
        else power();
        --depth;
    };
    product = [&] {
        unary();
        while (valid) {
            if (take('*')) { unary(); m_program.push_back({Operation::Multiply}); }
            else if (take('/')) { unary(); m_program.push_back({Operation::Divide}); }
            else break;
        }
    };
    sum = [&] {
        product();
        while (valid) {
            if (take('+')) { product(); m_program.push_back({Operation::Add}); }
            else if (take('-')) { product(); m_program.push_back({Operation::Subtract}); }
            else break;
        }
    };
    sum();
    skipSpace();
    valid = valid && position == expression.size() && !m_program.empty() && m_program.size() <= 256;
    if (!valid) m_program.clear();
    return valid;
}

double FunctionExpression::evaluate(double x) const
{
    std::vector<double> stack;
    stack.reserve(m_program.size());
    for (const auto &instruction : m_program) {
        if (instruction.operation == Operation::Number) stack.push_back(instruction.number);
        else if (instruction.operation == Operation::Variable) stack.push_back(x);
        else if (instruction.operation >= Operation::Negate) {
            double &value = stack.back();
            switch (instruction.operation) {
            case Operation::Negate: value = -value; break;
            case Operation::Sin: value = std::sin(value); break;
            case Operation::Cos: value = std::cos(value); break;
            case Operation::Tan:
                // libm returns a huge finite value at the rounded pi/2. Treat
                // roundoff-sized cosines as poles instead of plotting that value.
                value = std::abs(std::cos(value)) < 1e-14
                    ? std::numeric_limits<double>::quiet_NaN() : std::tan(value);
                break;
            case Operation::Sqrt: value = std::sqrt(value); break;
            case Operation::Abs: value = std::abs(value); break;
            case Operation::Ln: value = std::log(value); break;
            case Operation::Log: value = std::log10(value); break;
            case Operation::Exp: value = std::exp(value); break;
            default: break;
            }
        }
        else {
            const double right = stack.back(); stack.pop_back();
            double &left = stack.back();
            switch (instruction.operation) {
            case Operation::Add: left += right; break;
            case Operation::Subtract: left -= right; break;
            case Operation::Multiply: left *= right; break;
            case Operation::Power: left = std::pow(left, right); break;
            case Operation::Divide: left = right == 0 ? std::numeric_limits<double>::quiet_NaN() : left / right; break;
            default: break;
            }
        }
        // Undefined/overflowing subexpressions stay undefined even if a later
        // operation (for example NaN^0) would turn them into a finite number.
        if (!std::isfinite(stack.back())) return std::numeric_limits<double>::quiet_NaN();
    }
    return stack.empty() ? std::numeric_limits<double>::quiet_NaN() : stack.back();
}
