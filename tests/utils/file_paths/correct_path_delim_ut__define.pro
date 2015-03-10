pro correct_path_delim_ut::setup
    compile_opt strictarr
    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_FUNCTION="correct_path_delim"
end

function nps
    sep=path_sep()
    if(sep eq "/") then begin
        return, "\"
    endif else begin
        return, "/"
    endelse
end

function ps
    return, path_sep()
end

function correct_path_delim_ut::test_Pre_Corrected
    compile_opt strictarr
    testin = ps()+"a"+ps()+"precorrected"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"
    expected = testin

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect handling of already correct path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function correct_path_delim_ut::test_Absolute_Path
    compile_opt strictarr
    testin = nps()+"absolute"+nps()+"path"+nps()+"to"+nps()+"a"+nps()+"file.txt"
    expected = ps()+"absolute"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect conversion of absolute path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function correct_path_delim_ut::test_URIAbsolute_Path_1
    compile_opt strictarr
    testin = "C:"+nps()+"absolute"+nps()+"path"+nps()+"to"+nps()+"a"+nps()+"file.txt"
    expected = "C:"+ps()+"absolute"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect conversion of absolute URI or Drive style path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function correct_path_delim_ut::test_URIAbsolute_Path_2
    compile_opt strictarr
    testin = "file:"+nps()+nps()+"absolute"+nps()+"path"+nps()+"to"+nps()+"a"+nps()+"file.txt"
    expected = "file:"+ps()+ps()+"absolute"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect conversion of absolute URI or Drive style path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function correct_path_delim_ut::test_Relative_Path_1
    compile_opt strictarr
    testin = "a"+nps()+"relative"+nps()+"path"+nps()+"to"+nps()+"a"+nps()+"file.txt"
    expected = "a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect conversion of relative path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function correct_path_delim_ut::test_Relative_Path_2
    compile_opt strictarr
    testin = "."+nps()+"a"+nps()+"relative"+nps()+"path"+nps()+"to"+nps()+"a"+nps()+"file.txt"
    expected = "."+ps()+"a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect conversion of relative path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function correct_path_delim_ut::test_Complex_Relative_Path
    compile_opt strictarr
    testin = ".."+nps()+".."+nps()+"a"+nps()+"."+nps()+"relative"+nps()+"path"+nps()+"to"+nps()+"a"+nps()+"file.txt"
    expected = ".."+ps()+".."+ps()+"a"+ps()+"."+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"file.txt"

    result=correct_path_delim(testin)
    assert, result eq expected, $
            'incorrect conversion of relative path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

pro correct_path_delim_ut__define
    compile_opt strictarr

    struct = { correct_path_delim_ut, inherits MGutTestCase }
end
