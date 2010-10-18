" Vim indent file for Tcl/tk language
" Language:	Tcl
" Maintained:	SM Smithfield <m_smithfield@yahoo.com>
" Last Change:	02/01/2007 (06:35:02)
" Filenames:    *.tcl
" Version:      0.3
" ------------------------------------------------------------------
" GetLatestVimScripts: 1717 1 :AutoInstall: indent/tcl.vim
" ------------------------------------------------------------------


" if there is another, bail
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
let s:syng_strcom = '\<tcl\%(Quotes\|Comment\|SemiColon\|Special\|Todo\|Start\)\>'
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),0),'name') =~ '".s:syng_strcom."'"

" returns 0/1 whether the cursor pos is in a string/comment syntax run or no.
function s:IsInStringOrComment(lnum, col)
    let q = synIDattr(synID(a:lnum, a:col, 0), 'name') 
    let rv = (q =~ s:syng_strcom)
    return rv
endfunction

" returns the position of the brace that opens the current line
" or -1 for no match
function s:GetOpenBrace(lnum)
    let openpos = s:rightmostChar(a:lnum, '{', -1)
    let closepos = s:rightmostChar(a:lnum, '}', -1)
    let sum = 0

    while openpos >= 0
        if closepos < 0
            let sum = sum + 1
            if sum > 0
                return openpos
            endif
            let openpos = s:rightmostChar(a:lnum, '{', openpos-1)
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
function s:GetCloseBrace(lnum)
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
function s:leftmostChar(lnum, ch, pos0)
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
function s:rightmostChar(lnum, ch, pos0)
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


function s:HasLeadingStuff(lnu, pos)
    let rv = 0
    let line = getline(a:lnu)
    let pos1 = matchend(line, '{\s*\S', a:pos)
    if pos1 >= 0
        let rv = !s:IsInStringOrComment(a:lnu,pos1)
    endif
    return rv
endfunction


function s:HasTrailingStuff(lnu, pos)
    " find the first non-ws-char after matchopen, is NOT string/comment -> has stuff
    let rv = 0
    let line = getline(a:lnu)
    let expr = '\S\s*\%'.(a:pos+1).'c}'
    let pos1 = match(line, expr)
    return (pos1 >= 0)
endfunction

function s:LineContinueIndent(lnu)
    let ind = 0
    if a:lnu > 1 
        let pline = getline(a:lnu-1)
        let line = getline(a:lnu)
        if pline =~ '\\$'
            if line !~ '\\$'
                let ind = -&sw
            endif
        else
            if line =~ '^\(#\)\@!.*\\$'
                let ind = &sw
            endif
        endif
    endif
    return ind
endfunction

function s:CloseBracePriorIter(lnu,pos)
    " what is the ind for a line that has this close brace previous?
    " this function often depends on the previous open brace
    let ind = -1
    call cursor(a:lnu, a:pos+1) 
    " seek the mate
    let matchopenlnum = searchpair('{', '', '}', 'bW', s:skip_expr)
    " does it have a mate
    if  matchopenlnum >= 0
        let closeopenpos = s:GetCloseBrace(matchopenlnum)
        if closeopenpos >= 0
            " " recurse
            let ind = s:CloseBracePriorIter(matchopenlnum, closeopenpos)
        else
            let ind = indent(matchopenlnum)
            " if matchopenlnum, is lc-bumped, then remove that bump
            let pline = getline(matchopenlnum-1)
            if pline =~ '\\$'
                let ind = ind - &sw
                let ind = ind - (ind % &sw)
            endif
        endif
    endif
    return ind
endfunction

function s:CloseBraceInd(lnu, pos)
    let ind = -1
    call cursor(a:lnu, a:pos+1) 
    " seek the mate
    let matchopenlnum = searchpair('{', '', '}', 'bW', s:skip_expr)
    " does it have a mate
    if  matchopenlnum >= 0
        let matchopen = s:GetOpenBrace(matchopenlnum)
        let matchopenline = getline(matchopenlnum)
        let closeopenpos = s:GetCloseBrace(matchopenlnum)

        if closeopenpos >= 0
            " recurse
            let ind = s:CloseBracePriorIter(matchopenlnum, closeopenpos)
        else
            let hasLeadingStuff = s:HasLeadingStuff(matchopenlnum, matchopen)
            let hasTrailingStuff = s:HasTrailingStuff(a:lnu, a:pos)

            if hasLeadingStuff && hasTrailingStuff
                " seek to the first nonwhite and make a hanging indent
                let ind = matchend(matchopenline, '{\s*', matchopen)
            elseif hasTrailingStuff
                " indent of openbrace PLUS shiftwidth
                let ind = indent(matchopenlnum) + &sw
            elseif hasLeadingStuff
                " let ind = matchend(matchopenline, '{\s*', matchopen)
                let ind = indent(matchopenlnum)
            else
                " indent of openbrace
                let ind = indent(matchopenlnum)
            endif

            let pline = getline(matchopenlnum-1)
            if pline =~ '\\$'
                let ind = ind - &sw
                let ind = ind - (ind % &sw)
            endif
        endif

    endif
    return ind
endfunction

function s:CloseBracePriorInd(lnu,pos)
    " what is the ind for a line that has this close brace previous?
    " this function often depends on the previous open brace
    let ind = -1
    call cursor(a:lnu, a:pos+1) 
    " seek the mate
    let matchopenlnum = searchpair('{', '', '}', 'bW', s:skip_expr)
    " does it have a mate
    if  matchopenlnum >= 0
        let closeopenpos = s:GetCloseBrace(matchopenlnum)
        if closeopenpos >= 0
            " recurse
            let ind = s:CloseBracePriorIter(matchopenlnum, closeopenpos)
        else
            let ind = indent(matchopenlnum)
            " if matchopenlnum, is lc-bumped, then remove that bump
            let pline = getline(matchopenlnum-1)
            if pline =~ '\\$'
                let ind = ind - &sw
                let ind = ind - (ind % &sw)
            endif
        endif
    endif
    return ind
endfunction

function s:GetTclIndent(lnum0)

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
        let ind = s:CloseBraceInd(vlnu, closebrace)
        let flag = 1
    endif
    
    if flag == 1
        call cursor(vlnu, vcol)
        return ind
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


    if line =~ '}'
        " upto this point, the indent is simply inherited from prevlnum
        let closebrace = s:GetCloseBrace(prevlnum)
        if closebrace >= 0
            let ind2 = s:CloseBracePriorInd(prevlnum, closebrace)
            let flag = 1
        endif
    endif


    " if there is an open brace
    if line =~ '{'
        let openbrace = s:GetOpenBrace(prevlnum)
        if openbrace >= 0 
            " does the line end in a comment? or nothing?
            if s:HasLeadingStuff(prevlnum, openbrace)
                " LineContinueIndent
                let ind3 = s:LineContinueIndent(prevlnum)
                let ind2 = matchend(line, '{\s*', openbrace) + ind3
            else
                let ind2 = ind2 + &sw
            endif
            let flag = 1
        endif
    endif

    if flag == 0
        " if nothing else has changed the indentation, check for a
        let ind3 = s:LineContinueIndent(prevlnum)
        let ind2 = ind2 + ind3
    endif

    " restore the cursor to its original position
    call cursor(vlnu, vcol)
    return ind2
endfunction

function GetTclIndent()
    let l:val = s:GetTclIndent(v:lnum)
    return l:val
endfunction

function Gpeek()
    let lnu = line('.')
    let val = s:GetTclIndent(lnu)
    let openbrace = s:GetOpenBrace(lnu)
    let closebrace = s:GetCloseBrace(lnu)
    echo "ind>" val ": (" openbrace closebrace ")"
endfunction
