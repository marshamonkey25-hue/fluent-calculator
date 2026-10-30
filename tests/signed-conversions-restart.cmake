include("${CMAKE_CURRENT_LIST_DIR}/restart-driver.cmake")
run_calculator_restart(signed-conversions-restart temperature-power-angle-restart-data "Temperature/power/angle"
    temperature-write temperature-restore power-write power-restore angle-write angle-restore)
