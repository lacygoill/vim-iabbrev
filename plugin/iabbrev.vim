if exists('g:loaded_iabbrev')
    finish
endif
let g:loaded_iabbrev = 1

" Autocmd {{{1

augroup lazy_load_vim_iabbrev
    au!
    "              ┌─ digraphs should be accessible on the command-line
    "              │  even if we haven't entered insert mode at least once
    "              │
    au InsertEnter,CmdLineEnter * call s:lazy_load_vim_iabbrev()
augroup END

" Functions {{{1
fu! s:lazy_load_vim_iabbrev() abort "{{{2
    exe 'so '.fnameescape(s:autoload_script)
    au! lazy_load_vim_iabbrev
    aug! lazy_load_vim_iabbrev
endfu

fu! s:my_r() abort "{{{2
    call s:lazy_load_vim_iabbrev()
    sil! unmap r
    return 'r'
endfu
" The goal of  this function is to  make sure our digraphs are  accessible if we
" enter replace mode without having entered insert mode during the session.

" Mapping {{{1
nno <expr> r <sid>my_r()

" Variables {{{1

let s:autoload_script = expand('<sfile>:p:h:h').'/autoload/'.expand('<sfile>:t')
