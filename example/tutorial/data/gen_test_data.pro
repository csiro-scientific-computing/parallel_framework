pro gen_test_data
    FILE_MKDIR, "./research/studyresults"
    seed=1
    for i=0,31 do begin
        mean_var=RANDOMU(seed,2)
        A=RANDOMN(seed, 1000)+(3*mean_var[0])
        B=RANDOMN(seed+500, 1000)+(2*mean_var[1])
        save, A, FILENAME='./research/studyresults/'+STRTRIM(i,2)+'_male.sav'
        save, B, FILENAME='./research/studyresults/'+STRTRIM(i,2)+'_female.sav'
    endfor
end

