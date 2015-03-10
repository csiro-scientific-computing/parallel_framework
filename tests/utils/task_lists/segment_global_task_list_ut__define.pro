pro segment_global_task_list_ut::setup
    compile_opt strictarr
    self.dest_dir="destdir"
    self.fname_prefix="fnameeprefix"
    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_PROCEDURE="segment_global_task_list", /CONTINUE_ON_ERROR, /QUIET

    FILE_MKDIR, "./"+self.dest_dir

end

pro segment_global_task_list_ut::teardown
    compile_opt strictarr

    FILE_DELETE, "worker_task_list0.sav", "worker_task_list1.sav", "worker_task_list2.sav", "worker_task_list3.sav", $
                 STRING(self.fname_prefix)+"\0.sav", STRING(self.fname_prefix)+"\1.sav", $
                 STRING(self.fname_prefix)+"\2.sav", STRING(self.fname_prefix)+"\3.sav", /QUIET

    FILE_DELETE, self.dest_dir, /RECURSIVE, /QUIET
end

function segment_global_task_list_ut::segment_global_task_list_check, $
            testin_dest_dir, $
            testin_n_workers, $
            testin_task_params, $
            testin_fname_prefix, $
            expected_err, $
            err_msg

    compile_opt strictarr

    MESSAGE, /CONTINUE, /RESET
    segment_global_task_list, dest_dir=testin_dest_dir, n_workers=testin_n_workers, $
                              task_params=testin_task_params, fname_prefix=testin_fname_prefix


    assert, STRCMP(!ERROR_STATE.NAME, expected_err), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT))+', '+testin_fname_prefix+']'+ $
            ', error %s, error expected %s', $
            in, !ERROR_STATE.NAME, expected_err

    return, 1

end

function segment_global_task_list_ut::segment_global_task_list_check_files_exist, $
            testin_dest_dir, $
            testin_n_workers, $
            testin_task_params, $
            testin_fname_prefix, $
            err_msg

    compile_opt strictarr
    ; Compile the list of expected output files
    out_file=[]
    for i=0,testin_n_workers-1 do begin
        out_file=[out_file, testin_dest_dir+path_sep()+testin_fname_prefix+strtrim(i,2)+".sav"]
    endfor
    res_msg=', one or more out put files f=['+STRJOIN(STRING(out_file, /PRINT), ", ")+'] tested FILE_TEST("f")=FALSE'

    ; check output files were written
    no_wrong=1
    for i=0,N_ELEMENTS(out_file)-1 do begin
        if ~FILE_TEST(out_file[i]) then no_wrong=0
    endfor

    assert, no_wrong, $
            err_msg+': in ['+testin_dest_dir+', '+strtrim(testin_n_workers, 2)+ $
            ', '+STRJOIN(STRING(testin_task_params, /PRINT))+', !NULL OR UNDEFINED]'+ $
            res_msg+', expected TRUE'

    return, 1

end

function segment_global_task_list_ut::segment_global_task_list_check_file_contains, $
            testin_dest_dir, $
            testin_n_workers, $
            testin_task_params, $
            testin_fname_prefix, $
            check_file, $
            expected, $
            err_msg

    compile_opt strictarr
    work_items=!null
    no_wrong=1
    if FILE_TEST(check_file) then restore, check_file

    if (work_items eq !null) OR (expected eq !null) then begin
        no_wrong=(work_items eq expected)
    endif else begin

        except=0
        CATCH, except
        if(except eq 0) then begin
            no_wrong=(ARRAY_EQUAL(work_items.arg_A, expected.arg_A) AND $
                          ARRAY_EQUAL(work_items.arg_B, expected.arg_B)) 
        endif
        CATCH, /CANCEL
    endelse

    assert, no_wrong, $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', work_items '+STRJOIN(STRING(work_items, /PRINT), " ")+ $
            ', expected '+STRJOIN(STRING(expected, /PRINT), " ")

    return, 1
end


function segment_global_task_list_ut::test_N_Workers_Exceeds_N_Tasks

    compile_opt strictarr
    testin_task_params = REPLICATE(self.t, 4)
    testin_n_workers = 5
    testin_dest_dir=self.dest_dir
    testin_fname_prefix=self.fname_prefix
    out_file=testin_fname_prefix+"\4.sav"
    expected_err='IDL_M_USER_ERR'
    err_msg="Invalid handling when number of workers exceeds number of tasks"

    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    res2=self->segment_global_task_list_check_files_exist(testin_dest_dir, testin_n_workers-1, $
                                              testin_task_params, testin_fname_prefix, err_msg)

    assert, ~FILE_TEST(out_file), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', FILE_TEST('+out_file+')=TRUE'+ $
            ', expected FALSE'

    res3=self->segment_global_task_list_check_file_contains(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              testin_dest_dir+path_sep()+testin_fname_prefix+"\0.sav", $
                                              self.t, err_msg)


    res4=self->segment_global_task_list_check_file_contains(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              testin_dest_dir+path_sep()+testin_fname_prefix+"\3.sav", $
                                              self.t, err_msg)

    return, (res1 AND res2 AND res3 AND res4)
end

function segment_global_task_list_ut::test_Even_N_Tasks_Per_Worker

    compile_opt strictarr
    testin_task_params = REPLICATE(self.t, 8)
    testin_n_workers = 4
    testin_dest_dir=self.dest_dir
    testin_fname_prefix=self.fname_prefix
    expected_err='IDL_M_SUCCESS'
    err_msg="Invalid handling when tasks per worker is even"

    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    res2=self->segment_global_task_list_check_files_exist(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, err_msg)


    res3=self->segment_global_task_list_check_file_contains(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              testin_dest_dir+path_sep()+testin_fname_prefix+"\0.sav", $
                                              REPLICATE(self.t,2), err_msg)


    res4=self->segment_global_task_list_check_file_contains(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              testin_dest_dir+path_sep()+testin_fname_prefix+"\3.sav", $
                                              REPLICATE(self.t,2), err_msg)

    return, (res1 AND res2 AND res3 AND res4)

end

function segment_global_task_list_ut::test_Uneven_N_Tasks_Per_Worker

    compile_opt strictarr
    testin_task_params = REPLICATE(self.t, 7)
    testin_n_workers = 4
    testin_dest_dir=self.dest_dir
    testin_fname_prefix=self.fname_prefix
    expected_err='IDL_M_SUCCESS'
    err_msg="Invalid handling when tasks per worker is uneven"

    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    res2=self->segment_global_task_list_check_files_exist(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, err_msg)


    res3=self->segment_global_task_list_check_file_contains(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              testin_dest_dir+path_sep()+testin_fname_prefix+"\0.sav", $
                                              REPLICATE(self.t,2), err_msg)


    res4=self->segment_global_task_list_check_file_contains(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              testin_dest_dir+path_sep()+testin_fname_prefix+"\3.sav", $
                                              self.t, err_msg)

    return, (res1 AND res2 AND res3 AND res4)
end

function segment_global_task_list_ut::test_Missing_And_Null_Task_Params_Arg

    compile_opt strictarr
    testin_task_params = !NULL
    testin_n_workers = 4
    testin_dest_dir=self.dest_dir
    testin_fname_prefix=self.fname_prefix
    out_file=testin_fname_prefix+"\0.sav"
    expected_err='IDL_M_USER_ERR'
    err_msg="Invalid handling when parameter task_params !NULL or not provided"

    ; TEST MISSING
    MESSAGE, /CONTINUE, /RESET
    segment_global_task_list, dest_dir=testin_dest_dir, n_workers=testin_n_workers, $
                              fname_prefix=testin_fname_prefix

    assert, STRCMP(!ERROR_STATE.NAME, expected_err), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            'UNDEFINED, '+testin_fname_prefix+']'+ $
            ', error %s, error expected %s', $
            in, !ERROR_STATE.NAME, expected_err

    ; TEST !NULL
    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    ; TEST that files were not written when they weren't supposed to be
    assert, ~FILE_TEST(out_file), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', FILE_TEST('+out_file+')=TRUE'+ $
            ', expected FALSE'

    return, res1
end

function segment_global_task_list_ut::test_Negative_Missing_And_Null_N_Workers

    compile_opt strictarr
    testin_task_params = REPLICATE(self.t, 4)
    testin_n_workers = !NULL
    testin_dest_dir=self.dest_dir
    testin_fname_prefix=self.fname_prefix
    out_file=testin_fname_prefix+"\0.sav"
    expected_err='IDL_M_USER_ERR'
    err_msg="Invalid handling when parameter n_workers !NULL or not provided"

    MESSAGE, /CONTINUE, /RESET

    ; TEST MISSING
    segment_global_task_list, dest_dir=testin_dest_dir, task_params=testin_task_params, $
                              fname_prefix=testin_fname_prefix

    assert, STRCMP(!ERROR_STATE.NAME, expected_err), $
            err_msg+': in ['+testin_dest_dir+', UNDEFINED, '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', error %s, error expected %s', $
            in, !ERROR_STATE.NAME, expected_err

    ; TEST !NULL
    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    ; TEST that files were not written when they weren't supposed to be
    assert, ~FILE_TEST(out_file), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', FILE_TEST('+out_file+')=TRUE'+ $
            ', expected FALSE'

    ; TEST negative 
    testin_n_workers=-4
    res2=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    ; TEST that files were not written when they weren't supposed to be
    assert, ~FILE_TEST(out_file), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', FILE_TEST('+out_file+')=TRUE'+ $
            ', expected FALSE'

    return, (res1 AND res2)

end

function segment_global_task_list_ut::test_Default_Local_On_Missing_Dest_Dir_Arg

    compile_opt strictarr
    testin_task_params = REPLICATE(self.t, 4)
    testin_n_workers = 4
    testin_dest_dir= !NULL
    testin_fname_prefix=self.fname_prefix
    expected_err='IDL_M_SUCCESS'
    err_msg="Invalid handling when parameter dest_dir !NULL or not provided"

    ; TEST MISSING
    MESSAGE, /CONTINUE, /RESET
    segment_global_task_list, n_workers=testin_n_workers, task_params=testin_task_params, $
                              fname_prefix=testin_fname_prefix

    assert, STRCMP(!ERROR_STATE.NAME, expected_err), $
            err_msg+': in [UNDEFINED, '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', '+testin_fname_prefix+']'+ $
            ', error %s, error expected %s', $
            in, !ERROR_STATE.NAME, expected_err

    ; TEST !NULL
    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    res2=self->segment_global_task_list_check_files_exist("./", testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, err_msg)

    return, (res1 AND res2)

end

function segment_global_task_list_ut::test_Default_Local_On_Missing_Fname_Prefix_Arg

    compile_opt strictarr
    testin_task_params = REPLICATE(self.t, 4)
    testin_n_workers = 4
    testin_dest_dir= self.dest_dir
    testin_fname_prefix= !NULL
    expected_err='IDL_M_SUCCESS'
    err_msg="Invalid handling when parameter fname_prefix !NULL or not provided"

    ; TEST MISSING
    MESSAGE, /CONTINUE, /RESET
    segment_global_task_list, dest_dir=testin_dest_dir, n_workers=testin_n_workers, $
                              task_params=testin_task_params

    assert, STRCMP(!ERROR_STATE.NAME, expected_err), $
            err_msg+': in ['+testin_dest_dir+', '+STRTRIM(testin_n_workers, 2)+', '+ $
            STRJOIN(STRING(testin_task_params, /PRINT), " ")+', UNDEFINED]'+ $
            ', error %s, error expected %s', $
            in, !ERROR_STATE.NAME, expected_err

    ; TEST !NULL
    res1=self->segment_global_task_list_check(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, testin_fname_prefix, $
                                              expected_err, err_msg)

    res2=self->segment_global_task_list_check_files_exist(testin_dest_dir, testin_n_workers, $
                                              testin_task_params, "worker_task_list", err_msg)

    return, (res1 && res2)

end


pro segment_global_task_list_ut__define
    compile_opt strictarr
    struct = { segment_global_task_list_ut, inherits MGutTestCase, $
               t:{task, arg_A:0L, arg_B:0L}, $
               dest_dir:"", $
               fname_prefix:""}
end
