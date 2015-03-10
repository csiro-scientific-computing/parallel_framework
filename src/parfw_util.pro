; docformat = 'rst'
;+
; Module containing non-user API helper functions for the IDL Job Parallel
; Framework
;
; :Private:
;
; :Categories:
;   Parallel Computing, File Handling
;-

pro parfw_util
    print, "This DUMMY procedure lets IDL find and compile this file by name. "+$
           "Using: RESOLVE_ROUTINE, 'parfw_util', /COMPILE_FULL_FILE"
end

;+
; Changes file path delimiters (i.e. the slashes between directories) to those
; required for the platform the code runs on
;
; Only supports 'windows' and 'unix' OS families as returned by IDLs
; !VERSION.OS_FAMILY system variable
;
; :Private:
;
; :Categories:
;   File Handling
;
; :Params:
;   path : in, required, type=string/strarr
;        File path string or array of strings to be corrected. The file(s) do
;        not need to exist.
;
; :Returns:
;   Path string (for scalar input) or array of string (for array input) with
;   the correct directory path delimiters for current platform. Null string ""
;   returned when given Null string input.
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
;   xx/11/2012  Luke Domanski    Written
;   13/03/2014  Luke Domanski    Moved from estarfm_util.pro to parfw_utile.pro
;   xx/06/2014  Luke Domanski    Added support for array input
;-
function correct_path_delim, path

    search_delim='\'
    replace_delim='/'

    switch !VERSION.OS_FAMILY of
        'windows':
        'Windows': begin
            search_delim='/'
            replace_delim='\'
            break
            end
        'unix':
        'Unix': begin
            search_delim='\'
            replace_delim='/'
            break
            end
        ELSE: message, 'Unsupported Platform: IDL system variable !VERSION.OS_FAMILY returned an unknown operating system name. Assuming Unix directory naming', /CONTINUE
    endswitch

    ; find out if the path is scalar so we can convert it
    ; back after processing
    path_is_scalar=(SIZE(path, /N_DIMENSIONS) EQ 0) ? 1:0

    ; handle arrays of file names
    for i=0,N_ELEMENTS(path)-1 do begin

        temp=path[i]

        ; replace each occurrence of search_delim
        ; with replace_delim
        slash_pos=strpos(temp, search_delim)
        while slash_pos NE -1 do begin
            strput, temp, replace_delim, slash_pos
            slash_pos=strpos(temp, search_delim)
        endwhile

        ; remove the trailing slash if it exists
        slash_pos=strpos(temp, replace_delim, /REVERSE_SEARCH)
        if slash_pos EQ (strlen(temp)-1) then begin
            strput, temp, ' ', slash_pos
            temp=strtrim(temp)
        endif

        path[i]=temp

    endfor

    ; convert back to a scalar if the input was one
    if path_is_scalar then path=path[0]

    return, path

end

;+
; Changes given file path(s) into minimal absolute file path with corrected
; platform path delimiters.
;
; Specified file **must** exist. Path delimiters in input path string do not
; need to be valid for platform, however, when an absolute path is passed in,
; drive prefixing must be valid for the platform as per IDL in built functions,
; such as `cd`.
;
; Calls `correct_path_delim` for correcting path delimiters.
;
; :Private:
;
; :Categories:
;   File Handling
;
; :Uses:
;   correct_path_delim
;
; :Params:
;   path : in, required, type=string/strarr
;        File path string or array of strings to be corrected. The file(s) must
;        exist.
;
; :Returns:
;   Path string (for scalar input) or array of strings (for array input)
;   containing the minimal absolute paths, or Null string "" if file does not
;   exist, of input file paths, with directory path delimiters corrected for
;   current platform.
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
;   xx/06/2014  Luke Domanski    Written
function fully_qualified_path, path

    corrected_path=correct_path_delim(path)

    ; GDL does not handle relative paths well when trying to get the
    ; fully qualified path of a directory from FILE_EXPAND_PATH or
    ; FILE_SEARCH. So we will do it manually

    ; fortunately GDL's implementation of CD does support relative paths
    ; as well as recording of the former directory. So we can use the
    ; following cd trick to get a fully qualified path

    ; find out if the path is scalar so we can convert it
    ; back after processing
    path_is_scalar=(SIZE(path, /N_DIMENSIONS) EQ 0) ? 1:0

    ; handle arrays of file names
    full_path=STRARR(N_ELEMENTS(corrected_path))
    for i=0,N_ELEMENTS(corrected_path)-1 do begin

        if FILE_TEST(corrected_path[i]) then begin
            ; change to the base dir of specified path, while storing the current dir
            cd, FILE_DIRNAME(corrected_path[i]), CURRENT=cur_dir
            ; change back to our original working dir while storing full base dir path
            cd, cur_dir, CURRENT=corrected_dirname
            ; add the basename of the path to its dirname/base dir
            full_path[i]=corrected_dirname+PATH_SEP()+FILE_BASENAME(corrected_path[i])
        endif else begin
            message, "File or directory "+path[i]+" does not exist on this system", /CONTINUE
            full_path[i]=""
        endelse

    endfor

    ; convert back to a scalar if the input was one
    if path_is_scalar then full_path=full_path[0]

    return, full_path
end

;+
; Retrieves command line parameters required for parallel framework
; functionality and returns them to named variables.
;
; Notes
; =====
;   Programs calling this procedure should reserve the first six command
;   line parameters for the parallel framework. Subsequent parameters are
;   ignored by procedure and can be used by the program itself
;
; Limitations
; ===========
;   If calling program utilises additional command line arguments, this
;   function can not distinguish between parallel framework and application
;   specific arguments. It **CAN NOT** detect missing parallel framework
;   arguments when arg count is greater than five.
;
; :Private:
;
; :Categories:
;   Parallel Computing
;
; :Keywords:
;   phase : out, required, type=string
;       Named variable that will contain (string) the parallel framework
;       processing phase being invoked.
;   work_item_file : out, required, type=string
;       Named variable that will contain (string) name of the work item file
;       containing an array of application defined structures representing
;       input tasks to this processing phase. See `generate_parallel_job` for
;       details.
;   out_item_file : out, required, type=string
;       Named variable that will contain (string) name of the work item file
;       containing an array of application defined structures represent input
;       tasks to this processing phase. See `generate_parallel_job` for
;       details.
;   worker_func : out, required, type=string
;       Named variable that will contain (string) the name of the task
;       processing function to use for this parallel worker.
;   worker_id : out, required, type=integer
;       Named variable that will contain (integer) the ID of this parallel
;       worker.
;   task_subdivision : out, required, type=integer
;       Named variable that will contain (integer) the number of subtasks
;       initially application tasks have/should be broken into.
;
; :Returns:
;   On success, named input variables (See Keywords) will contain corresponding
;   command line arguments, otherwise all variables will be set to !NULL.
;
; :Author:
;   Luke Domanski, CSIRO Advanced Scientific Computing (2013)
;
; :History:
; .. table::
;
;   =========== ================ ============================================
;   Date        Author           Comment
;   =========== ================ ============================================
;   4/11/2013   Luke Domanski    Written
;   21/02/2014  Luke Domanski    Added worker_func parameter
;   04/07/2014  Luke Domanski    Change error warning print out to use MESSAGE
;-
pro parse_worker_command_line_args, phase=phase, work_item_file=work_item_file,$
    out_item_file=out_item_file, worker_func=worker_func, worker_id=worker_id,$
    task_subdivision=task_subdivision

    phase=!NULL
    work_item_file=!NULL
    out_item_file=!NULL
    worker_func=!NULL
    worker_id=!NULL
    task_subdivision=!NULL

    ; Get the command line arguments for worker number and job state file
    args = command_line_args(COUNT=num_args)
    if num_args GT 5 then begin
        task_subdivision = LONG(args[5])
        worker_id = LONG(args[4])
        worker_func = args[3]
        out_item_file = args[2]
        work_item_file = args[1]
        phase = args[0]
    endif else begin
        MESSAGE, "WARNING - usage requires six input arguments in the following order:\n" +$
               'phase - "preprocessing"|"work"|"postprocessing" indicating the phase of the job to be executed\n' +$
               'work_item_file - name of file containing the list of work items/tasks to be performed\n' +$
               'out_item_file - name of the file where the output details for each work item/task should be listed\n' +$
               'worker_func - name of parallel worker task processing function to use\n' +$
               'worker_id - the integer ID assigned to this process instance when used as part of a parallel job (if only running serially, specify ID as 0)\n' +$
               'task_subdivision - the number of parts (subtasks) each input task should be/was broken into at the preprocessing phase (if no subdivision applied, specify as 1)'
    endelse

end


;+
; Load specified IDL module or program file.
;
; Given a string containing an IDL module name (i.e. a file containing a
; collection of IDL functions and routines) without the file extension. This
; function searches directories in !PATH for the appropriate module file, and
; loads the contents into the session.
;
; It provides a single machanism for loading the named module regardless of
; whether a .pro (source) version, .sav (compiled) version, or both are found,
; or whether the function is being called from IDL or GDL.
;
; The function favours loading the precompiled .sav version of the module where
; available and possible, otherwise it falls back to compiling the source
; definition if available. NOTE: This is the opposite behaviour to IDL autoload
; mechanism
;
; :Private:
;
; :Categories:
;   File Handling, Utilities
;
; :Keywords:
;   module_name : in, required, type=string
;       Name of module or program file to load without filename extension.
;   VERBOSE : in, optional, type=boolean
;       Indicates that detailed information should be displayed upon loading
;       module.
;
; :Post:
;   Currently compiled functions or routines in the IDL session are overwritten
;   if the specified module file defines a construct of the same name
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
;   18/02/2014  Luke Domanski    Written
;   xx/07/2014  Luke Domanski    Enhanced checking for missing module_name
;-
pro load_module, module_name=module_name, VERBOSE=verbose

    if ~KEYWORD_SET(module_name) || $
        (module_name EQ !NULL)   || $
        (module_name EQ '') then begin
        MESSAGE, "ERROR - module_name string is empty"
        return
    endif

    ; check if we are running GDL
    DEFSYSV, '!GDL', EXISTS=running_gdl

    compiled_version=""
    compiled_exists=0

    ; if we are not running GDL, check if a compiled
    ; version of the module is the local dir or the !PATH
    if (~running_gdl) then begin
        search_res=FILE_SEARCH(module_name+".sav")
        if (search_res[0] EQ '') then begin
            search_res=FILE_SEARCH(STRSPLIT(!PATH, PATH_SEP(/SEARCH_PATH), $
                                /EXTRACT)+PATH_SEP()+module_name+".sav")
        endif

        if (search_res[0] NE '') then begin
            compiled_version=search_res[0]
            compiled_exists=1
        endif
    endif

    ; if not running GDL, and a compiled version of the
    ; framework exists, load the compiled version
    if (~running_gdl) && (compiled_exists) then begin
        restore, compiled_version, VERBOSE=verbose

    ; Else load/compile the whole Parallel Framework source file
    endif else begin
        RESOLVE_ROUTINE, module_name, /EITHER, /COMPILE_FULL_FILE
    endelse
end


;+
; Copy specified IDL module or program file to desired location.
;
; Given a string naming an IDL module or program file (i.e. a file containing a
; collection of IDL functions and routines) without its file extension. This
; function searches the current directory, and those in `!PATH`, for the
; appropriate module file(s), and copies either or both of the first compiled
; (.sav) and source code (.pro) versions of the module (see `Copy precedence`
; for details).
;
; An array of strings naming the path(s) of the files copied is returned in an
; optional named parameter `copied`, if provided. If the module was not found,
; a null string is returned
;
; Copy Precedence
; ===============
; If both a .pro (source) and .sav (compiled) version of the module exist and
; are in the same directory, both are copied to the specified destination
; directory (assume files in same directory contain the same implementation).
; Otherwise, only the first instances found is copied, regardless of its
; extension or how many module files were located (avoids fetching different
; implementations).
;
; These defaults can be modified with the `/SAV_ONLY`, `/PRO_ONLY`, and
; `/FORCE_BOTH`, switches defined in `Keywords`.
;
; :Private:
;
; :Categories:
;   File Handling, Utilities
;
; :Uses:
;   fully_qualified_path
;
; :Keywords:
;   module_name : in, required, type=string
;       Name of module, without file extension, to be located and copied
;   dest_dir : in, optional, type=string
;       Destination directory to copy module to. Defaults to current directory.
;   copied ; out, optional, type=strarr
;       Named variable that will receive an array of strings containing the
;       source file paths of module files that were copied, or the null string
;       "" in the case of no copies.
;   /SAV_ONLY, in, optional, type=boolean
;       Specifies that only a compiled version of the module is to be copied.
;   /PRO_ONLY, in, optional, type=boolean
;       Specifies that only a source code version of the module is to be
;       copied. Takes precedence over `/SAV_ONLY`.
;   /FORCE_BOTH, in, optional, type=boolean
;       Specifies that, if found, **both** a source code and compiled version
;       of the module are to be copied regardless of whether they are in the
;       same directory. Default function behaviour is to copy both **only** if
;       the first instances found are in the same directory. Takes precedence
;       over **both** `/SAV_ONLY` end `/PRO_ONLY`.
;
; :Post:
;   If the located file already existed in destination directory, they will be
;   overwritten.
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
;   18/02/2014  Luke Domanski    Written
;   xx/03/2014  Luke Domanski    - Added flag keyword to direct behaviour re. .sav vs .pro files
;                                - Added "copied" output parameter indicating action
;   xx/06/2014  Luke Domanski    Changed error reporting to use MEASSAGE
;   16/07/2014  Luke Domanski    Added creation of dest dir if it doesn't exist
;   xx/07/2014  Luke Domanski    - Added check that dest_dir is a DIRECTORY
;                                - Brought consistency to error handling approach
;                                - Added creation of dest_dir if it doesn't exist
;                                - Changed recursive search of PATH dirs to direct search
;                                  for dirs+module to avoid very long search times
;-
pro copy_module, module_name=module_name, dest_dir=dest_dir, copied=copied, $
                 SAV_ONLY=sav_only, PRO_ONLY=pro_only, FORCE_BOTH=force_both


    if ~KEYWORD_SET(dest_dir) || $
       (dest_dir EQ !NULL) || $
       (dest_dir EQ '') then begin
        dest_dir="."
    endif

    if ~KEYWORD_SET(module_name) || $
       (module_name EQ !NULL) || $
       (module_name EQ '') then begin
        MESSAGE, "ERROR - module_name string is empty", /CONTINUE
        if ARG_PRESENT(copied) then copied=''
        return
    endif

    ; If the destination directory exists and is normal
    ; file, we are not going to over write it!
    if FILE_TEST(dest_dir, /REGULAR) then begin
        MESSAGE, "ERROR - destination directory dest_dir="+dest_dir+$
                 " exist and is a regular file! Aborting", /CONTINUE
        if ARG_PRESENT(copied) then copied=''
        return
    endif

    ; FORCE_BOTH overwrite all
    ; PRO_ONLY overwrites SAV_ONLY
    ;   The following commented code using wild cards dramatically
    ;   simplifies enforcing these rules in this function's code.
    ;   BUT GDL does not support the wild cards
    ;   So we have to do the long winded version
    ;   search_ext=".{pro,sav}"
    ;   if ~KEYWORD_SET(force_both) then begin
    ;      if KEYWORD_SET(sav_only) then search_ext=".sav"
    ;      if KEYWORD_SET(pro_only) then search_ext=".pro"
    ;   endif
    get_sav=1
    get_pro=1
    if ~KEYWORD_SET(force_both) then begin
        if KEYWORD_SET(sav_only) then begin
           get_sav=1
           get_pro=0
        endif
        if KEYWORD_SET(pro_only) then begin
           get_sav=0
           get_pro=1
        endif
    endif


    ; Search the current directory
    ;   Short wild card version not supported by GDL
    ;   local_files=FILE_SEARCH(module_name+search_ext)
    local_pro_files=''
    local_sav_files=''
    if get_pro then local_pro_files=FILE_SEARCH(module_name+".pro")
    if get_sav then local_sav_files=FILE_SEARCH(module_name+".sav")
    if (local_pro_files[0] EQ '') then local_pro_files=!NULL
    if (local_sav_files[0] EQ '') then local_sav_files=!NULL
    local_files=[ local_pro_files, local_sav_files ]
    if (local_files EQ !NULL) then local_files=''

    ; IF none found in the current directory
    ; OR one was found but we are copying both
    ; THEN check !PATH
    path_files=''
    if (local_files[0] EQ '') || $
       (N_ELEMENTS(local_file) LT 2 && KEYWORD_SET(force_both)) then begin

        ; Search the path
        ;   Short wild card version not supported by GDL
        ;   path_files=FILE_SEARCH(STRSPLIT(!PATH, PATH_SEP(/SEARCH_PATH), $
        ;                          /EXTRACT), module_name+search_ext)
        path_pro_files=''
        path_sav_files=''
        if get_pro then $
            path_pro_files=FILE_SEARCH(STRSPLIT(!PATH, PATH_SEP(/SEARCH_PATH), $
                                       /EXTRACT)+PATH_SEP()+module_name+".pro")
        if get_sav then $
            path_sav_files=FILE_SEARCH(STRSPLIT(!PATH, PATH_SEP(/SEARCH_PATH), $
                                       /EXTRACT)+PATH_SEP()+module_name+".sav")
        if (path_pro_files[0] EQ '') then path_pro_files=!NULL
        if (path_sav_files[0] EQ '') then path_sav_files=!NULL
        path_files=[ path_pro_files, path_sav_files ]
        if (path_files EQ !NULL) then path_files=''

        ; remove duplicates resulting from directories appearing
        ; multiple times in path
        path_files=path_files[UNIQ(path_files, SORT(path_files))]
    end

    ; get a full list of candidate files (concatenate result)
    ; NOTE :  AGAIN The following one liner is preferred, but GDL chokes on array[!NULL]
    ; candidate_files=[ local_files[WHERE(local_files NE '', /NULL)], $
    ;                  path_files[WHERE(path_files NE '', /NULL)]  ]
    candidate_files=!NULL
    local_file_mask=WHERE(local_files NE '', valid_local_files)
    path_file_mask=WHERE(path_files NE '', valid_path_files)
    if (valid_local_files GT 0) then candidate_files=[ candidate_files, local_files[local_file_mask] ]
    if (valid_path_files GT 0) then candidate_files=[ candidate_files, path_files[path_file_mask] ]

    ; narrow down the candidates to only the first .pro and .sav found
    ; NOTE :  AGAIN GDL chokes on the short version of the following
    ; elaborate code, as it does not handle array[!NULL] gracefully.
    if (candidate_files NE !NULL) then begin
        candidate_mask=!NULL
        pro_files=WHERE(STREGEX(candidate_files, ".*\.pro", /BOOLEAN ), valid_pro_files)
        sav_files=WHERE(STREGEX(candidate_files, ".*\.sav", /BOOLEAN ), valid_sav_files)
        if (valid_pro_files GT 0) then candidate_mask=[ candidate_mask, pro_files[0] ]
        if (valid_sav_files GT 0) then candidate_mask=[ candidate_mask, sav_files[0] ]
        if (candidate_mask NE !NULL) then begin
            candidate_files=candidate_files[candidate_mask]
        endif else begin
            candidate_files=!NULL
        endelse
    endif

    if (candidate_files EQ !NULL) then begin
        MESSAGE, "ERROR - module_name " + module_name + " not found", /CONTINUE
        if ARG_PRESENT(copied) then copied=''
        return
    endif else begin

        ; If only one candidate remains, no more filtering
        ; is performed.
        ;
        ; If two candidates remain at this point, they must
        ; consist of one .pro and one .sav
        ;
        ; We need to address two situations
        ; 1) FORCE_BOTH was not selected - we only copy both
        ;   files if they are in the same directory
        ; 2) FORCE_BOTH was selected - copy both
        if (N_ELEMENTS(candidate_files) GE 2) && $
           (~KEYWORD_SET(force_both)) then begin

           if (FILE_DIRNAME(candidate_files[0]) NE $
               FILE_DIRNAME(candidate_files[1])) then begin
                candidate_files=candidate_files[0]
            endif

        endif

        copy_files=candidate_files

    endelse

    ; Make the destination directory if it does not already exist
    if ~FILE_TEST(dest_dir, /DIRECTORY) then begin
        FILE_MKDIR, dest_dir
    endif

    ; GDL does not handle relative directories well for destination in FILE_COPY
    ; so we will expand to fully qualified path manually
    file_copy, fully_qualified_path(copy_files), $
               fully_qualified_path(dest_dir)+path_sep(), $
               /OVERWRITE

    if ARG_PRESENT(copied) then copied=copy_files

end

;+
; Saves a work item list or task list to a file suffixed with worker ID.
;
; Given a 1D or 2D array of structures `out_items`, with each first dimension
; element representing the output information for the processing of a single
; work item (tasks) under the IDL Job Parallel Framework (see
; `generate_parallel_job`), this function saves the output items list/array
; into a file based on `file_prefix` and `worker_id`.
;
; If `out_items` is a 2D array, the function assumes that the output items are
; the result of a task processing step that applied task subdivision. In which
; case, output items with the same first dimension index `i` represent
; part-/sub-output items of task `i`. The size of the second dimension
; indicates the level of subdivision `d` that was applied. The output item list
; is then segmented into `d` lists along the second dimension, and saved across
; multiple files for further processing by the IDL Job Parallel Framework.
;
; This procedure creates file names based on the `worker_id` AND `d` determined
; as described above. It is the users responsibility to check that any 2D `out_item`
; array passed to this procedure has the correct second dimensions size. If two
; worker files are saved in your application with `d` resolving to different values
; the behaviour is undefined.
;
; :Private:
;
; :Categories:
;   Parallel Computing, File Handling
;
; :Uses:
;   correct_path_delim
;
; :Params:
;   out_items : in, required, type=array of structures 
;       1D or 2D array of structures representing output items of a number of
;       task processed under the IDL Paralle Framework
;   file_prefix : in, required, type=string
;       the file path+basename (without extension) to use for output file(s)
;       prior to worker identifier suffix being added
;   worker_id : in, required, type=integer
;       The integer identifier of the worker process saving the file(s)
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
;   20/02/2014  Luke Domanski    Written
;-
pro save_worker_out_items, out_items, file_prefix, worker_id

    ; check that the worker ID is not completely bogus
    if worker_id LT 0 then begin
            MESSAGE, "ERROR - worker ID worker_id="+strtrim(worker_id,1)+$
                     " is a negative number! Aborting", /CONTINUE
            return
    endif

    ; Trim and neaten up the file_prefix
    file_prefix=correct_path_delim(file_prefix)
    file_prefix=file_dirname(file_prefix)+path_sep()+$
        file_basename(file_prefix,".sav")

    ; if the out_items array is 1D, then just save the file
    if ~(SIZE(out_items, /N_DIMENSIONS) GT 1) then begin

        work_items=out_items
        save, work_items, filename=file_prefix+strtrim(worker_id,2)+".sav"
    endif else begin

    ; if the array of out item structures is two dimensional,
    ; assume the out items are a result of subdividing a single
    ; task into multiple sub-/part-tasks

        dims=SIZE(out_items, /DIMENSIONS)
        ; number of tasks is the first dimension length
        n_tasks=dims[0]
        ; number of parts is the second dimension length
        n_parts=dims[1]

        for i=0,n_parts-1 do begin
            ; little trick by Andrew Cool (dsto) and David Fanning (cyote)
            ; for deleting a variable
            tempvar=SIZE(TEMPORARY(work_items))

            ; gdl had trouble handling array ranges for structure
            ; assignment at time of writing, hence the long winded
            ; version of the following loop
            work_items = []
            for j=0,n_tasks-1 do begin
                work_items=[work_items, out_items[j,i]]
            endfor

            save, work_items, $
                filename=file_prefix+strtrim((worker_id*n_parts)+i,2)+".sav"
        endfor
    endelse
end

;+
; Load parallel worker's work items from file give file prefix and worker ID
;
; Given the reference `file_prefix` of input work item files for appropriate
; parallel job+phase, and `worker_id` of the chosen parallel worker, this
; function loads the worker's work item list file(s) for the parallel job and
; returns the work items list as a 1D or 2D array of structures. Each task is
; represented by the structure or sub-array of structures referenced by a
; single first dimension array index. The filename(s) of the relevant file(s)
; are constructed from the `file_prefix` and `worker_id`
;
; If `n_parts` is greater than 1, the function assumes that the worker's task
; processing function will collate the output of a number of part-tasks
; resulting from a previously subdivided parent task. In that case this
; function generates the work items list from a number of part-task files and
; returns a single 2D array, where structures sharing a common first dimension
; index represent part-task of a single collation task.
;
; :Private:
;
; :Categories:
;   Parallel Computing
;
; :Uses:
;   correct_path_delim
;
; :Params:
;   file_prefix : in, required, type=string
;       The file path+basename (without extension) to use for the input task
;       file(s) prior to worker identifier suffix being added
;   worker_id : in, required, type=integer
;       The integer identifier of the worker process loading the file(s)
;   n_parts : in, required, type=integer
;       The expected number of part-tasks in the worker's task list, i.e. the
;       number of part-tasks the worker's task processing function will collate
;       into a single output item (use 1 for no collation)
;
; :Returns:
;   On success, returns a 1D or 2D array (see description) containing the
;   specified worker's task list
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
;   20/02/2014  Luke Domanski    Written
;-
function load_worker_task_list, file_prefix, worker_id, n_parts

    tasks=!NULL

    ; catch clearly invalid numbers (negatives)
    if worker_id LT 0 then begin
            MESSAGE, "ERROR - worker ID worker_id="+strtrim(worker_id,1)+$
                     " is a negative number! Aborting", /CONTINUE
            return, !null
    endif

    if n_parts LT 0 then begin
            MESSAGE, "ERROR - number of parts n_parts="+strtrim(n_parts,1)+$
                     " is a negative number! Aborting", /CONTINUE
            return, !null
    endif

    ; Trim and neaten up the file_prefix
    file_prefix=correct_path_delim(file_prefix)
    file_prefix=file_dirname(file_prefix)+path_sep()+$
        file_basename(file_prefix,".sav")

    ; if our task list is contained in a single file
    ; (n_parts EQ 1), then load that file
    if ~(n_parts GT 1) then begin

        task_file=file_prefix+strtrim(worker_id,1)+".sav"

        ; Check for existence of file and whether it regular readable
        if ~FILE_TEST(task_file, /READ, /REGULAR) then begin
            MESSAGE, "ERROR - worker task file "+task_file+$
                     " does not exist! Aborting", /CONTINUE
            return, !null
        endif

        restore, task_file

        if work_items EQ !null then begin
            MESSAGE, "ERROR - Invalid task file "+task_file+"!"+$
                     " Aborting", /CONTINUE
            return, !null
        endif

        tasks=work_items

    endif else begin

    ; else if the complete task list is split across n_parts
    ; assume we are generating collation tasks for a task
    ; that was subdivided in an earlier processing stage/phase
    ; So construct the complete task list from all sub-/part-task
    ; files.

        ; Collect all the part-tasks from various files and place
        ; them into a single 2D array.
        file_suffix_start=worker_id*n_parts
        file_suffix_end=file_suffix_start+n_parts-1
        j=0
        for i=file_suffix_start,file_suffix_end do begin

            part_file=file_prefix+strtrim(i,1)+".sav"

            ; Check for existence of part task 
            ; file and whether it regular readable
            if ~FILE_TEST(part_file, /READ, /REGULAR) then begin
                MESSAGE, "ERROR - worker partial task file "+part_file+$
                         " does not exist! Aborting", /CONTINUE
                return, !null
            endif

            restore, part_file

            if work_items EQ !null then begin
                MESSAGE, "ERROR - Invalid part task file "+part_file+"!"+$
                         " Aborting", /CONTINUE
                return, !null
            endif

            ; If this is the first file we loaded
            ; allocate our 2D array based on the
            ; the retrieved task structure
            if i EQ file_suffix_start then begin
                n_tasks=N_ELEMENTS(work_items)
                sub_items=REPLICATE(work_items[0], n_tasks, n_parts)
            endif
            sub_items[0:(n_tasks-1),j]=work_items
            j=j+1
        endfor
        tasks=sub_items
    endelse

    return, tasks

end

;+
; Splits a tasks list up uniformly based on a specified number of worker
; processes
;
; This function uniformly splits up a list of tasks specified as an array of
; application defined structures based on the number of desired worker
; processes and saves the non-overlapping sub-sets of the array to separate
; work items files of a common prefix, suffixed with worker IDs.
;
; :Private:
;
; :Categories:
;   Parallel Computing.
;
; :Keywords:
;   dest_dir : in, optional, type=string
;       Directory path to save all the output files to
;   n_workers : in, required, type=integer
;       Desired number of worker processes being run.
;   task_params : in, required, type=array of structures
;       An array of application defined structures each representing the input
;       parameters for a single application task. See `generate_parallel_job`
;       for details.
;   fname_prefix : in, required, type=string
;       Prefix used to name work item output files. The resulting file names
;       will match the pattern "fname_prefix[0-9]+.sav", where "[0-9]+"
;       represents one or more digits matching worker IDs.
;
; :Post:
;   A number of work item files suffixed with worker IDs and prefixed with
;   a common name. The files constitute non-overlapping partial lists of
;   the input tasks_params list provided, distributed uniformly based on 
;   the number of workers request.
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
;   17/10/2012  Luke Domanski    Written
;   21/02/2014  Luke Domanski    Changed procedure name from save_worker_task_lists
;   04/07/2014  Luke Domanski    - Added error checking and reporting
;                                - Added defaults for optional parameter dest_dir
;-
pro segment_global_task_list, dest_dir=dest_dir, n_workers=n_workers,$
        task_params=task_params, fname_prefix=fname_prefix

    ; Provide defaults for optional parameters
    if ~KEYWORD_SET(dest_dir) || $
        (dest_dir EQ !NULL) || $
        (dest_dir EQ "") then dest_dir="."
    if ~KEYWORD_SET(fname_prefix) || $
        (fname_prefix EQ !NULL) || $
        (fname_prefix EQ "") then fname_prefix="worker_task_list"

    ; Check that we have been given something to split up
    if ~KEYWORD_SET(task_params) || $
       (task_params EQ !NULL) then begin
        MESSAGE, "ERROR - No task list task_params specified.\n" $
               + " Aborting!", /CONTINUE
        return
    endif

    ; Check for funky n_workers
    if ~KEYWORD_SET(n_workers) || $
       (n_workers EQ !NULL) || $
       (n_workers LT 1) then begin
        MESSAGE, "ERROR - Illegal negative or !NULL n_workers specified.\n" $
               + " Aborting!", /CONTINUE
        return
    endif

    ; find out the number of initial tasks
    n_tasks=size(task_params, /N_ELEMENTS)
    if n_tasks LT 1 then begin
        MESSAGE, "ERROR - Task list task_params has zero length.\n" $
               + " No work item file generated!", /CONTINUE
        return
    endif

    ; check number of works is less than tasks
    if n_tasks LT n_workers then begin
        MESSAGE, "WARNING - Number or workers exceeds number of tasks provided.\n" $
               + " Only producing work item files for some workers!", /CONTINUE
    endif

    ; figure out how many tasks will be
    ; assigned to each worker process
    n_tasks_p_worker=MAX([LONG(n_tasks)/LONG(n_workers), 1])
    n_tasks_left_over=MAX([n_tasks-(n_tasks_p_worker*LONG(n_workers)), 0])

    ; save the initial individual worker tasks to file
    for i=0,n_workers-1 do begin

        ; cover the case that we might have more
        ; workers than tasks
        if i LT n_tasks then begin
            ; find start and end of worker's task range
            ; allowing for n_tasks not being wholely
            ; divisible by n_workers
            k=n_tasks_p_worker*i
            if i LE n_tasks_left_over then k=k+i
            l=k+n_tasks_p_worker-1
            if i LT n_tasks_left_over then l=l+1

            ; get subset of task for worker
            work_items=task_params[k:l]

            ; save it to task file suffixed with worker ID
            save, work_items, filename=dest_dir+path_sep()+fname_prefix+STRTRIM(STRING(i),2)+".sav"
        endif
    endfor
    return
end

