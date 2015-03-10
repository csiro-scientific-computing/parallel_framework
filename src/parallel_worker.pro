; docformat = 'rst'
@parfw_util

;+
; Worker process driver procedure that dispatches a list of work items to a
; specified IDL Job Parallel Framework worker functions, and collates and save
; their results to file.
;
; This procedure is the run-time work horse of the IDL Job Parallel Function
; and represents the entry point to a *worker process*.
;
; Worker processes load a list of *tasks* (more generally *work items*) from a
; file specified to them by the Framework, and processes each item of the list
; by passing it to a user defined *worker function* (also specified to it by the
; Framework).
;
; The worker process (this function) orchestrating the dispatch and collation
; of input and output work items, respectively, to and from worker functions,
; and saving collated work item lists to file for use by subsequent worker
; processing phases. It handles sending, receiving, and collating the correct
; number of work items per call to and from the worker function based on
; `task_subdivison` level. See `generate_parallel_job` for details.
;
; Separate worker processes are launched for separate worker functions
; representing each of the preprocessing, processing, and postprocessing phases
; (if invoked) of the Framework's workflow. Multiple instances of the worker
; process processing different work item lists are launched "within" a phase to
; achieve parallelism. i.e. One instance of the worker process is launched on
; each of the requested compute resources, for each of the requested processing
; phases.
;
; Being the entry point to a process, this procedure takes all its parameters
; via commandline arguments. See `parse_worker_command_line_args` for more
; details.
;
; :Private:
;
; :Private_file:
;
; :Pre:
;   The IDL process running this procedure must have been started with the
;   commandline arguments specified in `parse_worker_command_line_args`.
;
;   The `worker_func` module containing a IDL Job Parallel Framework compatible
;   worker function of the same name, must be visible in the current directory
;   or !PATH. It must also accept the same structure as are stored in the work
;   item array stored in `work_item_file`, and a second parameter indicating
;   subdivision level.
;
;   Other prerequisites are common sense, or non fatal if violated.
;
; :Post:
;   A file matching the IDL Job Parallel Framework naming requirements for the
;   current worker is created, which contains the collated output work items
;   matching the worker process' input work items, i.e. outputs from each call
;   to the worker function.
;
; :Author:
;   Luke Domanski, Scientific Computing Services, CSIRO (2014)
;-
pro parallel_worker

    ; get the parallel worker's command line parameters
    processing_phase=''
    work_item_fname=''
    out_item_fname=''
    worker_func=''
    worker_id=LONG(-1)
    task_subdivision=LONG(-1)

    parse_worker_command_line_args, $
        phase=processing_phase, work_item_file=work_item_fname,$
        out_item_file=out_item_fname, worker_func=worker_func, $
        worker_id=worker_id, task_subdivision=task_subdivision

    ; if if something went wrong, just exit
    if (processing_phase EQ !NULL) then return

    ; load the module containing the worker function
    load_module, module_name=worker_func

    ; if it is the preprocessing or postprocessing phase we will consider
    ; subdivision.
    ; if it is the work phase we wont
    subdivision=task_subdivision
    if(processing_phase EQ "work") then subdivision=1

    ; if it is the preprocessing or work phase only one task part is accepted per
    ; task i.e. they do not merge/collate previously subdivided tasks
    ; if it is the postprocessing phase it will be receiving
    ; task_subdivision task parts
    in_parts=1
    if(processing_phase EQ "postprocessing") then in_parts=task_subdivision

    ; if it is the postprocessing or work phase only one task part is output
    ; i.e. they do not subdivided tasks
    ; if it is the preprocessing phase it will output task_subdivision
    ; task parts
    out_parts=1
    if(processing_phase EQ "preprocessing") then out_parts=task_subdivision

    ; load the worker task list
    tasks=load_worker_task_list(work_item_fname, worker_id, in_parts)

    ; loop over each task calling the specified worker task function
    n_tasks=(SIZE(tasks, /DIMENSIONS))[0]
    for i=0,n_tasks-1 do begin

        ; call the worker task function
        results=call_function(worker_func, tasks[i], subdivision)

        ; If this is the first task we processed
        ; pre-allocate out_items array based on the
        ; the resulting task structure
        if i EQ 0 then begin
            out_items=REPLICATE(results[0], n_tasks, out_parts)
        endif

        ; save the results to the array of task output items for this worker
        out_items[i,0:out_parts-1]=results

    endfor

    ; save the worker's output items to disk
    out_items=REFORM(out_items)
    save_worker_out_items, out_items, out_item_fname, worker_id

end

