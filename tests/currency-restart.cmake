include("${CMAKE_CURRENT_LIST_DIR}/restart-driver.cmake")
run_calculator_restart(currency-restart currency-restart-data "Currency"
    write restore recover restore-recovered)
