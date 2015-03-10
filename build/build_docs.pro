
; Make a doc directory, and extract IDL html
; docs from the code comments.
FILE_MKDIR, 'doc/reference'
sfiles=FILE_SEARCH('./src','*.pro')
outfiles=FILE_BASENAME(sfiles, '.pro')+'.html'
for i=0,N_ELEMENTS(sfiles)-1 do $
MK_HTML_HELP, sfiles[i], 'doc/reference'+outfiles[i]
