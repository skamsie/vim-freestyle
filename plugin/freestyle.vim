" helper function for sorting a list of lists with 2 elements
function! s:list_comparer(i1, i2)
  if a:i1 == a:i2
    return 0
  elseif a:i1[0] == a:i2[0]
    return a:i1[1] > a:i2[1] ? 1 : -1
  else
    return a:i1[0] < a:i2[0] ? -1 : 1
  endif
endfunction

" toggle a single cursor at line, col
function! s:toggle_cursor(ln, col)
  execute 'highlight link FreestyleHL IncSearch'
  let l:position = string([a:ln, a:col])
  let l:pattern = '\%'. a:ln . 'l\%' . a:col . 'c'
  let b:freestyle_data = get(b:, 'freestyle_data', {})
  if has_key(b:freestyle_data, l:position)
    call matchdelete(b:freestyle_data[l:position])
    call remove(b:freestyle_data, l:position)
  else
    let b:freestyle_data[l:position] = matchadd('FreestyleHL', l:pattern)
  endif
endfunction

" when visual selection spans multiple lines add a cursor
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
  while search('\V' . escape(l:w, '\'), '', line('$'))
    call s:toggle_cursor(line('.'), col('.'))
  endwhile
  if l:w == getline('1')[:len(l:w) - 1]
    call s:toggle_cursor(1, 1)
  endif
  call winrestview(l:start_layout)
  return l:w
endfunction

function! s:clear()
  let b:freestyle_data = get(b:, 'freestyle_data', {})
  for k in values(b:freestyle_data)
    call matchdelete(k)
  endfor
  unlet b:freestyle_data
endfunction

function! s:toggle_cursors(m) range
  let l:initial_bag = len(get(b:, 'freestyle_data', {}))
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
  let l:diff = len(b:freestyle_data) - l:initial_bag
  let l:s = l:diff == -1 || l:diff == 1 ? '' : 's'
  if l:diff > 0
    if l:w != ''
      echo 'Added ' . l:diff . ' cursor' . l:s . ' for pattern: '
            \ | echohl MoreMsg | echon l:w | echohl NONE |
            \ echon ' len: ' . strchars(l:w)
    else
      echo 'Added ' . l:diff . ' cursor' . l:s
    endif
  else
    echo 'Removed ' . -l:diff . ' cursor' . l:s
  endif
endfunction

function! s:run(m) range
  let l:start_layout = winsaveview()
  let b:freestyle_data = get(b:, 'freestyle_data', {})
  if b:freestyle_data == {}
    echo 'Freestyle: No cursors set!'
    return 0
  endif
  let l:f = a:firstline
  let l:l = a:lastline
  let l:cursors = map(keys(b:freestyle_data), {idx, val -> eval(val)})
  if a:m == 'v'
    let l:cursors = filter(l:cursors,
          \ {idx, val -> val[0] >= l:f && val[0] <= l:l})
  endif
  let l:msg = '[' . len(l:cursors) . '] Your normal! command: '
  let l:cmd = input({'prompt': l:msg, 'default': ''})
  " Disable coc.nvim temporarily as it's making things slow
  if exists(':CocDisable')
    silent! CocDisable
  endif
  try
    for p in reverse(sort(l:cursors, 's:list_comparer'))
      call cursor(p[0], p[1])
      execute 'normal! ' . l:cmd
    endfor
  catch /E471/
  endtry
  if exists(':CocEnable')
    silent! CocEnable
  endif
  call s:clear()
  call winrestview(l:start_layout)
endfunction

" --- Commands
command! -range FreestyleRunV <line1>,<line2>call s:run('v')
command! -range FreestyleToggleCursorsV call s:toggle_cursors('v')
command! FreestyleToggleCursorsN call s:toggle_cursors('n')
command! FreestyleRunN call s:run('n')
command! FSClear call s:clear()

" --- Mappings
nnoremap <silent><C-k> :FreestyleRunN<cr>
vnoremap <silent><C-k> :FreestyleRunV<cr>
nnoremap <silent><C-j> :FreestyleToggleCursorsN<cr>
vnoremap <silent><C-j> :FreestyleToggleCursorsV<cr>
