-- Set indenting stuff
vim.opt.tabstop = 4                    -- number of spaces in a <Tab>
vim.opt.shiftwidth = 4                 -- number of spaces to use for autoindent. Should be == tabstop
vim.opt.softtabstop = 4                -- number of spaces for <Tab> when editing
vim.opt.expandtab = true               -- use spaces as <Tab>
vim.opt.smarttab = true                -- insert shiftwidth worth of whitespace at beginning of line
vim.opt.backspace = 'indent,eol,start' -- make <BS> well behaved
vim.opt.autoindent = true              -- make sure autoindent is turned on
vim.opt.smartindent = true             -- smart indenting for C-like languages

-- Format options
vim.opt.textwidth = 100
vim.opt.formatoptions:remove { 't' }

-- status line
-- 0: never
-- 1: only if there are at least two windows
-- 2: always
-- 3: always and ONLY the last window
vim.opt.laststatus = 3

-- block cursor
vim.opt.guicursor = ""

-- Set incremental search
vim.opt.incsearch = true

-- Show substitutions in split
vim.opt.inccommand = 'split'

-- Disable hlsearch
vim.opt.hlsearch = false

-- Enable smart case
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Always keep 2 line above and below cursor,
-- and 5 columns to the right and left
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5

-- Line numbering
vim.opt.number = true
vim.opt.relativenumber = true

-- Show command
vim.opt.showcmd = true

-- Set default spell language
vim.opt.spelllang = 'en_gb'

-- Set window title
vim.opt.title = true

-- Always use ft=tex as default for .tex-files
vim.g.tex_flavor = 'latex'

-- Map <Space> to <Leader>
vim.g.mapleader = ' '

-- always split the screen to the right or below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Highlight the current line
vim.opt.cursorline = true

-- Highlight column
vim.opt.colorcolumn = '+1'

-- Enable mouse
vim.opt.mouse = 'a'

-- don't wrap lines
vim.opt.wrap = false

-- show list chars
vim.opt.list = true
vim.opt.listchars = { tab = '└─', trail = '∙', nbsp = '␣', extends = '»', precedes = '«' }

-- swapfile, undo, and backup
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- allow buffers to be open in the background
vim.opt.hidden = true

-- dark background and 24 bit colors
vim.opt.termguicolors = true
vim.opt.background = 'dark'

local function init_submodules()
    local object = vim.system({ 'git', 'submodule', 'status' }, { cwd = vim.fn.stdpath('config'), text = true }):wait()
    for line in vim.gsplit(object.stdout, '\n', { trimempty = true }) do
        if vim.startswith(line, '-') then
            local path = vim.split(line, ' ')[2]
            local cmd = { 'git', 'submodule', 'update', '--depth=1', '--init', '--', path }
            vim.system(cmd, { cwd = vim.fn.stdpath('config'), text = true }):wait()

            local components = vim.split(vim.fs.normalize(path), '/')
            local module = components[#components]
            vim.cmd { cmd = 'packadd', args = { module }, bang = true }
        end
    end
end
init_submodules()

-- set colorscheme
vim.cmd.colorscheme('gruvbox')

-- Buffer management
vim.keymap.set('n', '<Leader><Leader>', '<C-^>')
vim.keymap.set('n', '<M-q>', ':bdelete<CR>')
vim.keymap.set('n', '<M-Q>', ':bdelete!<CR>')

-- mappings for quickfix list
vim.keymap.set('n', '<M-n>', ':cnext<CR>')
vim.keymap.set('n', '<M-p>', ':cprev<CR>')
vim.keymap.set('n', '<M-N>', ':clast<CR>')
vim.keymap.set('n', '<M-P>', ':cfirst<CR>')
vim.keymap.set('n', '<Leader>qc', ':cclose<CR>')
vim.keymap.set('n', '<Leader>qo', ':copen<CR>')

-- mappings for location list
vim.keymap.set('n', '<Leader>lc', ':lclose<CR>')
vim.keymap.set('n', '<Leader>lo', ':lopen<CR>')

-- command line editing
vim.keymap.set('c', '<C-a>', '<Home>')    -- start of line
vim.keymap.set('c', '<C-e>', '<End>')     -- end of line
vim.keymap.set('c', '<C-f>', '<Right>')   -- forward one character
vim.keymap.set('c', '<C-b>', '<Left>')    -- back one character
vim.keymap.set('c', '<C-d>', '<Del>')     -- delete character under cursor
vim.keymap.set('c', '<M-b>', '<S-Left>')  -- back one word
vim.keymap.set('c', '<M-f>', '<S-Right>') -- forward one word

-- move selected line/block down/up/right/left
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('v', '>', ">gv")
vim.keymap.set('v', '<', "<gv")

-- copy and paste to system clipboard (Ctrl-C / Ctrl-V)
vim.keymap.set('v', '<Leader>y', '"+y')
vim.keymap.set('n', '<Leader>y', '"+yy')
vim.keymap.set('n', '<Leader>p', '"+p')

-- natural navigation when using tmux
local navigate = function(dir)
    local tmux_env = os.getenv('TMUX')
    local at_edge = vim.fn.winnr() == vim.fn.winnr(dir)
    if tmux_env ~= nil and at_edge then
        local socket = vim.split(tmux_env, ',')[1]
        local pane = os.getenv('TMUX_PANE')
        local dir_flags = { h = '-L', j = '-D', k = '-U', l = '-R' }
        local pane_check = {
            h = "'#{pane_at_left}'",
            j = "'#{pane_at_bottom}'",
            k = "'#{pane_at_top}'",
            l = "'#{pane_at_right}'"
        }
        local command = { 'tmux', '-S', socket, 'if', pane_check[dir], "''",
            string.format("select-pane -t '%s' %s", pane, dir_flags[dir])
        }
        vim.system(command, { text = true }):wait()
    else
        vim.cmd.wincmd(dir)
    end
end

-- Window movement bindings
vim.keymap.set('n', '<C-h>', function() navigate('h') end)
vim.keymap.set('n', '<C-l>', function() navigate('l') end)
vim.keymap.set('n', '<C-k>', function() navigate('k') end)
vim.keymap.set('n', '<C-j>', function() navigate('j') end)

-- natural window resizing
local resize = function(dir)
    local at_edge = vim.fn.winnr() == vim.fn.winnr(dir)
    local edge_commands = {
        h = '<',
        l = '<',
        k = '-',
        j = '-',
    }
    local commands = {
        h = '>',
        l = '>',
        k = '+',
        j = '+',
    }
    local command = at_edge and edge_commands[dir] or commands[dir]
    vim.cmd.wincmd(command)
end

-- Window resize bindings
vim.keymap.set('n', '<M-h>', function() resize('h') end)
vim.keymap.set('n', '<M-l>', function() resize('l') end)
vim.keymap.set('n', '<M-k>', function() resize('k') end)
vim.keymap.set('n', '<M-j>', function() resize('j') end)
