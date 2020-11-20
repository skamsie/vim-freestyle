function AddToFreestyle()
  let l:position = getcurpos()[1:2]
  if !exists("g:freestyle_cursors")
    let g:freestyle_cursors = [l:position]
  else
    call add(g:freestyle_cursors, l:position)
  endif

  let pattern ='\%'. line('.') . 'l\%' . col('.') . 'c'
  let w:free_match = matchadd("FreeRed", pattern)
endfunction

function GetFreestyle()
  let l:cmd = input('Your command: ')

  for p in reverse(sort(g:freestyle_cursors, 'ListComparer'))
    call cursor(p[0], p[1])
    execute "normal!" . l:cmd
  endfor
  call matchdelete(w:free_match)
  unlet w:free_match

  let g:freestyle_cursors = []
endfunction

" Helper function for sorting a list of lists with 2 elements
function ListComparer(i1, i2)
  if a:i1 == a:i2
    return 0
  elseif a:i1[0] == a:i2[0]
    return a:i1[1] > a:i2[1] ? 1 : -1
  else
    return a:i1[0] < a:i2[0] ? -1 : 1
  endif
endfunction

highlight FreeRed ctermbg=red ctermfg=0 guibg=#ff0000 guifg=#000000

"nmap ; :call AddToFreestyle()<CR>
