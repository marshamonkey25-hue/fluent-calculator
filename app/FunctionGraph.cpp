#include "FunctionGraph.h"
#include <QPainter>
#include <cmath>
#include <functional>
#include <algorithm>

FunctionGraph::FunctionGraph(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
}

void FunctionGraph::setExpression(const QString &expression)
{
    m_expression = expression;
    m_lines.clear();
    m_status = expression.trimmed().isEmpty() ? Empty : Invalid;
    if (!expression.trimmed().isEmpty() && m_function.compile(expression)) {
        // Bounded work and curvature checks prevent a finite pair of samples
        // on opposite sides of a pole from becoming a false vertical stroke.
        constexpr int intervals = 512;
        constexpr int evaluationBudget = 65536;
        constexpr int maxDepth = 12;
        int evaluations = 0;
        bool finitePoint = false;
        bool omitted = false;
        auto evaluate = [&](double x) {
            ++evaluations;
            const double y = m_function.evaluate(x);
            finitePoint = finitePoint || std::isfinite(y);
            return QPointF(x, y);
        };
        auto appendClipped = [&](QPointF a, QPointF b) {
            // Clip in mathematical coordinates before handing values to QPainter;
            // huge but finite results must never overflow its raster coordinates.
            if (std::max(a.y(), b.y()) < -10 || std::min(a.y(), b.y()) > 10) return;
            if (a.y() < -10 || a.y() > 10) {
                const double edge = std::clamp(a.y(), -10.0, 10.0);
                a.setX(a.x() + (b.x() - a.x()) * (edge - a.y()) / (b.y() - a.y()));
                a.setY(edge);
            }
            if (b.y() < -10 || b.y() > 10) {
                const double edge = std::clamp(b.y(), -10.0, 10.0);
                b.setX(a.x() + (b.x() - a.x()) * (edge - a.y()) / (b.y() - a.y()));
                b.setY(edge);
            }
            m_lines.emplace_back(a, b);
        };
        std::function<void(QPointF, QPointF, int)> sample;
        sample = [&](QPointF a, QPointF b, int depth) {
            if (evaluations + 2 > evaluationBudget) { omitted = true; return; }
            const QPointF middle = evaluate((a.x() + b.x()) / 2);
            // A non-dyadic probe prevents periodic functions whose zeros align
            // with the regular grid and midpoints from masquerading as a line.
            constexpr double probeFraction = 0.3819660112501051;
            const QPointF probe = evaluate(a.x() + (b.x() - a.x()) * probeFraction);
            const bool finite = std::isfinite(a.y()) && std::isfinite(b.y())
                && std::isfinite(middle.y()) && std::isfinite(probe.y());
            if (finite) {
                // Segments entirely beyond the viewport need no rasterization.
                if (std::min({a.y(), b.y(), middle.y(), probe.y()}) > 10
                    || std::max({a.y(), b.y(), middle.y(), probe.y()}) < -10) return;
                const double deviation = std::max(std::abs(middle.y() - (a.y() / 2 + b.y() / 2)),
                    std::abs(probe.y() - (a.y() * (1 - probeFraction) + b.y() * probeFraction)));
                if (deviation <= 0.002) { appendClipped(a, b); return; }
            } else {
                omitted = true;
                if (!std::isfinite(a.y()) && !std::isfinite(b.y())
                    && !std::isfinite(middle.y()) && !std::isfinite(probe.y())) return;
            }
            if (depth >= maxDepth) { omitted = true; return; }
            sample(a, middle, depth + 1);
            sample(middle, b, depth + 1);
        };
        QPointF previous = evaluate(-10);
        for (int index = 1; index <= intervals && evaluations < evaluationBudget; ++index) {
            const auto next = evaluate(-10 + 20.0 * index / intervals);
            sample(previous, next, 0);
            previous = next;
        }
        m_status = !finitePoint ? NoPoints : m_lines.empty() ? NoVisibleCurve : omitted ? PartialDomain : Ready;
    }
    emit expressionChanged();
    emit statusChanged();
    update();
}

void FunctionGraph::paint(QPainter *painter)
{
    painter->fillRect(boundingRect(), m_backgroundColor);
    const auto point = [&](QPointF value) { return QPointF((value.x() + 10) * width() / 20, (10 - value.y()) * height() / 20); };
    painter->setPen(QPen(m_gridColor, 1));
    for (int value = -8; value <= 8; value += 2) {
        painter->drawLine(point({double(value), -10}), point({double(value), 10}));
        painter->drawLine(point({-10, double(value)}), point({10, double(value)}));
    }
    painter->setPen(QPen(m_axisColor, 1));
    painter->drawLine(point({-10, 0}), point({10, 0}));
    painter->drawLine(point({0, -10}), point({0, 10}));
    QFont font = painter->font();
    font.setPixelSize(12);
    painter->setFont(font);
    for (int value = -8; value <= 8; value += 2) {
        if (value == 0) continue;
        painter->drawText(point({double(value), 0}) + QPointF(3, 15), QString::number(value));
        painter->drawText(point({0, double(value)}) + QPointF(4, -4), QString::number(value));
    }
    painter->drawText(QPointF(width() - 14, height() / 2 - 6), QStringLiteral("x"));
    painter->drawText(QPointF(width() / 2 + 6, 14), QStringLiteral("y"));
    painter->setClipRect(boundingRect());
    painter->setPen(QPen(m_curveColor, 2.5));
    for (const auto &line : m_lines) painter->drawLine(point(line.p1()), point(line.p2()));
}
