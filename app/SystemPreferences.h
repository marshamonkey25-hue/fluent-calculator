#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// The platform boundary for native appearance/language. Tests replace only this
// external input; the settings UI, persistence, translation and core stay real.
class SystemPreferences : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit SystemPreferences(QObject *parent = nullptr);
    virtual QString language() const;
    virtual void applyTheme(const QString &preference);
signals:
    void languageChanged();
protected:
    bool eventFilter(QObject *object, QEvent *event) override;
};
