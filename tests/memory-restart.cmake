include("${CMAKE_CURRENT_LIST_DIR}/restart-driver.cmake")
run_calculator_restart(memory-restart memory-restart-data "Memory"
    standard-write standard-restore scientific-write scientific-restore programmer-write programmer-restore)
