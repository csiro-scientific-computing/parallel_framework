;+
; Sums arrays A and B stored in specified data files and returns the mean and
; stddev of the result in named input variables
;
; :Params:
;   fname_arrayA : in, required, type=string
;       name of the data file containing array name `A`
;   fname_arrayB : in, required, type=string
;       name of the data file containing array name `B`
;   m : out, required, type=float
;       named variable where `mean(A+B)` will be stored
;   s : out, required, type=float
;       named variable where `stddev(A+B)` will be stored
;
; :Returns:
;   mean of `A+B` in input variable `m`, standard deviation of `A+B` in input
;   variable `s`
;
; :Uses:
;   mean, stddev
;-
pro sum_mean_stddev, fname_arrayA, fname_arrayB, m, s
    restore, fname_arrayA
    restore, fname_arrayB
    m=mean(A+B)
    s=stddev(A+B)
end
