-- Schermate di testo (home, briefing, riepilogo) e gestione della finestra principale.
local M = {}
local ns = vim.api.nvim_create_namespace('dattilo_schermo')
local buffers = {}
M.principale = nil
M.mostrato = nil -- l'ultimo buffer messo nella finestra principale con `mostra`: quello che ci deve stare

function M.finestra()
  if M.principale and vim.api.nvim_win_is_valid(M.principale) then return M.principale end
  M.principale = vim.api.nvim_get_current_win()
  return M.principale
end

-- Se la finestra principale viene chiusa (ZZ, :quit, <C-w>q) si torna alla home
-- in una finestra sola, invece di restare con il riquadro del suggerimento.
vim.api.nvim_create_autocmd('WinClosed', { group = vim.api.nvim_create_augroup('dattilo_schermo', { clear = true }), callback = function(a)
  if not M.principale or tonumber(a.match) ~= M.principale then return end
  M.principale = nil
  vim.schedule(function()
    local cur = vim.api.nvim_get_current_win()
    -- con la guida e una lezione aperta, la lezione si rimette nella finestra che resta (G7)
    local g = package.loaded['dattilo.guida']
    if g and g.attiva() and g.riprendi(cur, a.buf) then return end
    require('dattilo.ui').dimentica_tip(cur)
    local lezione, dojo = require('dattilo.lezione'), require('dattilo.dojo')
    for _, e in ipairs({ lezione.s and lezione.s.e or false, dojo.e or false }) do
      if e and e.fin == cur then e.fin = nil end
    end
    M.principale = cur
    local wo = vim.wo[cur]
    wo.winfixheight, wo.winbar, wo.statuscolumn = false, '', ''
    require('dattilo.home').apri()
    vim.o.cmdheight = 1
  end)
end })

function M.buffer(nome)
  local b = buffers[nome]
  if b and vim.api.nvim_buf_is_valid(b) then return b end
  b = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(b, 'dattilo://' .. nome)
  vim.bo[b].bufhidden = 'hide'
  buffers[nome] = b
  return b
end

-- righe = { { {testo, hl}, ... }, ... }
function M.scrivi(buf, righe)
  local testi, segni = {}, {}
  for i, segs in ipairs(righe) do
    local t, col = '', 0
    for _, s in ipairs(segs) do
      t = t .. s[1]
      if s[2] and s[2] ~= '' then segni[#segni + 1] = { i - 1, col, col + #s[1], s[2] } end
      col = col + #s[1]
    end
    testi[i] = t
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, testi)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, s in ipairs(segni) do
    vim.api.nvim_buf_set_extmark(buf, ns, s[1], s[2], { end_col = s[3], hl_group = s[4] })
  end
end

-- Mostra un buffer nella finestra principale. tipo = 'testo' | 'editor'
function M.mostra(buf, tipo)
  local win = M.finestra()
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_buf(win, buf)
  M.mostrato = buf
  local wo = vim.wo[win]
  local ed = tipo == 'editor'
  wo.number, wo.relativenumber, wo.cursorline = ed, ed, ed
  wo.signcolumn = ed and 'yes' or 'no'
  wo.wrap, wo.list, wo.foldcolumn = false, false, '0'
  return win
end

-- Riga di testo con tasti ‹k› evidenziati.
function M.con_tasti(rientro, testo, hl)
  local ui = require('dattilo.ui')
  local segs = { { rientro, nil } }
  vim.list_extend(segs, ui.segmenti(testo, hl or 'DattiloTesto'))
  return segs
end

return M
