; docformat = 'rst'
;+
; IDL Job Parallel Framework job generator for Linux systems running the
; Simple Linux Utility for Resource Management.
;
; Users should not call any functions in this file directly. This plugin can
; be loaded into the Framework by passing "slurm" as the plugin ident to the
; Framework's `load_generator_plugin` procedure.
;
; All procedures in this module (except helper generate_generic_script)
; are implementations of the job script generator plugin API and
; functionality defined for the IDL Job Parallel Framework.
;
; :Categories:
;   Parallel Computing
;
; :Author:
;   Luke Domanski, CSIRO Advanced Scientific Computing (2014)
;
; :History:
; .. table::
;
;   =========== ================ ============================================
;   Date        Author           Comment
;   =========== ================ ============================================
;   21/01/2014  Luke Domanski    Copied and modified from pbs_job_generator.pro
;-


;+
; :Hidden:
;
pro slurm_job_generator
    print, "This DUMMY procedure lets IDL find and compile this file by name. "+$
           "Using: RESOLVE_ROUTINE, 'slurm_job_generator', /COMPILE_FULL_FILE"
end

;+
; :Hidden:
;
function get_generator_info
    generator_info=STRARR(4)
    generator_info[0]="IDL Parallel Framework SLURM+Linux job generator"
    generator_info[1]="SLURM + Linux"
    generator_info[2]="IDL Parallel Framework job generator for Linux systems running the Simple Linux Utility for Resource Management (SLURM)."
    generator_info[3]="slurm_job_generator"

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
    writeu, control_file, '	echo "	--slurm \"sbatchoptions\"         SLURM sbatch options passed through to ALL processing phases"', 10B
    writeu, control_file, '	echo "	--slurm-work \"sbatchoptions\"    SLURM sbatch options passed through to work phase"', 10B
    writeu, control_file, '	echo "	--slurm-pre \"sbatchoptions\"     SLURM sbatch options passed through to preprocessing phase"', 10B
    writeu, control_file, '	echo "	--slurm-post \"sbatchoptions\"    SLURM sbatch options passed through to postprocessing phase"', 10B
    writeu, control_file, "	echo '	-h|--help                   This help message'", 10B
    writeu, control_file, '	echo "The last \"--use-*\" (or equivalent) parameter supplied takes precedence over others"', 10B, 10B
    writeu, control_file, '	echo "The job_env.sh will be sourced when running worker processes, place shell commands for job specific environment setup into this file"', 10B
    writeu, control_file, '}', 10B

    ; Write out parameter initialisation
    writeu, control_file, "PRE_JOB_ID=''", 10B
    writeu, control_file, "WORK_JOB_IDS=''", 10B
    writeu, control_file, "POST_JOB_ID=''", 10B
    writeu, control_file, "N_WORKERS_PRE_POST="+STRTRIM(STRING(n_pre_post_workers),1), 10B
    writeu, control_file, "TASK_SUBDIVISION="+STRTRIM(STRING(task_subdivision),1), 10B
    writeu, control_file, "N_WORK_JOBS=$((N_WORKERS_PRE_POST*TASK_SUBDIVISION))", 10B
    writeu, control_file, "USE_GDL='FALSE'", 10B
    writeu, control_file, "SLURM_OPTS=''", 10B
    writeu, control_file, "SLURM_WORK_OPTS=''", 10B
    writeu, control_file, "SLURM_PRE_OPTS=''", 10B
    writeu, control_file, "SLURM_POST_OPTS=''", 10B

    ; Write out commandline option parsing
    writeu, control_file, 'OPTS=`getopt -o "igh" -l "use-idl,use-gdl,slurm:,slurm-work:,slurm-pre:,slurm-post:,help" -- "$@"`', 10B

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
    writeu, control_file, "		--slurm)", 10B
    writeu, control_file, "			SLURM_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		--slurm-work)", 10B
    writeu, control_file, "			SLURM_WORK_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		--slurm-pre)", 10B
    writeu, control_file, "			SLURM_PRE_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		--slurm-post)", 10B
    writeu, control_file, "			SLURM_POST_OPTS=$2", 10B
    writeu, control_file, "			shift 2;;", 10B
    writeu, control_file, "		-h|--help)", 10B
    writeu, control_file, "			usage $0", 10B
    writeu, control_file, "			exit 0;;", 10B
    writeu, control_file, "		--)", 10B
    writeu, control_file, "			shift", 10B
    writeu, control_file, "			break;;", 10B
    writeu, control_file, "	esac", 10B
    writeu, control_file, 'done', 10B


    ; Start submitting job
    writeu, control_file, "mkdir ./temp_pf", 10B

    ; Write out SLURM job submission code
    writeu, control_file, "for (( i = 0; i < $N_WORKERS_PRE_POST; i++)); do", 10B
    if preprocessing_script NE "" then begin
        writeu, control_file, "	PRE_JOB_ID=$(sbatch --output=./temp_pf --export=SLURM_ARRAY_TASK_ID=${i},TASK_SUBDIV=${TASK_SUBDIVISION},USE_GDL=${USE_GDL} ${SLURM_OPTS} ${SLURM_PRE_OPTS} "+preprocessing_script+".q)", 10B
        writeu, control_file, "	PRE_JOB_ID=$(echo $PRE_JOB_ID | sed 's/^[^0-9]*//g')", 10B
        writeu, control_file, "	DISP_ID=$((i+1))", 10B
        writeu, control_file, "	echo 'Submitting '${DISP_ID}' of '${N_WORKERS_PRE_POST}' pre-processing scripts "+preprocessing_script+" with SLURM job id '${PRE_JOB_ID}", 10B
        writeu, control_file, "	sleep 2", 10B

        writeu, control_file, "	WORK_JOB_IDS=''", 10B
        writeu, control_file, "	for (( j = 0; j < $TASK_SUBDIVISION; j++ )); do", 10B
        writeu, control_file, "		WORK_ARRAY_ID=$((i*TASK_SUBDIVISION+j))", 10B
    endif else begin
        writeu, control_file, "		WORK_ARRAY_ID=$i", 10B
    endelse

    if work_script NE "" then begin
        writeu, control_file, "		PRE_JOB_DEPEND=''", 10B
        writeu, control_file, '		if [[ "$PRE_JOB_ID" != "" ]]; then PRE_JOB_DEPEND="--dependency=afterok:${PRE_JOB_ID}"; fi ', 10B
        writeu, control_file, "		WORK_JOB_ID=$(sbatch --output=./temp_pf --export=SLURM_ARRAY_TASK_ID=${WORK_ARRAY_ID},TASK_SUBDIV=${TASK_SUBDIVISION},USE_GDL=${USE_GDL} ${SLURM_OPTS} ${SLURM_WORK_OPTS} ${PRE_JOB_DEPEND} "+work_script+".q)", 10B
        writeu, control_file, "		WORK_JOB_ID=$(echo $WORK_JOB_ID | sed 's/^[^0-9]*//g')", 10B
        writeu, control_file, "		DISP_W_ID=$((WORK_ARRAY_ID+1))", 10B
        writeu, control_file, "		echo 'Submitting '${DISP_W_ID}' of '${N_WORK_JOBS}' work scripts "+work_script+" with SLURM job id '${WORK_JOB_ID}", 10B
        writeu, control_file, '		if [[ "$WORK_JOB_IDS" != "" ]]; then WORK_JOB_IDS="${WORK_JOB_IDS}:"; fi ', 10B
        writeu, control_file, "		WORK_JOB_IDS=${WORK_JOB_IDS}${WORK_JOB_ID}", 10B
    endif


    if preprocessing_script NE "" then begin
        writeu, control_file, "	done", 10B
    endif

    if postprocessing_script NE "" then begin
        writeu, control_file, "	WORK_JOB_DEPEND=''", 10B
        writeu, control_file, '	if [[ "$WORK_JOB_IDS" != "" ]]; then WORK_JOB_DEPEND="--dependency=afterok:${WORK_JOB_ID}"; fi '
        writeu, control_file, "	sleep 2", 10B
        writeu, control_file, "	POST_JOB_ID=$(sbatch --output=./temp_pf --export=SLURM_ARRAY_TASK_ID=${i},TASK_SUBDIV=${TASK_SUBDIVISION},USE_GDL=${USE_GDL} ${SLURM_OPTS} ${SLURM_POST_OPTS} ${WORK_JOB_DEPEND} "+postprocessing_script+".q)", 10B
        writeu, control_file, "	POST_JOB_ID=$(echo $POST_JOB_ID | sed 's/^[^0-9]*//g')", 10B
        writeu, control_file, "	echo 'Submitting '${DISP_ID}' of '${N_WORKERS_PRE_POST}' post-processing scripts "+postprocessing_script+" with SLURM job id '${POST_JOB_ID}", 10B
    endif
    writeu, control_file, "done", 10B
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
    writeu, script_file, "#SBATCH --time=02:00:00", 10B
    writeu, script_file, "#SBATCH --export=ALL", 10B
    writeu, script_file, "#SBATCH --job-name="+job_name+"_"+phase+"", 10B
    writeu, script_file, "cd ${SLURM_SUBMIT_DIR:-.}", 10B
    writeu, script_file, "source job_env.sh", 10B
    writeu, script_file, 'if [[ "$USE_GDL" != "TRUE" ]]; then', 10B
    writeu, script_file, '	idl -rt="'+worker_executable+'.sav" -args "'+phase+'" ',$
        '"'+work_item_file_prefix+'.sav" ',$
        '"'+out_item_file_prefix+'.sav" ',$
        '"'+worker_task_func+'" ',$
        ' ${SLURM_ARRAY_TASK_ID} ${TASK_SUBDIV}', 10B
    writeu, script_file, "else", 10B
    writeu, script_file, '	gdl -e "'+worker_executable+'" -args "'+phase+'" ',$
        '"'+work_item_file_prefix+'.sav" ',$
        '"'+out_item_file_prefix+'.sav" ',$
        '"'+worker_task_func+'" ',$
        '${SLURM_ARRAY_TASK_ID} ${TASK_SUBDIV}', 10B
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
        n_tasks=n_tasks, task_subdivision=task_subdivision,$
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


