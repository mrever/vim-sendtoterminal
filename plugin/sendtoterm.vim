command! VimSendLinesToTerm :call VimSendToTerm()

func! VimSendToTerm()

let g:termnum=0
for i in range(0, 9)
  let cmd = printf(':let g:termnum=%d<cr>:echo "terminal %d"<cr>', i, i)
  execute 'nnoremap <leader>' . i . ' ' . cmd
  execute 'inoremap <leader>' . i . ' <esc>' . cmd . 'a'
  execute 'vnoremap <leader>' . i . ' mP' . cmd . '`P'
endfor

if !has("nvim")
    set nossl
    function! SendLinesToTerm()
      for line in split(getreg('"'), "\n")
        if !empty(line)
          call term_sendkeys(term_list()[g:termnum], line . "\r")
        endif
      endfor
    endfunction
    nnoremap <silent> <leader>t yy:call SendLinesToTerm()<CR>
    inoremap <silent> <leader>t <esc>yy:call SendLinesToTerm()<CR>a
    vnoremap <silent> <leader>t mPyy:call SendLinesToTerm()<CR>`P
else
lua << EOF
    function send_lines_to_terminal(lines)
      local term_bufs = vim.tbl_filter(function(buf)
        return vim.bo[buf].buftype == 'terminal'
      end, vim.api.nvim_list_bufs())

      if #term_bufs == 0 then
        print("No terminal buffer found.")
        return
      end

      local chan_id = vim.b[term_bufs[vim.g.termnum+1]].terminal_job_id

      for _, line in ipairs(lines) do
        if line ~= '' then
          vim.fn.chansend(chan_id, line .. '\r')
        end
      end
    end

    -- Normal mode: yank current line and send
    vim.keymap.set('n', '<leader>t', function()
      vim.cmd('normal! yy')
      local reg = vim.fn.getreg('"')
      send_lines_to_terminal(vim.split(reg, '\n'))
    end, { noremap = true, silent = true })

    vim.keymap.set('i', '<leader>t', function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.schedule(function()
        vim.cmd('normal! yy')
        local reg = vim.fn.getreg('"')
        send_lines_to_terminal(vim.split(reg, '\n'))
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('a', true, false, true), 'n', false)
      end)
    end, { noremap = true, silent = true })

    vim.keymap.set('v', '<leader>t', function()
      vim.schedule(function()
        vim.cmd('normal! yy')
        local reg = vim.fn.getreg('"')
        send_lines_to_terminal(vim.split(reg, '\n'))
      end)
    end, { noremap = true, silent = true })
EOF
endif

endfunc "end VimSendToTerm()
