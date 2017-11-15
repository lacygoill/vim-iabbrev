if exists('g:autoloaded_iabbrev')
    finish
endif
let g:autoloaded_iabbrev = 1

" Don't move the `Manual` section after the `Automatic`, because `s:pab()`
" relies on `:Aab`.
" Manual {{{1

" ✔ ✘
digraphs ok 10004 no 10008

" â ê î ô û
digraphs aa 226 ee 234 ii 238 oo 244 uu 251

" …
digraphs pp 8230

" ┌ ┐ └ ┘
digraphs tl 9484 tr 9488 bl 9492 br 9496
"        │       │       │       │
"        │       │       │       └─ Bottom Right
"        │       │       └─ Bottom Left
"        │       └─ Top Right
"        └─ Top Left

" ∀ ∃
digraphs fa 8704 te 8707

" ∈ ∉
digraphs e_ 8712 e/ 8713

" ⊥
digraphs co 8869

" ∧ ∨
digraphs an 8743 or 8744

" ↓ ↑ ↳
digraph \|v 8595 \|^ 8593 \|> 8627

" ≈
digraphs =~ 8776


" `crg` is mapped to an operator defined in the unicode.vim plugin.
" It searches for every pair of characters inside a text-object matching
" a digraph, and when it finds one, converts it into the corresponding glyph.
"
" But we don't want all of them to be converted, otherwise it can converts
" undesirable digraphs. E.g.:
"
"     hello world    →    へllo をr┐
"
" We can restrict the digraph generation to certain digraphs only:
let g:Unicode_ConvertDigraphSubset = [
                                     \ char2nr("…"),
                                     \ char2nr("∀"),
                                     \ char2nr("∃"),
                                     \ char2nr("∈"),
                                     \ char2nr("∉"),
                                     \ char2nr("∧"),
                                     \ char2nr("∨"),
                                     \ char2nr("⊥"),
                                     \ char2nr("¬"),
                                     \ char2nr("â"),
                                     \ char2nr("ê"),
                                     \ char2nr("î"),
                                     \ char2nr("ô"),
                                     \ char2nr("û"),
                                     \ char2nr("€"),
                                     \ char2nr("≤"),
                                     \ char2nr("≥"),
                                     \ char2nr("≈"),
                                     \ char2nr("→"),
                                     \ char2nr("←"),
                                     \ char2nr("↑"),
                                     \ char2nr("↓"),
                                     \ char2nr("⇒"),
                                     \ char2nr("⇐"),
                                     \ char2nr("⇔"),
                                     \ char2nr("✘"),
                                     \ char2nr("✔"),
                                     \ char2nr("₀"),
                                     \ char2nr("₁"),
                                     \ char2nr("₂"),
                                     \ char2nr("₃"),
                                     \ char2nr("₄"),
                                     \ char2nr("₅"),
                                     \ char2nr("₆"),
                                     \ char2nr("₇"),
                                     \ char2nr("₈"),
                                     \ char2nr("₉"),
                                     \ char2nr("⁰"),
                                     \ char2nr("¹"),
                                     \ char2nr("²"),
                                     \ char2nr("³"),
                                     \ char2nr("⁴"),
                                     \ char2nr("⁵"),
                                     \ char2nr("⁶"),
                                     \ char2nr("⁷"),
                                     \ char2nr("⁸"),
                                     \ char2nr("⁹"),
                                     \ ]

" By default, the only type of abbreviation which can be expanded in a word is
" end-id: the end character is in 'isk', but not the others.
" But this is limited:
"
"     - works only at the end of a word (suffix)
"     - the {lhs} must use only characters outside of 'isk' except the last one
"       which must be in 'isk'
"
" Problem: What if we want to expand an abbreviation whose {lhs} is somewhere else?
" Prefix, right in the middle of a word, anywhere…
" And what if the {lhs} we want doesn't follow the 2nd rule?
" For example, what if we want a {lhs} whose last character is not in isk.
"
" Solution: We can add special abbreviations in the dictionary s:anywhere_abbr
" and hit C-] to expand them.
"
" Inspiration:
" https://vi.stackexchange.com/questions/6391/backspace-in-insert-abbreviation/6400#6400
"
" Usage:
"     Aab xv ✔
"
" We may also pass a 2nd argument to `:Aab`; ex:
"     Aab rmp remplacement replacement
"
" With 2 arguments, the abbreviation will look at `&spl` to decide whether it
" must expand the abbreviation into the 1st or 2nd word.

" initialize `s:anywhere_abbr`
" it's a dictionary, whose keys are abbreviations (ex: 'rmp'), and whose
" values are lists containing 1 or 2 words (ex: [ 'remplacement', 'replacement'])
let s:anywhere_abbr = {}

com! -nargs=+ Aab call s:add_anywhere_abbr(<f-args>)

fu! s:add_anywhere_abbr(lhs, rhs, ...)
    " The default mapping or abbreviations commands (like :ino or
    " :inorea) automatically translate control characters.
    " Our custom command :Aab should do the same.
    let rhs = substitute(a:rhs, '<CR>', "\<CR>", 'g')
    let rhs = substitute(rhs, '<Esc>', "\<Esc>", 'g')

    let s:anywhere_abbr[a:lhs] = [ rhs ] + ( exists('a:1') ? [ a:1 ] : [] )
endfu

fu! s:expand_anywhere_abbr() abort
    " iterate over the abbreviations in `s:anywhere_abbr`
    let keys = keys(s:anywhere_abbr)

    for key in keys
        " capture the text befothe cursor with a possible space at the end
        " why a space?
        "
        "     le drn|
        "     le drn |
        "           ^
        "
        " we could hit `C-]` right after the abbreviation (no space between it
        " and the cursor), OR after a space
        let text_before_cursor = matchstr(getline('.'), repeat('.', strchars(key)).' \?\%'.col('.').'c')
        let after_space = match(text_before_cursor, ' ') != -1

        " if one of them matches the word before the cursor …
        if text_before_cursor ==# key || text_before_cursor ==# key.' '
            let expansions = s:anywhere_abbr[key]

            " … we use the first/french expansion if there's only one word in
            " `expansions` or if we're in a french buffer
            let expansion = len(expansions) == 1 || &spl ==# 'fr'
            \?                  expansions[0]
            \:                  expansions[1]

            " … delete the abbreviation before the cursor and replace it with
            " the expansion
            return repeat("\<BS>", strchars(key) + (after_space ? 1 : 0)).expansion.(after_space ? ' ' : '')
            "                                       │                                │
            "                                       │                                └─ and reinsert it at the end
            "                                       └─ if there was a space delete it
        endif
    endfor
    return "\<C-]>"
endfu

ino <expr> <C-]> <sid>expand_anywhere_abbr()

" BRACKET EXPANSION ON THE CHEAP
"
" Terminology:
"     []    square brackets
"     ()    round brackets or parentheses
"     {}    curly brackets or braces
"     <>    angle brackets or chevrons

fu! s:install_bracket_expansion_abbrev(brackets) abort
    if a:brackets !~# '()\|\[\]\|{}' | return | endif
    let opening_bracket = a:brackets[0]
    let closing_bracket = a:brackets[1]

    " ( [ {
    exe 'Aab '.opening_bracket.' '.opening_bracket."\<CR>".closing_bracket."\<Esc>O"

    " [, {, [; {;
    if opening_bracket =~# '[[{]'
        exe 'Aab '.opening_bracket.', '.opening_bracket."\<CR>".closing_bracket.",\<Esc>O"
        exe 'Aab '.opening_bracket.'; '.opening_bracket."\<CR>".closing_bracket.";\<Esc>O"
    endif
endfu

call s:install_bracket_expansion_abbrev('()')
call s:install_bracket_expansion_abbrev('[]')
call s:install_bracket_expansion_abbrev('{}')

" Automatic {{{1

" This command should simply move the cursor on a duplicate abbreviation.
" FIXME:
" define the cmd automatically ? because atm it doesn't work until we source
" this file
com! -buffer Duplicates call s:duplicates()

fu! s:duplicates() abort "{{{2
    let branch1 = 'Abolish\s+(\S+)\s+\_.*\_^Abolish\s+\zs\1\ze\s+'
    let branch2 = 'inorea%[bbrev]\s+(\S+)\s+\_.*\_^inorea%[bbrev]\s+\zs\2\ze\s+'
    let branch3 = 'Pab\s+%(adj|adv|noun|verb)\s+(\S+)\s+\_.*\_^Pab\s+%(adj|adv|noun|verb)\s+\zs\3\ze\s+'

    let pattern = '\v^%('.branch1.'|'.branch2.'|'.branch3.')'
    let duplicate_line = search(pattern)
    if !duplicate_line
        echo 'no duplicates'
    endif
endfu

let [ s:adj, s:adv, s:noun, s:verb ] = [ {}, {}, {}, {} ]
fu! s:expand_adj(abbr,expansion) abort "{{{2
"                     │
"                     └─ the function doesn't need it: it's just for our
"                        completion plugin, to get a description of what an
"                        abbreviation will be expanded into

    let prev_word = s:get_prev_word()

    if &l:spl ==# 'en'
        return s:adj[a:abbr].english
    else
        if prev_word =~# '\v\c^%(un|le|[mts]on|ce%(tte)@!|au|était|est|sera)$'
            return s:adj[a:abbr].le

        elseif prev_word =~# '\v\c^%(une|[lmts]a|cette)$'
            return s:adj[a:abbr].la

        elseif prev_word =~# '\v\c^%([ldmtsc]es|aux|[nv]os|leurs|étaient|sont|seront)$'
            return s:adj[a:abbr].les

        else
            return a:abbr
        endif
    endif
endfu

fu! s:expand_adv(abbr,expansion) abort "{{{2
    let prev_word = s:get_prev_word()
    let to_capitalize = s:should_we_capitalize()

    if &l:spl ==# 'en'

        " A french abbreviation (like `ctl`) shouldn't be expanded into an
        " english buffer.
        " Without this check, in an english buffer, if we type a french
        " abbreviation at the beginning of a line, which follows a line ending
        " with a dot/bang/exclamation mark (ex: `autocmd!`), it's expanded like so:
        "
        "         ctl  →  Ctl,
        "
        " NOTE:
        " We don't have this problem with verbs and adjectives, because we
        " don't transform the keys (from the dictionaries) we return.
        " But we have the same issue with english nouns, and more generally every
        " time we transform a key before returning it (adding an `s`, a comma, …).
        if s:adv[a:abbr].english ==# a:abbr
            return a:abbr
        endif

        return to_capitalize
        \?         toupper(s:adv[a:abbr].english[0]).s:adv[a:abbr].english[1:].','
        \:         s:adv[a:abbr].english
    else
        " an english abbreviation (like `ctl`) shouldn't be expanded into an
        " french buffer
        if s:adv[a:abbr].french ==# a:abbr
            return a:abbr
        endif

        return to_capitalize
        \?         toupper(s:adv[a:abbr].french[0]).s:adv[a:abbr].french[1:].','
        \:         s:adv[a:abbr].french
    endif
endfu

fu! s:expand_noun(abbr,expansion) abort "{{{2
    let prev_word = s:get_prev_word()

    if &l:spl ==# 'en'
        " A french abbreviation (like `dcl`) shouldn't be expanded into an
        " english buffer.
        " Without this check, in an english buffer, if we type `some dcl`,
        " it's expanded like so:
        "
        "         some dcl →  some dcls
        "
        " NOTE:
        " We don't have this problem with verbs and adjectives, because we
        " don't transform the keys (from the dictionaries) we return.
        " But we have the same issue with adverbs, and more generally every
        " time we transform a key before returning it (adding an `s`, a comma, …).
        if s:noun[a:abbr].english ==# a:abbr
            return a:abbr
        endif
        return s:noun[a:abbr].english.(prev_word =~# '\v\c^%(most|some|th[e|o]se|various|\d)$' ? 's' : '')
    else
        "                                                                        digit ┐
        "                                                                              │
        if prev_word =~# '\v\c^%(un|l|[ld]e|ce%(tte)?|une|[mlts]a|[mts]on|d|du|au|1er|\de|quel%(le)?)$'
        "                           │
        "                           └─ `l` is the previous word, if we type `l'argument`
            return s:noun[a:abbr].sg

        elseif prev_word =~# '\v\c^%(aux|\d+)$'
            return s:noun[a:abbr].pl

        " if the previous word ends with an a `s`, expands the abbreviation into
        " its plural form:
        "         ce sont les derniers remplacements
        "                            ^             ^
        " should take care of several previous words which could appear before
        " a plural form:
        "
        "               • [ldmts]es
        "               • [nv]os
        "               • leurs
        "               • plusieurs
        "               • certains
        "               • quel%(le)?s

        elseif prev_word =~# 's$'
            return s:noun[a:abbr].pl

        else
            return a:abbr
        endif
    endif
endfu

fu! s:expand_verb(abbr,expansion) abort "{{{2
    let prev_word = s:get_prev_word()

    if &l:spl ==# 'en'
        if prev_word =~# '\v\c^%(s?he|it)$'
            return s:verb[a:abbr]['en_s']

        elseif prev_word =~# '\v\c^%(by)$'
            return s:verb[a:abbr]['en_ing']

        else
            return s:verb[a:abbr]['en_inf']
        endif
    else

        if prev_word =~# '\v\c^%(en)$'
            return s:verb[a:abbr]['fr_ant']

        "                                       ┌─ negation
        "                                       │
        elseif prev_word =~# '\v\c^%(il|elle|ça|ne|qui)$'
            return s:verb[a:abbr]['fr_il']

        " previously, we used this:
        "         elseif prev_word =~# '\v\c^%(ils|elles)$'
        " but it missed sth like:
        "         ces arguments prm
        elseif prev_word =~# '\Cs$'
            return s:verb[a:abbr]['fr_ils']

        elseif prev_word =~# '\v\c^%(a|ont|fut)$'
            return s:verb[a:abbr]['fr_passe']

        else
            return s:verb[a:abbr]['fr_inf']
        endif
    endif
endfu

fu! s:get_expansion(abbr,type) abort "{{{2
" This function may be called like this:
"     s:get_expansion('tpr','adj')
"
" In this example, it must look inside the dictionary `s:adj['tpr']` and return
" the first value which isn't 'tpr'.
" We need this value to get a meaningful description of all our abbreviations
" inside the popup completion menu.
    return items(filter(deepcopy(s:{a:type}[a:abbr]), 'v:val !=# '.string(a:abbr)))[0][1]
endfu

fu! s:get_prev_word() abort "{{{2
" get the word before the cursor
" necessary to know which form of the expansion should be used (plural, tense, …)

    " we split whenever there's a space or a single quote (to get `une` out of `d'une`)
    let prev_words = split(matchstr(getline('.'), '\v.*%'.col('.').'c'), "'\\| ")
    return empty(prev_words) ? '' : prev_words[-1]
endfu

" is_short_adj {{{2

" this function receives an abbreviation and a key, and returns 1 if the
" expansion of the abbreviation associated with the key contains a double
" quote
" Ex:
"                                                                    ┌─ doesn't contain a double quote
"                                                                    │
"     s:is_short_adj('drn', 'le')  →  0  because :Pab drn dernier "s dernière "s
"
"     s:is_short_adj('drn', 'la')  →  1  because :Pab drn dernier "s dernière "s
"                                                                             │
"                                                                             └─ contains a double quote

" we use this function to check whether a given argument passed to `:Pab` is
" a short version of an expansion, and should be transformed
" Ex:    Pab drn dernier "s
"                        │
"                        └─ short version of dernier
fu! s:is_short_adj(abbr, key) abort
    return match(s:adj[a:abbr][a:key], '"') != -1 &&
                \ ( a:key ==# 'les' || a:key ==# 'la' )
endfu

fu! s:pab(nature, abbr, ...) abort "{{{2
    " check we've given a valid type to `:Pab`
    " also check that we gave at least one argument (the expanded word) besides
    " the abbreviation
    if count([ 'adj', 'adv', 'noun', 'verb' ], a:nature) == -1 || !exists('a:1')
        return
    endif

    let [ nature, abbr ]     = [ a:nature, a:abbr ]
    let [ fr_args, en_args ] = s:separate_args_enfr(a:000)

    " add support for manual expansion when one should have occurred but didn't; ex:
    "         la semaine drn    →    la semaine dernière
    exe 'Aab '.a:abbr.' '.(escape(a:1, ' ')).(empty(en_args) ? '' : ' '.en_args[0])
    "                      │
    "                      └─ The first expansion could contain a space.
    "                      If it does, we need to escape it.
    "                      Otherwise, when we manually expand the
    "                      abbreviation, we would only get the last word.
    "                      Ex:
    "                      Try `bdo C-v SPC C-]`. Instead of getting `by default`,
    "                      we would get `default`.

    if nature ==? 'adj'

        let s:adj[abbr] = {
                          \ 'le':      get(fr_args, '0', abbr),
                          \ 'les':     get(fr_args, '1', abbr),
                          \ 'la':      get(fr_args, '2', abbr),
                          \ 'les_fem': get(fr_args, '3', abbr),
                          \ 'english': get(en_args, '0', abbr),
                          \ }

        " add support for the following syntax:
        "
        "     Pab adj crn courant    "s  courante  "es  --  current
        "     Pab adj drn dernier    "s  dernière  "s
        call map(s:adj[abbr], '  !s:is_short_adj(abbr, v:key)
        \                      ?     v:val
        \                      :     s:adj[abbr][ v:key ==# "les" ? "le" : "la" ].s:adj[abbr][v:key][1:]
        \                     ')

        " Example of command executed by the next `exe`:
        "     inorea <silent> tpr <c-r>=<sid>expand_adj('tpr','temporaire')<cr>
        "                                                      │
        "                                                      └─ returned by `s:get_expansion('tpr','adj')`
        "
        " We need `s:get_expansion()` because we don't know what's the key
        " inside `s:adj['tpr']`, containing the first true expansion of the
        " abbreviation.
        " Indeed, maybe the abbreviation is only expanded in english or only in french.
        exe 'inorea <silent> '.abbr
         \ .' <c-r>=<sid>expand_adj('.string(abbr).','.string(s:get_expansion(abbr,'adj')).')<cr>'

    elseif nature ==? 'adv'
        let s:adv[abbr] = {
                          \ 'french':  get(fr_args, '0', abbr),
                          \ 'english': get(en_args, '0', abbr),
                          \ }

        exe 'inorea <silent> '.abbr
         \ .' <c-r>=<sid>expand_adv('.string(abbr).','.string(s:get_expansion(abbr,'adv')).')<cr>'

    elseif nature ==? 'noun'

        " if we didn't provide a plural form for a noun, use the same as the
        " singular with the additional suffix `s`
        if len(fr_args) == 1
            let fr_args += [ fr_args[0].'s' ]
        endif

        let s:noun[abbr] = {
                           \ 'sg':      get(fr_args, '0', abbr),
                           \ 'pl':      get(fr_args, '1', abbr),
                           \ 'english': get(en_args, '0', abbr),
                           \ }

        exe 'inorea <silent> '.abbr
         \ .' <c-r>=<sid>expand_noun('.string(abbr).','.string(s:get_expansion(abbr,'noun')).')<cr>'

    elseif nature ==? 'verb'
        let s:verb[abbr] = {
                         \   'fr_inf':   get(fr_args, '0', abbr),
                         \   'fr_il':    get(fr_args, '1', abbr),
                         \   'fr_ils':   get(fr_args, '2', abbr),
                         \   'fr_passe': get(fr_args, '3', abbr),
                         \   'fr_ant':   get(fr_args, '4', abbr),
                         \   'en_inf':   get(en_args, '0', abbr),
                         \ }

        " With the command:
        "     Pab verb ctn contenir contient contiennent contenu contenant -- contain
        "
        " … `contains contained containing` should be deduced from `contain`
        if s:verb[abbr].en_inf !=# abbr
            call extend(s:verb[abbr],
                                    \ {
                                    \   'en_s':   s:verb[abbr].en_inf.'s',
                                    \   'en_ed':  s:verb[abbr].en_inf.'ed',
                                    \   'en_ing': matchstr(s:verb[abbr].en_inf, '.*\zee\?').'ing',
                                    \ } )
        endif

        exe 'inorea <silent> '.abbr
         \ .' <c-r>=<sid>expand_verb('.string(abbr).','.string(s:get_expansion(abbr,'verb')).')<cr>'
    endif
endfu

fu! s:separate_args_enfr(args) abort "{{{2
    let [ fr_args, en_args ] = [ [], [] ]

    " check if there's a double dash inside the arguments passed to `:Pab`
    " a double dash is used to end the french arguments; the next ones are
    " english
    let dash = index(a:args, '--')
    " the double dash is at the start of the command:
    "     :Pab abr -- abbreviation
    if dash == 0
        let en_args = a:args[1:]

    " there's a double dash somewhere in the middle
    "     :Pab abr french_abbr … -- english_abbr
    elseif dash != -1
        let fr_args = a:args[0:dash-1]
        let en_args = a:args[dash+1:]

        " if the argument after the double dash is a double quote, the english
        " abbreviation should be the same as the french one
        "     :Pab noun agt argument -- "
        if get(en_args, 0, '') ==# '"'
            let en_args[0] = fr_args[0]
        endif

    " there's no double dash
    "     :Pab abr french_abbr …
    else
        let fr_args = a:args
    endif
    return [ fr_args, en_args ]
endfu

fu! s:should_we_capitalize() abort "{{{2
" Should `pdo` be expanded into `by default` or into `By default,`?
    let cml              = !empty(&l:cms) ? '\V\%('.escape(split(&l:cms, '%s')[0], '\').'\)\?\v' : ''
    let after_dot        = match(getline('.'), '\v%(\.|\?|!)\s+%'.col('.').'c') != -1
    let after_nothing    = match(getline('.'), '\v^\s*'.cml.'\s*%'.col('.').'c') != -1
    let dot_on_prev_line = match(getline(line('.')-1), '\v%(\.|\?|!)\s*$') != -1
    let empty_prev_line  = match(getline(line('.')-1), '^\s*$') != -1

    return after_dot || (
    \                     after_nothing &&
    \                                   ( empty_prev_line || ( dot_on_prev_line || line('.') == 1 ) )
    \                   )
endfu

" abbreviations {{{2

"             ┌─ Poly abbreviation
"             │
com! -nargs=+ Pab call s:pab(<f-args>)

" TODO:
" add support for cycling, to get feminine plural and maybe for verb conjugations
" use `C-]` (or `C-g j` and `C-g J`)

Pab adj crn courant "s courante "es -- current
Pab adj drn dernier "s dernière "s
Pab adj ncs nécessaire "s nécessaire "s -- necessary
Pab adj prc précédent -- previous
Pab adj tpr temporaire -- temporary

Pab adv  bcp  beaucoup -- a\ lot\ of
Pab adv  bdo  -- by\ default
Pab adv  ctl  actuellement
Pab adv  gnr  généralement -- generally
Pab adv  pbb  probablement -- probably
Pab adv  pdo  par\ défaut
Pab adv  plq  plutôt\ que
Pab adv  rtt  -- rather\ than
Pab adv  tmt  automatiquement -- automatically
Pab adv  tprr temporairement -- temporarily
Pab adv  trm  autrement -- otherwise

Pab noun bfr buffer -- "
Pab noun ccr occurrence -- "
Pab noun cct concaténation -- concatenation
Pab noun cfg configuration -- "
Pab noun cmm commande -- command
Pab noun crc caractère -- character
Pab noun dcl déclaration
Pab noun drc dossier -- directory
Pab noun fcn fonction -- function
Pab noun fhr fichier -- file
Pab noun fnt fenêtre -- window
Pab noun hne chaîne -- string
Pab noun icn icône -- icon
Pab noun kbg key\ binding -- "
Pab noun lg  ligne -- line
Pab noun mvm mouvement
Pab noun nvr environnement -- environment
Pab noun opn option -- "
Pab noun opu opérateur -- operator
Pab noun pcs processus processus -- process
Pab noun pgf paragraphe -- paragraph
Pab noun prg programme -- program
Pab noun pth parenthèse -- parentheses
Pab noun rgm argument -- "
Pab noun rgs registre -- register
Pab noun rhh recherche -- search
Pab noun rmp remplacement -- replacement
Pab noun sbs substitution -- "
Pab noun stt -- statement
Pab noun tah tâche -- task
Pab noun vlr valeur -- value
Pab noun vnm évènement -- event
Pab noun vrb variable -- "
Pab noun xpr expression -- "

Pab verb ctn contenir contient contiennent contenu contenant -- contain
Pab verb dsp -- display
Pab verb dwl télécharger -- download
Pab verb ffh afficher affiche affichent affiché affichant
Pab verb llw -- allow
Pab verb prm permettre permet permettent permis permettant
Pab verb rpl remplacer remplace remplacent remplacé remplaçant -- replace
Pab verb rtr retourner retourne retournent retourné retournant -- return
Pab verb lls illustrer illustre illustrent illustré illustrant


inorea  ac    avec
inorea  al    la
inorea  cm    comme
inorea  crr   correspondant à
inorea  ds    dans
inorea  dsn   doesn't
inorea  ee    être
inorea  el    le
inorea  fi    if
inorea  fxm   FIXME
inorea  ie    i.e.
inorea  itr   intérieur
inorea  izn   isn't
inorea  mm    même
inorea  nimp  n'importe quel
inorea  ocd   autocmd
inorea  ot    to
inorea  pee   peut-être
inorea  pls   plusieurs
inorea  pmp   peu importe
inorea  pr    pour
inorea  prt   particulièrement
inorea  pt    peut
inorea  ptt   pattern
inorea  svr   several
inorea  td    TODO
inorea  vai   via
inorea  wsp   whitespace
