{ pkgs, ... }:

{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-airline pathogen ];
    extraConfig = ''
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " General
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Sets how many lines of history VIM has to remember
      set history=700
      
      execute pathogen#infect()
      
      " Enable filetype plugins
      filetype plugin on
      filetype indent on
      
      " Set to auto read when a file is changed from the outside
      set autoread
      
      " With a map leader it's possible to do extra key combinations
      " like <leader>w saves the current file
      let mapleader = "-"
      let g:mapleader = "-"
      
      " Fast saving
      nmap <leader>w :w!<cr>
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " VIM user interface
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Set 8 lines to the cursor - when moving vertically using j/k
      set so=8
      
      " Turn on the WiLd menu
      set wildmenu
      
      " Ignore compiled files
      set wildignore=*.o,*~,*.pyc
      
      "Always show current position
      set ruler
      
      " Height of the command bar
      "set cmdheight=2
      
      " A buffer becomes hidden when it is abandoned
      set hid
      
      " Configure backspace so it acts as it should act
      set backspace=eol,start,indent
      set whichwrap+=<,>,h,l
      
      " Ignore case when searching
      set ignorecase
      
      " When searching try to be smart about cases 
      set smartcase
      
      " Highlight search results
      set hlsearch
      
      " Makes search act like search in modern browsers
      set incsearch
      
      " For regular expressions turn magic on
      set magic
      
      " Show matching brackets when text indicator is over them
      set showmatch
      " How many tenths of a second to blink when matching brackets
      set mat=2
      
      " No annoying sound on errors
      set noerrorbells
      set novisualbell
      set t_vb=
      set tm=500
      
      " Line numbers
      set number
      " Allow mouse to move cursor around
      set mouse=r
      set cursorline
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Colors and Fonts
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Font
      set guifont=Liberation\ Mono\ 10
     
      " Enable syntax highlighting
      syntax enable
      syntax on

      " General
      set t_Co=256
      set background=dark

      " Airline
      let g:airline_symbols = {}
      let g:airline#extensions#tabline#enabled = 1
      let g:airline#extensions#tabline#show_buffers = 1
      let g:airline_left_sep = ' '
      let g:airline_right_sep = ' '
      let g:airline_symbols.colnr = ':'
      let g:airline_symbols.crypt = ' '
      let g:airline_symbols.linenr = ' '
      let g:airline_symbols.maxlinenr = ' '
      let g:airline_symbols.branch = ' '
      let g:airline_symbols.paste = 'p'
      let g:airline_symbols.spell = 's'
      let g:airline_symbols.notexists = ' '
      let g:airline_symbols.whitespace = ' '
      
      " Set extra options when running in GUI mode
      if has("gui_running")
          set guioptions-=T
          set guioptions+=e
          set guitablabel=%M\ %t
      endif
      
      " Set utf8 as standard encoding and en_US as the standard language
      set encoding=utf8
      
      " Use Unix as the standard file type
      set ffs=unix,dos,mac
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Files, backups and undo
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Turn backup off
      set nobackup
      set nowb
      set noswapfile
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Text, tab and indent related
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Use spaces instead of tabs
      set expandtab
      
      " Be smart when using tabs ;)
      set smarttab
      
      " 1 tab == 4 spaces
      set shiftwidth=4
      set tabstop=4
      
      " Linebreak on 500 characters
      set lbr
      set tw=500
      
      set ai "Auto indent
      set cindent
      set cinkeys-=0#
      set indentkeys-=0#
      set wrap "Wrap lines
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Moving around, tabs, windows and buffers
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Treat long lines as break lines (useful when moving around in them)
      map j gj
      map k gk
      
      " Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
      map <space> /
      map <c-space> ?
      
      " Disable highlight when <leader><cr> is pressed
      map <silent> <leader><cr> :noh<cr>
      
      " Smart way to move between windows
      map <C-j> <C-W>j
      map <C-k> <C-W>k
      map <C-h> <C-W>h
      map <C-l> <C-W>l
      
      " Close the current buffer
      map <leader>bd :Bclose<cr>
      
      " Close all the buffers
      map <leader>ba :1,1000 bd!<cr>
      
      " Useful mappings for managing tabs
      map <leader>tn :tabnew<cr>
      map <leader>to :tabonly<cr>
      map <leader>tc :tabclose<cr>
      map <leader>tm :tabmove
      
      " Opens a new tab with the current buffer's path
      " Super useful when editing files in the same directory
      map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
      
      " Switch CWD to the directory of the open buffer
      map <leader>cd :cd %:p:h<cr>:pwd<cr>
      
      " Specify the behavior when switching between buffers 
      try
        set switchbuf=useopen,usetab,newtab
        set stal=2
      catch
      endtry
      
      " Return to last edit position when opening files
      autocmd BufReadPost *
           \ if line("'\"") > 0 && line("'\"") <= line("$") |
           \   exe "normal! g`\"" |
           \ endif
      " Remember info about open buffers on close
      set viminfo^=%
      
      """"""""""""""""""""""""""""""
      " Status line
      """"""""""""""""""""""""""""""
      " Always show the status line
      set laststatus=2
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Editing mappings
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Delete trailing white space on save
      func! DeleteTrailingWS()
        exe "normal mz"
        %s/\s\+$//ge
        exe "normal `z"
      endfunc
      autocmd BufWrite *.py :call DeleteTrailingWS()
      autocmd BufWrite *.coffee :call DeleteTrailingWS()
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Spell checking
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Pressing ,ss will toggle and untoggle spell checking
      map <leader>ss :setlocal spell!<cr>
      
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Colors
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      set background=dark
      hi clear
      " General colors
      hi CursorLine ctermbg=237 guibg=#3a3a3a cterm=none gui=none
      hi CursorLine guibg=#2d2d2d ctermbg=236
      hi CursorColumn guibg=#2d2d2d ctermbg=236
      hi MatchParen guifg=#d0ffc0 guibg=#2f2f2f gui=bold ctermfg=157 ctermbg=237 cterm=bold
      hi Pmenu 		guifg=#ffffff guibg=#444444 ctermfg=255 ctermbg=238
      hi PmenuSel 	guifg=#000000 guibg=#b1d631 ctermfg=0 ctermbg=148
      hi Cursor 		guifg=NONE    guibg=#626262 gui=none ctermbg=241
      hi Normal 		guifg=#e2e2e5 guibg=#202020 gui=none ctermfg=253 ctermbg=234
      hi NonText 		guifg=#808080 guibg=#303030 gui=none ctermfg=244 ctermbg=235
      hi LineNr 		guifg=#808080 guibg=#000000 gui=none ctermfg=244 ctermbg=232
      hi StatusLine 	guifg=#d3d3d5 guibg=#444444 gui=italic ctermfg=253 ctermbg=238 cterm=italic
      hi StatusLineNC guifg=#939395 guibg=#444444 gui=none ctermfg=246 ctermbg=238
      hi VertSplit 	guifg=#444444 guibg=#444444 gui=none ctermfg=238 ctermbg=238
      hi Folded 		guibg=#384048 guifg=#a0a8b0 gui=none ctermbg=4 ctermfg=248
      hi Title		guifg=#f6f3e8 guibg=NONE	gui=bold ctermfg=254 cterm=bold
      hi Visual		guifg=#faf4c6 guibg=#3c414c gui=none ctermfg=254 ctermbg=4
      hi SpecialKey	guifg=#808080 guibg=#343434 gui=none ctermfg=244 ctermbg=236
      " Syntax highlighting
      hi Comment 		guifg=#808080 gui=italic ctermfg=244
      hi Todo 		guifg=#8f8f8f gui=italic ctermfg=245
      hi Boolean      guifg=#b1d631 gui=none ctermfg=148
      hi String 		guifg=#b1d631 gui=italic ctermfg=148
      hi Identifier 	guifg=#b1d631 gui=none ctermfg=148
      hi Function 	guifg=#ffffff gui=bold ctermfg=255
      hi Type 		guifg=#7e8aa2 gui=none ctermfg=103
      hi Statement 	guifg=#7e8aa2 gui=none ctermfg=103
      hi Keyword		guifg=#ff9800 gui=none ctermfg=208
      hi Constant 	guifg=#ff9800 gui=none  ctermfg=208
      hi Number		guifg=#ff9800 gui=none ctermfg=208
      hi Special		guifg=#ff9800 gui=none ctermfg=208
      hi PreProc 		guifg=#faf4c6 gui=none ctermfg=230
      hi Todo         guifg=#000000 guibg=#e6ea50 gui=italic
      " Code-specific colors
      hi pythonOperator guifg=#7e8aa2 gui=none ctermfg=103
    '';
  };
}