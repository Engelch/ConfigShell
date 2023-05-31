" vi -R <<file>>  open the file in RO-mode
"
" gwip      format current paragraph
" gwG       format document from current line to EOF
"           use set textwidth=80, defaulting to 78

" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
let g:ale_completion_enabled = 1

" ====================================================
scriptencoding utf-8
set nofoldenable

" ==========================================================
filetype plugin indent on

set autowriteall " Like 'autowrite', but also used for commands ":edit", ":enew", ":quit",
  " ":qall", ":exit", ":xit", ":recover" and closing the Vim window.
  " Setting this option also implies that Vim behaves like 'autowrite' has
  " been set.

" Backup stuff
set backupdir=~/.vim/backup
set directory=~/.vim/swap
set undodir=~/.vim/undo
set undofile
set undolevels=1000
set undoreload=10000
" Set the commands to save in history default number is 20.
set history=1000

" https://www.freecodecamp.org/news/vimrc-configuration-guide-customize-your-vim-editor/

" Enable auto completion menu after pressing TAB.
set wildmenu

" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest

" There are certain files that we would never want to edit with Vim.
" Wildmenu will ignore files with these extensions.
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Clear status line when vimrc is reloaded.
set statusline=

" Status line left side.
set statusline+=\ %F\ %M\ %Y\ \%R\ col:%c\ %p%%

" Show the status on the second to last line.
set laststatus=2

" Go syntax highlighting
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_operators = 1

" Auto formatting and importing
let g:go_fmt_autosave = 1
let g:go_fmt_command = "goimports"

" Status line types/signatures
let g:go_auto_type_info = 1

" ========================================================== completor
" Enable lsp for go by using gopls
let g:completor_filetype_map = {}
let g:completor_filetype_map.go = {'ft': 'lsp', 'cmd': 'gopls -remote=auto'}"
" ========================================================== end
syntax on
filetype on

" Highlight cursor line underneath the cursor horizontally.
set cursorline

" Highlight cursor line underneath the cursor vertically.
set cursorcolumn

:set ignorecase
:set smartcase
:set incsearch
:set hlsearch

:set tabstop=3     " tabs are at proper location"
:set shiftwidth=3  " indenting is 4 spaces"
:set autoindent    " turns it on"
:set smartindent   " does the right thing (mostly) in programs"
:set cindent       " stricter rules for C programs"
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

:set backup       " makes tilde file backups"
:set mouse=a      " allow mouse to change cursor position"
:set showmatch	   " briefly jump to matching brackets"

:set number
:set expandtab
:set noswapfile   " disable the swap file as required for some docker directories

" *               - search for word currently under cursor"
" g*              - search for partial word under cursor "
"                   (repeat with n)"
" ctrl-o, ctrl-i  - go through jump locations"
" [I              - show lines with matching word under cursor"

if has("spell")
  " turn spelling on by default
  "set spell

  " toggle spelling with F12 key
  map <F12> :set spell!<CR><Bar>:echo "Spell Check: " . strpart("OffOn", 3 * &spell, 3)<CR>

  " they were using white on white
  highlight PmenuSel ctermfg=black ctermbg=lightgray

  " limit it to just the top 10 items
  set sps=best,10
endif

" if you manually add to your wordlist, you need to regenerate it:
"     :mkspell! ~/.vim/spell/en.latin1.add
" some useful keys for spellchecking:
"   ]s       - forward to misspelled/rare/wrong cap word
"  [s       - backwards

"  ]S       - only stop at misspellings
"  [S       - in other direction

"  zG       - accept spelling for this session
"  zg       - accept spelling and add to personal dictionary

"  zW       - treat as misspelling for this session
"  zw       - treat as misspelling and add to personal dictionary

"  z=       - show spelling suggestions

"  :spellr  - repeat last spell replacement for all words in window

