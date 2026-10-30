#pragma once
#include "FunctionExpression.h"
#include <QQuickPaintedItem>
#include <QLineF>
#include <QtQml/qqmlregistration.h>

class FunctionGraph : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString expression READ expression WRITE setExpression NOTIFY expressionChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QColor curveColor READ curveColor WRITE setCurveColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor axisColor READ axisColor WRITE setAxisColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor gridColor READ gridColor WRITE setGridColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY colorsChanged)
public:
    enum Status { Empty, Ready, Invalid, NoPoints, PartialDomain, NoVisibleCurve };
    Q_ENUM(Status)
    explicit FunctionGraph(QQuickItem *parent = nullptr);
    QString expression() const { return m_expression; }
    void setExpression(const QString &expression);
    Status status() const { return m_status; }
    QColor curveColor() const { return m_curveColor; }
    QColor axisColor() const { return m_axisColor; }
    QColor gridColor() const { return m_gridColor; }
    QColor backgroundColor() const { return m_backgroundColor; }
    void setCurveColor(const QColor &color) { m_curveColor = color; update(); emit colorsChanged(); }
    void setAxisColor(const QColor &color) { m_axisColor = color; update(); emit colorsChanged(); }
    void setGridColor(const QColor &color) { m_gridColor = color; update(); emit colorsChanged(); }
    void setBackgroundColor(const QColor &color) { m_backgroundColor = color; update(); emit colorsChanged(); }
    void paint(QPainter *painter) override;
signals:
    void expressionChanged();
    void statusChanged();
    void colorsChanged();
private:
    QString m_expression;
    Status m_status = Empty;
    FunctionExpression m_function;
    std::vector<QLineF> m_lines;
    QColor m_curveColor, m_axisColor, m_gridColor, m_backgroundColor;
};
