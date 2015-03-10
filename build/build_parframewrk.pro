
.FULL_RESET_SESSION
; compile the framework plugins and save
; the binaries to the ./bin/plugins directory
FILE_MKDIR, 'bin/plugins'
PUSHD, 'src/plugins'
plugins=FILE_SEARCH('*.pro')
binfiles=FILE_BASENAME(plugins, '.pro')+'.sav'
rnames=FILE_BASENAME(plugins, '.pro')
comp_n_save=STRARR(N_ELEMENTS(plugins))
for i=0,N_ELEMENTS(plugins)-1 do $
    comp_n_save[i] = 'RESOLVE_ROUTINE, "'+rnames[i]+'", /COMPILE_FULL_FILE & SAVE, /ROUTINES, FILENAME="../../bin/plugins/'+binfiles[i]+'"'
for i=0,N_ELEMENTS(plugins)-1 do $
    void=EXECUTE(comp_n_save[i])
POPD

; compile the IDL parallel framework
; save the compiled IDL binary for later use
CD, 'src'
.COMPILE parfw_util.pro
.COMPILE par_framework.pro
SAVE, /ROUTINES, FILENAME='../bin/par_framework.sav'

.FULL_RESET_SESSION
.COMPILE parallel_worker.pro
SAVE, /ROUTINES, FILENAME='../bin/parallel_worker.sav'

.FULL_RESET_SESSION
.COMPILE parfw_runner.pro
SAVE, /ROUTINES, FILENAME='../bin/parfw_runner.sav'
CD, '../'

