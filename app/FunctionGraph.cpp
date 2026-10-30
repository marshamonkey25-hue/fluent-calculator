#include "FunctionGraph.h"
#include <QPainter>
#include <cmath>
#include <functional>
#include <algorithm>
#include <limits>

FunctionGraph::FunctionGraph(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
    m_curves.push_back(Curve{1, {}});
}

void FunctionGraph::setExpression(const QString &expression)
{
    auto &curve = m_curves[m_selectedIndex];
    curve.expression = expression;
    sampleCurve(curve);
    emit expressionChanged();
    emit statusChanged();
    emit inspectionChanged();
    emit functionsChanged();
    update();
}

QVariantList FunctionGraph::functions() const
{
    QVariantList result;
    for (const auto &curve : m_curves)
        result.append(QVariantMap{{"id", curve.id}, {"expression", curve.expression},
            {"status", curve.status}, {"color", colorFor(curve)}});
    return result;
}

QColor FunctionGraph::colorFor(const Curve &curve) const
{
    if (curve.id == 1) return m_curveColor;
    const QColor base = QColor::fromHsvF(std::fmod(m_curveColor.hsvHueF() + (curve.id - 1) * 0.381966, 1.0),
        0.75, m_curveColor.valueF());
    if (!m_axisColor.isValid() || !m_backgroundColor.isValid()) return base;
    const auto luminance = [](const QColor &color) {
        const auto linear = [](double channel) {
            return channel <= 0.04045 ? channel / 12.92 : std::pow((channel + 0.055) / 1.055, 2.4);
        };
        return 0.2126 * linear(color.redF()) + 0.7152 * linear(color.greenF()) + 0.0722 * linear(color.blueF());
    };
    const double background = luminance(m_backgroundColor);
    // Keep every curve and its text identifier readable, including bright
    // green on white and saturated violet on dark surfaces.
    for (int step = 0; step <= 20; ++step) {
        const double weight = step / 20.0;
        const QColor color = QColor::fromRgbF(
            base.redF() * (1 - weight) + m_axisColor.redF() * weight,
            base.greenF() * (1 - weight) + m_axisColor.greenF() * weight,
            base.blueF() * (1 - weight) + m_axisColor.blueF() * weight);
        const double foreground = luminance(color);
        if ((std::max(foreground, background) + 0.05) / (std::min(foreground, background) + 0.05) >= 4.5)
            return color;
    }
    return m_axisColor;
}

void FunctionGraph::setSelectedIndex(int index)
{
    if (index < 0 || index >= int(m_curves.size())) return;
    m_selectedIndex = index;
    emit selectionChanged();
    emit expressionChanged();
    emit statusChanged();
    emit inspectionChanged();
    update();
}

void FunctionGraph::addFunction()
{
    m_curves.push_back(Curve{m_nextId++, {}});
    emit functionsChanged();
    setSelectedIndex(int(m_curves.size()) - 1);
}

void FunctionGraph::deleteFunction()
{
    if (m_curves.size() == 1) { setExpression({}); return; }
    m_curves.erase(m_curves.begin() + m_selectedIndex);
    m_selectedIndex = std::min(m_selectedIndex, int(m_curves.size()) - 1);
    emit functionsChanged();
    setSelectedIndex(m_selectedIndex);
}

void FunctionGraph::zoom(double factor)
{
    if (!std::isfinite(factor) || factor <= 0) return;
    m_span = std::clamp(m_span * factor, 0.000001, 1000000.0);
    resampleViewport();
}

void FunctionGraph::pan(double horizontal, double vertical)
{
    if (!std::isfinite(horizontal) || !std::isfinite(vertical)) return;
    m_center.setX(std::clamp(m_center.x() + horizontal * m_span, -1e9, 1e9));
    m_center.setY(std::clamp(m_center.y() + vertical * m_span, -1e9, 1e9));
    resampleViewport();
}

void FunctionGraph::resetView()
{
    m_center = {};
    m_span = 20;
    resampleViewport();
}

void FunctionGraph::resampleViewport()
{
    for (auto &curve : m_curves) sampleCurve(curve);
    emit viewportChanged();
    emit statusChanged();
    emit inspectionChanged();
    emit functionsChanged();
    update();
}

QString FunctionGraph::formatCoordinate(double value) const
{
    if (!std::isfinite(value)) return {};
    const int precision = std::clamp(int(std::ceil(std::log10(std::max(1.0, std::abs(value)))
        - std::log10(m_span))) + 8, 8, 16);
    return QString::number(value, 'g', precision);
}

QVariantMap FunctionGraph::inspection() const
{
    if (!m_inspectionVisible) return {};
    const auto &curve = m_curves[m_selectedIndex];
    const double x = minimumX() + m_inspectionPosition.x() * m_span;
    const double y = maximumY() - m_inspectionPosition.y() * m_span;
    const double value = curve.status == Empty || curve.status == Invalid
        ? std::numeric_limits<double>::quiet_NaN() : curve.function.evaluate(x);
    return {{"x", formatCoordinate(x)}, {"y", formatCoordinate(y)},
        {"id", curve.id}, {"defined", std::isfinite(value)},
        {"value", std::isfinite(value) ? formatCoordinate(value) : QString()}};
}

void FunctionGraph::inspectAt(double x, double y)
{
    if (width() <= 0 || height() <= 0 || !std::isfinite(x) || !std::isfinite(y)) return;
    m_inspectionPosition = {std::clamp(x / width(), 0.0, 1.0), std::clamp(y / height(), 0.0, 1.0)};
    m_inspectionVisible = true;
    emit inspectionChanged();
    update();
}

void FunctionGraph::sampleCurve(Curve &curve)
{
    curve.lines.clear();
    curve.status = curve.expression.trimmed().isEmpty() ? Empty : Invalid;
    if (!curve.expression.trimmed().isEmpty() && curve.function.compile(curve.expression)) {
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
            const double y = curve.function.evaluate(x);
            finitePoint = finitePoint || std::isfinite(y);
            return QPointF(x, y);
        };
        auto appendClipped = [&](QPointF a, QPointF b) {
            // Clip in mathematical coordinates before handing values to QPainter;
            // huge but finite results must never overflow its raster coordinates.
            if (std::max(a.y(), b.y()) < minimumY() || std::min(a.y(), b.y()) > maximumY()) return;
            if (a.y() < minimumY() || a.y() > maximumY()) {
                const double edge = std::clamp(a.y(), minimumY(), maximumY());
                a.setX(a.x() + (b.x() - a.x()) * (edge - a.y()) / (b.y() - a.y()));
                a.setY(edge);
            }
            if (b.y() < minimumY() || b.y() > maximumY()) {
                const double edge = std::clamp(b.y(), minimumY(), maximumY());
                b.setX(a.x() + (b.x() - a.x()) * (edge - a.y()) / (b.y() - a.y()));
                b.setY(edge);
            }
            curve.lines.emplace_back(a, b);
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
                if (std::min({a.y(), b.y(), middle.y(), probe.y()}) > maximumY()
                    || std::max({a.y(), b.y(), middle.y(), probe.y()}) < minimumY()) return;
                const double deviation = std::max(std::abs(middle.y() - (a.y() / 2 + b.y() / 2)),
                    std::abs(probe.y() - (a.y() * (1 - probeFraction) + b.y() * probeFraction)));
                if (deviation <= m_span * 0.0001) { appendClipped(a, b); return; }
            } else {
                omitted = true;
                if (!std::isfinite(a.y()) && !std::isfinite(b.y())
                    && !std::isfinite(middle.y()) && !std::isfinite(probe.y())) return;
            }
            if (depth >= maxDepth) { omitted = true; return; }
            sample(a, middle, depth + 1);
            sample(middle, b, depth + 1);
        };
        QPointF previous = evaluate(minimumX());
        for (int index = 1; index <= intervals && evaluations < evaluationBudget; ++index) {
            const auto next = evaluate(minimumX() + m_span * index / intervals);
            sample(previous, next, 0);
            previous = next;
        }
        curve.status = !finitePoint ? NoPoints : curve.lines.empty() ? NoVisibleCurve : omitted ? PartialDomain : Ready;
    }
}

void FunctionGraph::paint(QPainter *painter)
{
    painter->fillRect(boundingRect(), m_backgroundColor);
    const auto point = [&](QPointF value) {
        return QPointF((value.x() - minimumX()) * width() / m_span,
            (maximumY() - value.y()) * height() / m_span);
    };
    // Nice decimal tick spacing keeps labels legible and work bounded at every zoom.
    const double magnitude = std::pow(10.0, std::floor(std::log10(m_span / 8)));
    const double normalized = m_span / 8 / magnitude;
    const double tick = (normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10) * magnitude;
    const double axisX = std::clamp(point({0, 0}).x(), 1.0, std::max(1.0, width() - 30));
    const double axisY = std::clamp(point({0, 0}).y(), 1.0, std::max(1.0, height() - 18));
    painter->setClipRect(boundingRect());
    QFont font = painter->font();
    font.setPixelSize(12);
    painter->setFont(font);
    const double firstX = std::ceil(minimumX() / tick) * tick;
    const double firstY = std::ceil(minimumY() / tick) * tick;
    for (int index = 0; index < 20; ++index) {
        const double x = firstX + index * tick;
        const double y = firstY + index * tick;
        painter->setPen(QPen(m_gridColor, 1));
        if (x <= maximumX()) painter->drawLine(point({x, minimumY()}), point({x, maximumY()}));
        if (y <= maximumY()) painter->drawLine(point({minimumX(), y}), point({maximumX(), y}));
        painter->setPen(m_axisColor);
        if (x >= minimumX() && x <= maximumX() && std::abs(x) > tick * 0.001)
            painter->drawText(QPointF(point({x, 0}).x() + 3, axisY + 15), formatCoordinate(x));
        if (y >= minimumY() && y <= maximumY() && std::abs(y) > tick * 0.001)
            painter->drawText(QPointF(axisX + 4, point({0, y}).y() - 4), formatCoordinate(y));
    }
    painter->setPen(QPen(m_axisColor, 1));
    if (minimumY() <= 0 && maximumY() >= 0)
        painter->drawLine(point({minimumX(), 0}), point({maximumX(), 0}));
    if (minimumX() <= 0 && maximumX() >= 0)
        painter->drawLine(point({0, minimumY()}), point({0, maximumY()}));
    painter->drawText(QPointF(width() - 14, axisY - 6), QStringLiteral("x"));
    painter->drawText(QPointF(axisX + 6, 14), QStringLiteral("y"));
    painter->setClipRect(boundingRect());
    for (size_t index = 0; index < m_curves.size(); ++index) {
        const auto &curve = m_curves[index];
        painter->setPen(QPen(colorFor(curve), 2.5));
        for (const auto &line : curve.lines) painter->drawLine(point(line.p1()), point(line.p2()));
        if (!curve.lines.empty()) {
            // Spread identifiers along the curves so intersecting functions do
            // not place all their labels at the same sampled coordinate.
            const auto &line = curve.lines[curve.lines.size() * (index + 1) / (m_curves.size() + 1)];
            painter->drawText(point(line.p1()) + QPointF(5, -6), QStringLiteral("F%1").arg(curve.id));
        }
    }
    if (m_inspectionVisible) {
        const double x = minimumX() + m_inspectionPosition.x() * m_span;
        const auto &curve = m_curves[m_selectedIndex];
        const double y = curve.status == Empty || curve.status == Invalid
            ? std::numeric_limits<double>::quiet_NaN() : curve.function.evaluate(x);
        if (std::isfinite(y) && y >= minimumY() && y <= maximumY()) {
            painter->setPen(QPen(colorFor(curve), 2));
            painter->setBrush(m_backgroundColor);
            painter->drawEllipse(point({x, y}), 4, 4);
        }
    }
}
