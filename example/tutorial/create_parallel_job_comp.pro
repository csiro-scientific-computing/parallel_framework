
pro create_parallel_job_comp, g_task_list=g_task_list

    ; just checking if student has already put relative paths
    ; in g_task_list
    g_task_list_rel=g_task_list
    if(STRPOS(g_task_list[0].filename_A, ".") NE 0) then begin
        g_task_list_rel.filename_A="."+g_task_list_rel.filename_A
        g_task_list_rel.filename_B="."+g_task_list_rel.filename_B
    endif

    ; Example code from tutorial
    RESOLVE_ROUTINE, "sum_mean_stddev_pfw", /IS_FUNCTION, /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_FUNCTION=SUM_MEAN_STDDEV_PFW, /CONTINUE_ON_ERROR
    SAVE, /ROUTINES, filename="sum_mean_stddev_pfw.sav"
    generate_parallel_job, task_params=g_task_list, job_dir="./parallel_job", $
                           work_func="sum_mean_stddev_pfw", n_workers=8, $
                           bundle_data=FILE_SEARCH("data/research/studyresults/*.sav"),$
                           data_dest="research/studyresults"

end
