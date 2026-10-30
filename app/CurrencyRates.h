#pragma once

#include "CurrencySource.h"
#include "UnitConverter.h"
#include <QPointer>
#include <QVariantList>
#include <QHash>
#include <QJsonObject>

// Validated daily observations, persisted independently of calculation sessions.
class CurrencyRates : public QObject, public UnitConversionManager::IConverterDataLoader
{
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(QString observationDate READ observationDate NOTIFY changed)
    Q_PROPERTY(QString refreshedAt READ refreshedAt NOTIFY changed)
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(bool usingCached READ usingCached NOTIFY changed)
    Q_PROPERTY(bool cacheWriteFailed READ cacheWriteFailed NOTIFY changed)
public:
    explicit CurrencyRates(QObject *parent = nullptr);
    void setSource(CurrencySource *source);
    QString state() const { return m_state; }
    QString observationDate() const { return m_date; }
    QString refreshedAt() const { return m_refreshedAt; }
    bool available() const { return m_rate > 0; }
    bool usingCached() const { return m_usingCached; }
    bool cacheWriteFailed() const { return m_cacheWriteFailed; }
    void selectPair(int first, int second);
    Q_INVOKABLE void refresh();
    QVariantList units(const QString &language) const;
    void LoadData() override {}
    std::vector<UnitConversionManager::Category> GetOrderedCategories() override;
    std::vector<UnitConversionManager::Unit> GetOrderedUnits(const UnitConversionManager::Category &) override;
    bool IsCurrencyCategory(const UnitConversionManager::Category &category) const override { return category.id == 3; }
    bool SupportsCategory(const UnitConversionManager::Category &category) override { return category.id == 3; }
    std::unordered_map<UnitConversionManager::Unit, UnitConversionManager::ConversionData, UnitConversionManager::UnitHash>
        LoadOrderedRatios(const UnitConversionManager::Unit &unit) override;
signals:
    void changed();
    void dataChanged();
private:
    void receive(quint64 requestId, const QByteArray &body, bool success);
    void requestRate();
    void loadCache();
    void saveCache();
    QString code(int id) const;
    CurrencySource m_defaultSource;
    QPointer<CurrencySource> m_source;
    QVariantList m_catalog;
    QHash<QString, QJsonObject> m_observations;
    QString m_base;
    QString m_quote;
    QString m_state = QStringLiteral("unavailable");
    QString m_date;
    QString m_refreshedAt;
    double m_rate = 0;
    bool m_usingCached = false;
    bool m_cacheWriteFailed = false;
    quint64 m_generation = 0;
    quint64 m_catalogRequest = 0;
    quint64 m_rateRequest = 0;
};
