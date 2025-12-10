-- lua/custom/keymaps.lua

local M = {}

function M.setup()
  -- ROS / colcon shortcuts
  vim.keymap.set('n', '<leader>cb', function()
    vim.cmd 'botright 12split | terminal'
    local chan = vim.b.terminal_job_id
    if chan then
      vim.api.nvim_chan_send(chan, 'colcon build --symlink-install\n')
    else
      vim.cmd 'terminal colcon build --symlink-install'
    end
  end, { desc = '[C]olcon [B]uild --symlink-install' })

  vim.keymap.set('n', '<leader>cC', function()
    vim.cmd 'botright 12split | terminal'
    local chan = vim.b.terminal_job_id
    if chan then
      vim.api.nvim_chan_send(chan, 'rm -rf build install log && colcon build --symlink-install\n')
    end
  end, { desc = '[C]olcon [C]lean + build' })
end

return M
