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
        app/EngineResources.h app/EngineResources.cpp
    QML_FILES
        qml/MainWindow.qml
        qml/StandardPage.qml
        qml/SettingsPage.qml
        qml/ScientificPage.qml
        qml/CalculatorButton.qml
        qml/ModeRegistry.qml
)
target_include_directories(calculator_ui PUBLIC app)
target_link_libraries(calculator_ui PUBLIC Qt6::Quick Qt6::QuickControls2 microsoft_calculator_core)
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
    qt_add_executable(calculator_ui_tests tests/quicktest.cpp)
    target_link_libraries(calculator_ui_tests PRIVATE calculator_ui calculator_uiplugin Qt6::QuickTest)
    target_compile_definitions(calculator_ui_tests PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/qml")
    add_test(NAME calculator-preferences-restart
        COMMAND ${CMAKE_COMMAND}
            -DTEST_EXECUTABLE=$<TARGET_FILE:calculator_ui_tests>
            -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -DBUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/preferences-restart.cmake)
    set_tests_properties(calculator-preferences-restart PROPERTIES TIMEOUT 100)
    foreach(theme light dark)
        add_test(NAME calculator-ui-${theme} COMMAND calculator_ui_tests)
        set_tests_properties(calculator-ui-${theme} PROPERTIES
            ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QSG_RHI_BACKEND=software;CALCULATOR_TEST_THEME=${theme}"
            TIMEOUT 60
        )
    endforeach()
    add_test(NAME calculator-ui-zh-CN COMMAND calculator_ui_tests)
    set_tests_properties(calculator-ui-zh-CN PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QSG_RHI_BACKEND=software;CALCULATOR_TEST_LANGUAGE=zh-CN;CALCULATOR_TEST_THEME=light"
        TIMEOUT 60
    )
endif()
