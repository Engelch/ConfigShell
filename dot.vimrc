" = READ ONLY MODE =======================================================
" vi -R <<file>>  open the file in RO-mode

" = SHOW/REMOVE TABS =======================================================
" /\t  to show tabs
" :retab to replace tabs with spaces
" test line with tabs 	bla
" :set list to show EOL and Tabs as ^I, :set nolist to remove this mode again
"
" = previous delete/yank  =======================================================
" :reg to show the previous deletes (vim clipboards) = :registers
" To add the 2nd register again below the current line:  "2p
"
" There is a YankRing plugin if you are also interested in previous yanks
" (copy clipboard).
"
" = PARAGRAPH FORMATTING =======================================================
"
" gwip      format current paragraph
" gwG       format document from current line to EOF
"           use set textwidth=80, defaulting to 78

" = RELOAD VIMRC WITHOUT STOPPING VI =======================================================
" reload .vimrc if file is in the active buffer:  :so %
" 
" surround plugin: yss to impact a full line.
"                  ysip to impact a paragraph
"                  ysi) to impact a sentence
" iw, aw :- inside/around word
" is, as :- inside/around sentence
" ip, ap :- inside/around paragraph
" i",i',a",a' :- e.g. ci" will delete everything inside double-quotes
" i[,i(,i{,a(,a[,a{
" it,at  :- tags
"
" % represents the active buffer, can also be used to replace 1,$
"
" :ls list buffer
" :b1..n change to buffer n

" PLUGINS ----------------------------------------------------------------
" removed as plugins are directly install using the vim-internal package
" manager. Packages are in the directory ~/.vim/pack/<name>/{start,opt}/<plugin>
" If the parent directory is called start, then the plugin is loaded
" automatically. If it is called opt, then the plugin is loaded only when
" called with :packadd <plugin-name>.

" MAPPINGS ---------------------------------------------------------------
" 3 different ways to change keyboard mappings
"     nnoremap – Allows you to map keys in normal mode.
"     inoremap – Allows you to map keys in insert mode.
"     vnoremap – Allows you to map keys in visual mode.
"
" Mapleader will allow you set a key unused by Vim as the <leader> key.
" The leader key, in conjunction with another key, will allow you to create new shortcuts.
" 
" The backslash key is the default leader key but some people change it to a comma ",".
" let mapleader = ","

" With the leader key mapped to backslash, I can use it like this:

" Turn off search highlighting by pressing \\.
nnoremap <leader>\ :nohlsearch<CR>

" move between windows, default ^w h/j/k/l   or   ^w left-arrow/...
nnoremap <C-H> <C-W>h
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l

" use control left/... to move between tabs
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>

map <F2> :w<CR>
map <S-F2> :wq<CR>

" show spaces as ., enabled with :set list, disabled w/ :set nolist
set lcs+=space:· 
let b:togglelist = 0
function ToggleList()
  echom "hi"
 if b:togglelist == 0
   :set list
   let b:togglelist = 1
 else
   :set nolist
   let b:togglelist = 0
 endif
endfunction
map <F3> :call ToggleList()<CR>

map <F4> :noh<CR>

" ====================================================
scriptencoding utf-8
set nofoldenable
set nocompatible

" = ALE plugin specifics =======================================================
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
let g:ale_completion_enabled = 1

" nerdtree show number of lines per file
let g:NERDTreeFileLines = 1

" ==========================================================
filetype plugin indent on

"set autowriteall " Like 'autowrite', but also used for commands ":edit", ":enew", ":quit",
  " ":qall", ":exit", ":xit", ":recover" and closing the Vim window.
  " Setting this option also implies that Vim behaves like 'autowrite' has
  " been set.

" Backup stuff
" :set backup       " makes tilde file backups"
set backupdir=~/.vim/backup
set directory=~/.vim/swap
set undodir=~/.vim/undo
set undofile
set undolevels=1000
set undoreload=10000
" Set the commands to save in history default number is 20.
set history=1000

" https://www.freecodecamp.org/news/vimrc-configuration-guide-customize-your-vim-editor/

set nocp
filetype plugin on

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
set statusline+=\ %M\ %F\ %M\ %Y\ \%R\ col:%c\ ASCII_Unic/hex:%b/0x%B\ %p%%
"⌘
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
" set cursorline

" Highlight cursor line underneath the cursor vertically.
" set cursorcolumn

:set ignorecase
:set smartcase
:set incsearch
:set hlsearch

:set tabstop=2     " tabs are at proper location"
:set shiftwidth=2  " indenting is 4 spaces"
:set autoindent    " turns it on"
:set smartindent   " does the right thing (mostly) in programs"
:set cindent       " stricter rules for C programs"
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

:set mouse=a      " allow mouse to change cursor position"
:set showmatch    " briefly jump to matching brackets"
:set number       " show line numbers"
:set expandtab    " replace tabs with spaces"
" :set noswapfile " disable the swap file as required for some docker directories
" *               - search for word currently under cursor"
" g*              - search for partial word under cursor "
"                   (repeat with n)"
" ctrl-o, ctrl-i  - go through jump locations"
" [I              - show lines with matching word under cursor"

set spelllang=en_gb
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

" GUI font
set guifont=Source\ Code\ Pro\ for\ Powerline\ 16
