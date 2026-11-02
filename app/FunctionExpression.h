#pragma once
#include <QString>
#include <vector>

// Restricted mathematical expression, deliberately independent of CEngine's
// sequential calculator commands. No scripting engine or host calls are used.
class FunctionExpression
{
public:
    bool compile(const QString &expression);
    double evaluate(double x) const;
private:
    enum class Operation {
        Number, Variable, Add, Subtract, Multiply, Divide, Power,
        Negate, Sin, Cos, Tan, Sqrt, Abs, Ln, Log, Exp
    };
    struct Instruction { Operation operation; double number = 0; };
    std::vector<Instruction> m_program;
};
