# Native packages use distribution Qt; macOS/Windows installers deploy the SDK runtime.
include(GNUInstallDirs)
option(CALCULATOR_BUNDLE_QT "Deploy a private Qt runtime for the Linux package" OFF)
if(CALCULATOR_BUNDLE_QT)
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux" OR NOT CMAKE_INSTALL_PREFIX STREQUAL "/opt/fluent-calculator")
        message(FATAL_ERROR "Linux bundled-Qt packages require CMAKE_INSTALL_PREFIX=/opt/fluent-calculator")
    endif()
    set_target_properties(calculator PROPERTIES OUTPUT_NAME fluent-calculator
        INSTALL_RPATH "$ORIGIN/../lib")
endif()
set(CALCULATOR_PACKAGE_PLATFORM "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}"
    CACHE STRING "Platform label included in release artifact names")
set(CALCULATOR_PACKAGE_CONTACT "Fluent Calculator contributors"
    CACHE STRING "Maintainer contact written into package metadata")

if(APPLE)
    set_target_properties(calculator PROPERTIES
        MACOSX_BUNDLE TRUE
        OUTPUT_NAME "FluentCalculator"
        MACOSX_BUNDLE_BUNDLE_NAME "Fluent Calculator"
        MACOSX_BUNDLE_GUI_IDENTIFIER "org.fluentcalculator.Calculator"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_ICON_FILE fluent-calculator.icns)
    target_sources(calculator PRIVATE "${PROJECT_SOURCE_DIR}/packaging/macos/fluent-calculator.icns")
    set_source_files_properties("${PROJECT_SOURCE_DIR}/packaging/macos/fluent-calculator.icns"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
elseif(WIN32)
    enable_language(RC)
    set_target_properties(calculator PROPERTIES WIN32_EXECUTABLE TRUE OUTPUT_NAME fluent-calculator)
    configure_file("${PROJECT_SOURCE_DIR}/packaging/windows/app.rc.in"
        "${PROJECT_BINARY_DIR}/calculator-icon.rc" @ONLY)
    target_sources(calculator PRIVATE "${PROJECT_BINARY_DIR}/calculator-icon.rc")
endif()

if(APPLE OR WIN32 OR CALCULATOR_BUNDLE_QT)
    install(TARGETS calculator BUNDLE DESTINATION . RUNTIME DESTINATION bin)
    # Qt's supported native deployment path copies the QML imports, platform
    # plugins, libraries/frameworks and compiler runtime required by the app.
    qt_generate_deploy_qml_app_script(TARGET calculator OUTPUT_SCRIPT calculator_deploy_script)
    install(SCRIPT "${calculator_deploy_script}")
    include("${PROJECT_SOURCE_DIR}/packaging/DeployExtraPlugins.cmake")
    if(MSVC)
        set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION bin)
        include(InstallRequiredSystemLibraries)
    endif()
    if(APPLE)
        set(calculator_docs "FluentCalculator.app/Contents/Resources/doc")
        set(calculator_license_dir "FluentCalculator.app/Contents/Resources/licenses")
    else()
        set(calculator_docs "${CMAKE_INSTALL_DATADIR}/doc/fluent-calculator")
        set(calculator_license_dir "${CMAKE_INSTALL_DATADIR}/licenses/fluent-calculator")
    endif()
    install(DIRECTORY "${PROJECT_SOURCE_DIR}/packaging/licenses/"
        DESTINATION "${calculator_docs}/qt-licenses")
    if(CALCULATOR_BUNDLE_QT)
        install(FILES packaging/linux/fluent-calculator.desktop DESTINATION /usr/share/applications)
        install(FILES packaging/linux/fluent-calculator.svg DESTINATION /usr/share/icons/hicolor/scalable/apps)
        install(FILES packaging/linux/fluent-calculator.png DESTINATION /usr/share/icons/hicolor/256x256/apps)
        install(SCRIPT "${PROJECT_SOURCE_DIR}/packaging/linux/install-command-link.cmake")
    endif()
else()
    # The Linux development executable remains `calculator` for existing commands.
    install(PROGRAMS "$<TARGET_FILE:calculator>"
        DESTINATION ${CMAKE_INSTALL_BINDIR} RENAME fluent-calculator)
    install(FILES packaging/linux/fluent-calculator.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES packaging/linux/fluent-calculator.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
    install(FILES packaging/linux/fluent-calculator.png
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps)
    set(calculator_docs "${CMAKE_INSTALL_DOCDIR}")
    set(calculator_license_dir "${CMAKE_INSTALL_DATADIR}/licenses/fluent-calculator")
endif()

install(FILES third_party/microsoft-calculator/LICENSE third_party/microsoft-calculator/NOTICE.txt
    DESTINATION "${calculator_license_dir}/microsoft-calculator")
install(FILES packaging/linux/LICENSE-STATUS.txt
    DESTINATION "${calculator_license_dir}" RENAME PROJECT-LICENSE-STATUS.txt)
install(FILES README.md DESTINATION "${calculator_docs}")
install(DIRECTORY docs/ DESTINATION "${calculator_docs}/docs")
install(FILES third_party/microsoft-calculator/README.md
    third_party/microsoft-calculator/LICENSE third_party/microsoft-calculator/NOTICE.txt
    DESTINATION "${calculator_docs}/third_party/microsoft-calculator")
if(APPLE OR WIN32 OR CALCULATOR_BUNDLE_QT)
    get_filename_component(calculator_qt_prefix "${Qt6_DIR}/../../.." ABSOLUTE)
    if(EXISTS "${calculator_qt_prefix}/licenses")
        install(DIRECTORY "${calculator_qt_prefix}/licenses/" DESTINATION "${calculator_docs}/qt-licenses/sdk")
    endif()
endif()
if(APPLE)
    set(CALCULATOR_MACOS_SIGN_IDENTITY "-" CACHE STRING "codesign identity; '-' produces an ad-hoc signature")
    configure_file("${PROJECT_SOURCE_DIR}/packaging/macos/sign-bundle.cmake.in"
        "${PROJECT_BINARY_DIR}/sign-bundle.cmake" @ONLY)
    # Sign last, after deployment and documentation have populated Resources.
    install(SCRIPT "${PROJECT_BINARY_DIR}/sign-bundle.cmake")
endif()

set(CPACK_PACKAGE_NAME fluent-calculator)
set(CPACK_VERBATIM_VARIABLES ON)
set(CPACK_PACKAGE_VENDOR "Fluent Calculator contributors")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_CONTACT "${CALCULATOR_PACKAGE_CONTACT}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Fluent desktop calculator with scientific, programmer, graphing and conversion modes")
set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/packaging/linux/LICENSE-STATUS.txt")
set(CPACK_PACKAGE_FILE_NAME "fluent-calculator-${PROJECT_VERSION}-${CALCULATOR_PACKAGE_PLATFORM}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Fluent Calculator")
set(CPACK_PACKAGE_EXECUTABLES fluent-calculator "Fluent Calculator")
set(CPACK_MONOLITHIC_INSTALL ON)

if(APPLE)
    set(CPACK_GENERATOR DragNDrop)
    set(CPACK_DMG_VOLUME_NAME "Fluent Calculator ${PROJECT_VERSION}")
    # Notices are inside the app; keep mounting/verifying the image unattended.
    set(CPACK_DMG_SLA_USE_RESOURCE_FILE_LICENSE OFF)
    set(CPACK_PACKAGING_INSTALL_PREFIX "/")
elseif(WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_NSIS_DISPLAY_NAME "Fluent Calculator")
    set(CPACK_NSIS_PACKAGE_NAME "Fluent Calculator")
    set(CPACK_NSIS_MUI_ICON "${PROJECT_SOURCE_DIR}/packaging/windows/fluent-calculator.ico")
    set(CPACK_NSIS_MUI_UNIICON "${PROJECT_SOURCE_DIR}/packaging/windows/fluent-calculator.ico")
    set(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\fluent-calculator.exe")
    set(CPACK_NSIS_MODIFY_PATH OFF)
    set(CPACK_CREATE_DESKTOP_LINKS fluent-calculator)
    set(CPACK_PACKAGING_INSTALL_PREFIX "/")
else()
    set(CPACK_GENERATOR "TGZ")
    if(CALCULATOR_BUNDLE_QT)
        set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/fluent-calculator")
        set(CPACK_SET_DESTDIR ON)
    else()
        set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
    endif()
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CALCULATOR_PACKAGE_CONTACT}")
    set(CPACK_DEBIAN_PACKAGE_SECTION utils)
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
    # These modules are imported at runtime, so ELF dependency scanning alone
    # cannot detect them. The package is built against Debian's actual Qt.
    if(CALCULATOR_BUNDLE_QT)
        # Qt is private in /opt; dpkg-shlibdeps supplies system ELF dependencies.
        # OpenSSL is loaded by Qt's TLS backend at runtime.
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "libssl3t64")
    else()
        set(CPACK_DEBIAN_PACKAGE_DEPENDS
            "qml6-module-qtquick (>= ${Qt6_VERSION}), qml6-module-qtquick-controls (>= ${Qt6_VERSION}), qml6-module-qtquick-layouts, qml6-module-qtqml-workerscript, qml6-module-qtquick-window, qml6-module-qtquick-templates, qt6-qpa-plugins, qt6-wayland")
    endif()
    set(CPACK_RPM_PACKAGE_LICENSE "LicenseRef-Project-Unspecified AND MIT")
    set(CPACK_RPM_PACKAGE_GROUP "Applications/Utilities")
    set(CPACK_RPM_PACKAGE_AUTOREQ ON)
    set(CPACK_RPM_PACKAGE_REQUIRES "qt6-qtbase-gui >= ${Qt6_VERSION}, qt6-qtdeclarative >= ${Qt6_VERSION}, qt6-qtwayland")
    set(CPACK_RPM_PACKAGE_RELEASE_DIST ON)
    set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
        /usr/share /usr/share/applications /usr/share/icons /usr/share/icons/hicolor
        /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/256x256/apps
        /usr/share/icons/hicolor/scalable /usr/share/icons/hicolor/scalable/apps
        /usr/share/doc /usr/share/licenses)
endif()
include(CPack)
