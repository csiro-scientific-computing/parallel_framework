;+
; Runs sum_mean_stddev function on data files specified within fields of an
; input parameter structure, and returns the mean and stddev in fields of an
; output structure
;
; This function meets the interface requirements for use as a worker task
; function within the IDL Job Parallel Framework
;
; :Params:
;   task : in, required, type=structure
;       structure `{task, filename_A:'', filename_B:''}` containing the name of
;       data files to be pass to parameters `A` and `B` of the
;       `sum_mean_stddev` procedure
;   subdivision : in, required
;       not used, need to meet Job Parallel Framework interface requirements
;
; :Returns:
;   a structure::
;
;       {output, mean:0.0, stddev:0.0}
;
;   containing the `m` (mean) and `s` (standard deviation) outputs of the
;   `sum_mean_stddev` procedure.
;
; :Uses:
;   sum_mean_stddev
;-
function sum_mean_stddev_pfw, task, subdivision
    sum_mean_stddev, task.filename_A, task.filename_B, m, s
    out_item={output, mean:m, stddev:s}
    return, out_item
end
