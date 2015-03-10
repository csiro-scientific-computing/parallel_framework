pro save_worker_out_items_ut::setup
    compile_opt strictarr

    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_PROCEDURE="save_worker_out_items";, $
                 ; /CONTINUE_ON_ERROR, /QUIET

end

pro save_worker_out_items_ut::teardown
    compile_opt strictarr

    FILE_DELETE, "valid_task_file2.sav", $
                 "valid_task_file-2.sav", $
                 "valid_task_file8.sav", $
                 "valid_task_file9.sav", $
                 "valid_task_file10.sav", $
                 "valid_task_file11.sav", /QUIET
end

function save_worker_out_items_ut::save_worker_out_items_check, $
            testin_out_items, $
            testin_file_prefix, $
            testin_worker_id, $
            n_parts, $
            expected, $
            err_msg

    compile_opt strictarr

    res_msg=''

    ; Compile the list of expected output files
    out_file=[]
    if(n_parts gt 1) then begin 
        for i=0,n_parts-1 do begin
            out_file=[out_file, testin_file_prefix+strtrim(testin_worker_id*n_parts+i,2)+".sav"]
        endfor
        res_msg=', one or more out put files "f" tested FILE_TEST("f")=FALSE'
    endif else begin
        out_file=testin_file_prefix+strtrim(testin_worker_id,2)+".sav"
        res_msg=', FILE_TEST('+out_file+')=FALSE'
    endelse

    ; check output files were written
    no_wrong=1
    for i=0,N_ELEMENTS(out_file)-1 do begin
        if ~FILE_TEST(out_file[i]) then no_wrong=0
    endfor

    assert, no_wrong, $
            err_msg+': in ['+STRJOIN(STRING(testin_out_items, /PRINT))+', '+testin_file_prefix+', ' + $
            STRTRIM(testin_worker_id, 2)+']'+ $
            res_msg+', expected all TRUE'

    ; a bit incomprehensive
    ; but check the FIRST file contains what we expected.
    work_items=!null
    no_wrong=1
    if FILE_TEST(out_file[0]) then restore, out_file[0]

    if (work_items eq !null) OR (expected eq !null) then begin
        no_wrong=(work_items eq expected)
    endif else begin

        except=0
        CATCH, except
        if(except eq 0) then begin
            if(n_parts gt 1) then begin
                no_wrong=(ARRAY_EQUAL(work_items.part_arg_A, expected.part_arg_A) AND $
                              ARRAY_EQUAL(work_items.part_arg_B, expected.part_arg_B)) 
            endif else begin
                no_wrong=(ARRAY_EQUAL(work_items.arg_A, expected.arg_A) AND $
                              ARRAY_EQUAL(work_items.arg_B, expected.arg_B))
            endelse
        endif
        CATCH, /CANCEL
    endelse

    assert, no_wrong, $
            err_msg+': in ['+STRJOIN(STRING(testin_out_items, /PRINT))+', '+testin_file_prefix+', ' + $
            STRTRIM(testin_worker_id, 2)+']'+ $
            ', work_items '+STRJOIN(STRING(work_items, /PRINT), " ")+ $
            ', expected '+STRJOIN(STRING(expected, /PRINT), " ")

    return, 1
end

function save_worker_out_items_ut::test_Negative_Worker_ID
    compile_opt strictarr

    testin_out_items={task, arg_A:0L, arg_B:0L}
    testin_file_prefix = "valid_task_file"
    testin_worker_id = -2
    err_msg='incorrect handling of negative worker id'
    out_file=testin_file_prefix+strtrim(testin_worker_id,2)+".sav"

    save_worker_out_items, testin_out_items, testin_file_prefix, testin_worker_id

    assert, ~FILE_TEST(out_file), $
            err_msg+': in ['+STRJOIN(STRING(testin_out_items, /PRINT))+', '+testin_file_prefix+', ' + $
            STRTRIM(STRING(testin_worker_id), 2)+']'+ $
            ', FILE_TEST('+out_file+')=TRUE'+ $
            ', expected FALSE'

    return, 1
end

function save_worker_out_items_ut::test_Null_Out_Items
    compile_opt strictarr

    testin_out_items=!null
    testin_file_prefix = "valid_task_file"
    testin_worker_id = 2
    expected=!null
    err_msg='incorrect handling of !null out items'

    save_worker_out_items, testin_out_items, testin_file_prefix, testin_worker_id

    return, self->save_worker_out_items_check(testin_out_items, testin_file_prefix, testin_worker_id, 1, expected, err_msg)
end


function save_worker_out_items_ut::test_Non_Null_Out_Items
    compile_opt strictarr

    testin_out_items={task, arg_A:0L, arg_B:0L}
    testin_file_prefix = "valid_task_file"
    testin_worker_id = 2
    expected=testin_out_items
    err_msg='incorrect handling of !null out items'

    save_worker_out_items, testin_out_items, testin_file_prefix, testin_worker_id

    return, self->save_worker_out_items_check(testin_out_items, testin_file_prefix, testin_worker_id, 1, expected, err_msg)
end

function save_worker_out_items_ut::test_Non_Null_Array_Out_Items
    compile_opt strictarr

    t={task, arg_A:0L, arg_B:0L}
    testin_out_items=REPLICATE(t, 4)
    testin_file_prefix = "valid_task_file"
    testin_worker_id = 2
    expected=testin_out_items
    err_msg='incorrect handling of array of out items'

    save_worker_out_items, testin_out_items, testin_file_prefix, testin_worker_id

    return, self->save_worker_out_items_check(testin_out_items, testin_file_prefix, testin_worker_id, 1, expected, err_msg)
end

function save_worker_out_items_ut::test_Non_Null_Part_Out_Items
    compile_opt strictarr

    p={part_task, part_arg_A:0.0, part_arg_B:0L}
    testin_out_items=REPLICATE(p, 1, 4)
    testin_file_prefix = "valid_task_file"
    testin_worker_id = 2
    expected=p
    err_msg='incorrect handling of part out items'

    save_worker_out_items, testin_out_items, testin_file_prefix, testin_worker_id

    return, self->save_worker_out_items_check(testin_out_items, testin_file_prefix, testin_worker_id, 4, expected, err_msg)
end

function save_worker_out_items_ut::test_Non_Null_Array_Part_Out_Items
    compile_opt strictarr

    p={part_task, part_arg_A:0.0, part_arg_B:0L}
    testin_out_items=REPLICATE(p, 4, 2)
    testin_file_prefix = "valid_task_file"
    testin_worker_id = 2
    expected=REPLICATE(p, 4)
    err_msg='incorrect handling of array of part out items'

    save_worker_out_items, testin_out_items, testin_file_prefix, testin_worker_id

    return, self->save_worker_out_items_check(testin_out_items, testin_file_prefix, testin_worker_id, 2, expected, err_msg)
end

pro save_worker_out_items_ut__define
    compile_opt strictarr
    struct = { save_worker_out_items_ut, inherits MGutTestCase }
end
