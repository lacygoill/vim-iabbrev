vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Functions {{{1
def LazyLoadVimIabbrev() #{{{2
    # The goal of  this function is to  make sure our digraphs are  accessible if we
    # enter replace mode without having entered insert mode during the session.
    au! LazyLoadVimIabbrev
    aug! LazyLoadVimIabbrev
    exe 'so ' .. fnameescape(AUTOLOAD_SCRIPT)
    sil! unmap r
enddef
#}}}1
# Mapping {{{1

nno r <cmd>call <sid>LazyLoadVimIabbrev()<cr>r

# Variables {{{1

const AUTOLOAD_SCRIPT: string = expand('<sfile>:p:h:h') .. '/autoload/' .. expand('<sfile>:t')

# Autocmd {{{1

# Warning: Leave the autocmd at the end.{{{
#
# Otherwise, it will give an error when you start Vim in debug mode:
#
#         $ vim -D
#             > f[inish]
#             > f
#             ...
#             " vim-iabbrev
#             > n[ext]
#             > n
#             ...
#}}}
augroup LazyLoadVimIabbrev | au!
    # Why `CmdlineEnter`?{{{
    #
    # Digraphs  should be  accessible on  the  command-line even  if we  haven't
    # entered insert mode at least once.
    #}}}
    au InsertEnter,CmdlineEnter * LazyLoadVimIabbrev()
augroup END
