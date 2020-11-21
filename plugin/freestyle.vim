function! ToggleFreestyleCursor()
  highlight FreestyleHL ctermbg=red ctermfg=0 guibg=#ff0000 guifg=#000000
  let l:position = string(getcurpos()[1:2])
  let l:pattern = '\%'. line('.') . 'l\%' . col('.') . 'c'

  let b:freestyle_data = get(b:, 'freestyle_data', {})
  if has_key(b:freestyle_data, l:position)
    call matchdelete(b:freestyle_data[l:position])
    call remove(b:freestyle_data, l:position)
  else
    let b:freestyle_data[l:position] = matchadd('FreestyleHL', l:pattern)
  endif
endfunction

function! Freestyle()
  let b:freestyle_data = get(b:, 'freestyle_data', {})
  if b:freestyle_data == {}
    echo 'Freestyle: No cursors set!'
    return 0
  endif

  let l:cmd = input('Your command: ')
  let l:cursors = map(keys(b:freestyle_data), {idx, val -> eval(val)})

  try
    for p in reverse(sort(l:cursors, 's:ListComparer'))
      call cursor(p[0], p[1])
      execute 'normal! ' . l:cmd
    endfor
  catch /E471/
    redraw | echo ''
  endtry

  for k in values(b:freestyle_data)
    call matchdelete(k)
  endfor

  unlet b:freestyle_data
endfunction

" Helper function for sorting a list of lists with 2 elements
function! s:ListComparer(i1, i2)
  if a:i1 == a:i2
    return 0
  elseif a:i1[0] == a:i2[0]
    return a:i1[1] > a:i2[1] ? 1 : -1
  else
    return a:i1[0] < a:i2[0] ? -1 : 1
  endif
endfunction
