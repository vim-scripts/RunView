" RunView:
"   Author: Charles E. Campbell, Jr.
"   Date:   Jan 12, 2009
"   Version: 2
" Copyright:    Copyright (C) 2005-2009 Charles E. Campbell, Jr. {{{1
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
let g:loaded_RunView= "v2"

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
com!         -bang -range -nargs=? RunView silent <line1>,<line2>call s:RunView(<bang>0,<q-args>)
silent! com  -bang -range -nargs=? RV      silent <line1>,<line2>call s:RunView(<bang>0,<q-args>)

" \rh map: RunView filter-command
if !hasmapto('<Plug>RunViewH')
 vmap <unique> <Leader>rh <Plug>RunViewH
endif
vmap <silent> <script> <Plug>RunViewH	:call <SID>RunView(0)<cr>

" \rv map: RunView! filter-command
if !hasmapto('<Plug>RunViewV')
 vmap <unique> <Leader>rv <Plug>RunViewV
endif
vmap <silent> <script> <Plug>RunViewV	:call <SID>RunView(1)<cr>

" =====================================================================
"  Functions: {{{1

" ---------------------------------------------------------------------
" RunView: {{{2
fun! s:RunView(v,...) range
"  call Dfunc("RunView(v=".a:v.") [".a:firstline.",".a:lastline."] a:0=".a:0)

  " set splitright to zero while in this function
  let keep_splitright= &splitright
  let keep_splitbelow= &splitbelow
  set nosplitright nosplitbelow

  " if arg provided, use it as filter-command.
  " Otherwise, use g:runview_filtcmd.
  if a:0 > 0 && a:1 != ""
   let filtcmd= a:1
  else
   let filtcmd= g:runview_filtcmd
  endif
"  call Decho("filtcmd<".filtcmd.">")

  " get a copy of the selected lines
  let keepa   = @a
  let marka   = getpos("'a")
  let curfile = expand("%")
  exe "silent ".a:firstline.",".a:lastline."y a"
  if filtcmd =~ '-@'
   " insert curfile before -@
   let winout = substitute(filtcmd,'^\(.*\)\(-@ .*\)$','\1','')." ".curfile." ".substitute(filtcmd,'^\(.*\)\(-@ .*\)$','\2','')
  else
   let winout = filtcmd.' '.curfile
  endif
"  call Decho("curfile<".curfile.">")
"  call Decho("winout<".winout.">")

  if bufexists(filtcmd." ".curfile)
   " output window already exists by given name.
   " Place delimiter and append output to it
"   call Decho("output window<".filtcmd." ".curfile."> already exists, appending to it")
   let curwin  = winnr()
   let bufout  = bufwinnr(winout)
   exe bufout."wincmd w"
   set ma
   let lastline= line("$")
"   call Decho("lastline=".lastline)
   let delimstring = "===".strftime("%m/%d/%y %H:%M:%S")."==="
   call setline(lastline+1,delimstring)
   $
   silent put a
   let lastlinep2= lastline + 2
"   call Decho("exe silent ".lastlinep2.",$!".filtcmd)
   exe "silent ".lastlinep2.",$!".filtcmd
   set noma nomod bh=wipe
   $
   exe curwin."wincmd w"

  else
   " (vertically) split and run register a's lines through filtcmd
"   call Decho("split and run filtcmd<".filtcmd.">")
   let curname= bufname("%")
"   call Decho("curname<".curname.">")
   if !a:v
    vert new
   else
    new
   endif
   set ma
   silent put a
"   call Decho("exe silent %!".filtcmd)
   exe "silent %!".filtcmd
   exe "file ".fnameescape(winout)
   let title       = 'RunView '.filtcmd.' Output Window'
   let delimstring = "===".strftime("%m/%d/%y %H:%M:%S")."==="
   1
   silent put!=''
   put =''
   call setline(1,title)
   call setline(2,delimstring)
   silent 3
   set ft=runview
   set noma nomod bh=wipe
   $
   if g:runview_swapwin == 1
    wincmd x
   else
    wincmd w
   endif
  endif

  " restore register a, splitright, and splitbelow
  let @a          = keepa
  let &splitright = keep_splitright
  let &splitbelow = keep_splitbelow
  call setpos("'a",marka)

"  call Dret("RunView")
endfun

" ---------------------------------------------------------------------
"  Modelines: {{{1
"  vim: fdm=marker
