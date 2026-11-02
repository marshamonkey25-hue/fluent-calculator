#pragma once

#include "CalculatorResource.h"
#include <QHash>
#include <QString>

class EngineResources final : public CalculationManager::IResourceProvider
{
public:
    EngineResources();
    void setLanguage(const QString &language);
    std::wstring GetCEngineString(std::wstring_view id) override;

private:
    QHash<QString, QString> m_strings;
};
