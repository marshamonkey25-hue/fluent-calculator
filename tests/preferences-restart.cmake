include("${CMAKE_CURRENT_LIST_DIR}/restart-driver.cmake")
run_calculator_restart(restart restart-data "Preference"
    write restore scientific-write scientific-restore programmer-write programmer-restore invalid)
