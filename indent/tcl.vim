" finish

" Handles trailing comments
" FASTER than default (by alot)
" TODO line-continuations -> deep indent?
" TODO detect array set {} ?? hanging indent for array set {}

" Only load this indent file when no other was loaded yet.
if exists("b:did_indent")
  finish
endif

let b:did_indent = 1

" always use setlocal for indent expr
setlocal indentexpr=GetTclIndent_fast()
setlocal indentkeys-=:,0#

" indent function only need to be defined once
" say something once, why say it again
" if exists("*GetTclIndent_fast")
  " finish
" endif
" to trigger indenting after a keyword, add the word to cinkeys

" trim tcl comments
function! s:Trim(line)
    let retval = a:line
    let commentidx = match(retval,";#.*$")
    if commentidx >= 0
	let retval = strpart(retval,0,commentidx)
    endif
    return retval
endfun

" pare nested braces
function! s:Pare(line)
    let l:retval = a:line
    let l:pat = '{[^{]\{-}}'
    while (match(l:retval,l:pat)!=-1)
	" echo l:retval
	let l:retval = substitute(l:retval,l:pat,"","")
    endwhile
    " all done
    return l:retval
endfun


" simple version
function! GetTclIndent_fast()
    " current (non-blank) line
    let lnum1 = v:lnum
    " seek previous (non-blank) line
    let lnum0 = prevnonblank(v:lnum - 1)
    " at the TOP? start with zero
    if lnum0 == 0
	return 0
    endif
    let flag = 1
    let ind = indent(lnum0)
    " get the line, trim trailing comments, pare nested braces
    let pline = s:Pare(s:Trim(getline(lnum0)))
    let line  = s:Pare(s:Trim(getline(lnum1)))
    " add for prev line that ends with open '{'
    if pline =~ '{\s*$'
	let ind = ind + &sw
    endif
    " subtract for current line that starts with open '}'
    if line =~ '^\s*}'
	let ind = ind - &sw
    endif
    " subtract for prev line that ends with open '}' AND does not also start with open '}'
    if pline =~ '}\s*$' && pline !~ '^\s*}'
	let ind = ind - &sw
    endif

    " error debuggery
    " echoerr v:lnum . " -> " . ind . " (" . lnum0 . "," . lnum1 . ")"
    return ind
endfun
