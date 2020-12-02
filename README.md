# vim-freestyle

<img src="https://user-images.githubusercontent.com/7014744/100924505-0587bd80-34e1-11eb-8192-af8717aa9fb4.gif" width="650" height="437"/>

Freestyle is a vim plugin that allows normal mode commands to be run in bulk for multiple
locations in the buffer at once.

It is useful for normal commands that are too complex to be repeated with the `.` operator,
but simple enough to be achieved without regular expressions. It also leverages the visual
block mode by allowing commands to be run on noncontiguous selections.

## Installation

Use your favorite plugin manager

`Plug 'skamsie/vim-freestyle'`

## Usage

  - the following examples assume the default key mappings; see **Customization** if you want to change them  
  - for lack of a better word, the term 'cursor' is used to denote a saved position in the buffer
    (line, column)
  - you can check the help file at any time with `:help freestyle`
    
Use `<C-j>` to add a freestyle cursor at the current cursor location. The location will be
highlighted. To remove a cursor use the same key over the highlighted cursor.

After the desired number of cursors was added, use the mapping for inputing the command `<C-k>`. In the command line
type the command and then run it by hitting the enter key `<CR>`. If the command uses special keys,
like `CTRL`, `ESC`, `ENTER`, etc, you need to use `<C-v>` before entering the special key, see `:he c_CTRL-V`
for more details.

```
1) [<n>] Your normal! command: ciwfoo
2) [<n>] Your normal command: wbi"`^[`ea"
```

1) Will run `ciwfoo` at all the locations where the cursors were added. The `<n>`
represents the number of cursors where the command applies. `normal!` means
the command is run disregarding the user key mappings.
2) `^[` means the Escape key. It was added with the sequence `<C-v><Esc>`.
`normal` means the command is considering the user mappings.

Freestyle commands can be used on normal mode and visual mode. Depending
on the mode and the selected text, they do something different.

### Normal mode

`<C-j>` Will toggle cursor at the current vim cursor postion.  
`<C-k>` Will trigger command input for all the added cursors.  
`<C-q>` Remove all cursors

### Visual mode

`<C-j>` When visual selection spans multiple lines, it will toggle a cursor to all the selected
lines on the column equal to the cursor position where the selection started (or ended if selection
starts from bigger line nr). When visual selection is on the same line, it will toggle a cursor to
the beginning of the selected pattern throughout the buffer.  
`<C-k>` When visually selecting one or multiple lines, it will only consider the cursors within
those selected lines for the normal command.  
`<C-q>` Remove all cursors

**Example**

```vim
" Given the following text
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod
tempor incididunt labore dolore magna aliqua. Ut enim ad minim.
Lorem ipsum dolor sit amet, adipiscing elit sit consectetur sed.

" Go on the first occurence of 'consectetur' on the first 'c' and do <C-v>jj<C-j>
" Go on any occurence of 'sit' and do viw<C-j>
" You will have 6 cursors, now do <C-k>wbi{{<C-v><Esc>ea}}<CR>
Lorem ipsum dolor {{sit}} amet, {{consectetur}} adipiscing elit, sed eiusmod
tempor incididunt labore {{dolore}} magna aliqua. Ut enim ad minim.
Lorem ipsum dolor {{sit}} amet, {{adipiscing}} elit {{sit}} consectetur sed.
```

### Remove cursors

To remove a single cursor, use `<C-j>` on a previously added cursor. On
'buffer leave' and 'window leave' events all cursors are removed. They can
also be removed at any time with `<C-q>`

Note that the order in which the command is executed is from bottom to top, no matter
in which order they were added. For example, given 3 cursors at these locations

```
a: line: 33, col: 21
b: line: 34, col: 12
c: line: 34, col: 2
```

the order of execution will be b,c,a

## Customization

You can change the freestyle default settings by adding the following global
variable in your vimrc `g:freestyle_settings`. It should be a dictionary with
one or more of the following keys:

  `no_maps` - set to 1 if you want to disable default key mappings  
  `cursor_hl` - specify the highlight group for the cursors  
  `match_hl` - specify the highlight group for the selected pattern  
  `normal_no_bang` - set to 1 to use normal instead of normal! (you can then use commands like `ysiw"` for example)   
  `max_hl_count` - maximum number of cursor highlights; the number of cursors
  will not be affected, just their highlights. This prevents vim from becoming very slow if thousands of cursors are added  
    
```vim
let g:freestyle_settings = {
      \ 'no_maps': 0,
      \ 'cursor_hl': 'IncSearch',
      \ 'match_hl': 'MoreMsg',
      \ 'normal_no_bang': 0,
      \ 'max_hl_count': 600
      \ }
      
" change the default key mappings using the following pattern
map <C-j> <Plug>FreestyleToggleCursors
map <C-k> <Plug>FreestyleRun
map <C-q> <Plug>FreestyleClear
```
