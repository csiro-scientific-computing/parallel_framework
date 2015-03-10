
function create_task_list
    t={task, filename_A:'', filename_B:''}
    g_task_list=REPLICATE({task}, 31)
    g_task_list.filename_A="/research/studyresults/"+STRTRIM(STRING(INDGEN(31)),2)+"_male.sav"
    g_task_list.filename_B="/research/studyresults/"+STRTRIM(STRING(INDGEN(31)),2)+"_female.sav"
    return, g_task_list
end

