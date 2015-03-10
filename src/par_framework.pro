; docformat = 'rst'
;+
; Module file containing the user callable API functions for the IDL Job Parallel Framework.
;
; It contains all API functions except for `load_par_framework`.
;
; :Author:
;    Luke Domanski, CSIRO Advanced Scientific Computing (2012)
;
; :History:
; .. table::
;
;   =========== ================ ============================================
;   Date        Author           Comment
;   =========== ================ ============================================
;    17/10/2012  Luke Domanski    Written
;    24/06/2013  Luke Domanski    Added discover_generator_plugins function
;-

;+
; :Hidden:
;-
pro par_framework
    print, "This DUMMY procedure lets IDL find and compile this file by name. "+$
           "Using: RESOLVE_ROUTINE, 'par_framework', /COMPILE_FULL_FILE"
end

;+
; Find information and identifiers of available job generator plugins.
;
; This function returns information on the job generators available for
; producing parallel jobs.
;
; It searches directories on the !PATH for compiled IDL files (.sav) or source
; files (.pro) with names matching the pattern *job_generator.{sav,pro}, loads
; them, and calls their `generator_info` functions to obtain details of the job
; generator.
;
; The identifier strings returned with each generator's information can be used to
; load it's plugin in subsequent calls to `load_generator_plugin`.
;
; :Categories:
;    Parallel Computing
;
; :Returns:
;    An *Nx4* dimension array of character strings providing the::
;
;        - Name
;        - Short Name
;        - Description
;        - Identifier (Filename without extension)
;
;    of each of the *N* unique plugins discovered.
;
; :Author:
;    Luke Domanski, CSIRO Advanced Scientific Computing (2013)
;
; :History:
; .. table::
;
;   =========== ================ ============================================
;   Date        Author           Comment
;   =========== ================ ============================================
;   24/06/2013  Luke Domanski    Written
;   18/02/2014  Luke Domanski    - Generalised plugin discover to IDL & GDL
;                                - Generalised discover to .sav and .pro file
;                                - Improved documentation
;-
function discover_generator_plugins

    DEFSYSV, '!GDL', EXISTS=running_gdl

    ; if running GDL only search for .pro files
    ; else, search for .sav & .pro files
    template='*job_generator.'
    if (running_gdl) then begin
        template=template+'pro'
    endif else begin
        template=template+'{pro,sav}'
    endelse

    ; Do a search for all .pro[ and .sav] files matching plugin name template
    plugins=FILE_SEARCH(STRSPLIT(!PATH, PATH_SEP(/SEARCH_PATH), $
                /EXTRACT), template)
    ; Remove duplicates
    plugins=plugins[UNIQ(plugins, SORT(plugins))]

    plugin_info=[ ]

    ; if no plugins were found print an error
    if (N_ELEMENTS(plugins) EQ 1) AND (plugins[0] EQ '') then begin
        MESSAGE, "No plugins found, check your IDL_PATH environment variable includes plugin directories."

    ; Otherwise load and get info on each plugin found
    endif else begin

        ; split .sav and .pro file so we can handle loading differently
        sav_idxs=WHERE(STREGEX(plugins, '\.sav$', /BOOLEAN), sav_count, $
                    COMPLEMENT=pro_idxs, NCOMPLEMENT=pro_count, /NULL)
        if (sav_idxs EQ !NULL) then begin
            sav_plugins=[ ]
        endif else begin
            sav_plugins=plugins[sav_idxs]
        endelse
        if (pro_idxs EQ !NULL) then begin
            pro_plugins=[ ]
        endif else begin
            pro_plugins=plugins[pro_idxs]
        endelse

        ; do .sav plugins
        for i=0,sav_count-1 do begin
            restore, sav_plugins[i]
            plugin_info=[[plugin_info], [call_function("get_generator_info")]]
        endfor

        ; do .pro plugins
        for i=0,pro_count-1 do begin
            RESOLVE_ROUTINE, FILE_BASENAME(pro_plugins[i], '.pro'), $
                /COMPILE_FULL_FILE
            plugin_info=[[plugin_info], [call_function("get_generator_info")]]
        endfor

        ; Remove duplicates
        plugin_info=plugin_info[*,UNIQ(plugin_info[3,*], SORT(plugin_info[3,*]))]

    endelse

    return, plugin_info

end




;+
; Load an IDL Job Parallel Framework job generator plugin given its identifier
;
; Given the identifier (i.e. file base name without extension) of a job
; generator plugin, this procedure loads/restores the plugin if visible on
; `!PATH`. Identifiers for available plugins can be retrieved using the
; `discover_generator_plugins` function.
;
; Any subsequent calls to the framework utilise this plugin for job generation
; until a different plugin is requested through this procedure.
;
; :Categories:
;    Parallel Computing
;
; :Uses:
;    load_module
;
; :Keywords:
;   plugin_ident : in, required, type=string
;       Identifier string of the plugin to be loaded.
;
; :Post:
;    Any functions or procedures (declared through a job generator plugin or
;    otherwise) that match the API described for job generators of the IDL
;    Job Parallel Framework will be overwritten by the implementations defined
;    in the named plugin.
;
; :Author:
;    Luke Domanski, CSIRO Advanced Scientific Computing (2013)
;
; :History:
; .. table::
;
;   =========== ================ ============================================
;   Date        Author           Comment
;   =========== ================ ============================================
;   4/07/2013   Luke Domanski    Written
;-
pro load_generator_plugin, plugin_ident=plugin_ident

    ; The commented line below is the best way of doing the
    ; conditional check, but GDL was choking on it during testing
    ;
    ; if (STREGEX(plugin_ident, '*_job_generator$', /BOOLEAN)) then begin
    if (STREGEX(plugin_ident, '.*_job_generator$') NE -1) then begin
        load_module, module_name=plugin_ident
    endif else begin
        MESSAGE, "ERROR - invalid generator plugin name " + plugin_ident
    endelse

end





;+
; Generate a parallel job using the specified application task list and worker
; functions
;
; This procedure generates parallel job scripts and data files that can be used
; to run a number of parallel workers that invoke specified pre-processing,
; processing, and post-processing worker functions (chained in that order), on
; a specified list of tasks (*task list*).
;
; The function uses the currently loaded job generator plugin (see
; `load_generator_plugin`) to create the job scripts. The resulting job
; scripts and files can be saved or copied to a parallel platform supported by
; the plugin and run independently of the computer used to generate the job.
;
; Application tasks and worker functions
; ======================================
; The *task list* should be provided as an array of application defined
; structures representing an *application task* or input parameters.
;
; Specified application worker functions should be accessible within IDL
; program files (source or compiled) of the same name, visible either in the
; current directory, or on `!PATH`. They should accept a structure as input,
; and return a structure as output, with the first worker function in the
; specified chain (either pre-processing or processing) accepting a single
; *application task structure*, and each subsequent function accepting the
; structure type returned by the preceding function.
;
; Task Subdivision
; ================
; When subdivision is specified, the *preprocessing* function in the chain (if
; specified) must instead *accept* a **single** input application task
; structure element, but *return* **an array** of output structure elements
; equal in length to the subdivision requested. The *postprocessing* function
; (if specified) should then *accept* a similar sized *array* of structures and
; *return* and *single* structure (collating a subdivided task).
;
; :Categories:
;    Parallel Computing
;
; :Uses:
;   copy_module, segment_global_task_list, fully_qualified_path
;
; :Keywords:
;    job_name : in, optional, default="pfwjob", type=string
;        A name for the jobs
;    job_dir : in, optional, default=".", type=string
;        Directory path to save all the job file to
;    task_params : in, required, type=array of structures
;        an array of application defined
;        structures each representing the input parameters for a single
;        application task. i.e. the operations you want to perform. The
;        tasks will be distributed amongst worker instances calling the
;        first non !NULL specified IDL function `preprocess_func`,
;        `work_func`, or `postprocess_func`, in that order. Input
;        work-items (tasks/sub-tasks) to subsequent non !NULL
;        function will be taken from the output of previous stages.
;    preprocess_func : in, optional, type=string
;        Name of an IDL code or binary file (base name without extension)
;        containing a function of the same name, that will perform the
;        preprocessing phase of the application on a single work item (task)
;        given an application defined structure contain task parameters
;    work_func : in, required, type=string
;        Same as above but for work/processing phase
;    postprocess_func : in, optional, type=string
;        Same as above but for postprocessing phase
;    n_workers : in, optional, default=1, type=integer
;        Desired number of worker processes to run. For
;        performance you should ensure that this will not be greater
;        than the available processors on the target system. The
;        job generator plugins currently loaded may or
;        may not efficiently pack the requested workers onto
;        the available resources.
;    n_threads_p_worker : in, optional, default=1, type=integer, private
;        Number of "threads" (or processes
;        depending on implementation) utilized by each worker instance
;        of the application phases
;    task_subdivision : in, optional, default=1, type=integer
;        Number of sub-tasks (work_items) an initial
;        application task will be subdivided into by `preprocess_func`, and
;        the number of work_func results postprocess_func will consume. (currently
;        unsupported)
;    bundle_prog : in, optional, type=strarr/string
;        String or array of strings specifying the path to idl .sav or .pro
;        files to copy into the parallel job directory `job_dir`. Can be used to
;        include worker function dependencies with the job.
;    bundle_data : in, optional, type=strarr/string
;        String or array of strings specifying data files to package with
;        parallel job
;    data_dest : in, optional, default=".", type=string
;        String specifying the path location relative to `job_dir` to copy
;        `bundle_data`
;
; :Post:
;    Parallel job scripts, data files, and program files are output or copied
;    into `job_dir`.
;
;    The job generator plugin called by this module will output a set of
;    job scripts for running the specified worker functions, as well as a control
;    script for coordinating the running of these job scripts.
;
;    Calls a helper function segment_global_task_list that divides up the
;    input `task_params` list and saves a number work item files containing
;    uniformly distributed sub-sets of the list.
;
; :Description:
;    Job Parallelism
;       The paradigm of parallel computation used by the IDL Job Parallel
;       Framework is *job parallelism*, which can be considered the same as
;       *task farming* under static, uniform, task distribution. The terms task
;       farming and *task parallelism* are often, erroneously, used
;       interchangeably but they are **not** the same thing.
;
;       Under this framework a list of application tasks stored as an array of
;       application defined structures is split up, saved in separate files,
;       and processed by multiple worker processes, each running an independent
;       instance of a defined worker functions on assigned task (possibly one
;       for each of the phases, preprocessing, processing, and postprocessing).
;       Tasks are currently distributed evenly amongst the worker processes.
;
; :Author:
;    Luke Domanski, CSIRO Advanced Scientific Computing (2012)
;
; :History:
;   .. table::
;
;      =========== ================ ============================================
;      Date        Author           Comment
;      =========== ================ ============================================
;      17/10/2012  Luke Domanski    Written
;      04/07/2014  Luke Domanski    Modified to match new segment_task_list interface
;-
pro generate_parallel_job, job_name=job_name, job_dir=job_dir,$
        task_params=task_params, preprocess_func=preprocess_func,$
        work_func=work_func, postprocess_func=postprocess_func,$
        n_workers=n_workers, n_threads_p_worker=n_threads_p_worker,$
        task_subdivision=task_subdivision, bundle_prog=bundle_prog,$
        bundle_data=bundle_data, data_dest=data_dest

    ; Set some defaults
    ; -----------------
    ; allow for anything < 1 to represent no task_subdivision
    if (~KEYWORD_SET(task_subdivision)) || (task_subdivision LT 1) then task_subdivision=1
    ; allow for anything < 1 to represent 1 threads
    if (~KEYWORD_SET(n_threads_p_worker)) || (n_threads_p_worker LT 1) then n_threads_p_worker=1
    ; allow for anything < 1 to represent 1 worker
    if (~KEYWORD_SET(n_workers)) || (n_workers LT 1) then n_workers=1
    ; set default job and data directory as current dir
    if (~KEYWORD_SET(job_dir)) || (job_dir EQ !NULL) then job_dir="."
    if (~KEYWORD_SET(data_dest)) || (data_dest EQ !NULL) then data_dest="."
    ; set default job name
    if (~KEYWORD_SET(job_name)) || (job_name EQ !NULL) then job_name="pfwjob"


    ; find out the number of initial tasks
    n_tasks=size(task_params, /N_ELEMENTS)

    ; if no tasks are in the task list, print error and return
    if n_tasks LT 1 then begin
        MESSAGE, "ERROR - Task list task_params has zero length, no tasks to perform." $
               + " Parallel job not generated!"
        return
    endif


    ; initially set number of workers for pre & post processing
    ; to total number of requested workers
    n_pre_post_workers=n_workers

    ; handle problematic combinations of
    ; n_workers, n_tasks & task_subdivision
    ; -------------------------------------
    ; the code simply doesn't handle less workers than
    ; subdivision level
    if n_workers LT task_subdivision then begin
        MESSAGE, "ERROR - Number of requested workers must be >= requested task subdivision." $
               + " Parallel job not generated!"
        return
    endif

    ; If the number of tasks is less than the number of requested
    ; workers, then we will reduce the number of workers used in
    ; pre and post processing
    if n_tasks LT n_workers then begin
        n_pre_post_workers=n_tasks
    endif

    ; if the number of task lists that will be generated and
    ; consumed by pre and post processing, respectively, is
    ; more than the number of requested workers, then we will
    ; further reduce number of pre and post processing workers
    ; so that generated/consumed list count <= n_workers
    if n_pre_post_workers*task_subdivision GT n_workers then begin
        n_pre_post_workers=floor(n_workers/task_subdivision)
    endif

    ; finally truncate total workers to match number task lists
    ; after any subdivision
    if n_workers GT n_pre_post_workers*task_subdivision then begin
        MESSAGE, "WARNING - Number of requested workers/processors exceeds task_count after subdivision." $
               + " Total number of workers/processors reduced to "+strtrim(n_workers,2)
        n_workers=n_pre_post_workers*task_subdivision
    endif


    ; create the names for the task/work_item files
    ; input and output from preprocessing, work, and
    ; postprocessing phases respectively
    ; ----------------------------------------------
    tasks_file_prefix=job_name+"_tasklist"
    work_item_file_prefix=job_name+"_worklist"
    subres_file_prefix=job_name+"_subresultlist"
    result_file_prefix=job_name+"_resultlist"

    pre_script_name=""
    work_script_name=""
    post_script_name=""


    ; Start generating job scripts
    ; ----------------------------

    FILE_MKDIR, job_dir

    ; Copy over the wrapper around the framework's parallel_worker routine
    ; make sure we get the .sav (for IDL) and .pro (for GDL) versions
    copy_module, module_name="parfw_runner", dest_dir=job_dir, $
        copied=runner_cp, /FORCE_BOTH

    if (N_ELEMENTS(runner_cp) LT 2) then begin
        if (FILE_BASENAME(runner_cp[0]) NE "parfw_runner.sav") then begin
            MESSAGE, "ERROR - Unable to locate parfw_runner.sav file." $
                   + " Check your system IDL_PATH or GDL_PATH variable includes the correct IDL Parallel Framework configuration"
            return
        endif
    endif


    ; if a user specified worker task functions for the three
    ; phases are provided, create the job scripts to run them in
    ; parallel using the job generator plugin provided
    ;
    ; Also copy the phase worker task function files to job_dir
    if (KEYWORD_SET(preprocess_func)) && (preprocess_func NE !NULL) then begin
        if (file_basename(preprocess_func) NE "") then begin

            copy_module, module_name=preprocess_func, dest_dir=job_dir

            pre_script_name=job_name+"_preprocess"
            generate_preprocessing_script,$
                job_name=job_name, $
                job_dir=job_dir,$
                work_item_file_prefix=tasks_file_prefix, $
                n_tasks=n_tasks,$
                task_subdivision=task_subdivision,$
                n_workers=n_pre_post_workers,$
                worker_executable="parfw_runner",$
                worker_task_func=file_basename(preprocess_func),$
                script_name_prefix=pre_script_name,$
                out_item_file_prefix=work_item_file_prefix
        endif else begin
            MESSAGE, "ERROR - preprocess_func argument to generate_parallel_job is an ill-formed worker_task_func name." $
                   + " Parallel job not generated!"
            return
        endelse
    endif


    if (KEYWORD_SET(work_func)) && (work_func NE !NULL) then begin
        if (file_basename(work_func) NE "") then begin

            copy_module, module_name=work_func, dest_dir=job_dir

            work_script_name=job_name+"_work"
            generate_work_script, $
                job_name=job_name, $
                job_dir=job_dir,$
                work_item_file_prefix=work_item_file_prefix, $
                n_tasks=n_tasks, $
                task_subdivision=task_subdivision,$
                n_workers=n_workers, $
                worker_executable="parfw_runner",$
                worker_task_func=file_basename(work_func),$
                script_name_prefix=work_script_name,$
                out_item_file_prefix=subres_file_prefix

        endif else begin
            MESSAGE, "ERROR - work_func argument to generate_parallel_job is an ill-formed worker_task_func name." $
                   + " Parallel job not generated!"
            return
        endelse
    endif else begin
        ; specification of a work step is mandatory
        MESSAGE, "ERROR - work_func argument must be specified to generate_parallel_job." $
               + " Parallel job not generated!"
        return
    endelse


    if (KEYWORD_SET(postprocess_func)) && (postprocess_func NE !NULL) then begin
        if (file_basename(postprocess_func) NE "") then begin

            copy_module, module_name=postprocess_func, dest_dir=job_dir

            post_script_name=job_name+"_postprocess"
            generate_postprocessing_script, $
                job_name=job_name, $
                job_dir=job_dir,$
                work_item_file_prefix=subres_file_prefix,$
                n_tasks=n_tasks, $
                task_subdivision=task_subdivision,$
                n_workers=n_pre_post_workers,$
                worker_executable="parfw_runner",$
                worker_task_func=file_basename(postprocess_func),$
                script_name_prefix=post_script_name,$
                out_item_file_prefix=result_file_prefix

        endif else begin
            MESSAGE, "ERROR - postprocess_func argument to generate_parallel_job is an ill-formed worker_task_func name." $
                   + " Parallel job not generated!"
            return
        endelse
    endif


    if (pre_script_name NE "") OR $
       (work_script_name NE "") OR $
       (post_script_name NE "") then begin

       ; save the initial complete tasks to file
       ;work_items=task_params
       ;save, work_items, filename=tasks_file_prefix+".sav", /compress

       ; if a preprocessing phase was not requested, save
       ; the initial task list as the input work item list for
       ; the work phase, otherwise save it as input to
       ; the preprocessing phase
       file_prefix=work_item_file_prefix
       if pre_script_name NE "" then file_prefix=tasks_file_prefix

       ; save individual worker's task lists
       segment_global_task_list,$
           dest_dir=job_dir,$
           n_workers=n_pre_post_workers,$
           task_params=task_params,$
           fname_prefix=file_prefix

       generate_control_script, $
           job_name=job_name,$
           job_dir=job_dir, $
           n_tasks=n_tasks, $
           task_subdivision=task_subdivision, $
           n_workers=n_workers,$
           n_pre_post_workers=n_pre_post_workers,$
           preprocessing_script=pre_script_name,$
           work_script=work_script_name,$
           postprocessing_script=post_script_name

    endif

    if KEYWORD_SET(bundle_data) then begin
        FILE_MKDIR, job_dir+path_sep()+data_dest
        FILE_COPY, fully_qualified_path(bundle_data), $
                   fully_qualified_path(job_dir+path_sep()+data_dest), $
                   /OVERWRITE
    endif

    if KEYWORD_SET(bundle_prog) then begin
        FILE_COPY, fully_qualified_path(bundle_prog), $
                   fully_qualified_path(job_dir), $
                   /OVERWRITE
    endif


end
