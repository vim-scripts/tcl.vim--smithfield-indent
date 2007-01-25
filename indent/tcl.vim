" Vim indent file for Tcl/tk language
" Language:	Tcl
" Maintained:	SM Smithfield <m_smithfield@yahoo.com>
" Last Change:	01/25/2007 (02:11:02)
" Filenames:    *.tcl
" Version:      0.2
" ------------------------------------------------------------------
" GetLatestVimScripts: 1717 1 :AutoInstall: indent/tcl.vim
" ------------------------------------------------------------------

" -------------------------
" Handles trailing comments, escaped braces, commented braces, lots of stuff
" Faster than default (by alot)
" TODO line-continuations -> deep indent

" Only load this indent file when no other was loaded yet.
if exists("b:did_indent")
  finish
endif

let b:did_indent = 1

setlocal nosmartindent

" indent expression and keys that trigger it
setlocal indentexpr=GetTclIndent()
setlocal indentkeys-=:,0#

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" say something once, why say it again
if exists("*GetTclIndent")
  finish
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" regex -> syntax group names that are or delimit strings AND comments
let s:syng_strcom = '\<tcl\%(Quotes\|Comment\|SemiColon\|Special\|Todo\)\>'
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),0),'name') =~ '".s:syng_strcom."'"

" returns 0/1 whether the cursor pos is in a string/comment syntax run or no.
function! s:IsInStringOrComment(lnum, col)
    let q = synIDattr(synID(a:lnum, a:col, 0), 'name') 
    let rv = (q =~ s:syng_strcom)
    return rv
endfunction

" returns the position of the brace that opens the current line
" or -1 for no match
function! s:GetOpenBrace(lnum)
    let openpos = s:rightmostChar(a:lnum, '{', -1)
    let closepos = s:rightmostChar(a:lnum, '}', -1)
    let sum = 0

    while openpos >= 0
        if closepos < 0
            let sum = sum + 1
            if sum > 0
                return openpos
            endif
            let openpos = s:rightmostChar(a:lnum, '}', openpos-1)
        elseif openpos > closepos
            let sum = sum + 1
            if sum > 0
                return openpos
            endif
            let closepos = s:rightmostChar(a:lnum, '}', openpos-1)
            let openpos = s:rightmostChar(a:lnum, '{', openpos-1)
        else
            let sum = sum - 1
            let openpos = s:rightmostChar(a:lnum, '{', closepos-1)
            let closepos = s:rightmostChar(a:lnum, '}', closepos-1)
        endif
    endwhile
    return -1
endfunction

" returns the position of the brace that closes the current line
" or -1 for no match
function! s:GetCloseBrace(lnum)
    let openpos = s:leftmostChar(a:lnum, '{', -1)
    let closepos = s:leftmostChar(a:lnum, '}', -1)
    let sum = 0

    while closepos >= 0
        if openpos < 0
            let sum = sum + 1
            if sum > 0
                return closepos
            endif
            let closepos = s:leftmostChar(a:lnum, '}', closepos+1)
        elseif closepos < openpos
            let sum = sum + 1
            if sum > 0
                return closepos
            endif
            let openpos = s:leftmostChar(a:lnum, '{', closepos+1)
            let closepos = s:leftmostChar(a:lnum, '}', closepos+1)
        else
            let sum = sum - 1
            let closepos = s:leftmostChar(a:lnum, '}', openpos+1)
            let openpos = s:leftmostChar(a:lnum, '{', openpos+1)
        endif
    endwhile
    return -1
endfunction

" returns the pos of the leftmost valid occurance of ch
" or -1 for no match
function! s:leftmostChar(lnum, ch, pos0)
    let line = getline(a:lnum)
    let pos1 = stridx(line, a:ch, a:pos0)
    if pos1>=0
        if s:IsInStringOrComment(a:lnum, pos1+1) == 1
            let pos2 = pos1
            let pos1 = -1
            while pos2>=0 && s:IsInStringOrComment(a:lnum, pos2+1)
                let pos2 = stridx(line, a:ch, pos2+1)
            endwhile
            if pos2>=0 
                let pos1 = pos2
            endif
        endif
    endif
    return pos1
endfunction

" returns the pos of the rightmost valid occurance of ch
" or -1 for no match
function! s:rightmostChar(lnum, ch, pos0)
    let line = getline(a:lnum)
    if a:pos0 == -1
        let pos = strlen(line)
    else
        let pos = a:pos0
    endif
    let pos1 = strridx(line, a:ch, pos)
    if pos1>=0
        if s:IsInStringOrComment(a:lnum, pos1+1) == 1
            let pos2 = pos1
            let pos1 = -1
            while pos2>=0 && s:IsInStringOrComment(a:lnum, pos2+1)
                let pos2 = strridx(line, a:ch, pos2-1)
            endwhile
            if pos2>=0
                let pos1 = pos2
            endif
        endif
    endif
    return pos1
endfunction

function! s:GetTclIndent(lnum0)

    " cursor-restore-position 
    let vcol = col('.')
    let vlnu = a:lnum0

    " ------------
    " current line
    " ------------

    let line = getline(vlnu)
    let ind1 = -1
    let flag = 0
    
    " a line may have an 'open' open brace and an 'open' close brace
    let openbrace = s:GetOpenBrace(vlnu)
    let closebrace = s:GetCloseBrace(vlnu)

    " does the line have an 'open' closebrace?
    if closebrace >= 0
        " move the cursor one col inside the brace
        call cursor(vlnu, closebrace+1) 
        " seek the mate
        let matchopenlnum = searchpair('{', '', '}', 'bW', s:skip_expr)
        " does it have a mate
        if  matchopenlnum >= 0
            let matchopen = s:GetOpenBrace(matchopenlnum)
            let matchopenline = getline(matchopenlnum)
            if matchopen >= 0 
                let leadHasStuff = 0
                let trailHasStuff = 0
                let pos1 = matchend(matchopenline, '{\s*\S', matchopen)
                if pos1 >= 0
                    let leadHasStuff = !s:IsInStringOrComment(matchopenlnum,pos1)
                endif
                " find the first non-ws-char after matchopen, is NOT string/comment -> has stuff
                let expr = '\S\s*\%'.(closebrace+1).'c}'
                let pos2 = match(line, expr)
                if pos2 >= 0
                    let trailHasStuff = !s:IsInStringOrComment(vlnu,pos2)
                endif
                " find the first non-ws-char before closebrace, is NOT string/comment? -> has stuff
                if leadHasStuff && trailHasStuff
                    let ind1 = matchend(matchopenline, '{\s*', matchopen)
                elseif trailHasStuff
                    let ind1 = indent(matchopenlnum) + &sw
                elseif leadHasStuff
                    let ind1 = matchend(matchopenline, '{\s*', matchopen)
                    " there is some stuff on the line, seek to the first
                    " nonwhite and make a hanging indent
                else
                    let ind1 = indent(matchopenlnum)
                    " a comment? 
                    " " or nothing?
                endif
            endif
        endif
        let flag = 1
    endif

    if openbrace >= 0
        " there is ALSO an open brace:
    endif

    if flag == 1
        call cursor(vlnu, vcol)
        return ind1
    endif

    " ---------
    " prev line
    " ---------

    let flag = 0
    let prevlnum = prevnonblank(vlnu - 1)
    
    " at the start? => indent = 0
    if prevlnum == 0
        return 0
    endif

    let line = getline(prevlnum)
    let ind2 = indent(prevlnum)

    " if there is an open brace
    if line =~ '{'
        let openbrace = s:GetOpenBrace(prevlnum)
        if openbrace >= 0 
            " does the line end in a comment? or nothing?
            if s:IsInStringOrComment(prevlnum, strlen(line)) || line =~ '{\s*$'
                let ind2 = ind2 + &sw
                let flag = 1
            else
                let ind2 = matchend(line, '{\s*', openbrace)
            endif
        endif
    endif

    if flag == 1
        call cursor(vlnu, vcol)
        return ind2
    endif

    if line =~ '}'
        " upto this point, the indent is simply inherited from prevlnum
        let closebrace = s:GetCloseBrace(prevlnum)
        if closebrace >= 0
            " this line SHOULD have the same indent as the line that the
            " previous block closes, which is what a closebrace would get
            call cursor(prevlnum, closebrace+1) " move the cursor one col inside the brace
            let openbracelnum = searchpair('{', '', '}', 'bW', s:skip_expr)
            if  openbracelnum >= 0
                let openbrace = s:GetOpenBrace(openbracelnum)
                if openbrace >= 0 
                    let ind2 = indent(openbracelnum)
                endif
            endif
        endif
    endif

    " restore the cursor to its original position
    call cursor(vlnu, vcol)
    return ind2
endfunction

function! GetTclIndent()
    let l:val = s:GetTclIndent(v:lnum)
    return l:val
endfunction

function! Gpeek()
    let lnu = line('.')
    let val = s:GetTclIndent(lnu)
    let openbrace = s:GetOpenBrace(lnu)
    let closebrace = s:GetCloseBrace(lnu)
    echo "ind>" val ": (" openbrace closebrace ")"
endfunction
