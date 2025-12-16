-- lua/custom/ros.lua

local M = {}

-- Find the workspace root by walking up until we see a `src` dir
local function find_workspace_root()
  local cwd = vim.fn.getcwd()
  local path = cwd

  while path ~= '/' do
    if vim.fn.isdirectory(path .. '/src') == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ':h')
  end

  return cwd
end

local function open_term(height)
  if height then
    vim.cmd(string.format('botright %dsplit | terminal', height))
  else
    vim.cmd 'terminal'
  end
  return vim.b.terminal_job_id
end

local function send(chan, text)
  if chan then
    vim.api.nvim_chan_send(chan, text)
  end
end

local function ros_env_prefix()
  return table.concat({
    'if [ -n "$ROS_DISTRO" ] && [ -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then',
    '  source "/opt/ros/$ROS_DISTRO/setup.bash";',
    'fi;',
    'if [ -f "install/setup.bash" ]; then',
    '  source "install/setup.bash";',
    'elif [ -f "install/local_setup.bash" ]; then',
    '  source "install/local_setup.bash";',
    'fi;',
  }, ' ')
end

local function colcon_build_cmd()
  return ros_env_prefix() .. ' colcon build --symlink-install'
end

local function colcon_clean_build_cmd()
  return table.concat({
    ros_env_prefix(),
    'rm -rf build install log;',
    'colcon build --symlink-install',
  }, ' ')
end

-- Open a 2x2 terminal layout and run the ROS commands
function M.open_ros_session()
  -- Ensure we’re at the workspace root
  local root = find_workspace_root()
  vim.cmd 'tabnew'
  vim.cmd('cd ' .. root)

  local env = ros_env_prefix()

  -- Top-left: navigation launch
  vim.cmd 'terminal'
  send(vim.b.terminal_job_id, env .. ' ros2 launch mir_navigation navigate_grasping_path.launch.py map:="map_1.yaml"\n')

  -- Top-right: teleop
  vim.cmd 'vsplit'
  vim.cmd 'wincmd l'
  vim.cmd 'terminal'
  send(vim.b.terminal_job_id, env .. ' ros2 run teleop_twist_keyboard teleop_twist_keyboard\n')

  -- Bottom-left: ur_rtde_wrapper
  vim.cmd 'wincmd h'
  vim.cmd 'wincmd j'
  vim.cmd 'terminal'
  send(vim.b.terminal_job_id, env .. ' ros2 run ur_rtde_wrapper ur_rtde_wrapper\n')

  -- Bottom-right: wsg_ctrl
  vim.cmd 'wincmd l'
  vim.cmd 'terminal'
  send(vim.b.terminal_job_id, env .. ' ros2 run wsg_ctrl wsg\n')

  -- Now you have:
  --  top-left:   navigation launch
  --  top-right:  teleop
  --  bottom-left: UR RTDE wrapper
  --  bottom-right: WSG node
end

function M.setup()
  -- colcon build
  vim.keymap.set('n', '<leader>cb', function()
    local chan = open_term(12)
    send(chan, colcon_build_cmd() .. '\n')
  end, { desc = '[C]olcon [B]uild (source ws setup)' })

  -- colcon clean + build
  vim.keymap.set('n', '<leader>cC', function()
    local chan = open_term(12)
    send(chan, colcon_clean_build_cmd() .. '\n')
  end, { desc = '[C]olcon [C]lean + build (source ws setup)' })

  -- 4-terminal ROS session in a new tab
  vim.keymap.set('n', '<leader>rm', function()
    M.open_ros_session()
  end, { desc = '[R]OS [M]ulti-terminal session' })
end

return M
