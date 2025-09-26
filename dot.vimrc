" vimrc ConfigShell

" Turn off search highlighting by pressing \\.
:let mapleader = "\\"
nnoremap <leader>\ :nohlsearch<CR>
nnoremap <leader>ev :split $MYVIMRC<CR>
nnoremap <leader>lv :so $MYVIMRC<cr>

" move between windows, default ^w h/j/k/l   or   ^w left-arrow/...
nnoremap <C-H> <C-W>h
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l

" use control left/... to move between tabs
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>

map <F2> :w<CR>
inoremap <F2> <Esc>:w<CR>
map <S-F2> :wq<CR>
inoremap <S-F2> <Esc>:wq<CR>

" show spaces as ., enabled with :set list, disabled w/ :set nolist
set lcs+=space:· 

let b:togglelist = 0
function! ToggleList()
 if b:togglelist == 0
   echom "list mode"
   set list
   let b:togglelist = 1
 else
   echom "nolist mode"
   set nolist
   let b:togglelist = 0
 endif
endfunction

let b:togglepaste = 0
function! TogglePaste()
   if b:togglepaste == 0
      let b:togglepaste = 1
		echom "paste"
      set paste
   else
      let b:togglepaste = 0
		echom "nopaste"
      set nopaste
   endif
endfunction

map <F3> :call ToggleList()<CR>
map <F4> :noh<CR>
" to stop indenting when pasting
map <F5> :call TogglePaste()<CR>

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

" Backup stuff
" set backup       " makes tilde file backups"
set backupdir=~/.vim/backup
set directory=~/.vim/swap
set undodir=~/.vim/undo
set undofile
set undolevels=10000
set undoreload=10000
" Set the commands to save in history default number is 20.
set history=1000

filetype plugin on   " enable file-type detection
syntax on
filetype on

" Enable auto completion menu after pressing TAB.
set wildmenu
" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest
" There are certain files that we would never want to edit with Vim.
" Wildmenu will ignore files with these extensions.
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Status line left side.
set statusline=\ %M\ %F\ %M\ %Y\ \%R\ col:%c\ ASCII_ord\ (dec/hex):%b/0x%B\ %p%%

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

" set cursorline     " Highlight cursor line underneath the cursor horizontally.
" set cursorcolumn   " Highlight cursor line underneath the cursor vertically.

set incsearch
set hlsearch

set tabstop=3     " tabs are at proper location"
set shiftwidth=3  " indenting is 3 spaces"
set autoindent    " turns it on"
autocmd FileType yaml setlocal ts=3 sts=3 sw=3 expandtab

" paste command <F5> might be required if you paste from outside
" and all text gets more and more indented by line

set smartindent   " does the right thing (mostly) in programs"
set cindent       " stricter rules for C programs"
set expandtab    " replace tabs with spaces"

set mouse=a      " allow mouse to change cursor position"

set showmatch    " briefly jump to matching brackets"

set relativenumber " show line numbers, short form rnu, nornu
set number " show the current line not as 0 but as the current line number
" set noswapfile " disable the swap file as required for some docker directories

set splitright	" new window to the right, def left
set splitbelow	" new windoe to bottom, def top

set clipboard+=unnamed  " plus	" yanked elements also put into system clipboard

" ==============================================================
" spelling
"
" use built-in spelling, as vimspell only supports [ia]spell, no hunspell,...
" It also downloads dictionaries on demand,...
" Still have to teach it to avoid -ize endings

set spell
set spelllang=en_gb,de " de_ch existing
let b:togglespell = 0
function! ToggleSpell()
   if b:togglespell == 0
      let b:togglespell = 1
		echom "nospell"
      set nospell
   else
      let b:togglespell = 0
		echom "spell"
      set spell
   endif
endfunction

map <F4>   :noh<CR>
map <S-F4> :call ToggleSpell()<CR>

" GUI font
" better set in ~/.gvimrc
" set guifont=Source\ Code\ Pro\ for\ Powerline\ 16
:augroup autochg
  :autocmd!
  :autocmd FocusLost * nested silent! wall
:augroup END

iabbrev adn and
iabbrev tehn then

" echo $MYVIMRC " loaded" 
