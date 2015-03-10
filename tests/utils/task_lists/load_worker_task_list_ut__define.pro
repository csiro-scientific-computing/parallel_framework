pro load_worker_task_list_ut::setup
    compile_opt strictarr

    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_FUNCTION="load_worker_task_list";, $
                 ; /CONTINUE_ON_ERROR, /QUIET

    ; set up test files.
    work_items=self.task_array
    SAVE, work_items, FILENAME="valid_task_file3.sav"

    work_items=self.part_task_array[*,0]
    SAVE, work_items, FILENAME="valid_part_task_file0.sav"
    work_items=self.part_task_array[*,1]
    SAVE, work_items, FILENAME="valid_part_task_file1.sav"
    work_items=self.part_task_array[*,2]
    SAVE, work_items, FILENAME="valid_part_task_file2.sav"
    work_items=self.part_task_array[*,3]
    SAVE, work_items, FILENAME="valid_part_task_file3.sav"

    fred=1.765
    SAVE, fred, FILENAME="invalid_task_file3.sav"

    part_fred=4.567
    SAVE, part_fred, FILENAME="invalid_part_task_file0.sav"
    SAVE, part_fred, FILENAME="invalid_part_task_file1.sav"
    SAVE, part_fred, FILENAME="invalid_part_task_file2.sav"
    SAVE, part_fred, FILENAME="invalid_part_task_file3.sav"

end

pro load_worker_task_list_ut::teardown
    compile_opt strictarr

    FILE_DELETE, "invalid*task_file*.sav", "valid*task_file*.sav"
end

function load_worker_task_list_ut::load_worker_task_list_test, $
            testin_file_prefix, $
            testin_worker_id, $
            testin_nparts, $
            expected, $
            is_part_task_test, $
            err_msg

    compile_opt strictarr

    result=load_worker_task_list(testin_file_prefix, testin_worker_id, testin_nparts)

    are_the_same=0
    if (result eq !null) OR (expected eq !null) then begin
        are_the_same=(result eq expected)
    endif else begin

        except=0
        CATCH, except
        if(except eq 0) then begin
            if(is_part_task_test) then begin
                are_the_same=(ARRAY_EQUAL(result.part_arg_A, expected.part_arg_A) AND $
                              ARRAY_EQUAL(result.part_arg_B, expected.part_arg_B)) 
            endif else begin
                are_the_same=(ARRAY_EQUAL(result.arg_A, expected.arg_A) AND $
                              ARRAY_EQUAL(result.arg_B, expected.arg_B))
            endelse
        endif
        CATCH, /CANCEL
    endelse

    assert, are_the_same, $
            err_msg+': in ['+testin_file_prefix+', '+STRTRIM(STRING(testin_worker_id), 2)+', '+STRTRIM(STRING(testin_nparts), 2)+']'+ $
            ', out '+STRJOIN(STRING(result, /PRINT), " ")+ $
            ', expected '+STRJOIN(STRING(expected, /PRINT), " ")

    return, 1
end

function load_worker_task_list_ut::test_Non_Existent_Worker_File
    compile_opt strictarr

    testin_file_prefix = "non_existant_worker_file"
    testin_worker_id = 3
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, 1, expected, 0, 'incorrect handling of non-existent file')
end

function load_worker_task_list_ut::test_Non_Existent_Worker_ID_Negative
    compile_opt strictarr

    testin_file_prefix = "valid_task_file"
    testin_worker_id = -1
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, 1, expected, 0, 'incorrect handling of negative worker id')
end

function load_worker_task_list_ut::test_Non_Existent_Worker_ID_Positive
    compile_opt strictarr

    testin_file_prefix = "valid_task_file"
    testin_worker_id = 100
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, 1, expected, 0, 'incorrect handling of handling of missing worker file')
end

function load_worker_task_list_ut::test_Valid_File
    compile_opt strictarr

    testin_file_prefix = "valid_task_file"
    testin_worker_id = 3
    expected = self.task_array

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, 1, expected, 0, 'incorrect loaded valid task file')
end

function load_worker_task_list_ut::test_Valid_NParts_File
    compile_opt strictarr

    testin_file_prefix = "valid_part_task_file"
    testin_worker_id = 0
    testin_nparts = 4
    expected = self.part_task_array

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, testin_nparts, expected, 1, 'incorrectly loaded valid nparts task file')
end

function load_worker_task_list_ut::test_Invalid_File
    compile_opt strictarr

    testin_file_prefix = "invalid_task_file"
    testin_worker_id = 3
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, 1, expected, 0, 'incorrect handling of invalid task file')
end

function load_worker_task_list_ut::test_Invalid_NParts_File
    compile_opt strictarr

    testin_file_prefix = "invalid_part_task_file"
    testin_worker_id = 0
    testin_nparts = 4
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, testin_nparts, expected, 1, 'incorrect handling of an invalid nparts task file')
end

function load_worker_task_list_ut::test_Incomplete_NParts_File
    compile_opt strictarr

    testin_file_prefix = "valid_part_task_file"
    testin_worker_id = 0
    testin_nparts = 8
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, testin_nparts, expected, 1, 'incorrect handling of incomplete nparts task file')
end

function load_worker_task_list_ut::test_Negative_NParts
    compile_opt strictarr

    testin_file_prefix = "valid_part_task_file"
    testin_worker_id = 0
    testin_nparts = -4
    expected = !NULL

    return, self->load_worker_task_list_test(testin_file_prefix, testin_worker_id, testin_nparts, expected, 1, 'incorrect handling of negative nparts argument')
end


pro load_worker_task_list_ut__define
    compile_opt strictarr
    t={task, arg_A:0L, arg_B:0L}
    p={part_task, part_arg_A:0.0, part_arg_B:0L}
    pa=REPLICATE(p, 2)
    struct = { load_worker_task_list_ut, inherits MGutTestCase, $
               task_array:REPLICATE(t, 2), $
               part_task_array:[[pa], [pa], [pa], [pa]] }
end
