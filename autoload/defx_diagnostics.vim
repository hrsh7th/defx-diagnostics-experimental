let g:defx_diagnostics#definitions = [
      \   {
      \     'name': 'typescript',
      \     'markers': ['tsconfig.json'],
      \     'command': ['npx', 'tsc', '--noEmit']
      \   }
      \ ]

let g:defx_diagnostics_result = []
let g:defx_diagnostics_output = ''

let g:defx_diagnostics#parsers = {}

function! g:defx_diagnostics#parsers.typescript(definition, output)
  let result = split(a:output, '\n')
  let result = map(result, { _, l -> substitute(l, '^\(.*\)(\d\+,\d\+).*$', '\1', '') })
  let result = filter(result, { _, l -> strlen(l) })
  let result = map(result, { _, l -> a:definition['cwd'] . '/' . l })
  let g:defx_diagnostics_output = a:output
  let g:defx_diagnostics_result = result
  return result
endfunction

function! defx_diagnostics#find(path)
  for def in g:defx_diagnostics#definitions
    for marker in def['markers']
      let root_path = findfile(marker, fnamemodify(a:path, ':p:h') . ';')
      if root_path != ''
        return {
              \ 'name': def['name'],
              \ 'cmd': def['command'],
              \ 'cwd': fnamemodify(root_path, ':p:h'),
              \ }
      endif

      let root_path = finddir(marker, fnamemodify(a:path, ':p:h') . ';')
      if root_path != ''
        return {
              \ 'name': def['name'],
              \ 'cmd': def['command'],
              \ 'cwd': fnamemodify(root_path, ':p'),
              \ }
      endif
    endfor
  endfor
  return {}
endfunction

function! defx_diagnostics#parse(definition, output)
  return g:defx_diagnostics#parsers[a:definition['name']](a:definition, a:output)
endfunction

