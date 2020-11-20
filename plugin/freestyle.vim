function AddToFreestyle()
  let l:position = getcurpos()[1:2]
  let l:pattern ='\%'. l:position[0] . 'l\%' . l:position[1] . 'c'

  let l:match_id = matchadd("FreestyleHL", l:pattern)

  if !exists("g:freestyle_cursors")
    let g:freestyle_cursors = [l:position]
  else
    call add(g:freestyle_cursors, l:position)
  endif

  if !exists("b:freestyle_hl_ids")
    let b:freestyle_hl_ids = [l:match_id]
  else
    call add(b:freestyle_hl_ids, l:match_id)
  endif
endfunction

function GetFreestyle()
  let l:cmd = input('Your command: ')

  for p in reverse(sort(g:freestyle_cursors, 'ListComparer'))
    call cursor(p[0], p[1])
    execute "normal! " . l:cmd
  endfor

  for i in b:freestyle_hl_ids
    call matchdelete(i)
  endfor

  unlet b:freestyle_hl_ids
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

highlight FreestyleHL ctermbg=red ctermfg=0 guibg=#ff0000 guifg=#000000

"nmap ; :call AddToFreestyle()<CR>
