include("${CMAKE_CURRENT_LIST_DIR}/restart-driver.cmake")
run_calculator_restart(history-restart history-restart-data "History"
    standard-write standard-restore scientific-write scientific-restore)
