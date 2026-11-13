-- dattilo: avvio dell'app dentro Neovim pulito.
local M = {}

function M.abbreviazioni()
  local voci = { { 'q', 'DattiloEsci' }, { 'q!', 'DattiloEsci' }, { 'wq', 'DattiloEsci' }, { 'x', 'DattiloEsci' }, { 'e!', 'DattiloRicomincia' } }
  for _, a in ipairs(voci) do
    vim.cmd(string.format("cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s'", a[1], a[1], a[2], a[1]))
  end
end

function M.comandi()
  vim.api.nvim_create_user_command('DattiloEsci', function()
    if require('dattilo.stato').schermo == 'home' then vim.cmd('qa!') else require('dattilo.home').apri() end
  end, { bang = true, desc = 'Torna alla home, o esce dalla home' })
  vim.api.nvim_create_user_command('DattiloRicomincia', function()
    local schermo = require('dattilo.stato').schermo
    if schermo == 'lezione' then require('dattilo.lezione').ricomincia()
    elseif schermo == 'dojo' then
      local dojo = require('dattilo.dojo')
      if dojo.e then require('dattilo.esercizio').ricomincia(dojo.e) end
    end
  end, { bang = true, desc = 'Ricomincia l\'esercizio' })
  vim.api.nvim_create_user_command('Home', function() require('dattilo.home').apri() end, {})
  vim.api.nvim_create_user_command('Lezione', function(a) require('dattilo.lezione').apri(tonumber(a.args) or 1) end, { nargs = '?' })
  vim.api.nvim_create_user_command('Dojo', function(a) require('dattilo.dojo').apri(tonumber(a.args) or 1) end, { nargs = '?' })
end

function M.avvia(opts)
  M.radice = opts and opts.radice
  local o = vim.o
  o.termguicolors, o.laststatus, o.showtabline, o.showmode, o.ruler = true, 3, 2, false, false
  o.swapfile, o.undofile, o.hidden, o.scrolloff, o.mouse = false, false, true, 4, 'a'
  o.shortmess = o.shortmess .. 'I'
  o.fillchars = 'eob: '
  o.tabline = "%!v:lua.require'dattilo.ui'.tabline()"
  o.statusline = "%!v:lua.require'dattilo.ui'.statusline()"
  local tokyonight = vim.fn.expand('~/.local/share/nvim/lazy/tokyonight.nvim')
  if vim.fn.isdirectory(tokyonight) == 1 then
    vim.opt.runtimepath:append(tokyonight)
    pcall(vim.cmd.colorscheme, 'tokyonight-night')
  end
  local ui = require('dattilo.ui')
  ui.colori()
  vim.api.nvim_create_autocmd('ColorScheme', { group = vim.api.nvim_create_augroup('dattilo', { clear = true }), callback = ui.colori })
  vim.cmd('filetype plugin indent off')
  M.comandi()
  M.abbreviazioni()
  require('dattilo.home').apri()
end

return M
