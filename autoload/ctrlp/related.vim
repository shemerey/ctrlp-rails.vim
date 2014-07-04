" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:ts=2:sw=2:sts=2:nu

if exists('g:loaded_ctrlp_related') && g:loaded_ctrlp_related
  finish
endif
let g:loaded_ctrlp_related = 1


" Utility Functions {{{1
let s:app_prototype = {}

function! s:add_methods(namespace, method_names)
  for name in a:method_names
    let s:{a:namespace}_prototype[name] = s:function('s:'.a:namespace.'_'.name)
  endfor
endfunction

function! s:function(name)
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'),
        \ '<SNR>\d\+_'),''))
endfunction

function! s:sub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

function! s:gsub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:startswith(string,prefix)
  return strpart(a:string, 0, strlen(a:prefix)) ==# a:prefix
endfunction

function! s:endswith(string,suffix)
  return strpart(a:string, len(a:string) - len(a:suffix), len(a:suffix)) ==# a:suffix
endfunction

function! s:uniq(list) abort
  let i = 0
  let seen = {}
  while i < len(a:list)
    if (a:list[i] ==# '' && exists('empty')) || has_key(seen,a:list[i])
      call remove(a:list,i)
    elseif a:list[i] ==# ''
      let i += 1
      let empty = 1
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
endfunction

function! s:getlist(arg, key)
  let value = get(a:arg, a:key, [])
  return type(value) == type([]) ? copy(value) : [value]
endfunction

function! s:split(arg, ...)
  return type(a:arg) == type([]) ? copy(a:arg) : split(a:arg, a:0 ? a:1 : "\n")
endfunction

function! s:lencmp(i1, i2) abort
  return len(a:i1) - len(a:i2)
endfunc

function! s:escarg(p)
  return s:gsub(a:p,'[ !%#]','\\&')
endfunction

function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

function! s:app_path(...) dict
  return join([self.root]+a:000,'/')
endfunction

function! s:app_has_path(path) dict
  return getftime(self.path(a:path)) != -1
endfunction

call s:add_methods('app', ['path','has_path'])

function! s:warn(str)
  echohl WarningMsg
  echomsg a:str
  echohl None
  let v:warningmsg = a:str
endfunction

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

function! s:pluralize(word)
  return a:word . 's'
endfunction

function! s:singularize(word)
  let word = a:word
  if word =~? '\.js$' || word == ''
    return word
  endif
  let word = s:sub(word,'eople$','ersons')
  let word = s:sub(word,'%([Mm]ov|[aeio])@<!ies$','ys')
  let word = s:sub(word,'xe[ns]$','xs')
  let word = s:sub(word,'ves$','fs')
  let word = s:sub(word,'ss%(es)=$','sss')
  let word = s:sub(word,'s$','')
  let word = s:sub(word,'%([nrt]ch|tatus|lias)\zse$','')
  let word = s:sub(word,'%(nd|rt)\zsice$','ex')
  return word
endfunction
" }}}1

function! s:perform_search_for(walkers)
  let list = []
  for walker in a:walkers
    let list = list + split(system('{ find ' . walker . ' -type f } 2> /dev/null'), '\n')
  endfor

  return s:uniq(list)
endfunction

function! s:for_controllers(file)
  let controller = substitute(a:file, "_controller", "", "")
  let model = s:singularize(controller)

  let walkers = [
        \  'app/models/'     . model      . '*',
        \  'app/models/**/'  . model      . '*',
        \  'app/helpers/'    . controller . '**',
        \  'app/helpers/**/' . controller . '**',
        \  'app/views/'      . controller . '/**',
        \  'app/views/**/'   . controller . '/**',
        \  'test/'           . controller . '**',
        \  'test/**/'        . controller . '**',
        \  'spec/'           . controller . '**',
        \  'spec/**/'        . controller . '**'
        \  ]

  return s:perform_search_for(walkers)
endfunction

function! s:for_models(file)
  let model = a:file
  let controller = s:pluralize(model)
  let walkers = [
        \ 'app/controllers/'    . controller . '**',
        \ 'app/controllers/**/' . controller . '**',
        \ 'app/models/'         . model      . '**',
        \ 'app/models/**/'      . model      . '**',
        \ 'app/helpers/'        . controller . '**',
        \ 'app/helpers/**/'     . controller . '**',
        \ 'app/views/'          . controller . '/**',
        \ 'app/views/**/'       . controller . '/**'
        \ ]

  return s:perform_search_for(walkers)
endfunction

function! s:for_helpers(file)
  let helper = substitute(a:file, "_helper", "", "")
  let model = s:singularize(helper)
  let walkers = [
        \ 'app/models/'         . model  . '*',
        \ 'app/models/**/'      . model  . '*',
        \ 'app/controllers/'    . helper . '**',
        \ 'app/controllers/**/' . helper . '**',
        \ 'app/views/'          . helper . '/**',
        \ 'app/views/**/'       . helper . '/**',
        \ 'test/'               . helper . '**',
        \ 'test/**/'            . helper . '**',
        \ 'spec/'               . helper . '**',
        \ 'spec/**/'            . helper . '**'
        \ ]

  return s:perform_search_for(walkers)
endfunction

function! s:for_views()
  let working_directory_base = s:view_base_directory
  let model = s:singularize(s:split(working_directory_base, '/')[-1])
  let controller = model

  let walkers = [
        \ 'app/models/'             . model      . '**',
        \ 'app/models/**/'          . model      . '**',
        \ 'app/views/'              . working_directory_base . '/**',
        \ 'app/helpers/'            . controller . '**',
        \ 'app/helpers/**/'         . controller . '**',
        \ 'app/assets/javascripts/' . model      . '**',
        \ 'app/assets/stylesheets/' . model      . '**',
        \ 'app/controllers/'        . controller . '**',
        \ 'app/controllers/**/'     . controller . '**',
        \ 'test/'                   . controller . '**',
        \ 'test/**/'                . controller . '**',
        \ 'spec/'                   . controller . '**',
        \ 'spec/**/'                . controller . '**'
        \ ]

  return s:perform_search_for(walkers)
endfunction

function! s:for_tests(test)
  "   if '_controller' in base_file_name:
  "   controller = base_file_name.replace('_controller', '').replace('_spec', '').replace('_test', '').replace('test_', '')
  "   model = Inflector(English).singularize(controller).lower()
  " else:
  "   model = base_file_name.replace('_spec', '').replace('test_', '')
  "   controller = Inflector(English).pluralize(model).lower()

  let walkers = [
        \ 'app/controllers/'    . controller . '**',
        \ 'app/controllers/**/' . controller . '**',
        \ 'app/models/'         . model      . '**',
        \ 'app/models/**/'      . model      . '**',
        \ 'app/helpers/'        . controller . '**',
        \ 'app/helpers/**/'     . controller . '**',
        \ 'app/views/'          . controller . '/**',
        \ 'app/views/**/'       . controller . '/**'
        \ ]

endfunction

function! s:current_file_path()
  return  expand("%:h")
endfunction

function! s:current_file_name()
  return expand("%:t:r")
endfunction

function! s:view_base_directory()
  let path = expand("%:h:r:r:r:r")
  return substitute(path, "app/views/", "", "")
endfunction

function! s:list_of_related_files()
  let file_path = s:current_file_path
  let file_name = s:current_file_name

  let results = []

  if file_path =~ 'app/controllers'
    let results = s:for_controllers(file_name)
  elseif file_path =~ 'app/models'
    let results = s:for_models(file_name)
  elseif file_path =~ 'app/helpers'
    let results = s:for_helpers(file_name)
  elseif file_path =~ 'app/views'
    let results = s:for_views()
  endif

  return results
endfunction

" command! DoSomething :call <SID>doSomething()
" nmap <D-b> :so %<CR>:DoSomething<CR>

" ------------------- CtrlP extension part   ---------------------------------------------------------{{{
let s:related = {
      \  'init':   'ctrlp#related#init()',
      \  'enter':  'ctrlp#related#enter()',
      \  'accept': 'ctrlp#related#accept',
      \  'lname':  'related',
      \  'sname':  'relate',
      \  'type':   'path',
      \}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:related)
else
  let g:ctrlp_ext_vars = [s:related]
endif

function! ctrlp#related#enter()
  let [s:current_file_path, s:current_file_name, s:view_base_directory] = [s:current_file_path(), s:current_file_name(), s:view_base_directory()]
endfunction

function! ctrlp#related#init()
 return s:list_of_related_files()
endfunc

function! ctrlp#related#accept(mode, str)
  call ctrlp#acceptfile(a:mode,  a:str)
endfunc

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#related#id()
  return s:id
endfunction
"}}}
