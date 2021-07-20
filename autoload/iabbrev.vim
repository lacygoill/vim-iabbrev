vim9script noclear

# Don't move the `Manual` section after the `Automatic`, because `Pab()`
# relies on `:Aab`.
# Manual {{{1

var digraphs: list<string> =<< trim END
    ns  
    o/ ∅
    ok ✔
    no ✘
    aa â
    ee ê
    ii î
    oo ô
    uu û
    um ù
    pp …
    tl ┌
    bl └
    tr ┐
    br ┘
    fa ∀
    te ∃
    e_ ∈
    e/ ∉
    co ⊥
    an ∧
    or ∨
    |v ↓
    |^ ↑
    |> ↳
    =~ ≈
    f> →
    ti ˜
END

digraphs
    ->mapnew((_, v: string): list<string> => v->split())
    ->setdigraphlist()

# `crg` is mapped to an operator defined in the unicode.vim plugin.
# It searches for every pair of characters inside a text-object matching
# a digraph, and when it finds one, converts it into the corresponding glyph.
#
# But we don't want all of them to be converted, otherwise it can converts
# undesirable digraphs.  E.g.:
#
#     hello world    →    へllo をr┐
#
# We can restrict the digraph generation to certain digraphs only:
g:Unicode_ConvertDigraphSubset = [
    char2nr("…"),
    char2nr("∀"),
    char2nr("∃"),
    char2nr("∈"),
    char2nr("∉"),
    char2nr("∧"),
    char2nr("∨"),
    char2nr("⊥"),
    char2nr("¬"),
    char2nr("â"),
    char2nr("ê"),
    char2nr("î"),
    char2nr("ô"),
    char2nr("û"),
    char2nr("€"),
    char2nr("≤"),
    char2nr("≥"),
    char2nr("≈"),
    char2nr("→"),
    char2nr("←"),
    char2nr("↑"),
    char2nr("↓"),
    char2nr("⇒"),
    char2nr("⇐"),
    char2nr("⇔"),
    char2nr("✘"),
    char2nr("✔"),
    char2nr("₀"),
    char2nr("₁"),
    char2nr("₂"),
    char2nr("₃"),
    char2nr("₄"),
    char2nr("₅"),
    char2nr("₆"),
    char2nr("₇"),
    char2nr("₈"),
    char2nr("₉"),
    char2nr("⁰"),
    char2nr("¹"),
    char2nr("²"),
    char2nr("³"),
    char2nr("⁴"),
    char2nr("⁵"),
    char2nr("⁶"),
    char2nr("⁷"),
    char2nr("⁸"),
    char2nr("⁹"),
]

# By default, the only type of abbreviation which can be expanded in a word is
# end-id: the end character is in 'iskeyword', but not the others.
# But this is limited:
#
#    - works only at the end of a word (suffix)
#    - the {lhs} must use only  characters outside of 'iskeyword' except the last
#      one which must be in 'iskeyword'
#
# Problem: What if we want to expand an abbreviation whose {lhs} is somewhere else?
# Prefix, right in the middle of a word, anywhere ...
# And what if the {lhs} we want doesn't follow the 2nd rule?
# For example, what if we want a {lhs} whose last character is not in 'iskeyword'.
#
# Solution: We can  add special abbreviations in  the dictionary `anywhere_abbr`
# and hit `C-]` to expand them.
#
# Inspiration:
# https://vi.stackexchange.com/questions/6391/backspace-in-insert-abbreviation/6400#6400
#
# Usage:
#     Aab xv ✔
#
# We may also pass a 2nd argument to `:Aab`; e.g.:
#     Aab rmp remplacement replacement
#
# With 2 arguments, the abbreviation will look at `&spelllang` to decide whether
# it must expand the abbreviation into the 1st or 2nd word.

# initialize `anywhere_abbr`
# it's a dictionary, whose keys are abbreviations (e.g.: 'rmp'), and whose
# values are lists containing 1 or 2 words (ex: ['remplacement', 'replacement'])
var anywhere_abbr: dict<list<string>>

# Why `<f-args>` instead of `<q-args>`?{{{
#
# The splitting done by `<f-args>` lets us immediately separate the lhs from the
# rhs of the abbreviation inside the function.
# Otherwise, we would have to do sth like:
#
#     let args = split(a:1)
#     let lhs = args[0]
#     let rhs = args[1 :]
#}}}
command -nargs=+ Aab AddAnywhereAbbr(<f-args>)

def AddAnywhereAbbr(lhs: string, ...l: list<string>)
    var rhs: list<string> = l
        ->join()
        # The  default mapping  or abbreviations  commands (like  `:inoremap` or
        # `:inoreabbrev`) automatically translate control characters.
        # Our custom command `:Aab` should do the same.
        ->substitute('<CR>', "\<CR>", 'g')
        ->substitute('<Esc>', "\<Esc>", 'g')
        ->split('\s*--\s*')
    anywhere_abbr[lhs] = rhs
enddef

def ExpandAnywhereAbbr(): string
    for [key: string, value: list<string>] in anywhere_abbr->items()
        # capture the text befothe cursor with a possible space at the end
        # why a space?
        #
        #     le drn|
        #     le drn |
        #           ^
        #
        # we could hit `C-]` right after the abbreviation (no space between it
        # and the cursor), OR after a space
        var text_before_cursor: string = getline('.')
            ->matchstr(repeat('.', strcharlen(key)) .. ' \=\%.c')
        var after_space: bool = stridx(text_before_cursor, ' ') >= 0

        # if one of them matches the word before the cursor ...
        if text_before_cursor == key || text_before_cursor == key .. ' '
            var expansions: list<string> = value

            # ... we use the first/french expansion  if there's only one word in
            # `expansions` or if we're in a french buffer
            var expansion: string = len(expansions) == 1 || &l:spelllang == 'fr'
                ?     expansions[0]
                :     expansions[1]

            # ... delete the abbreviation before  the cursor and replace it with
            # the expansion
            return repeat("\<BS>", strcharlen(key)
                # if there was a space delete it
                + (after_space ? 1 : 0)) .. expansion
                # and reinsert it at the end
                .. (after_space ? ' ' : '')
        endif
    endfor
    return "\<C-]>"
enddef

inoremap <expr><unique> <C-]> <SID>ExpandAnywhereAbbr()

# BRACKET EXPANSION ON THE CHEAP
#
# Terminology:
#     []    square brackets
#     ()    round brackets or parentheses
#     {}    curly brackets or braces
#     <>    angle brackets or chevrons

def InstallBracketExpansionAbbrev(brackets: string)
    if brackets !~ '()\|\[\]\|{}'
        return
    endif
    var opening_bracket: string = brackets[0]
    var closing_bracket: string = brackets[1]

    # ( [ {
    execute 'Aab ' .. opening_bracket .. ' ' .. opening_bracket .. "\<CR>" .. closing_bracket .. "\<Esc>O"

    # [, {, [; {;
    if opening_bracket =~ '[[{]'
        execute 'Aab ' .. opening_bracket .. ', ' .. opening_bracket .. "\<CR>" .. closing_bracket .. ",\<Esc>O"
        execute 'Aab ' .. opening_bracket .. '; ' .. opening_bracket .. "\<CR>" .. closing_bracket .. ";\<Esc>O"
    endif
enddef

InstallBracketExpansionAbbrev('()')
InstallBracketExpansionAbbrev('[]')
InstallBracketExpansionAbbrev('{}')

# Automatic {{{1

# This command should simply move the cursor on a duplicate abbreviation.
command -bar FindDuplicateAbbreviation FindDuplicateAbbreviation()
# Do *not* add the  `-buffer` attribute to the command.  It  would be applied to
# the buffer that Vim opens during a session.

def FindDuplicateAbbreviation() #{{{2
    var branch1: string = 'Abolish\s\+\(\S\+\)\s\+\_.*\_^Abolish\s\+\zs\1\ze\s\+'
    var branch2: string = 'inorea\%[bbrev]\s\+\(\S\+\)\s\+\_.*\_^inorea\%[bbrev]\s\+\zs\2\ze\s\+'
    var branch3: string = 'Pab\s\+\%(adj\|adv\|noun\|verb\)\s\+\(\S\+\)\s\+\_.*'
        .. '\_^Pab\s\+\%(adj\|adv\|noun\|verb\)\s\+\zs\3\ze\s\+'

    var pattern: string = '^\%(' .. branch1 .. '\|' .. branch2 .. '\|' .. branch3 .. '\)'
    var duplicate_line: number = search(pattern)
    if duplicate_line == 0
        echo 'no duplicates'
    endif
enddef

var adj: dict<dict<string>>
var adv: dict<dict<string>>
var noun: dict<dict<string>>
var verb: dict<dict<string>>

def ExpandAdj(abbr: string, expansion: string): string #{{{2
#                           │
#                           └ the function doesn't need it: it's just for our
#                             completion plugin, to get a description of what an
#                             abbreviation will be expanded into

    var prev_word: string = GetPrevWord()

    if &l:spelllang == 'en'
        return adj[abbr]['english']
    else
        if prev_word =~ '\c^\%(un\|le\|[mts]on\|ce\%(tte\)\@!\|au\|était\|est\|sera\)$'
            return adj[abbr]['le']

        elseif prev_word =~ '\c^\%(une\|[lmts]a\|cette\)$'
            return adj[abbr]['la']

        elseif prev_word =~ '\c^\%([ldmtsc]es\|aux\|[nv]os\|leurs\|étaient\|sont\|seront\)$'
            return adj[abbr]['les']

        else
            return abbr
        endif
    endif
enddef

def ExpandAdv(abbr: string, expansion: string): string #{{{2
    var prev_word: string = GetPrevWord()
    var to_capitalize: bool = ShouldWeCapitalize()

    if &l:spelllang == 'en'

        # A french abbreviation (like `ctl`) shouldn't be expanded into an
        # english buffer.
        # Without  this  check, in  an  english  buffer,  if  we type  a  french
        # abbreviation at the  beginning of a line, which follows  a line ending
        # with  a dot/bang/exclamation  mark (e.g.:  `autocmd!`), it's  expanded
        # like so:
        #
        #     ctl
        #     Ctl,˜
        #
        # NOTE:
        # We don't have this problem with verbs and adjectives, because we
        # don't transform the keys (from the dictionaries) we return.
        # But we have the same issue with english nouns, and more generally every
        # time we transform a key before returning it (adding an `s`, a comma, ...).
        if adv[abbr]['english'] == abbr
            return abbr
        endif

        return to_capitalize
            ?     toupper(adv[abbr]['english'][0]) .. adv[abbr]['english'][1 :] .. ','
            :     adv[abbr]['english']
    else
        # an english abbreviation (like `ctl`) shouldn't be expanded into an
        # french buffer
        if adv[abbr]['french'] == abbr
            return abbr
        endif

        return to_capitalize
            ?     toupper(adv[abbr]['french'][0]) .. adv[abbr]['french'][1 :] .. ','
            :     adv[abbr]['french']
    endif
enddef

def ExpandNoun(abbr: string, expansion: string): string #{{{2
    var prev_word: string = GetPrevWord()

    if &l:spelllang == 'en'
        # A french abbreviation (like `dcl`) shouldn't be expanded into an
        # english buffer.
        # Without this check, in an english buffer, if we type `some dcl`,
        # it's expanded like so:
        #
        #         some dcl
        #         some dcls˜
        #
        # NOTE:
        # We don't have this problem with verbs and adjectives, because we
        # don't transform the keys (from the dictionaries) we return.
        # But we have the same issue with adverbs, and more generally every
        # time we transform a key before returning it (adding an `s`, a comma, ...).
        if noun[abbr]['english'] == abbr
            return abbr
        endif
        return noun[abbr]['english'] .. (prev_word =~ '\c^\%(most\|some\|th[e|o]se\|various\|\d\)$' ? 's' : '')
    else
        #                          ┌ `l` is the previous word, if we type `l'argument`
        #                          │
        if prev_word =~ '\c^\%(un\|l\|[ld]e\|ce\%(t\|tte\)\=\|une\|[mlts]a\|[mts]on'
            .. '\|d\|du\|au\|1er\|[0-9]e\|quel\%(le\)\=\)$'

            return noun[abbr]['sg']

        elseif prev_word =~ '\c^\%(aux\|\d\+\)$'
            return noun[abbr]['pl']

        # if the previous word ends with an a `s`, expands the abbreviation into
        # its plural form:
        #         ce sont les derniers remplacements
        #                            ^             ^
        # should take care of several previous words which could appear before
        # a plural form:
        #
        #    - [ldmts]es
        #    - [nv]os
        #    - leurs
        #    - plusieurs
        #    - certains
        #    - quel%(le)?s

        elseif prev_word =~ 's$'
            return noun[abbr]['pl']

        else
            return abbr
        endif
    endif
enddef

def ExpandVerb(abbr: string, expansion: string): string #{{{2
    var prev_word: string = GetPrevWord()

    if &l:spelllang == 'en'
        if prev_word =~ '^\c\%(s\=he\|it\)$'
            return verb[abbr]['en_s']

        elseif prev_word =~ '^\c\%(by\)$'
            return verb[abbr]['en_ing']

        else
            return verb[abbr]['en_inf']
        endif
    else

        if prev_word =~ '\c^\%(en\)$'
            return verb[abbr]['fr_ant']

        #                                        ┌ negation
        #                                        │
        elseif prev_word =~ '\c^\%(il\|elle\|ça\|ne\|qui\)$'
            return verb[abbr]['fr_il']

        # previously, we used this:
        #     elseif prev_word =~ '\c^\%(ils\|elles\)$'
        # but it missed sth like:
        #     ces arguments prm
        elseif prev_word =~ '\Cs$'
            return verb[abbr]['fr_ils']

        elseif prev_word =~ '\c^\%(a\|ont\|fut\)$'
            return verb[abbr]['fr_passe']

        else
            return verb[abbr]['fr_inf']
        endif
    endif
enddef

def GetExpansion(abbr: string, type: string): string #{{{2
# This function may be called like this:
#     GetExpansion('tpr','adj')
#
# In this example, it must look inside the dictionary `adj['tpr']` and return
# the first value which isn't 'tpr'.
# We need this value to get a meaningful description of all our abbreviations
# inside the popup completion menu.
    var d: dict<string>
    if type == 'adj'
        d = adj[abbr]
    elseif type == 'adv'
        d = adv[abbr]
    elseif type == 'noun'
        d = noun[abbr]
    elseif type == 'verb'
        d = verb[abbr]
    endif
    return d
        ->deepcopy()
        ->filter((_, v: string): bool => v != abbr)
        ->items()[0][1]
enddef

def GetPrevWord(): string #{{{2
# get the word before the cursor
# necessary to know which form of the expansion should be used (plural, tense, ...)

    # we split whenever there's a space or a single quote (to get `une` out of `d'une`)
    var prev_words: list<string> = getline('.')
        ->strpart(0, col('.') - 1)
        ->split("'\\| ")
    return empty(prev_words) ? '' : prev_words[-1]
enddef

# IsShortAdj {{{2

# this function receives an abbreviation and a key, and returns 1 if the
# expansion of the abbreviation associated with the key contains a double
# quote
# Ex:
#
#     IsShortAdj('drn', 'le')
#     0  because :Pab drn dernier "s dernière "s˜
#                                    │˜
#                                    └ doesn't contain a double quote˜
#
#     IsShortAdj('drn', 'la')
#     1  because :Pab drn dernier "s dernière "s˜
#                                             │˜
#                                             └ contains a double quote˜

# we use this function to check whether a given argument passed to `:Pab` is
# a short version of an expansion, and should be transformed
# Ex:    Pab drn dernier "s
#                        │
#                        └ short version of dernier
def IsShortAdj(abbr: string, key: string): bool
    return stridx(adj[abbr][key], '"') >= 0
        && ( key == 'les' || key == 'la' )
enddef

def Pab( #{{{2
    nature: string,
    abbr: string,
    ...l: list<string>
)
    # Check we've given a valid type to `:Pab`.
    # Also check that we gave at  least one argument (the expanded word) besides
    # the abbreviation.
    if index(['adj', 'adv', 'noun', 'verb'], nature) == -1 || empty(l)
        return
    endif

    var fr_args: list<string>
    var en_args: list<string>
    [fr_args, en_args] = SeparateArgsEnfr(l)->deepcopy()

    # add support for manual expansion when one should have occurred but didn't; e.g.:
    #     la semaine drn
    #     la semaine dernière˜
    execute 'Aab ' .. abbr
        # The expansion could contain a space. {{{
        #
        # If it does, we need to escape it.
        # Otherwise, when we manually expand the abbreviation, we would only get
        # the last word.
        #
        # MWE:
        # Try `bdf C-v SPC C-]`.
        # Instead of getting `by default`, we would get `default`.
        #}}}
        .. ' ' .. escape(l[0], ' ')
        .. (empty(en_args) ? '' : ' -- ' .. escape(en_args[0], ' '))

    if nature == 'adj'

        adj[abbr] = {
            le: get(fr_args, 0, abbr),
            les: get(fr_args, 1, abbr),
            la: get(fr_args, 2, abbr),
            les_fem: get(fr_args, 3, abbr),
            english: get(en_args, 0, abbr),
        }

        # add support for the following syntax:
        #
        #     Pab adj crn courant    "s  courante  "es  --  current
        #     Pab adj drn dernier    "s  dernière  "s
        adj[abbr]
            ->map((k: string, v: string) =>
                    !IsShortAdj(abbr, k)
                    ?     v
                    :     adj[abbr][k == 'les' ? 'le' : 'la'] .. adj[abbr][k][1 :])

        # Example of command executed by the next `execute`:
        #
        #     inoreabbrev <silent> tpr <C-R>=<SID>ExpandAdj('tpr', 'temporaire')<CR>
        #                                                           │
        #                                                           └ returned by `GetExpansion('tpr', 'adj')`
        #
        # We need `GetExpansion()` because we don't know what's the key
        # inside `adj['tpr']`, containing the first true expansion of the
        # abbreviation.
        # Indeed, maybe the abbreviation is only expanded in english or only in french.
        execute 'inoreabbrev <silent> ' .. abbr
             .. ' <C-R>=<SID>ExpandAdj(' .. string(abbr)
             .. ', ' .. GetExpansion(abbr, 'adj')->string() .. ')<CR>'

    elseif nature == 'adv'
        adv[abbr] = {
            french: get(fr_args, 0, abbr),
            english: get(en_args, 0, abbr),
        }

        execute 'inoreabbrev <silent> ' .. abbr
            .. ' <C-R>=<SID>ExpandAdv(' .. string(abbr)
            .. ', ' .. GetExpansion(abbr, 'adv')->string() .. ')<CR>'

    elseif nature == 'noun'

        # if we didn't provide a plural form for a noun, use the same as the
        # singular with the additional suffix `s`
        if len(fr_args) == 1
            fr_args += [fr_args[0] .. 's']
        endif

        noun[abbr] = {
            sg: get(fr_args, 0, abbr),
            pl: get(fr_args, 1, abbr),
            english: get(en_args, 0, abbr),
        }

        execute 'inoreabbrev <silent> ' .. abbr
            .. ' <C-R>=<SID>ExpandNoun(' .. string(abbr)
            .. ', ' .. GetExpansion(abbr, 'noun')->string() .. ')<CR>'

    elseif nature == 'verb'
        verb[abbr] = {
            fr_inf: get(fr_args, 0, abbr),
            fr_il: get(fr_args, 1, abbr),
            fr_ils: get(fr_args, 2, abbr),
            fr_passe: get(fr_args, 3, abbr),
            fr_ant: get(fr_args, 4, abbr),
            en_inf: get(en_args, 0, abbr),
        }

        # With the command:
        #     Pab verb ctn contenir contient contiennent contenu contenant -- contain
        #
        # ... `contains contained containing` should be deduced from `contain`
        if verb[abbr]['en_inf'] != abbr
            extend(verb[abbr], {
                en_s: verb[abbr]['en_inf'] .. 's',
                en_ed: verb[abbr]['en_inf'] .. 'ed',
                en_ing: verb[abbr]['en_inf']->substitute('e$', '', '') .. 'ing',
                } )
        endif

        execute 'inoreabbrev <silent> ' .. abbr
            .. ' <C-R>=<SID>ExpandVerb(' .. string(abbr)
            .. ', ' .. GetExpansion(abbr, 'verb')->string() .. ')<CR>'
    endif
enddef

def SeparateArgsEnfr(args: list<string>): list<list<string>> #{{{2
    var fr_args: list<string>
    var en_args: list<string>

    # check if there are two hyphens inside the arguments passed to `:Pab`
    # two hyphens are used to end the french arguments; the next ones are
    # english
    var hyphens: number = index(args, '--')
    # two hyphens are at the start of the command:
    #     :Pab abr -- abbreviation
    if hyphens == 0
        en_args = args[1 :]
        #              │
        #              └ ignore the `--` token

    # there are two hyphens somewhere in the middle
    #     :Pab abr french_abbr ... -- english_abbr
    elseif hyphens >= 0
        fr_args = args[0 : hyphens - 1]
        en_args = args[hyphens + 1 :]

        # if the argument after the two hyphens is a double quote, the english
        # abbreviation should be the same as the french one
        #     :Pab noun agt argument -- "
        if get(en_args, 0, '') == '"'
            en_args[0] = fr_args[0]
        endif

    # there are no two hyphens
    #     :Pab abr french_abbr ...
    else
        fr_args = args
    endif
    return [fr_args, en_args]
enddef

def ShouldWeCapitalize(): bool #{{{2
# Should `bdf` be expanded into `by default` or into `By default,`?
    var cml: string = !empty(&l:commentstring)
        ?    '\V'
          .. '\%('
          ..     &l:commentstring->matchstr('\S*\ze\s*%s')->escape('\')
          .. '\)\='
          .. '\m'
        : ''
    var line: string = getline('.')
    var after_dot: bool = match(line, '\%(\.\|?|!\)\s\+\%.c') >= 0
    var after_nothing: bool = match(line, '^\s*' .. cml .. '\s*\%.c') >= 0
    var dot_on_prev_line: bool = (line('.') - 1)->getline()->match('\%(\.\|?\|!\)\s*$') >= 0
    var empty_prev_line: bool = (line('.') - 1)->getline()->match('^\s*$') >= 0

    return after_dot || (
             after_nothing &&
                 (empty_prev_line || (dot_on_prev_line || line('.') == 1)))
enddef

# abbreviations {{{2

#                ┌ Poly abbreviation
#                │
command -nargs=+ Pab Pab(<f-args>)

# TODO:
# add support for cycling, to get feminine plural and maybe for verb conjugations
# use `C-]` (or `C-g j` and `C-g J`)

Pab adj  crn  courant "s courante "es -- current
Pab adj  drn  dernier "s dernière "s
Pab adj  ncs  nécessaire "s nécessaire "s -- necessary
Pab adj  prc  précédent -- previous
Pab adj  tpr  temporaire -- temporary

Pab adv  bcp   beaucoup -- a\ lot\ of
Pab adv  bdf   -- by\ default
Pab adv  ctl   actuellement -- currently
Pab adv  fsr   -- for\ some\ reason
Pab adv  gnr   généralement -- generally
Pab adv  imd   immédiatement -- immediately
Pab adv  pbb   probablement -- probably
Pab adv  pdff  par\ défault
Pab adv  plq   plutôt\ que
Pab adv  rtt   -- rather\ than
Pab adv  tmt   automatiquement -- automatically
Pab adv  tprr  temporairement -- temporarily
Pab adv  trm   autrement -- otherwise

# The following words are not all adverbs, but the “adverb” category seems to be
# appropriate here.  It contains words wose form never changes (no conjugation).
# Why do you use `:Pab` instead of `:inoreabbrev`?{{{
#
# `:inoreabbrev` would make the abbreviation  be triggered no matter the current
# language we're typing in.
# Having a french  abbreviation being triggered while typing code  or writing in
# english is annoying.
# We want  french abbreviations to  be triggered  only when 'spelllang'  has the
# value 'fr'.
#}}}
Pab adv  ac    avec
# Alternative:
#     inoreabbrev <silent> ar <C-R>=<SID>ShouldWeCapitalize() ? 'As a result,' : 'as a result'<CR>
Pab adv  aar   -- as\ a\ result
Pab adv  cm    comme
Pab adv  crr   correspondant\ à
Pab adv  ds    dans
Pab adv  ee    être
Pab adv  eg    -- e.g.
Pab adv  el    le
Pab adv  fx    par\ exemple -- for\ example
Pab adv  itr   intérieur
Pab adv  mm    même
Pab adv  nimp  n'importe\ quel
Pab adv  pee   peut-être
Pab adv  pls   plusieurs
Pab adv  pmp   peu\ importe
Pab adv  pr    pour
Pab adv  prt   particulièrement

Pab noun  bfr  buffer -- "
Pab noun  ccr  occurrence -- "
Pab noun  cct  concaténation -- concatenation
Pab noun  cli  ligne\ de\ commande -- command-line
Pab noun  cmm  commande -- command
Pab noun  crc  caractère -- character
Pab noun  dcl  déclaration
Pab noun  drc  dossier -- directory
Pab noun  fcn  fonction -- function
Pab noun  fhr  fichier -- file
Pab noun  fnt  fenêtre -- window
Pab noun  hne  chaîne -- string
Pab noun  icn  icône -- icon
Pab noun  kbg  key\ binding -- "
Pab noun  mvm  mouvement
Pab noun  nvr  environnement -- environment
Pab noun  opn  option -- "
Pab noun  opu  opérateur -- operator
Pab noun  pcs  processus processus -- process
Pab noun  pgf  paragraphe -- paragraph
Pab noun  prg  programme -- program
Pab noun  pth  parenthèse -- parentheses
Pab noun  rgm  argument -- "
Pab noun  rgs  registre -- register
Pab noun  rhh  recherche -- search
Pab noun  rmp  remplacement -- replacement
Pab noun  ssn  substitution -- "
Pab noun  stt  -- statement
Pab noun  tah  tâche -- task
Pab noun  vlr  valeur -- value
Pab noun  vnm  évènement -- event
Pab noun  vrb  variable -- "
Pab noun  xpr  expression -- "

Pab verb  ctn  contenir contient contiennent contenu contenant -- contain
Pab verb  dsp  -- display
Pab verb  dwl  télécharger -- download
Pab verb  ffh  afficher affiche affichent affiché affichant
Pab verb  llw  -- allow
Pab verb  prm  permettre permet permettent permis permettant
Pab verb  rpl  remplacer remplace remplacent remplacé remplaçant -- replace
Pab verb  rtr  retourner retourne retournent retourné retournant -- return
Pab verb  lls  illustrer illustre illustrent illustré illustrant

inoreabbrev  dsn  doesn't
inoreabbrev  fm   FIXME
execute 'inoreabbrev  fmi   For more info, see:<CR>   '
inoreabbrev  ie   i.e.
inoreabbrev  izn  isn't
inoreabbrev  lx   LaTeX
inoreabbrev  ot   to
inoreabbrev  ptt  pattern
inoreabbrev  svr  several
inoreabbrev  tcm  autocmd
inoreabbrev  td   TODO
inoreabbrev  vai  via
inoreabbrev  wsp  whitespace
# }}}1
# Teardown {{{1

delcommand Aab
delcommand Pab

