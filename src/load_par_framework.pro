; docformat = 'rst'
;+
; Load the IDL Job Parallel Framework
;
; This procedure provides a single mechanism for loading the IDL Parallel
; Framework, regardless of the presence of a binary only, source only, or
; source+binary installation, or whether the function is being called from
; IDL or GDL. The function favours loading the precompiled binary of the
; library where available and possible, otherwise it falls back to compiling
; from a source definition
;
; :Categories:
;   Parallel Computing
;
; :Uses:
;   load_module, load_generator_plugin
;
; :Keywords:
;   VERBOSE: in, optional, type=boolean
;       Print verbose information of loading of framework module
;
; :Author:
;   Luke Domanski, CSIRO Advanced Scientific Computing (2013)
;
; :History:
;   .. table::
;
;      =========== ================ ============================================
;      Date        Author           Comment
;      =========== ================ ============================================
;      24/06/2013  Luke Domanski    Written
;-
@parfw_util
pro load_par_framework, VERBOSE=verbose
    load_module, module_name="par_framework", VERBOSE=verbose
    load_generator_plugin, plugin_ident="pbs_job_generator"
end

