""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" townkAutoCompleteChar.vim - Auto complete pair of characters (, ), [, ], {, }, " and '
" Version: 0.9
" Author: Thiago Alves <thiago.salves@gmail.com>
" Maintainer: Thiago Alves <thiago.salves@gmail.com>
" URL: http://townk.blogspot.com
" Licence: This script is released under the Vim License.
" Last modified: 09/04/2007 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:CursorMoved()
    autocmd! TownkAutoCompleteChar CursorMovedI
    let s:last_line = s:actual_line
    let s:last_linenr = s:actual_linenr
    let s:last_col = s:actual_col
    call s:InsertEnter()

    if s:last_linenr == s:actual_linenr && s:last_line != s:actual_line
        let l:last_removed = []
        if len(s:toCompleteStack) > 0 
            if s:toCompleteStack[0][1] != s:actual_linenr
                let s:toCompleteStack = []
            else
                while len(s:toCompleteStack) > 0 && (s:actual_col-1 < s:toCompleteStack[-1][2] || s:toCompleteStack[-1][3] < s:actual_col-1)
                    let l:last_removed = remove(s:toCompleteStack, -1)
                endwhile
            endif
        endif

        if strlen(s:last_line) < strlen(s:actual_line)
            let l:inserted = strpart(s:actual_line, col('.')-2, 1)
            let l:pos_inserted = strpart(s:actual_line, col('.')-1, 1)
            if has_key(s:charactersToComplete, l:inserted) && s:charactersToComplete[l:inserted] == l:pos_inserted
                for i in range(len(s:toCompleteStack))
                    let s:toCompleteStack[i][3] += 2
                endfor
                call add(s:toCompleteStack, [l:pos_inserted, s:actual_linenr, s:actual_col-1, s:actual_col])
            else
                for i in range(len(s:toCompleteStack))
                    let s:toCompleteStack[i][3] += 1
                endfor
            endif
        else
            let l:removed = strpart(s:last_line, col('.')-1, 1)
            let l:nextchar = strpart(s:actual_line, col('.')-1, 1)
            for i in range(len(s:toCompleteStack))
                let s:toCompleteStack[i][3] -= 1
            endfor
            if has_key(s:charactersToComplete, l:removed) && s:charactersToComplete[l:removed] == l:nextchar && 
               \len(l:last_removed) > 0 && l:last_removed[0] == l:nextchar
                call feedkeys("\<C-O>x")
            endif
        endif
    endif
    autocmd TownkAutoCompleteChar CursorMovedI * :call <SID>CursorMoved()
endfunction

function! s:InsertEnter()
    let s:actual_linenr = line('.')
    let s:actual_line = getline(s:actual_linenr)
    let s:actual_col = col('.')
endfunction

function! s:OpenChar(char) 
    let l:result = a:char
    let l:region = synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
    let l:nextchar = strpart(s:actual_line, col('.')-1, 1)
    if l:nextchar !~ '\w' && index(s:notCompleteRegions, l:region) == -1
        let l:result .= s:charactersToComplete[a:char] . "\<Left>"
    endif
    return l:result
endfunction

function! s:CloseChar(char)
    let l:result = a:char
    let l:nextchar = strpart(s:actual_line, col('.')-1, 1)
    if len(s:toCompleteStack) > 0 && s:toCompleteStack[0][2] <= s:actual_col && s:actual_col <= s:toCompleteStack[0][3]
        let l:doit = 1
    else
        let l:doit = 0
    endif
    
    if l:nextchar == a:char && l:doit
        while len(s:toCompleteStack) > 0 && (col('.') < s:toCompleteStack[-1][2] || s:toCompleteStack[-1][3] < col('.')+1)
            call remove(s:toCompleteStack, -1)
        endwhile
        let l:result = "\<Right>"
    endif
    return l:result
endfunction

function! s:CheckChar(char)
    let l:result = a:char
    let l:occur = 0
    let l:lastpos = 0
    let l:nextchar = strpart(s:actual_line, col('.')-1, 1)

    while l:lastpos > -1
        let l:lastpos = stridx(s:actual_line, a:char, l:lastpos+1)
        if l:lastpos > col('.')-2
            break
        endif
        if l:lastpos >= 0
            let l:occur += 1
        endif
    endwhile

    if l:occur == 0 || l:occur%2 == 0
        " Opening char
        let l:region = synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
        if l:nextchar !~ '\w' && index(s:notCompleteRegions, l:region) == -1
            let l:result .= s:charactersToComplete[a:char] . "\<Left>"
        endif
    else
        " Closing char
        if len(s:toCompleteStack) > 0 && s:toCompleteStack[0][2] <= s:actual_col && s:actual_col <= s:toCompleteStack[0][3]
            let l:doit = 1
        else
            let l:doit = 0
        endif

        if l:nextchar == a:char && l:doit
            while len(s:toCompleteStack) > 0 && (col('.') < s:toCompleteStack[-1][2] || s:toCompleteStack[-1][3] < col('.')+1)
                call remove(s:toCompleteStack, -1)
            endwhile
            let l:result = "\<Right>"
        endif
    endif
    return l:result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Control variables to know where some character was inserted or deleted
let s:last_line = ''
let s:actual_line = ''
let s:last_linenr = 0
let s:actual_linenr = 0
let s:last_col = 0
let s:actual_col = 0

" stack of characters autocompleted
let s:toCompleteStack = []

" Movement events
augroup TownkAutoCompleteChar
    autocmd CursorMovedI * :call <SID>CursorMoved()
    autocmd InsertEnter * :call <SID>InsertEnter()
augroup END

" let user define which character he/she wants to autocomplete
if exists("g:tacCharactersToComplete") && type(g:tacCharactersToComplete) == type({})
    let s:charactersToComplete = g:tacCharactersToComplete
    unlet g:tacCharactersToComplete
else
    let s:charactersToComplete = {'(': ')', '{': '}', '[': ']', '"': '"', "'": "'"}
endif

" let user define in which regions the autocomplete feature should not occur
if exists("g:tacNotCompleteRegions") && type(g:tacNotCompleteRegions) == type([])
    let s:notCompleteRegions = g:tacNotCompleteRegions
    unlet g:tacNotCompleteRegions
else
    let s:notCompleteRegions = ["Comment", "String", "Character"]
endif

" create appropriate maps to defined open/close characters
for key in keys(s:charactersToComplete)
    if key == s:charactersToComplete[key]
        if key == "'"
            execute "inoremap <silent> " . key . " <C-R>=<SID>CheckChar(\"'\")<CR>"
        else
            execute "inoremap <silent> " . key . " <C-R>=<SID>CheckChar('" . key . "')<CR>"
        endif
    else
        execute "inoremap <silent> " . key . " <C-R>=<SID>OpenChar('" . key . "')<CR>"
        execute "inoremap <silent> " . s:charactersToComplete[key] . " <C-R>=<SID>CloseChar('" . s:charactersToComplete[key] . "')<CR>"
    endif
endfor

unlet key
