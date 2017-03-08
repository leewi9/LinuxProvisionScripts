" Vim配置文件
" ~/.vimrc

" Vundle.vim 相关配置
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'c.vim'

Plugin 'taglist.vim'

Plugin 'Tagbar'
nmap <F8> :TagbarToggle<CR>

Plugin 'Syntastic'

" " The following are examples of different formats supported.
" " Keep Plugin commands between vundle#begin/end.
" " plugin on GitHub repo
" Plugin 'tpope/vim-fugitive'
" " plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" " Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" " git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" " The sparkup vim script is in a subdirectory of this repo called vim.
" " Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" " Install L9 and avoid a Naming conflict if you've already installed a
" " different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}

" " All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" " To ignore plugin indent changes, instead use:
" "filetype plugin on
"
" " Brief help
" " :PluginList       - lists configured plugins
" " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" " :PluginSearch foo - searches for foo; append `!` to refresh local cache
" " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" " see :h vundle for more details or wiki for FAQ
" " Put your non-Plugin stuff after this line


" 编码
set fileencodings=utf-8
set encoding=utf-8

"
syntax on

set nu

set smartindent     " autoindent、noautoindent


set tabstop=4       " The width of a TAB is set to 4.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 4.

set shiftwidth=4    " Indents will have a width of 4

set softtabstop=4   " Sets the number of columns for a TAB

set expandtab       " Expand TABs to spaces


" 括号自动补全（加在vim配置文件末尾，但是似乎在大段拷贝时会产生很多多余的！！？？？ ）

inoremap ( ()<ESC>i

inoremap [ []<ESC>i

inoremap { {}<ESC>i

inoremap < <><ESC>i
 
??? 是不是在Terminal中的vim字体遵守Terminal的设置，所以这里虽然设置也貌似无效？

" 在Linux下设置字体的命令是：
set guifont=Courier\ 14
" 而在Windows下则是：
set guifont = Courier:h14
" 当然，如果需要设置多个字体，则我们可以在各个字体之间添加逗号(,)来设置多个字体，如：
set guifont = Courier\ New\ 12 , Arial\ 10