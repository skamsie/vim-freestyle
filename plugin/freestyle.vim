function! ToggleFreestyleCursor()
  let l:position = string(getcurpos()[1:2])
  let l:pattern = '\%'. line('.') . 'l\%' . col('.') . 'c'

  let g:freestyle_data = get(g:, 'freestyle_data', {})
  if has_key(g:freestyle_data, l:position)
    call matchdelete(g:freestyle_data[l:position])
    call remove(g:freestyle_data, l:position)
  else
    let g:freestyle_data[l:position] = matchadd('FreestyleHL', l:pattern)
  endif
endfunction

function! GetFreestyle()
  let l:cmd = input('Your command: ')
  let l:cursors = map(keys(g:freestyle_data), {idx, val -> eval(val)})

  for p in reverse(sort(l:cursors, 'ListComparer'))
    call cursor(p[0], p[1])
    execute "normal! " . l:cmd
  endfor

  for k in values(g:freestyle_data)
    call matchdelete(k)
  endfor

  unlet g:freestyle_data
endfunction

" Helper function for sorting a list of lists with 2 elements
function! ListComparer(i1, i2)
  if a:i1 == a:i2
    return 0
  elseif a:i1[0] == a:i2[0]
    return a:i1[1] > a:i2[1] ? 1 : -1
  else
    return a:i1[0] < a:i2[0] ? -1 : 1
  endif
endfunction

highlight FreestyleHL ctermbg=red ctermfg=0 guibg=#ff0000 guifg=#000000
