#pragma once
#include "FunctionExpression.h"
#include <QQuickPaintedItem>
#include <QLineF>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class FunctionGraph : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString expression READ expression WRITE setExpression NOTIFY expressionChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantList functions READ functions NOTIFY functionsChanged)
    Q_PROPERTY(int selectedIndex READ selectedIndex WRITE setSelectedIndex NOTIFY selectionChanged)
    Q_PROPERTY(QVariantMap inspection READ inspection NOTIFY inspectionChanged)
    Q_PROPERTY(double minimumX READ minimumX NOTIFY viewportChanged)
    Q_PROPERTY(double maximumX READ maximumX NOTIFY viewportChanged)
    Q_PROPERTY(double minimumY READ minimumY NOTIFY viewportChanged)
    Q_PROPERTY(double maximumY READ maximumY NOTIFY viewportChanged)
    Q_PROPERTY(bool canZoomIn READ canZoomIn NOTIFY viewportChanged)
    Q_PROPERTY(bool canZoomOut READ canZoomOut NOTIFY viewportChanged)
    Q_PROPERTY(QColor curveColor READ curveColor WRITE setCurveColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor axisColor READ axisColor WRITE setAxisColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor gridColor READ gridColor WRITE setGridColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY colorsChanged)
public:
    enum Status { Empty, Ready, Invalid, NoPoints, PartialDomain, NoVisibleCurve };
    Q_ENUM(Status)
    explicit FunctionGraph(QQuickItem *parent = nullptr);
    QString expression() const { return m_curves[m_selectedIndex].expression; }
    void setExpression(const QString &expression);
    Status status() const { return m_curves[m_selectedIndex].status; }
    QVariantList functions() const;
    int selectedIndex() const { return m_selectedIndex; }
    void setSelectedIndex(int index);
    Q_INVOKABLE void addFunction();
    Q_INVOKABLE void deleteFunction();
    double minimumX() const { return m_center.x() - m_span / 2; }
    double maximumX() const { return m_center.x() + m_span / 2; }
    double minimumY() const { return m_center.y() - m_span / 2; }
    double maximumY() const { return m_center.y() + m_span / 2; }
    bool canZoomIn() const { return m_span > 0.000001; }
    bool canZoomOut() const { return m_span < 1000000; }
    Q_INVOKABLE void zoom(double factor);
    Q_INVOKABLE void pan(double horizontal, double vertical);
    Q_INVOKABLE void resetView();
    QVariantMap inspection() const;
    Q_INVOKABLE void inspectAt(double x, double y);
    Q_INVOKABLE QString formatCoordinate(double value) const;
    QColor curveColor() const { return m_curveColor; }
    QColor axisColor() const { return m_axisColor; }
    QColor gridColor() const { return m_gridColor; }
    QColor backgroundColor() const { return m_backgroundColor; }
    void setCurveColor(const QColor &color) { m_curveColor = color; update(); emit colorsChanged(); emit functionsChanged(); }
    void setAxisColor(const QColor &color) { m_axisColor = color; update(); emit colorsChanged(); }
    void setGridColor(const QColor &color) { m_gridColor = color; update(); emit colorsChanged(); }
    void setBackgroundColor(const QColor &color) { m_backgroundColor = color; update(); emit colorsChanged(); }
    void paint(QPainter *painter) override;
signals:
    void expressionChanged();
    void statusChanged();
    void colorsChanged();
    void functionsChanged();
    void selectionChanged();
    void viewportChanged();
    void inspectionChanged();
private:
    struct Curve {
        int id;
        QString expression;
        Status status = Empty;
        FunctionExpression function;
        std::vector<QLineF> lines;
    };
    void sampleCurve(Curve &curve);
    void resampleViewport();
    QPointF m_center;
    QPointF m_inspectionPosition{0.5, 0.5};
    bool m_inspectionVisible = false;
    double m_span = 20;
    QColor colorFor(const Curve &curve) const;
    std::vector<Curve> m_curves;
    int m_selectedIndex = 0;
    int m_nextId = 2;
    QColor m_curveColor, m_axisColor, m_gridColor, m_backgroundColor;
};
