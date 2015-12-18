" Name: matlab_behave.vim
" Site: http://github.com/elmanuelito/vim-matlab-behave
" Help And Description:
"   See readme file shipped with plugin
" Author: E. Branlard (lastname at gmail dot com) and Github contributors!

" Documentation:
" Registers:
"    Clear register a
"       normal qaq 
"    Set a register to a given value
"       let @a ="\n" 
"    Use redirection to a buffer       
"       redir @s
"       echo "..."
"       redir end
"    Search backward and forawrd and paste in register s (uppercase S is to append)
"       :?%%\|\%^?;/%%\|\%$/y S
"       :?%%\|\%^?;/%%\|\%$/y s



" --------------------------------------------------------------------------------
" --- Cell title in bold 
" --------------------------------------------------------------------------------
highlight MATCELL cterm=bold term=bold gui=bold
match MATCELL /^%%[^%]*$/

" --------------------------------------------------------------------------------
" --- Folding 
" --------------------------------------------------------------------------------
function! MatlabFolds()
    let thisline = getline(v:lnum)
    if match(thisline,'^[\ ]*%%') >=0
        return ">1"
    else
        return "="
    endif
endfunction

setlocal foldmethod=expr
setlocal foldexpr=MatlabFolds()


" --------------------------------------------------------------------------------
" --- Run functionality requirements 
" --------------------------------------------------------------------------------
" Do not enable this plugin if some if these tools are unavailable.
" Linux: they should be installed by the user
" Windows: The rest of the script is rely on these tools, so is not compatible
if !executable('xclip') || !executable('wmctrl') || !executable('xdotool')
	echo "vim-matlab-behave needs xclip, wmctrl and xdotool to be installed."
    finish
endif


" --------------------------------------------------------------------------------
" --- Customization of the command to swtich to matlab and paste
" --------------------------------------------------------------------------------
if !exists("g:matlab_behave_window_name")
    let g:matlab_behave_window_name="MATLAB R"
endif
if !exists("g:vim_window_name")
    let s:vim_window_name=system("xdotool getwindowfocus getwindowname")
    let g:vim_window_name=s:vim_window_name[0:-3]
endif
if !exists("g:matlab_behave_paste_cmd")
    let g:matlab_behave_paste_cmd="ctrl+v"
endif
if !exists("g:matlab_behave_software")
    let g:matlab_behave_software="matlab"
    let g:matlab_behave_software_param="-nojvm"
endif
" Which terminal to use for MatRunExtern
if !exists("g:matlab_behave_terminal")
    " Testing wheter environment variable exists
    if empty($TERM)
        " Default value
        let g:matlab_behave_terminal="xterm" 
    else
        let g:matlab_behave_terminal=$TERM
    end
endif

""" SwitchPastecommand: Switch to matlab window and paste in it. 
" Customize it with the two variables above in your vimrc.  
" Thanks to adrianolinux for the idea.
function! SwitchPasteCommand()
    " !wmctrl -a "MATLAB R";xdotool key "ctrl+v"
   execute "!wmctrl -a \"".g:matlab_behave_window_name."\";xdotool key \"Escape\";xdotool key \"".g:matlab_behave_paste_cmd."\""
endfunction

""" SwitchPastecommand: Switch to matlab window and paste in it. 
" Customize it with the two variables above in your vimrc.  
" Thanks to adrianolinux for the idea.
function! SwitchPasteCommandSil()
    " !wmctrl -a "MATLAB R";xdotool key "ctrl+v"
   silent! execute "!wmctrl -a \"".g:matlab_behave_window_name."\";xdotool key \"Escape\";xdotool key \"".g:matlab_behave_paste_cmd."\""
endfunction

" --------------------------------------------------------------------------------
" --- Cell title in bold 
" --------------------------------------------------------------------------------
""" Run selection (and go back to vim)
function! MatRunSelect()
	" added silent key words to avoid promt when execute shell commands
	" only execute once using i == 1 check upO
	" otherwise it operates k times, k is the number of lines selected
	" it requires a initiate a VisualLineCounter variable when v pressed
	" see the mapping section for this mapping
	if b:VisualLineCounter==1
		normal mm
		silent! !rm -f /tmp/buff
		redir > /tmp/buff
		echo @*
		redir END
		silent! execute "!echo \" \">>/tmp/buff" 
		silent! !cat /tmp/buff|xclip -selection c
		normal `m
		:call SwitchPasteCommandSil()
		" redraw! is need otherwise silent will cause problem when
		" there is an error
		redraw!
		let b:VisualLineCounter+=1
	endif
endfunction

"no change for this function , Yanfei
""" Run Current line
function! MatRunLine()
    " write current line and pipe to xclip
    :.w !xclip -selection c
    "     normal "+yy
    :call SwitchPasteCommand()
endfunction

" no change for this func, Yanfei
""" Run Current Cell
function! MatRunCell()
    normal mm
"     :?%%\|\%^?;/%%\|\%$/w !xclip -selection c 
" Search cell and write to register b (uppercase B to append)
    :?%%\|\%^?;/%%\|\%$/y b
    call system('xclip -selection c ', @b)
    call system('xclip ', @b)
    normal `m
    :call SwitchPasteCommand()
endfunction

" add silent keywords
""" Run Current cell and go back to editor
function! MatRunCellAdvanced()
	"copied to buff and matlab gui
	"add all those silent words by Yanfei
    normal mm
    " silent! execute "!echo \"cd(\'".expand("%:p:h")."\')\">/tmp/buff"  
    silent! execute "!echo \" \">/tmp/buff"  
    " added silent!
    :?%%\|\%^?;/%%\|\%$/w>> /tmp/buff
    " silent! execute "!echo \"edit ".expand("%:f")."\">>/tmp/buff"
    " added silent!
    silent! !cat /tmp/buff|xclip -selection c
    " added silent!
    :call SwitchPasteCommandSil()
	:call SwitchWindow()
    redraw! 
	normal `m
	silent! execute "normal! /%%<cr>"
endfunction

function! SwitchWindow()
	silent! execute "!sleep 0.4"
	silent! execute "!wmctrl -a \"".g:vim_window_name."\""
endfunction

""" Run current script 
" no change by Yanfei
function! MatRun()
	" nothing happens, I replaced all the + register by t, moved to \n
	" from the beginning of the line to the end, It works find now
    normal mm
    let @+="cd('".expand("%:p:h")."\'); run('".expand("%:p")."')\n"
    call system('xclip -selection c ', @+)
    call system('xclip ', @+)
    normal `m
    :call SwitchPasteCommand()
endfunction

""" Run current script in a new matlab session
function! MatRunExtern()
    if g:matlab_behave_software == "matlab"
        call system(g:matlab_behave_terminal." -T '".g:matlab_behave_window_name."' -e \"".g:matlab_behave_software." ".g:matlab_behave_software_param." -r ".shellescape('run '.expand("%:p"))."\"&")
    elseif g:matlab_behave_software == "octave"
        call system(g:matlab_behave_terminal." -T '".g:matlab_behave_window_name."' -e ".g:matlab_behave_software." --persist ".shellescape(expand("%:p"))."&")
    endif
endfunction


" --------------------------------------------------------------------------------
" --- Mappings 
" --------------------------------------------------------------------------------
if !exists("g:matlab_behave_mapping_kind")
    let g:matlab_behave_mapping_kind=1
endif

" Matlab like mappings: 
if g:matlab_behave_mapping_kind == 0
    map <buffer><F5> :w <cr> :call MatRun() <cr><cr>
    map <buffer><C-CR>,k :w <cr> :call MatRunCell()  <cr><cr>
    vmap <buffer><F9> :call MatRunSelect()  <cr><cr>
    " called multiple times depending on how many lines are selected
    map <buffer>,l :w <cr> :call MatRunLine()  <cr><cr>
    map <buffer><f4> :w <cr> :call MatRunExtern() <cr><cr>
    map <buffer>,n :call MatRunCellAdvanced()  <cr><cr>
    "the following lines is added by Yanfei
    nnoremap <S-V> :let b:VisualLineCounter=1<CR> <S-V> 
    nnoremap v :let b:VisualLineCounter=1<CR> v 
endif

" Mapping preferred by the author
if g:matlab_behave_mapping_kind == 1
    map <buffer>,m :w! <cr> :call MatRun() <cr><cr>
    map <buffer>,k :w! <cr> :call MatRunCell()  <cr><cr>
    map <buffer>,o :call MatRunCellAdvanced()  <cr><cr>
    map <buffer>,l :w! <cr> :call MatRunLine()  <cr><cr>
    map <buffer><f4> :w! <cr> :call MatRunExtern() <cr><cr>
    vmap <buffer><F9> :call MatRunSelect()  <cr><cr>
    "the following lines is added by Yanfei
    nnoremap <S-V> :let b:VisualLineCounter=1<CR> <S-V> 
    nnoremap v :let b:VisualLineCounter=1<CR> v 
endif

" 

" --------------------------------------------------------------------------------
" ---  With Align plugin
" --------------------------------------------------------------------------------
" Remeber there is \tt for latex tables and \tsp for spaces
" vmap ,af :Align Ip0p1= = ( ) ; % ,<CR>
" vmap ,ae :Align Ip0p1= = ; %<CR>
"  vmap ,aa :Align Ip0p1= = ; %<CR>
" --------------------------------------------------------------------------------
" ---  Old
" --------------------------------------------------------------------------------
" autocmd BufEnter *.m compiler mlint 
" Save Matlab session
" map ,ss :w <cr> :mksession! /work/code/SessionMatlab.vim <cr>
