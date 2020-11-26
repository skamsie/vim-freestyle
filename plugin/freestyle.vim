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

" add a single cursor at line, col
function! s:toggle_cursor(ln, col)
  highlight FreestyleHL ctermbg=red ctermfg=0 guibg=#ff0000 guifg=#000000
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

" when visual selection spans multiple lines add a cursor to all the
" selected lines on the starting column of the first line
function! s:toggle_cursors_v_multiline(sel)
  let l:order = sort([a:sel['l_start'], a:sel['l_end']], 'n')
  for i in range(l:order[0], l:order[1])
    call s:toggle_cursor(i, a:sel['c_start'])
  endfor
endfunction

" when visual selection is on one line add a cursor to the beginning
" of each search match of the selection
function! s:toggle_cursors_v_selection(sel)
  let l:word = getline("'<")[a:sel['c_start'] -1:a:sel['c_end'] -1]
  let l:start_layout = winsaveview()
  normal! gg0
  while search('\V' . escape(l:word, '\'), '', line('$'))
    call s:toggle_cursor(line('.'), col('.'))
  endwhile
  if l:word == getline('1')[:len(l:word) - 1]
    call s:toggle_cursor(1, 1)
  endif
  call winrestview(l:start_layout)
endfunction

function FreestyleToggleN()
  call s:toggle_cursor(line('.'), col('.'))
endfunction

function! ToggleCursorV()
  let l:sel = {
        \ 'l_start': getpos("'<")[1],
        \ 'l_end': getpos("'>")[1],
        \ 'c_start': getpos("'<")[2],
        \ 'c_end': getpos("'>")[2]
        \ }
  if l:sel['l_start'] == l:sel['l_end']
    call s:toggle_cursors_v_selection(l:sel)
  else
    call s:toggle_cursors_v_multiline(l:sel)
  endif
endfunction

function! s:clear()
  let b:freestyle_data = get(b:, 'freestyle_data', {})
  for k in values(b:freestyle_data)
    call matchdelete(k)
  endfor
  unlet b:freestyle_data
endfunction

function! FreestyleRun()
  let l:start_layout = winsaveview()
  let b:freestyle_data = get(b:, 'freestyle_data', {})
  if b:freestyle_data == {}
    echo 'Freestyle: No cursors set!'
    return 0
  endif

  " Disable coc.nvim temporarily as it's making things slow
  if exists(':CocDisable')
    silent! CocDisable
  endif

  let l:msg = '[' . len(b:freestyle_data) . '] Your normal! command: '
  let l:cmd = input({'prompt': l:msg, 'default':''})
  let l:cursors = map(keys(b:freestyle_data), {idx, val -> eval(val)})

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

command! FSClear call s:clear()
vnoremap <C-j> :<c-u>call ToggleCursorV()<CR>
nnoremap <silent> <C-j> :call FreestyleToggleN()<CR>
nmap  <silent> <C-k> :call FreestyleRun()<CR>
