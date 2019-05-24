if exists('g:loaded_iabbrev')
    finish
endif
let g:loaded_iabbrev = 1

" Functions {{{1
fu! s:lazy_load_vim_iabbrev() abort "{{{2
    exe 'so '.fnameescape(s:AUTOLOAD_SCRIPT)
    sil! unmap r
endfu

fu! s:my_r() abort "{{{2
    call s:lazy_load_vim_iabbrev()
    return 'r'
endfu
" The goal of  this function is to  make sure our digraphs are  accessible if we
" enter replace mode without having entered insert mode during the session.

" Mapping {{{1

nno  <expr>  r  <sid>my_r()

" Variables {{{1

let s:AUTOLOAD_SCRIPT = expand('<sfile>:p:h:h').'/autoload/'.expand('<sfile>:t')
" Autocmd {{{1

" Warning: Leave the autocmd at the end.{{{
"
" Otherwise, it will give an error when you start Vim in debug mode:
"
"         $ vim -D
"             > f[inish]
"             > f
"             ...
"             " vim-iabbrev
"             > n[ext]
"             > n
"             ...
"}}}
unlet! s:did_shoot
"              ┌ digraphs should be accessible on the command-line
"              │ even if we haven't entered insert mode at least once
"              │
au InsertEnter,CmdlineEnter * ++once
    \ if !get(s:, 'did_shoot', 0)
    \ |     let s:did_shoot = 1
    \ |     call s:lazy_load_vim_iabbrev()
    \ | endif

