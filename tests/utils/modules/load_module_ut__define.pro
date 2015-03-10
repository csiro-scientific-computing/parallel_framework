pro load_module_ut::setup
    compile_opt strictarr

    self->teardown

    ; set up test files. Individual tests should
    ; delete appropriate files to test desired 
    ; functionality
    FILE_MKDIR, "./first"
    OPENW, loc_pro, "on_path.pro", /GET_LUN

    writeu, loc_pro, "pro on_path", 10B
    writeu, loc_pro, "    print, !PATH", 10B
    writeu, loc_pro, "end", 10B

    CLOSE, loc_pro
    FREE_LUN, loc_pro

    FILE_COPY, "on_path.pro", "./first/on_path.pro"

    RESOLVE_ROUTINE, "on_path", /COMPILE_FULL_FILE
    SAVE, /ROUTINES, "on_path", FILENAME="on_path.sav"

    FILE_COPY, "on_path.sav", "./first/on_path.sav"

    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_PROCEDURE="load_module", /CONTINUE_ON_ERROR, /QUIET

    CD, "first"
    CD, "../", CURRENT=abs_first

    !PATH = abs_first+PATH_SEP(/SEARCH_PATH)+!PATH

end

pro load_module_ut::teardown
    compile_opt strictarr

    FILE_DELETE, "on_path.pro", "on_path.sav", "./first", /RECURSIVE, /QUIET
end

function load_module_ut::load_module_test, in, expected, msg
    compile_opt strictarr

    result=0

    if expected eq "none" then expected='IDL_M_SUCCESS'

    CATCH, result

    if result eq 0 then begin
        MESSAGE, /CONTINUE, /RESET
        load_module, module_name=in
    endif

    CATCH, /CANCEL

    assert, STRCMP(!ERROR_STATE.NAME, expected), $
            msg+': in %s, error %s, error expected %s', $
            in, !ERROR_STATE.NAME, expected
    return, 1
end

function load_module_ut::test_Error_On_Missing_Module_Name_Arg
    compile_opt strictarr
    testin = ""
    expected_error="IDL_M_USER_ERR"

    return, self->load_module_test(testin, expected_error, $
                            'incorrect handling of missing module_name arg')
end

function load_module_ut::test_Handling_Of_Nonexistent_Module
    compile_opt strictarr
    testin = "a_module_not_on_path"
    expected_error = "IDL_M_UPRO_UNDEF"

    return, self->load_module_test(testin, expected_error, $
                            'incorrect handling in case of non-existent module')
end

function load_module_ut::test_Success_On_Sav_But_No_Pro_Version
    compile_opt strictarr
    testin = "on_path"
    expected_error = "none"
    FILE_DELETE, "./on_path.pro", "./first/on_path.pro"

    return, self->load_module_test(testin, expected_error, $
                            'incorrect handling in case of sav but no pro versions module available')
end

function load_module_ut::test_Success_On_Pro_But_No_Sav_Version
    compile_opt strictarr
    testin = "on_path"
    expected_error = "none"
    FILE_DELETE, "./on_path.sav", "./first/on_path.sav"

    return, self->load_module_test(testin, expected_error, $
                            'incorrect handling in case of pro but no sav versions module available')
end


function load_module_ut::test_Success_On_Sav_In_Path_But_None_In_Local_Dir
    compile_opt strictarr
    testin = "on_path"
    expected_error = "none"
    FILE_DELETE, "./on_path.*", "./first/on_path.pro"

    return, self->load_module_test(testin, expected_error, $
                            'incorrect handling when sav version is on path, but none are in local dir')
end

function load_module_ut::test_Success_On_Sav_In_Path_And_Pro_In_Local_Dir
    compile_opt strictarr
    testin = "on_path"
    expected_error = "none"
    FILE_DELETE, "./on_path.sav", "./first/on_path.pro"

    return, self->load_module_test(testin, expected_error, $
                            'incorrect handling when sav version is on path with pro in local dir')
end

pro load_module_ut__define
    compile_opt strictarr
    struct = { load_module_ut, inherits MGutTestCase }
end
