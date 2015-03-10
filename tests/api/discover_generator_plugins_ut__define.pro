pro discover_generator_plugins_ut::setup
    compile_opt strictarr

    ; set up test files. Individual tests should
    ; delete appropriate files to test desired 
    ; functionality
    FILE_MKDIR, "./testpath"
    OPENW, loc_pro1, "./testpath/test1_job_generator.pro", /GET_LUN
    OPENW, loc_pro2, "./testpath/test2_job_generator.pro", /GET_LUN
    CLOSE, loc_pro1, loc_pro2
    CLOSE, loc_pro1, loc_pro2

    FILE_MKDIR, "./testpath2"
    FILE_COPY, ['./testpath/*.pro', './testpath/*.sav'], './testpath2'

    !PATH = abs_first+PATH_SEP(/SEARCH_PATH)+!PATH

end

pro discover_generator_plugins_ut::teardown
    compile_opt strictarr

    FILE_DELETE, "./testpath", "./testpath2", /RECURSIVE, /QUIET
end

pro discover_generator_plugins_ut::test_No_Plugin_Files
    compile_opt strictarr

    FILE_DELETE, "./testpath/", "./testpath2", /RECURSIVE, /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Sav_Plugin_Files_Only
    compile_opt strictarr

    FILE_DELETE, "./testpath2", "./testpath/*.pro", /RECURSIVE, /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Pro_Plugin_Files_Only
    compile_opt strictarr

    FILE_DELETE, "./testpath2", "./testpath/*.sav", /RECURSIVE, /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Mix_Pro_And_Sav_Plugin_Files
    compile_opt strictarr

    FILE_DELETE, "./testpath2", "./testpath/test2_job_generator.pro", $
                 "./test1_job_generator.sav", /RECURSIVE, /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Duplicate_Pro_vs_Sav_Plugin_Files_In_Same_Dir
    compile_opt strictarr

    FILE_DELETE, "./testpath2", /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Duplicate_Pro_vs_Sav_Plugin_Files_In_Diff_Dir
    compile_opt strictarr

    FILE_DELETE, "./testpath/*.pro", "./testpath2/*.sav", /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Duplicate_Pro_Plugin_Files
    compile_opt strictarr

    FILE_DELETE, "./testpath2/*.sav", /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut::test_Duplicate_Sav_Plugin_Files
    compile_opt strictarr

    FILE_DELETE, "./testpath2/*.pro", /QUIET
    result=discover_generator_plugins()
    assert, result eq expected, $
            'incorrect handling of non-existent plugins: out %s, expected %s', $
            result, expected
    return, 1
end

pro discover_generator_plugins_ut__define
	struct = { discover_generator_plugins_ut, inherits MGutTestCase }
end
