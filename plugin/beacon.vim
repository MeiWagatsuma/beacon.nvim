highlight Beacon guibg=white

redir => s:original
    silent! highlight CursorLine
redir END

let s:fake_buf = nvim_create_buf(v:false, v:true)
call nvim_buf_set_lines(s:fake_buf, 0, -1, v:true, [""])
let s:float = 0

let s:fade_timer = 0
let s:close_timer = 0

function! s:Clear_highlight(...)
    if s:close_timer > 0
        call timer_stop(s:close_timer)
    endif
    if s:fade_timer > 0
        call timer_stop(s:fade_timer)
    endif
    if s:float > 0
        call nvim_win_close(s:float, 0)
        let s:float = 0
    endif
endfunction

function! s:Delayed_highlight_position()
    call timer_start(50, funcref("s:Highlight_position"))
endfunction

function! s:Fade_window(...)
    if s:float > 0
        let l:old = nvim_win_get_option(s:float, "winblend")
        call nvim_win_set_option(s:float, 'winblend', l:old + 1)
    endif
endfunction

function! s:Highlight_position(...)
    if s:float > 0
        call s:Clear_highlight()
    endif
    let l:win = nvim_win_get_config(0)
    if has_key(l:win, "relative") && l:win.relative != ""
        return
    endif
    let l:opts = {'relative': 'win', 'width': 40,  'bufpos': [line(".")-1, col(".")], 'height': 1, 'col': 0,
        \ 'row': 0, 'anchor': 'NW', 'style': 'minimal', 'focusable': v:false}
    let s:float = nvim_open_win(s:fake_buf, 0, l:opts)
    call nvim_win_set_option(s:float, 'winhl', 'Normal:Beacon')
    call nvim_win_set_option(s:float, 'winblend', 70)
    let s:fade_timer = timer_start(16, funcref("s:Fade_window"), {'repeat': 40})
    let s:close_timer = timer_start(500, funcref("s:Clear_highlight"))
endfunction

let s:prev_cursor = 0

function! s:Cursor_moved()
    let l:cur = line(".")
    let l:diff = l:cur - s:prev_cursor

    if l:diff > 10 || l:diff < - 10
        call s:Highlight_position()
    endif

    let s:prev_cursor = l:cur
endfunction

augroup BeaconHighlightMoves
    autocmd!
    autocmd CursorMoved * call s:Cursor_moved()
    autocmd BufWinEnter * call s:Highlight_position()
    autocmd WinEnter * call s:Highlight_position()
augroup end