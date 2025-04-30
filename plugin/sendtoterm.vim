
if !has("nvim")
    set nossl
    function! SendLinesToTerm()
      for line in split(getreg('"'), "\n")
        if !empty(line)
          call term_sendkeys(term_list()[0], line . "\r")
        endif
      endfor
    endfunction
    nnoremap <silent> <leader>s yy:call SendLinesToTerm()<CR>
    inoremap <silent> <leader>s <esc>yy:call SendLinesToTerm()<CR>a
    vnoremap <silent> <leader>s mPyy:call SendLinesToTerm()<CR>`P
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

      local chan_id = vim.b[term_bufs[1]].terminal_job_id

      for _, line in ipairs(lines) do
        if line ~= '' then
          vim.fn.chansend(chan_id, line .. '\r')
        end
      end
    end

    -- Normal mode: yank current line and send
    vim.keymap.set('n', '<leader>s', function()
      vim.cmd('normal! yy')
      local reg = vim.fn.getreg('"')
      send_lines_to_terminal(vim.split(reg, '\n'))
    end, { noremap = true, silent = true })

    vim.keymap.set('i', '<leader>s', function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.schedule(function()
        vim.cmd('normal! yy')
        local reg = vim.fn.getreg('"')
        send_lines_to_terminal(vim.split(reg, '\n'))
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('i', true, false, true), 'n', false)
      end)
    end, { noremap = true, silent = true })

    vim.keymap.set('v', '<leader>s', function()
      vim.schedule(function()
        vim.cmd('normal! yy')
        local reg = vim.fn.getreg('"')
        send_lines_to_terminal(vim.split(reg, '\n'))
      end)
    end, { noremap = true, silent = true })
EOF
endif
