" RunView:
"   Author: Charles E. Campbell
"   Date:   Nov 25, 2013
"   Version: 3
" Copyright:    Copyright (C) 2005-2013 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like most software that's free,
"               RunView.vim is provided *as is* and comes with no warranty
"               of any kind, either expressed or implied. By using this
"               plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
" GetLatestVimScripts: 2511 1 :AutoInstall: RunView.vim

" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_RunView")
 finish
endif
let g:loaded_RunView= "v3h"
"DechoTabOn

" ---------------------------------------------------------------------
"  Defaults: {{{1
if !exists("g:runview_filtcmd")
 let g:runview_filtcmd= "ksh"
endif
if !exists("g:runview_swapwin")
 let g:runview_swapwin= 1
endif

" ---------------------------------------------------------------------
"  Public Interface: {{{1
com!      -bang -range=% -nargs=? RunView let s:winposn= SaveWinPosn(0)|sil <line1>,<line2>call s:RunView(<bang>0,<q-args>)
sil! com  -bang -range=% -nargs=? RV      let s:winposn= SaveWinPosn(0)|sil <line1>,<line2>call s:RunView(<bang>0,<q-args>)

" \rh map: RunView filter-command
if !hasmapto('<Plug>RunViewH')
 vmap <unique> <Leader>rh <Plug>RunViewH
endif
vmap <silent> <script> <Plug>RunViewH	:let s:winposn= SaveWinPosn(0)<bar>call <SID>RunView(0)<cr>

" \rv map: RunView! filter-command
if !hasmapto('<Plug>RunViewV')
 vmap <unique> <Leader>rv <Plug>RunViewV
endif
vmap <silent> <script> <Plug>RunViewV	:let s:winposn= SaveWinPosn(0)<bar>call <SID>RunView(1)<cr>

" =====================================================================
"  Functions: {{{1

" ---------------------------------------------------------------------
" RunView: {{{2
"   v  : controls whether 0=horizontal or 1=vertical splitting is used (default: vertical splitting)
"   ...: if present, use provided argument as the filter command (unless it begins with a "-")
"        by default, uses b:runview_filtcmd
"        If present and begins with a "-", then the argument is provided as an option to b:runview_filtcmd
fun! s:RunView(v,...) range
"  call Dfunc("RunView(v=".a:v.") [".a:firstline.",".a:lastline."] a:0=".a:0)

  " set splitright to zero while in this function
  let keep_splitright= &splitright
  let keep_splitbelow= &splitbelow
  set nosplitright nosplitbelow

  " if arg provided, use it as filter-command.  Use it for the default next time.
  " Otherwise, use g:runview_filtcmd.
  if a:0 > 0 && a:1 != ""
   if a:1 =~ '^-'
    let filtcmd = b:runview_filtcmd
    let i       = 1
	while i <= a:0
	 let filtcmd = filtcmd." ".a:{i}
	 let i       = i + 1
	endwhile
   else
    " use argument as filter command
    let filtcmd           = a:1
    let g:runview_filtcmd = filtcmd
   endif
  elseif exists("b:runview_filtcmd")
   " use buffer-local filter command
   let filtcmd= b:runview_filtcmd
  else
   " use default filter command
   let filtcmd= g:runview_filtcmd
  endif
  let filtcmdfile= substitute(filtcmd,' .*$','','')
"  call Decho("filtcmd<".filtcmd.">")
"  call Decho("filtcmdfile<".filtcmdfile.">")

  " get a copy of the selected lines
  let keepa   = @a
  let marka   = getpos("'a")
  let curfile = expand("%")
  let curname = bufname("%")
  exe "sil ".a:firstline.",".a:lastline."y a"
  if filtcmd =~ '-@'
   " insert curfile before -@
   let winout = substitute(filtcmd,'^\(.*\)\(-@ .*\)$','\1','')." ".curfile." ".substitute(filtcmd,'^\(.*\)\(-@ .*\)$','\2','')
  else
   let winout = filtcmd.' '.curfile
  endif
"  call Decho("curfile<".curfile.">")
"  call Decho("winout<".winout.">")

  if bufexists(filtcmdfile)
   " output window already exists by given name.
   " Place delimiter and append output to it
"   call Decho("output window<".g:runview_filtcmd."> already exists, appending to it")
   let curwin  = winnr()
   let bufout  = bufwinnr(filtcmdfile)
   exe bufout."wincmd w"
   set ma
   let lastline= line("$")
"   call Decho("lastline=".lastline)
   let delimstring = "===".strftime("%m/%d/%y %H:%M:%S")."==="
   call setline(lastline+1,delimstring)
   $

   " run the filter command here
   if filtcmd =~ '\s%\(\s\|$\)'
	let winout= substitute(filtcmd,'\(\s\)%\(\s\|$\)','\1'.curname.'\2','')
"	call Decho("exe sil r !".winout)
	exe "sil r !".winout
   else
    sil put a
    let lastlinep2= lastline + 2
"    call Decho("exe sil ".lastlinep2.",$!".filtcmd)
    exe "sil ".lastlinep2.",$!".filtcmd
   endif

   set noma nomod bh=wipe
   $
   call search('^===','bcW')
   exe "norm! z\<cr>"
   redraw
   exe curwin."wincmd w"

  else
   " (vertically) split and run register a's lines through filtcmd
"   call Decho("split and run filtcmd<".filtcmd.">")
"   call Decho("curname<".curname.">")
   if !a:v
    vert new
   else
    new
   endif
   setlocal ma buftype=nofile bh=wipe noswapfile
   if filtcmd =~ '\s%\(\s\|$\)'
	let winout= substitute(filtcmd,'\(\s\)%\(\s\|$\)','\1'.curname.'\2','')
	sil! %d
"	call Decho("exe sil r !".winout)
	exe "sil r !".winout
   else
    sil put a
"    call Decho("exe sil %!".filtcmd)
    exe "sil %!".filtcmd
   endif
   exe "file ".fnameescape(filtcmdfile)
   let title       = 'RunView '.filtcmd.' Output Window'
   let delimstring = "===".strftime("%m/%d/%y %H:%M:%S")."==="
   1
   sil put!=''
   put =''
   call setline(1,title)
   call setline(2,delimstring)
   sil 3
   set ft=runview
   set noma nomod
   $
   call search('^===','bcW')
   exe "norm! z\<cr>"
   redraw
   if g:runview_swapwin == 1
"	call Decho("exchange windows")
    wincmd x
   else
"	call Decho("move window to above/left")
    wincmd w
   endif
  endif

  " restore register a, splitright, and splitbelow
"  call Decho("restore register 2, splitright, splitbelow")
  let @a          = keepa
  let &splitright = keep_splitright
  let &splitbelow = keep_splitbelow
  call setpos("'a",marka)

  " restore position in script buffer
"  call Decho("restoring winposn")
  call RestoreWinPosn(s:winposn)

"  call Dret("RunView")
endfun

" ---------------------------------------------------------------------
"  Modelines: {{{1
"  vim: fdm=marker
