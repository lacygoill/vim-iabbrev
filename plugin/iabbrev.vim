vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Functions {{{1
def LazyLoadVimIabbrev() #{{{2
    # The goal of  this function is to  make sure our digraphs are  accessible if we
    # enter replace mode without having entered insert mode during the session.
    autocmd! LazyLoadVimIabbrev
    # `silent!` to suppress `E936: Cannot delete the current group`.
    # Only seems to happen when starting in debug mode: `$ vim -D`.
    silent! augroup! LazyLoadVimIabbrev
    execute 'source ' .. fnameescape(AUTOLOAD_SCRIPT)
    silent! unmap r
enddef
#}}}1
# Mapping {{{1

nnoremap <unique> r <Cmd>call <SID>LazyLoadVimIabbrev()<CR>r

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
#             # vim-iabbrev
#             > n[ext]
#             > n
#             ...
#}}}
augroup LazyLoadVimIabbrev | autocmd!
    # Why `CmdlineEnter`?{{{
    #
    # Digraphs  should be  accessible on  the  command-line even  if we  haven't
    # entered insert mode at least once.
    #}}}
    autocmd InsertEnter,CmdlineEnter * LazyLoadVimIabbrev()
augroup END
