
pro create_parallel_job_prog, g_task_list=g_task_list

    ; just checking if student has already put relative paths
    ; in g_task_list
    g_task_list_rel=g_task_list
    if(STRPOS(g_task_list[0].filename_A, ".") NE 0) then begin
        g_task_list_rel.filename_A="."+g_task_list_rel.filename_A
        g_task_list_rel.filename_B="."+g_task_list_rel.filename_B
    endif

    ; Example code from tutorial
    generate_parallel_job, task_params=g_task_list_rel, job_dir="./parallel_job", $
                           work_func="sum_mean_stddev_pfw", n_workers=8, $
                           bundle_data=FILE_SEARCH("data/research/studyresults/*.sav"),$
                           data_dest="research/studyresults", $
                           bundle_prog=["sum_mean_stddev.pro"]

end
