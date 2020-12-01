if exists('g:loaded_freestyle')
  finish
endif
let g:loaded_freestyle = 1

let g:freestyle_settings = get(g:, 'freestyle_settings', {})
let s:no_maps = get(g:freestyle_settings, 'no_maps', 0)
let s:cursor_hl = get(g:freestyle_settings, 'cursor_hl', 'IncSearch')
let s:match_hl = get(g:freestyle_settings, 'match_hl', 'MoreMsg')
let s:cmd_no_bang = get(g:freestyle_settings, 'cmd_no_bang', 0)
let s:max_hl_count = get(g:freestyle_settings, 'max_hl_count', 600)

" Helper function for sorting a list of lists with 2 elements
function! s:list_comparer(i1, i2)
  if a:i1 == a:i2
    return 0
  elseif a:i1[0] == a:i2[0]
    return a:i1[1] > a:i2[1] ? 1 : -1
  else
    return a:i1[0] < a:i2[0] ? -1 : 1
  endif
endfunction

" Toggle a single cursor at line, col
function! s:toggle_cursor(ln, col)
  exec 'highlight! link FreestyleHL ' . s:cursor_hl
  let l:position = string([a:ln, a:col])
  let l:pattern = '\%'. a:ln . 'l\%' . a:col . 'c'
  let w:freestyle_data = get(w:, 'freestyle_data', {})
  if has_key(w:freestyle_data, l:position)
    try
      call matchdelete(w:freestyle_data[l:position])
    catch /E802\|E803/
    finally
      call remove(w:freestyle_data, l:position)
    endtry
  else
    " add only cursor, but no highlight if we exceed the limit
    if len(w:freestyle_data) < s:max_hl_count
      let w:freestyle_data[l:position] = matchadd('FreestyleHL', l:pattern)
    else
      let w:freestyle_data[l:position] = -1
    endif
  endif
endfunction

" When visual selection spans multiple lines add a cursor
" to all the selected lines on the column equal to the cursor position
" where the selection started (or ended if selection starts from bigger line
" nr)
function! s:toggle_cursors_v_multiline(sel)
  for i in range(a:sel['l_start'], a:sel['l_end'])
    call s:toggle_cursor(i, a:sel['c_start'])
  endfor
endfunction

" when visual selection is on one line add a cursor to the beginning
" of each search match of the selection
function! s:toggle_cursors_v_selection(sel)
  let l:start_layout = winsaveview()
  let l:w = strpart(
        \ getline('.'), a:sel['c_start'] - 1,
        \ a:sel['c_end'] - a:sel['c_start'])
        \ . strcharpart(strpart(getline('.'),
        \ a:sel['c_end'] - 1), 0, 1)
  normal! gg0
  if l:w == getline('1')[:len(l:w) - 1]
    call s:toggle_cursor(1, 1)
  endif
  while search('\V' . escape(l:w, '\'), '', line('$'))
    call s:toggle_cursor(line('.'), col('.'))
  endwhile
  call winrestview(l:start_layout)
  return l:w
endfunction

" remove w:freestyle_data, clear highlight, run cleanup
function! s:clear()
  let w:freestyle_data = get(w:, 'freestyle_data', {})
  for k in values(w:freestyle_data)
    try
      call matchdelete(k)
    catch /E802\|E803/
    endtry
  endfor
  unlet w:freestyle_data
  hi link FreestyleHL NONE

  call s:cleanup()
endfunction

function! s:toggle_cursors(m)
  call s:setup()

  let l:initial_bag = len(get(w:, 'freestyle_data', {}))
  let l:w = ''
  if a:m == 'n'
    call s:toggle_cursor(line('.'), col('.'))
  else
    let l:sel = {
        \ 'l_start': getpos("'<")[1],
        \ 'l_end': getpos("'>")[1],
        \ 'c_start': getpos("'<")[2],
        \ 'c_end': getpos("'>")[2]
        \ }
    if l:sel['l_start'] == l:sel['l_end']
      let l:w = s:toggle_cursors_v_selection(l:sel)
    else
      call s:toggle_cursors_v_multiline(l:sel)
    endif
  endif

  redraw

  let l:diff = len(w:freestyle_data) - l:initial_bag
  let l:s = l:diff == -1 || l:diff == 1 ? '' : 's'
  if l:diff > 0
    if l:w != ''
      echo 'Added ' . l:diff . ' cursor' . l:s . ' for pattern: '
            \ | exec 'echohl ' . s:match_hl |
            \ echon l:w | echohl NONE | echon ' len: ' . strchars(l:w)
    else
      echo 'Added ' . l:diff . ' cursor' . l:s
    endif
  else
    echo 'Removed ' . -l:diff . ' cursor' . l:s
  endif

  " make sure we clean up if there are no cursors left
  if w:freestyle_data == {}
    call s:clear()
  endif
endfunction

function! s:run(m)
  let l:ei = &eventignore
  exec 'setlocal eventignore=all'
  let l:start_layout = winsaveview()
  let w:freestyle_data = get(w:, 'freestyle_data', {})
  let l:normal = s:cmd_no_bang <= 0 ?
        \ 'normal ' : 'normal! '
  if w:freestyle_data == {}
    echo 'Freestyle: No cursors set!'
    return 0
  endif
  let l:cursors = map(keys(w:freestyle_data), {idx, val -> eval(val)})
  if a:m == 'v'
    let l:cursors =
          \ filter(l:cursors, {
          \   idx, val ->
          \   val[0] >= getpos("'<")[1] && val[0] <= getpos("'>")[1]})
  endif
  let l:msg = '[' . len(l:cursors) . '] Your ' . l:normal . 'command: '
  let l:cmd = input(l:msg, '')
  try
    for p in reverse(sort(l:cursors, 's:list_comparer'))
      call cursor(p[0], p[1])
      execute l:normal . l:cmd
    endfor
  catch /E471/
  endtry
  exec 'setlocal eventignore='. l:ei
  call s:clear()
  call winrestview(l:start_layout)
endfunction

function! s:setup()
  augroup FreestyleAuto
    autocmd BufLeave,WinLeave,WinNew <buffer> call s:clear()
    " :Startiy does not seem to trigger any Buf*/Win* event
    autocmd FileType *startify call s:clear()
  augroup END

  silent doautocmd User FreestyleBegin
endfunction

function! s:cleanup()
  autocmd! FreestyleAuto

  silent doautocmd User FreestyleEnd
endfunction

" --- Mappings ---
nnoremap <silent> <Plug>FreestyleToggleCursors
      \ :call <SID>toggle_cursors('n')<CR>
vnoremap <silent> <Plug>FreestyleToggleCursors
      \ :<C-u>call <SID>toggle_cursors('v')<CR>
nnoremap <silent> <Plug>FreestyleRun :call <SID>run('n')<CR>
vnoremap <silent> <Plug>FreestyleRun :<C-u>call <SID>run('v')<CR>
nnoremap <silent> <Plug>FreestyleClear :call <SID>clear()<CR>

if !s:no_maps
  map <C-j> <Plug>FreestyleToggleCursors
  map <C-k> <Plug>FreestyleRun
  map <C-x> <Plug>FreestyleClear
endif
