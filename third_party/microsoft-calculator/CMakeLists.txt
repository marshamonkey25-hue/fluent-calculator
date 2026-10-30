# The pinned Microsoft Calculator arithmetic core; intentionally excludes UWP,
# forced PCH, unit conversion and the platform interop projects.
add_library(microsoft_calculator_core STATIC
    src/CalcManager/CalculatorHistory.cpp
    src/CalcManager/CalculatorManager.cpp
    src/CalcManager/ExpressionCommand.cpp
    src/CalcManager/CEngine/CalcInput.cpp
    src/CalcManager/CEngine/CalcUtils.cpp
    src/CalcManager/CEngine/History.cpp
    src/CalcManager/CEngine/Number.cpp
    src/CalcManager/CEngine/Rational.cpp
    src/CalcManager/CEngine/RationalMath.cpp
    src/CalcManager/CEngine/calc.cpp
    src/CalcManager/CEngine/scicomm.cpp
    src/CalcManager/CEngine/scidisp.cpp
    src/CalcManager/CEngine/scifunc.cpp
    src/CalcManager/CEngine/scioper.cpp
    src/CalcManager/CEngine/sciset.cpp
    src/CalcManager/Ratpack/basex.cpp
    src/CalcManager/Ratpack/conv.cpp
    src/CalcManager/Ratpack/exp.cpp
    src/CalcManager/Ratpack/fact.cpp
    src/CalcManager/Ratpack/itrans.cpp
    src/CalcManager/Ratpack/itransh.cpp
    src/CalcManager/Ratpack/logic.cpp
    src/CalcManager/Ratpack/num.cpp
    src/CalcManager/Ratpack/rat.cpp
    src/CalcManager/Ratpack/support.cpp
    src/CalcManager/Ratpack/trans.cpp
    src/CalcManager/Ratpack/transh.cpp
)
target_include_directories(microsoft_calculator_core PUBLIC src/CalcManager)
set_target_properties(microsoft_calculator_core PROPERTIES AUTOMOC OFF AUTOUIC OFF)

# Selected portable noncurrency converter and original numeric formatting.
add_library(microsoft_unit_converter STATIC
    src/CalcManager/UnitConverter.cpp
    src/CalcManager/NumberFormattingUtils.cpp
)
target_include_directories(microsoft_unit_converter PUBLIC src/CalcManager)
set_target_properties(microsoft_unit_converter PROPERTIES AUTOMOC OFF AUTOUIC OFF)
