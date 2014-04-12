if exists('g:loaded_ctrlp_models') && g:loaded_ctrlp_models
  finish
endif
let g:loaded_ctrlp_models = 1

let s:models_var = {
\  'init':   'ctrlp#models#init()',
\  'accept': 'ctrlp#models#accept',
\  'lname':  'models',
\  'sname':  'models',
\  'type':   'path',
\}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:models_var)
else
  let g:ctrlp_ext_vars = [s:models_var]
endif

function! ctrlp#models#init()
  return split(system("if [ -d app/models ]; then ; find app/models -type f -iname '*.rb' | sed 's_app/models/__' ; fi | awk '{print length, $0}' | sort -n | cut -d ' ' -f2-"), "\n")
endfunc

function! ctrlp#models#accept(mode, str)
  call ctrlp#acceptfile(a:mode, 'app/models/' . a:str)
endfunc

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#models#id()
  return s:id
endfunction
