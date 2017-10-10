if exists('g:loaded_iabbrev')
    finish
endif
let g:loaded_iabbrev = 1

" Autocmd {{{1

augroup lazy_load_vim_iabbrev
    au!
    au InsertEnter * exe 'so '.fnameescape(s:autoload_script)
                  \| exe 'au! lazy_load_vim_iabbrev'
                  \| aug! lazy_load_vim_iabbrev
augroup END

" Variables {{{1

let s:autoload_script = expand('<sfile>:p:h:h').'/autoload/'.expand('<sfile>:t')
