" Copyright (c) 2013 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists("g:loaded_easy_align_plugin")
  finish
endif
let g:loaded_easy_align_plugin = 1

command! -nargs=* -range -bang EasyAlign <line1>,<line2>call easy_align#align('<bang>' == '!', 0, '', <q-args>)
command! -nargs=* -range -bang LiveEasyAlign <line1>,<line2>call easy_align#align('<bang>' == '!', 1, '', <q-args>)

let s:last_command = 'EasyAlign'

function! s:remember_visual(mode)
  let s:last_visual = [a:mode, abs(line("'>") - line("'<")), abs(col("'>") - col("'<"))]
endfunction

function! s:repeat_visual()
  let [mode, ldiff, cdiff] = s:last_visual
  let cmd = 'normal! '.mode
  if ldiff > 0
    let cmd .= ldiff . 'j'
  endif

  let ve_save = &virtualedit
  try
    if mode == "\<C-V>"
      if cdiff > 0
        let cmd .= cdiff . 'l'
      endif
      set virtualedit+=block
    endif
    execute cmd.":\<C-r>=g:easy_align_last_command\<Enter>\<Enter>"
    call s:set_repeat()
  finally
    if ve_save != &virtualedit
      let &virtualedit = ve_save
    endif
  endtry
endfunction

function! s:repeat_in_visual()
  if exists('g:easy_align_last_command')
    call s:remember_visual(visualmode())
    call s:repeat_visual()
  endif
endfunction

function! s:set_repeat()
  silent! call repeat#set("\<Plug>(EasyAlignRepeat)")
endfunction

function! s:generic_easy_align_op(type, vmode, live)
  let sel_save = &selection
  let &selection = "inclusive"

  if a:vmode
    let vmode = a:type
    call s:remember_visual(vmode)
  else
    let tail = "\<C-c>"
    if a:type == 'line'
      silent execute "normal! '[V']".tail
    elseif a:type == 'block'
      silent execute "normal! `[\<C-V>`]".tail
    else
      silent execute "normal! `[v`]".tail
    endif
    let vmode = ''
    unlet! s:last_visual
  endif

  try
    if get(g:, 'easy_align_need_repeat', 0)
      execute "'<,'>". g:easy_align_last_command
    else
      '<,'>call easy_align#align('<bang>' == '!', a:live, vmode, '')
    end
    call s:set_repeat()
  finally
    let &selection = sel_save
  endtry
endfunction

function! s:easy_align_op(type, ...)
  call s:generic_easy_align_op(a:type, a:0, 0)
endfunction

function! s:live_easy_align_op(type, ...)
  call s:generic_easy_align_op(a:type, a:0, 1)
endfunction

function! s:easy_align_repeat()
  if exists('s:last_visual')
    call s:repeat_visual()
  else
    try
      let g:easy_align_need_repeat = 1
      normal! .
    finally
      unlet! g:easy_align_need_repeat
    endtry
  endif
endfunction

nnoremap <silent> <Plug>(EasyAlign) :set opfunc=<SID>easy_align_op<Enter>g@
vnoremap <silent> <Plug>(EasyAlign) :<C-U>call <SID>easy_align_op(visualmode(), 1)<Enter>
nnoremap <silent> <Plug>(LiveEasyAlign) :set opfunc=<SID>live_easy_align_op<Enter>g@
vnoremap <silent> <Plug>(LiveEasyAlign) :<C-U>call <SID>live_easy_align_op(visualmode(), 1)<Enter>

" vim-repeat support
nnoremap <silent> <Plug>(EasyAlignRepeat) :call <SID>easy_align_repeat()<Enter>
vnoremap <silent> <Plug>(EasyAlignRepeat) :<C-U>call <SID>repeat_in_visual()<Enter>

" Backward-compatibility (deprecated)
nnoremap <silent> <Plug>(EasyAlignOperator) :set opfunc=<SID>easy_align_op<Enter>g@

