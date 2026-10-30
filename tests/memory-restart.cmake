string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef run_id)
set(data_root "${BUILD_DIR}/memory-restart-data-${run_id}")
file(MAKE_DIRECTORY "${data_root}")
file(CHMOD "${data_root}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
foreach(stage standard-write standard-restore scientific-write scientific-restore programmer-write programmer-restore)
    execute_process(
        COMMAND "${TEST_PYTHON}" "${TEST_LAUNCHER}" "${CMAKE_COMMAND}" -E env
            "CALCULATOR_TEST_THEME=light" "CALCULATOR_TEST_LANGUAGE=en-US"
            "CALCULATOR_TEST_DATA_ROOT=${data_root}" "CALCULATOR_TEST_RESTART_STAGE=${stage}"
            "${TEST_EXECUTABLE}" -input "${SOURCE_DIR}/tests/memory-restart"
        WORKING_DIRECTORY "${BUILD_DIR}"
        RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE errors
        TIMEOUT 30
    )
    message("${stage}: ${output}${errors}")
    if(NOT result EQUAL 0)
        file(REMOVE_RECURSE "${data_root}")
        message(FATAL_ERROR "Memory restart stage ${stage} failed: ${result}")
    endif()
endforeach()
file(REMOVE_RECURSE "${data_root}")
