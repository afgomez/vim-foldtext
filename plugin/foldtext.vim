if has('multi_byte')
    let defaults = {'placeholder': '…'}
else
    let defaults = {'placeholder': '...'}
endif
let defaults['denominator'] = 25
let defaults['gap'] = 4

if !exists('g:FoldText_placeholder')
    let g:FoldText_placeholder = defaults['placeholder']
endif
if !exists('g:FoldText_gap')
    let g:FoldText_gap = defaults['gap']
endif

unlet defaults

function! FoldText()
    " Returns a line representing the folded text
    "
    " A fold across the following:
    "
    " fu! MyFunc()
    "    call Foo()
    "    echo Bar()
    " endfu
    "
    " should, in general, produce something like:
    "
    " fu! MyFunc() <...> endfu                    L*15 O*2/5 Z*2
    "
    " The folded line has the following components:
    "
    "   - <...>           the folded text, but squashed;
    "   - endfu           the last line (where applicable);
    "   - L*15            the number of lines folded (including first);
    "   - O*2/5           the fraction of the whole file folded;
    "   - Z*2             the fold level of the fold.
    "
    " You may also define any of the following strings:
    "
    " let g:FoldText_placeholder = '<...>'
    " let g:FoldText_line = 'L'
    " let g:FoldText_level = 'Z'
    " let g:FoldText_whole = 'O'
    " let g:FoldText_division = '/'
    " let g:FoldText_multiplication = '*'
    " let g:FoldText_epsilon = '0'
    " let g:FoldText_denominator = 25
    "
    let fs = v:foldstart
    while getline(fs) =~ '^\s*$'
        let fs = nextnonblank(fs + 1)
    endwhile
    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let spaces = repeat(' ', &tabstop)
        let line = substitute(getline(fs), '\t', spaces, 'g')
    endif

    let foldEnding = strpart(getline(v:foldend), indent(v:foldend), 3)

    let endBlockChars = ['end', '}', ']', ')']
    let endBlockRegex = printf('^\s*\(%s\)\(;\|,\)\?$', join(endBlockChars, '\|'))

    let endCommentRegex = '\s*\*/$'
    let startCommentBlankRegex = '\v^\s*/\*!?\s*$'

    if foldEnding =~ endBlockRegex
        let foldEnding = " " . g:FoldText_placeholder . " " . foldEnding
    elseif foldEnding =~ endCommentRegex
        if getline(v:foldstart) =~ startCommentBlankRegex
            let nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
            let line = line . nextLine
        endif
        let foldEnding = " " . g:FoldText_placeholder . " " . foldEnding
    else
        let foldEnding = " " . g:FoldText_placeholder
    endif
    let foldColumnWidth = &foldcolumn ? 1 : 0
    let numberColumnWidth = &number ? strwidth(line('$')) : 0
    let width = winwidth(0) - foldColumnWidth - numberColumnWidth - g:FoldText_gap

    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = printf("| %4d lines | ", foldSize)

    let ending = foldSizeStr

    if strwidth(line . foldEnding . ending) >= width
        let line = strpart(line, 0, width - strwidth(foldEnding . ending))
    endif

    let expansionStr = repeat(" ", g:FoldText_gap + width - 1 - strwidth(line . foldEnding . ending))
    return line . foldEnding . expansionStr . ending
endfunction

set foldtext=FoldText()
