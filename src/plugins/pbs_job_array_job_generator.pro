; docformat = 'rst'
;+
; IDL Job Parallel Framework array job generator for Linux systems running the
; Portable Batch System (PBS). It utilises PBS job arrays, and currently
; supports Torque PBS, but could be easily extended to support PBSPro.
;
; Users should not call any functions in this file directly. This plugin can
; be loaded into the Framework by passing "pbs_job_array" as the plugin ident
; to the Framework's `load_generator_plugin` procedure.
;
; All procedures in this module (except helper generate_generic_script)
; are implementations of the job script generator plugin API and
; functionality defined for the IDL Job Parallel Framework.
;
; :Categories:
;   Parallel Computing
;
; :Author:
;   Luke Domanski, CSIRO Advanced Scientific Computing (2012)
;
; :History:
; .. table::
;
;   =========== ================ ============================================
;   Date        Author           Comment
;   =========== ================ ============================================
;   15/11/2012. Luke Domanski    Written
;   24/06/2013  Luke Domanski    Changed file name and enhanced documentation.
;                                Added get_generator_info function.
;   24/02/2014  Luke Domanski    Changed executable argument name to worker_executable
;                                Added worker_task_func argument
;   13/03/2014  Luke Domanski    Added job_env.sh sourcing
;-

;+
; :Hidden:
;
pro pbs_job_array_job_generator
    print, "This DUMMY procedure lets IDL find and compile this file by name. "+$
           "Using: RESOLVE_ROUTINE, 'pbs_job_array_job_generator', /COMPILE_FULL_FILE"
end

;+
; :Hidden:
;
function get_generator_info
    generator_info=STRARR(4)
    generator_info[0]="IDL Parallel Framework PBS job array+Linux job generator"
    generator_info[1]="PBS job arrays + Linux"
    generator_info[2]="IDL Parallel Framework job generator for Linux systems running the Portable Batch System (PBS). It utilises PBS job arrays, and supports Torque PBS."
    generator_info[3]="pbs_job_array_job_generator"

    return, generator_info
end


;+
; :Hidden:
;
pro generate_control_script, job_name=job_name, job_dir=job_dir, $
    n_tasks=n_tasks, task_subdivision=task_subdivision, $
    n_workers=n_workers, n_pre_post_workers=n_pre_post_workers,$
    preprocessing_script=preprocessing_script, work_script=work_script,$
    postprocessing_script=postprocessing_script

    ; generate the control script to run a parallel job through
    ; all phases
    openw, control_file, job_dir+path_sep()+job_name+".sh", /get_lun

    writeu, control_file, "#!/bin/sh", 10B

    ; Write out usage
    writeu, control_file, 'usage(){', 10B
    writeu, control_file, '	echo "usage: ${0} [options]"', 10B
    writeu, control_file, "	echo 'options:'", 10B
    writeu, control_file, "	echo '	-i|--use-idl                Use IDL for processing (default)'", 10B
    writeu, control_file, "	echo '	-g|--use-gdl                Use GDL for processing'", 10B
    writeu, control_file, '	echo "	--pbs \"qsuboptions\"         PBS qsub options passed through to ALL processing phases"', 10B
    writeu, control_file, '	echo "	--pbs-work \"qsuboptions\"    PBS qsub options passed through to work phase"', 10B
    writeu, control_file, '	echo "	--pbs-pre \"qsuboptions\"     PBS qsub options passed through to preprocessing phase"', 10B
    writeu, control_file, '	echo "	--pbs-post \"qsuboptions\"    PBS qsub options passed through to postprocessing phase"', 10B
    writeu, control_file, "	echo '	-h|--help                   This help message'", 10B
    writeu, control_file, '	echo "The last \"--use-*\" (or equivalent) parameter supplied takes precedence over others"', 10B, 10B
    writeu, control_file, '	echo "The job_env.sh will be sourced when running worker processes, place shell commands for job specific environment setup into this file"', 10B
    writeu, control_file, '}', 10B

    ; Write out parameter initialisation
    writeu, control_file, "PRE_ID=''", 10B
    writeu, control_file, "WORK_ID=''", 10B
    writeu, control_file, "POST_ID=''", 10B
    writeu, control_file, "USE_GDL='FALSE'", 10B
    writeu, control_file, "PBS_OPTS=''", 10B
    writeu, control_file, "PBS_WORK_OPTS=''", 10B
    writeu, control_file, "PBS_PRE_OPTS=''", 10B
    writeu, control_file, "PBS_POST_OPTS=''", 10B

    ; Write out commandline option parsing
    writeu, control_file, 'OPTS=`getopt -o "igh" -l "use-idl,use-gdl,pbs:,pbs-work:,pbs-pre:,pbs-post:,help" -- "$@"`', 10B

    writeu, control_file, 'if [ $? -ne 0 ]; then', 10B
    writeu, control_file, "	usage $0", 10B
    writeu, control_file, "	exit 1", 10B
    writeu, control_file, 'fi', 10B

    writeu, control_file, 'eval set -- "$OPTS"', 10B
    writeu, control_file, 'while true; do', 10B
    writeu, control_file, '	case "$1" in', 10B
    writeu, control_file, "		-i|--use-idl)", 10B
    writeu, control_file, "			USE_GDL='FALSE'", 10B
    writeu, control_file, "			shift;;", 10B
    writeu, control_file, "		-g|--use-gdl)", 10B
    writeu, control_file, "			USE_GDL='TRUE'", 10B
    writeu, control_file, "			shift;;", 10B
    writeu, control_file, "		--pbs)", 10B
    writeu, control_file, "			PBS_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		--pbs-work)", 10B
    writeu, control_file, "			PBS_WORK_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		--pbs-pre)", 10B
    writeu, control_file, "			PBS_PRE_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		--pbs-post)", 10B
    writeu, control_file, "			PBS_POST_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		-h|--help)", 10B
    writeu, control_file, "			usage $0", 10B
    writeu, control_file, "			exit 0;;", 10B
    writeu, control_file, "		--)", 10B
    writeu, control_file, "			shift", 10B
    writeu, control_file, "			break;;", 10B
    writeu, control_file, "	esac", 10B
    writeu, control_file, "done", 10B

    writeu, control_file, "mkdir ./temp_pf", 10B
    if preprocessing_script NE "" then begin
        writeu, control_file, "PRE_ID=$(qsub -o ./temp_pf -v USE_GDL=${USE_GDL} ${PBS_OPTS} ${PBS_PRE_OPTS} "+preprocessing_script+".q)", 10B
        writeu, control_file, "echo 'Submitting preprocessing script "+preprocessing_script+" with PBS job id '${PRE_ID}", 10B
        writeu, control_file, "sleep 2", 10B
    endif
    if work_script NE "" then begin
        writeu, control_file, "WORK_ID=$(qsub -o ./temp_pf -v USE_GDL=${USE_GDL} ${PBS_OPTS} ${PBS_WORK_OPTS} -W depend=afterokarray:${PRE_ID} "+work_script+".q)", 10B
        writeu, control_file, "echo 'Submitting work script "+work_script+" with PBS job id '${WORK_ID}", 10B
        writeu, control_file, "sleep 2", 10B
    endif
    if postprocessing_script NE "" then begin
        writeu, control_file, "POST_ID=$(qsub -o ./temp_pf -v USE_GDL=${USE_GDL} ${PBS_OPTS} ${PBS_POST_OPTS} -W depend=afterokarray:${WORK_ID} "+postprocessing_script+".q)", 10B
        writeu, control_file, "echo 'Submitting postprocessing script "+postprocessing_script+" with PBS job id '${POST_ID}", 10B
    endif
    close, control_file

end

;+
; :Hidden:
;
pro generate_generic_script, job_name=job_name, job_dir=job_dir,$
    work_item_file_prefix=work_item_file_prefix,$
    n_tasks=n_tasks, task_subdivision=task_subdivision,$
    n_workers=n_workers, worker_executable=worker_executable,$
    worker_task_func=worker_task_func,$
    script_name_prefix=script_name_prefix,$
    out_item_file_prefix=out_item_file_prefix, phase=phase

    ; if for some reason there are less tasks than workers
    ; reduce the number of workers to match task count
    n=n_workers-1
    if n_tasks LT n_workers then n=n_tasks-1

    ; create environment setup file place holder if
    ; not already created
    if (FILE_TEST(job_dir+path_sep()+"job_env.sh", /REGULAR) NE 1) then begin
        openw, job_env_file, job_dir+path_sep()+"job_env.sh", /get_lun
        writeu, job_env_file, "# Place shell specific commands for job environment here", 10B
        close, job_env_file
    endif

    ; generate the jobs script to process work items
    ; in work item input files using the appropriate
    ; processing phase
    openw, script_file, job_dir+path_sep()+script_name_prefix+".q", /get_lun
    writeu, script_file, "#!/bin/sh", 10B
    writeu, script_file, "#PBS -l walltime=02:00:00", 10B
    writeu, script_file, "#PBS -t 0-"+STRTRIM(STRING(n),1), 10B
    writeu, script_file, "#PBS -j oe", 10B
    writeu, script_file, "#PBS -V", 10B
    writeu, script_file, "#PBS -N "+job_name+"_"+phase+"", 10B
    writeu, script_file, "cd ${PBS_O_WORKDIR:-.}", 10B
    writeu, script_file, "source job_env.sh", 10B
    writeu, script_file, 'if [[ "$USE_GDL" != "TRUE" ]]; then', 10B
    writeu, script_file, '	idl -rt="'+worker_executable+'.sav" -args "'+phase+'" ',$
    '"'+work_item_file_prefix+'.sav" ',$
    '"'+out_item_file_prefix+'.sav" ',$
    '"'+worker_task_func+'" ',$
    '${PBS_ARRAYID} '+STRTRIM(task_subdivision,1), 10B
    writeu, script_file, "else", 10B
    writeu, script_file, '	gdl -e "'+worker_executable+'" -args "'+phase+'" ',$
    '"'+work_item_file_prefix+'.sav" ',$
    '"'+out_item_file_prefix+'.sav" ',$
    '"'+worker_task_func+'" ',$
    ' ${PBS_ARRAYID} '+STRTRIM(task_subdivision,1), 10B
    writeu, script_file, "fi", 10B
    close, script_file

end

;+
; :Hidden:
;
pro generate_work_script, job_name=job_name, job_dir=job_dir,$
    work_item_file_prefix=work_item_file_prefix,$
    n_tasks=n_tasks, task_subdivision=task_subdivision,$
    n_workers=n_workers, worker_executable=worker_executable,$
    worker_task_func=worker_task_func,$
    script_name_prefix=script_name_prefix,$
    out_item_file_prefix=out_item_file_prefix


    generate_generic_script, job_name=job_name, job_dir=job_dir,$
        work_item_file_prefix=work_item_file_prefix,$
        n_tasks=n_tasks*task_subdivision, task_subdivision=task_subdivision,$
        n_workers=n_workers, worker_executable=worker_executable,$
        worker_task_func=worker_task_func,$
        script_name_prefix=script_name_prefix,$
        out_item_file_prefix=out_item_file_prefix, phase="work" 

end

;+
; :Hidden:
;
pro generate_preprocessing_script, job_name=job_name, job_dir=job_dir,$
    work_item_file_prefix=work_item_file_prefix,$
    n_tasks=n_tasks, task_subdivision=task_subdivision,$
    n_workers=n_workers, worker_executable=worker_executable,$
    worker_task_func=worker_task_func,$
    script_name_prefix=script_name_prefix,$
    out_item_file_prefix=out_item_file_prefix

    generate_generic_script, job_name=job_name, job_dir=job_dir,$
        work_item_file_prefix=work_item_file_prefix,$
        n_tasks=n_tasks, task_subdivision=task_subdivision,$
        n_workers=n_workers, worker_executable=worker_executable,$
        worker_task_func=worker_task_func,$
        script_name_prefix=script_name_prefix,$
        out_item_file_prefix=out_item_file_prefix, phase="preprocess" 
end

;+
; :Hidden:
;
pro generate_postprocessing_script, job_name=job_name, job_dir=job_dir,$
    work_item_file_prefix=work_item_file_prefix,$
    n_tasks=n_tasks, task_subdivision=task_subdivision,$
    n_workers=n_workers, worker_executable=worker_executable,$
    worker_task_func=worker_task_func,$
    script_name_prefix=script_name_prefix,$
    out_item_file_prefix=out_item_file_prefix

    generate_generic_script, job_name=job_name, job_dir=job_dir,$
        work_item_file_prefix=work_item_file_prefix,$
        n_tasks=n_tasks, task_subdivision=task_subdivision,$
        n_workers=n_workers, worker_executable=worker_executable,$
        worker_task_func=worker_task_func,$
        script_name_prefix=script_name_prefix,$
        out_item_file_prefix=out_item_file_prefix, phase="postprocess" 

end


