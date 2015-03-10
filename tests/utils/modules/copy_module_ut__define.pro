pro copy_module_ut::setup
    compile_opt strictarr
    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_PROCEDURE="copy_module", /CONTINUE_ON_ERROR, /QUIET

    ; set up test files. Individual tests should
    ; delete appropriate files to test desired 
    ; functionality
    FILE_MKDIR, "./first/second"
    FILE_MKDIR, "./dest"
    OPENW, loc_pro, "on_path.pro", /GET_LUN
    OPENW, loc_sav, "on_path.sav", /GET_LUN
    CLOSE, loc_pro, loc_sav
    FREE_LUN, loc_pro, loc_sav
    OPENW, first_pro, "./first/on_path.pro", /GET_LUN
    OPENW, first_sav, "./first/on_path.sav", /GET_LUN
    CLOSE, first_pro, first_sav
    FREE_LUN, first_pro, first_sav
    OPENW, second_pro, "./first/second/on_path.pro", /GET_LUN
    OPENW, second_sav, "./first/second/on_path.sav", /GET_LUN
    CLOSE, second_pro, second_sav
    FREE_LUN, second_pro, second_sav

    CD, "first", CURRENT=temp
    self.current_dir=temp
    CD, "../", CURRENT=abs_first

    !PATH = abs_first+PATH_SEP(/SEARCH_PATH)+!PATH

end

pro copy_module_ut::teardown
    compile_opt strictarr

    FILE_DELETE, "on_path.pro", "on_path.sav", "./dest", "./first", /RECURSIVE, /QUIET
end


function copy_module_ut::copy_module_test, in, expected, cpy_dest, msg
    compile_opt strictarr

    result=0

    CATCH, result

    if result eq 0 then begin
        MESSAGE, /CONTINUE, /RESET
        copy_module, module_name=in, dest_dir=cpy_dest, copied=result

        CATCH, /CANCEL
        matches=STRCMP(result, expected)
        assert, TOTAL(matches) eq N_ELEMENTS(expected), $
                msg+': in %s, out %s, expected %s', $
                "["+in+", "+cpy_dest+"]", $
                STRJOIN(result, " "), $
                STRJOIN(expected, " ")
    endif else begin

        CATCH, /CANCEL
        matches=STRCMP(!ERROR_STATE.NAME, expected)
        assert, TOTAL(matches) eq N_ELEMENTS(expected), $
                msg+': in %s, error %s, error expected %s', $
                in, !ERROR_STATE.NAME, STRJOIN(expected, " ")
    endelse

    return, 1
end

function copy_module_ut::test_Handling_Of_Missing_Module_Name_Arg
    compile_opt strictarr
    testin = ""
    expected = [ "" ]

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of missing module_name arg')
end

function copy_module_ut::test_Handling_On_Nonexistent_Module
    compile_opt strictarr
    testin = "a_module_not_on_path"
    expected = [ "" ]

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling in case of non-existent module')
end

function copy_module_ut::test_Default_Local_On_Missing_Dest_Dir_Arg
    compile_opt strictarr
    testin = "on_path"
    expected = [ self.current_dir+"/first/on_path.pro", self.current_dir+"/first/on_path.sav" ]
    FILE_DELETE, "./on_path.pro", "./on_path.sav"

    return, self->copy_module_test(testin, expected, !NULL, $
                            'incorrect handling of missing dest_dir arg')
end

function copy_module_ut::test_Success_Non_Existent_Dest_Dir
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.pro", "on_path.sav" ]
    FILE_DELETE, "./dest", /RECURSIVE

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of non existent dest_dir on disk')
end

function copy_module_ut::test_Handling_When_Dest_Dir_Is_Existing_File
    compile_opt strictarr
    testin = "on_path"
    expected = [ "" ]
    FILE_DELETE, "./dest", /RECURSIVE
    OPENW, f, "dest", /GET_LUN
    CLOSE, f

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of non existent dest_dir on disk')
end

function copy_module_ut::test_Both_In_Local_Dir
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.pro", "on_path.sav" ]

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of both files in local dir')
end

function copy_module_ut::test_Both_In_Same_Dir_On_Path_But_Not_In_Local_Dir
    compile_opt strictarr
    testin = "on_path"
    expected = [ self.current_dir+"/first/on_path.pro", self.current_dir+"/first/on_path.sav" ]
    FILE_DELETE, "./on_path.pro", "./on_path.sav"

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of both files in same location on path')
end

function copy_module_ut::test_Pro_But_No_Sav_In_Local_Dir
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.pro" ]
    FILE_DELETE, "./on_path.sav"

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of 1 pro file & 0 sav fils in local dir')
end

function copy_module_ut::test_Sav_But_No_Pro_In_Local_Dir
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.sav" ]
    FILE_DELETE, "./on_path.pro"

    return, self->copy_module_test(testin, expected, "./dest", $
                            'incorrect handling of 0 pro file & 1 sav files in local dir')
end

function copy_module_ut::test_Pro_But_No_Sav_In_Local_Dir_SAVONLY
    compile_opt strictarr
    testin = "on_path"
    expected = [ self.current_dir+"/first/on_path.sav" ]
    FILE_DELETE, "./on_path.sav"

    copy_module, module_name=testin, dest_dir="./dest", copied=result, /SAV_ONLY
    matches=STRCMP(result, expected)
    assert, TOTAL(matches) eq N_ELEMENTS(expected), $
            'incorrect handling of 1 pro file & 0 sav file in local dir under forced /SAV_ONLY: in %s, out %s, expected %s', $
            "["+testin+", ./dest, /SAV_ONLY]", $
            STRJOIN(result, " "), STRJOIN(expected, " ")
    return, 1
end

function copy_module_ut::test_Sav_But_No_Pro_In_Local_Dir_PROONLY
    compile_opt strictarr
    testin = "on_path"
    expected = [ self.current_dir+"/first/on_path.pro" ]
    FILE_DELETE, "./on_path.pro"

    copy_module, module_name=testin, dest_dir="./dest", copied=result, /PRO_ONLY
    matches=STRCMP(result, expected)
    assert, TOTAL(matches) eq N_ELEMENTS(expected), $
            'incorrect handling of 0 pro file & 1 sav file in local dir under forced /PRO_ONLY: in %s, out %s, expected %s', $
            "["+testin+", ./dest, /PRO_ONLY]", $
            STRJOIN(result, " "), STRJOIN(expected, " ")
    return, 1
end

function copy_module_ut::test_Pro_But_No_Sav_In_Local_Dir_FORCEBOTH
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.pro", self.current_dir+"/first/on_path.sav" ]
    FILE_DELETE, "./on_path.sav"

    copy_module, module_name=testin, dest_dir="./dest", copied=result, /FORCE_BOTH
    matches=STRCMP(result, expected)
    assert, TOTAL(matches) eq N_ELEMENTS(expected), $
            'incorrect handling of 1 pro file & 0 sav file in local dir under /FORCE_BOTH: in %s, out %s, expected %s', $
            "["+testin+", ./dest, /FORCE_BOTH]", $
            STRJOIN(result, " "), STRJOIN(expected, " ")
    return, 1
end

function copy_module_ut::test_Sav_But_No_Pro_In_Local_Dir_FORCEBOTH
    compile_opt strictarr
    testin = "on_path"
    expected = [ self.current_dir+"/first/on_path.pro", "on_path.sav" ]
    FILE_DELETE, "./on_path.pro"

    copy_module, module_name=testin, dest_dir="./dest", copied=result, /FORCE_BOTH
    matches=STRCMP(result, expected)
    assert, TOTAL(matches) eq N_ELEMENTS(expected), $
            'incorrect handling of 0 pro file & 1 sav file in local dir under /FORCE_BOTH: in %s, out %s, expected %s', $
            "["+testin+", ./dest, /FORCE_BOTH]",  $
            STRJOIN(result, " "), STRJOIN(expected, " ")
    return, 1
end

function copy_module_ut::test_PROONLY_Overwrites_SAVONLY
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.pro" ]

    copy_module, module_name=testin, dest_dir="./dest", copied=result, /SAV_ONLY, /PRO_ONLY
    matches=STRCMP(result, expected)
    assert, TOTAL(matches) eq N_ELEMENTS(expected), $
            'incorrect handling of 1 pro file & 1 sav file in local dir under /SAV_ONLY + /PRO_ONLY: in %s, out %s, expected %s', $
            "["+testin+", ./dest, /SAV_ONLY, /PRO_ONLY]", $
            STRJOIN(result, " "), STRJOIN(expected, " ")
    return, 1
end

function copy_module_ut::test_FORCEBOTH_Overwrites_Others
    compile_opt strictarr
    testin = "on_path"
    expected = [ "on_path.pro" , "on_path.sav" ]

    copy_module, module_name=testin, dest_dir="./dest", copied=result, /SAV_ONLY, /PRO_ONLY, /FORCE_BOTH
    matches=STRCMP(result, expected)
    assert, TOTAL(matches) eq N_ELEMENTS(expected), $
            'incorrect handling of 1 pro file & 1 sav file in local dir under /SAV_ONLY + /PRO_ONLY + /FORCE_BOTH: in %s, out %s, expected %s', $
            "["+testin+", ./dest, /SAV_ONLY, /PRO_ONLY, /FORCE_BOTH]", $
            STRJOIN(result, " "), STRJOIN(expected, " ")
    return, 1
end

pro copy_module_ut__define
    compile_opt strictarr
    struct = { copy_module_ut, inherits MGutTestCase, current_dir:'' }
end
