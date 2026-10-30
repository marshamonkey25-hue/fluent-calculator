// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
// Metadata ported from microsoft/calculator 79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128:
// Calculator.ViewModels/DataLoaders/UnitConverterDataLoader.cs and Resources.resw.
#include "DataConversionDataLoader.h"
#include <algorithm>

using namespace UnitConversionManager;

namespace {
struct DataUnit
{
    Unit unit;
    double megabytes;
};

class DataConversionDataLoader final : public IConverterDataLoader
{
    // Explicit megabyte factors preserve decimal/binary prefixes and bit/byte definitions.
    const std::vector<DataUnit> m_units {
        {{11, L"Bits", L"b", false, false, false}, 0.000000125},
        {{167, L"Nibble", L"nybl", false, false, false}, 0.0000005},
        {{12, L"Bytes", L"B", false, false, false}, 0.000001},
        {{15, L"Kilobits", L"Kb", false, false, false}, 0.000125},
        {{149, L"Kibibits", L"Ki", false, false, false}, 0.000128},
        {{16, L"Kilobytes", L"KB", false, false, false}, 0.001},
        {{150, L"Kibibytes", L"KiB", false, false, false}, 0.001024},
        {{17, L"Megabits", L"Mb", false, false, false}, 0.125},
        {{151, L"Mebibits", L"Mi", false, false, false}, 0.131072},
        {{18, L"Megabytes", L"MB", false, true, false}, 1},
        {{152, L"Mebibytes", L"MiB", false, false, false}, 1.048576},
        {{13, L"Gigabits", L"Gb", false, false, false}, 125},
        {{147, L"Gibibits", L"Gi", false, false, false}, 134.217728},
        {{100, L"floppy disks", L"floppy disks", false, false, true}, 1.474560},
        {{14, L"Gigabytes", L"GB", true, false, false}, 1000},
        {{101, L"CDs", L"CDs", false, false, true}, 700},
        {{148, L"Gibibytes", L"GiB", false, false, false}, 1073.741824},
        {{102, L"DVDs", L"DVDs", false, false, true}, 4700},
        {{21, L"Terabits", L"Tb", false, false, false}, 125000},
        {{155, L"Tebibits", L"Ti", false, false, false}, 137438.953472},
        {{22, L"Terabytes", L"TB", false, false, false}, 1000000},
        {{156, L"Tebibytes", L"TiB", false, false, false}, 1099511.627776},
        {{19, L"Petabits", L"Pb", false, false, false}, 125000000},
        {{153, L"Pebibits", L"Pi", false, false, false}, 140737488.355328},
        {{20, L"Petabytes", L"PB", false, false, false}, 1000000000},
        {{154, L"Pebibytes", L"PiB", false, false, false}, 1125899906.842624},
        {{143, L"Exabits", L"E", false, false, false}, 125000000000},
        {{145, L"Exbibits", L"Ei", false, false, false}, 144115188075.855872},
        {{144, L"Exabytes", L"EB", false, false, false}, 1000000000000},
        {{146, L"Exbibytes", L"EiB", false, false, false}, 1152921504606.846976},
        {{163, L"Zetabits", L"Z", false, false, false}, 125000000000000},
        {{161, L"Zebibits", L"Zi", false, false, false}, 147573952589676.412928},
        {{164, L"Zetabytes", L"ZB", false, false, false}, 1000000000000000},
        {{162, L"Zebibytes", L"ZiB", false, false, false}, 1180591620717411.303424},
        {{159, L"Yottabits", L"Y", false, false, false}, 125000000000000000},
        {{157, L"Yobibits", L"Yi", false, false, false}, 151115727451828646.838272},
        {{160, L"Yottabytes", L"YB", false, false, false}, 1000000000000000000},
        {{158, L"Yobibytes", L"YiB", false, false, false}, 1208925819614629174.706176}
    };
public:
    void LoadData() override {}
    std::vector<Category> GetOrderedCategories() override { return {{13, L"Data", false}}; }
    bool SupportsCategory(const Category &category) override { return category.id == 13; }
    std::vector<Unit> GetOrderedUnits(const Category &) override
    {
        std::vector<Unit> units;
        for (const auto &item : m_units)
            units.push_back(item.unit);
        return units;
    }
    std::unordered_map<Unit, ConversionData, UnitHash> LoadOrderedRatios(const Unit &unit) override
    {
        const auto source = std::find_if(m_units.begin(), m_units.end(),
                                        [&unit](const DataUnit &item) { return item.unit.id == unit.id; });
        std::unordered_map<Unit, ConversionData, UnitHash> ratios;
        for (const auto &target : m_units)
            ratios.emplace(target.unit, ConversionData(source->megabytes / target.megabytes, 0, false));
        return ratios;
    }
};
}

std::shared_ptr<IConverterDataLoader> createDataConversionDataLoader()
{
    return std::make_shared<DataConversionDataLoader>();
}
