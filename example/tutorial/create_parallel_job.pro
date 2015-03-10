
pro create_parallel_job, g_task_list=g_task_list

    generate_parallel_job, task_params=g_task_list, job_dir='./parallel_job', $
                           work_func='sum_mean_stddev_pfw', n_workers=8

end
