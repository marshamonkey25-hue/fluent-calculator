cmake_minimum_required(VERSION 3.21)
project(FluentCalculator VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)
include(CTest)
add_subdirectory(third_party/microsoft-calculator)

set_source_files_properties(qml/ModeRegistry.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_library(calculator_ui STATIC)
qt_add_qml_module(calculator_ui
    URI Calculator
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Calculator
    SOURCES
        app/AppPreferences.h app/AppPreferences.cpp
        app/SystemPreferences.h app/SystemPreferences.cpp
        app/CalculationSession.h app/CalculationSession.cpp
        app/FunctionExpression.h app/FunctionExpression.cpp
        app/FunctionGraph.h app/FunctionGraph.cpp
        app/EngineResources.h app/EngineResources.cpp
        app/DateCalculation.h app/DateCalculation.cpp
        app/ConversionSession.h app/ConversionSession.cpp
        app/LengthDataLoader.h app/LengthDataLoader.cpp
        app/MeasurementDataLoader.h app/MeasurementDataLoader.cpp
        app/EnergySpeedTimePressureDataLoader.h app/EnergySpeedTimePressureDataLoader.cpp
    QML_FILES
        qml/MainWindow.qml
        qml/StandardPage.qml
        qml/SettingsPage.qml
        qml/ScientificPage.qml
        qml/ScientificTrigonometry.qml
        qml/GraphingPage.qml
        qml/ProgrammerPage.qml
        qml/ProgrammerBitPanel.qml
        qml/HistoryPanel.qml
        qml/MemoryBar.qml
        qml/MemoryPanel.qml
        qml/DatePage.qml
        qml/DatePicker.qml
        qml/CalculatorButton.qml
        qml/ModeRegistry.qml
        qml/ConverterPage.qml
        qml/ConverterValue.qml
        qml/ConverterUnitSelector.qml
)
target_include_directories(calculator_ui PUBLIC app)
target_link_libraries(calculator_ui PUBLIC Qt6::Quick Qt6::QuickControls2 microsoft_calculator_core microsoft_unit_converter)
qt_add_resources(calculator_ui ui_translations
    PREFIX /ui
    BASE resources/ui
    FILES resources/ui/zh-CN.json
)
qt_add_resources(calculator_ui engine_resources
    PREFIX /engine
    BASE resources/engine
    FILES resources/engine/en-US.json resources/engine/zh-CN.json
)

qt_add_executable(calculator app/main.cpp)
target_link_libraries(calculator PRIVATE calculator_ui calculator_uiplugin)

if(BUILD_TESTING)
    find_package(Qt6 6.8 REQUIRED COMPONENTS QuickTest)
    find_package(Python3 3.8 REQUIRED COMPONENTS Interpreter)
    set(ui_test_launcher "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/run-ui-isolated.py")
    qt_add_executable(calculator_ui_tests tests/quicktest.cpp)
    target_link_libraries(calculator_ui_tests PRIVATE calculator_ui calculator_uiplugin Qt6::QuickTest)
    target_compile_definitions(calculator_ui_tests PRIVATE
        QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/qml"
        CALCULATOR_TEST_PYTHON="${Python3_EXECUTABLE}"
        CALCULATOR_TEST_LAUNCHER="${CMAKE_CURRENT_SOURCE_DIR}/tests/run-ui-isolated.py")
    add_test(NAME calculator-test-isolation
        COMMAND ${ui_test_launcher} "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_ui_isolation.py"
            --test-executable $<TARGET_FILE:calculator_ui_tests>)
    set_tests_properties(calculator-test-isolation PROPERTIES TIMEOUT 60)
    add_test(NAME calculator-memory-restart
        COMMAND ${ui_test_launcher} ${CMAKE_COMMAND}
            -DTEST_PYTHON=${Python3_EXECUTABLE}
            -DTEST_LAUNCHER=${CMAKE_CURRENT_SOURCE_DIR}/tests/run-ui-isolated.py
            -DTEST_EXECUTABLE=$<TARGET_FILE:calculator_ui_tests>
            -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -DBUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/memory-restart.cmake)
    set_tests_properties(calculator-memory-restart PROPERTIES TIMEOUT 200)
    add_test(NAME calculator-history-restart
        COMMAND ${ui_test_launcher} ${CMAKE_COMMAND}
            -DTEST_PYTHON=${Python3_EXECUTABLE}
            -DTEST_LAUNCHER=${CMAKE_CURRENT_SOURCE_DIR}/tests/run-ui-isolated.py
            -DTEST_EXECUTABLE=$<TARGET_FILE:calculator_ui_tests>
            -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -DBUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/history-restart.cmake)
    set_tests_properties(calculator-history-restart PROPERTIES TIMEOUT 100)
    add_test(NAME calculator-length-restart
        COMMAND ${ui_test_launcher} ${CMAKE_COMMAND}
            -DTEST_PYTHON=${Python3_EXECUTABLE}
            -DTEST_LAUNCHER=${CMAKE_CURRENT_SOURCE_DIR}/tests/run-ui-isolated.py
            -DTEST_EXECUTABLE=$<TARGET_FILE:calculator_ui_tests>
            -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -DBUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/length-restart.cmake)
    set_tests_properties(calculator-length-restart PROPERTIES TIMEOUT 100)
    add_test(NAME calculator-preferences-restart
        COMMAND ${ui_test_launcher} ${CMAKE_COMMAND}
            -DTEST_PYTHON=${Python3_EXECUTABLE}
            -DTEST_LAUNCHER=${CMAKE_CURRENT_SOURCE_DIR}/tests/run-ui-isolated.py
            -DTEST_EXECUTABLE=$<TARGET_FILE:calculator_ui_tests>
            -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -DBUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/preferences-restart.cmake)
    set_tests_properties(calculator-preferences-restart PROPERTIES TIMEOUT 100)
    foreach(variant light dark zh-CN)
        add_test(NAME calculator-energy-speed-time-pressure-${variant}
            COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
                -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/energy-speed-time-pressure)
        if(variant STREQUAL "zh-CN")
            set(conversion_test_environment "CALCULATOR_TEST_LANGUAGE=zh-CN;CALCULATOR_TEST_THEME=light")
        else()
            set(conversion_test_environment "CALCULATOR_TEST_THEME=${variant}")
        endif()
        set_tests_properties(calculator-energy-speed-time-pressure-${variant} PROPERTIES
            ENVIRONMENT "${conversion_test_environment}" TIMEOUT 600)
    endforeach()
    foreach(theme light dark)
        add_test(NAME calculator-ui-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>)
        add_test(NAME calculator-programmer-bits-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/programmer)
        add_test(NAME calculator-volume-area-mass-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/volume-area-mass)
        set_tests_properties(calculator-volume-area-mass-${theme} PROPERTIES
            ENVIRONMENT "CALCULATOR_TEST_THEME=${theme}"
            TIMEOUT 180)
        add_test(NAME calculator-length-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/length)

        add_test(NAME calculator-graphing-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/graphing)
        set_tests_properties(calculator-graphing-${theme} PROPERTIES
            ENVIRONMENT "CALCULATOR_TEST_THEME=${theme}"
            TIMEOUT 120)
        add_test(NAME calculator-history-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/history)
        add_test(NAME calculator-memory-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/memory)
        add_test(NAME calculator-date-${theme} COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/date)
        set_tests_properties(calculator-ui-${theme} calculator-programmer-bits-${theme} calculator-history-${theme} calculator-memory-${theme} calculator-date-${theme} calculator-length-${theme} PROPERTIES
            ENVIRONMENT "CALCULATOR_TEST_THEME=${theme}"
            TIMEOUT 600
        )
    endforeach()
    add_test(NAME calculator-ui-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>)
    add_test(NAME calculator-programmer-bits-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/programmer)
    add_test(NAME calculator-volume-area-mass-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/volume-area-mass)
    set_tests_properties(calculator-volume-area-mass-zh-CN PROPERTIES
        ENVIRONMENT "CALCULATOR_TEST_LANGUAGE=zh-CN;CALCULATOR_TEST_THEME=light"
        TIMEOUT 180)
    add_test(NAME calculator-volume-area-mass-ja-JP COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/volume-area-mass
        VolumeAreaMassConversion::test_000_reference_defaults
        VolumeAreaMassConversion::test_reference_unit_catalog_and_ratios)
    set_tests_properties(calculator-volume-area-mass-ja-JP PROPERTIES
        ENVIRONMENT "CALCULATOR_TEST_LOCALE=ja_JP;CALCULATOR_TEST_THEME=light"
        TIMEOUT 120)
    add_test(NAME calculator-length-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/length)

    add_test(NAME calculator-graphing-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/graphing)
    set_tests_properties(calculator-graphing-zh-CN PROPERTIES
        ENVIRONMENT "CALCULATOR_TEST_LANGUAGE=zh-CN;CALCULATOR_TEST_THEME=light"
        TIMEOUT 120)
    add_test(NAME calculator-history-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/history)
    add_test(NAME calculator-memory-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/memory)
    add_test(NAME calculator-date-zh-CN COMMAND ${ui_test_launcher} $<TARGET_FILE:calculator_ui_tests>
        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/date)
    set_tests_properties(calculator-ui-zh-CN calculator-programmer-bits-zh-CN calculator-history-zh-CN calculator-memory-zh-CN calculator-date-zh-CN calculator-length-zh-CN PROPERTIES
        ENVIRONMENT "CALCULATOR_TEST_LANGUAGE=zh-CN;CALCULATOR_TEST_THEME=light"
        TIMEOUT 600
    )
endif()
