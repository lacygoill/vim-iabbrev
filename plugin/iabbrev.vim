if exists('g:loaded_iabbrev')
    finish
endif
let g:loaded_iabbrev = 1

" Functions {{{1
fu s:lazy_load_vim_iabbrev() abort "{{{2
    " The goal of  this function is to  make sure our digraphs are  accessible if we
    " enter replace mode without having entered insert mode during the session.
    au! LazyLoadVimIabbrev
    aug! LazyLoadVimIabbrev
    exe 'so ' .. fnameescape(s:AUTOLOAD_SCRIPT)
    sil! unmap r
endfu
"}}}1
" Mapping {{{1

nno r <cmd>call <sid>lazy_load_vim_iabbrev()<cr>r

" Variables {{{1

const s:AUTOLOAD_SCRIPT = expand('<sfile>:p:h:h') .. '/autoload/' .. expand('<sfile>:t')

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
augroup LazyLoadVimIabbrev | au!
    " Why `CmdlineEnter`?{{{
    "
    " Digraphs  should be  accessible on  the  command-line even  if we  haven't
    " entered insert mode at least once.
    "}}}
    au InsertEnter,CmdlineEnter * call s:lazy_load_vim_iabbrev()
augroup END
