function ps
    return, path_sep()
end

pro fully_qualified_path_ut::setup
    compile_opt strictarr
    RESOLVE_ROUTINE, "parfw_util", /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_FUNCTION="fully_qualified_path"
    CD, CURRENT=pwd
    full_dir=pwd+ps()+"fully"+ps()+"qualified"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"
    abs_dir="."+ps()+"a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"
    FILE_MKDIR, full_dir
    FILE_MKDIR, abs_dir
    OPENW, F, full_dir+ps()+"file.txt", /GET_LUN
    CLOSE, F
    FREE_LUN, F
    OPENW, A, abs_dir+ps()+"file.txt", /GET_LUN
    CLOSE, A
    FREE_LUN, F
end

pro fully_qualified_path_ut::teardown
    compile_opt strictarr
    CD, CURRENT=pwd
    FILE_DELETE, pwd+ps()+"fully", /RECURSIVE
    FILE_DELETE, "."+ps()+"a", /RECURSIVE
end

function fully_qualified_path_ut::test_Absolute_Path_To_Dir
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = pwd+ps()+"fully"+ps()+"qualified"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"
    p=STRPOS(testin, ":")
    if p NE -1 then testin = STRMID(testin, p+1, STRLEN(testin)-(p+1))
    expected = testin

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect handling of already fully qualified directory path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Absolute_Path_To_File
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = pwd+ps()+"fully"+ps()+"qualified"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"+ps()+"file.txt"
    p=STRPOS(testin, ":")
    if p NE -1 then testin = STRMID(testin, p+1, STRLEN(testin)-(p+1))
    expected = testin

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect handling of already fully qualified file path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Drive_Absolute_Path_To_Dir
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "C:"+pwd+ps()+"fully"+ps()+"qualified"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"

	switch !VERSION.OS_FAMILY of
		'windows':
		'Windows': begin
            expected = testin
			break
			end
		'unix':
		'Unix': begin
            expected = ""
			break
			end
	endswitch

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect handling of already fully qualified Drive path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Drive_Absolute_Path_To_File
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "C:"+pwd+ps()+"fully"+ps()+"qualified"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"+ps()+"file.txt"
    expected = testin

	switch !VERSION.OS_FAMILY of
		'windows':
		'Windows': begin
            expected = testin
			break
			end
		'unix':
		'Unix': begin
            expected = ""
			break
			end
	endswitch

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect handling of already fully qualified Drive path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Relative_Path_To_Dir_1
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"
    expected = pwd+ps()+testin

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect conversion of relative directory path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Relative_Path_To_File_1
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"+ps()+"file.txt"
    expected = pwd+ps()+testin

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect conversion of relative file path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Relative_Path_To_Dir_2
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "."+ps()+"a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"
    expected = pwd+ps()+STRMID(testin, 2, STRLEN(testin)-2)

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect conversion of relative directory path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Relative_Path_To_File_2
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "."+ps()+"a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"+ps()+"file.txt"
    expected = pwd+ps()+STRMID(testin, 2, STRLEN(testin)-2)

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect conversion of relative file path: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Complex_Relative_Pat_To_Dir
    compile_opt strictarr
    cd, "a"+ps()+"relative", CURRENT=pwd
    testin = ".."+ps()+".."+ps()+"a"+ps()+"."+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"
    expected = pwd+ps()+"a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect conversion of relative directory path: in %s, out %s, expected %s', $
            testin, result, expected
    cd, pwd
    return, 1
end

function fully_qualified_path_ut::test_Complex_Relative_Path_To_File
    compile_opt strictarr
    cd, "a"+ps()+"relative", CURRENT=pwd
    testin = ".."+ps()+".."+ps()+"a"+ps()+"."+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"+ps()+"file.txt"
    expected = pwd+ps()+"a"+ps()+"relative"+ps()+"path"+ps()+"to"+ps()+"a"+ps()+"dir"+ps()+"file.txt"

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect conversion of relative file path: in %s, out %s, expected %s', $
            testin, result, expected
    cd, pwd
    return, 1
end

function fully_qualified_path_ut::test_Non_Existent_Dir
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "non"+ps()+"existent"+ps()+"dir"
    expected = ""

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect handling of non-existent directory: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

function fully_qualified_path_ut::test_Non_Existent_File
    compile_opt strictarr
    CD, CURRENT=pwd
    testin = "non"+ps()+"existent"+ps()+"dir"+ps()+"file.txt"
    expected = ""

    result=fully_qualified_path(testin)
    assert, result eq expected, $
            'incorrect handling of non-existent file: in %s, out %s, expected %s', $
            testin, result, expected
    return, 1
end

pro fully_qualified_path_ut__define
    compile_opt strictarr
	struct = { fully_qualified_path_ut, inherits MGutTestCase }
end
