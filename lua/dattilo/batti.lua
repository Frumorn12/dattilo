-- Schermata Batti: il bersaglio in grigio, gli errori in rosso, le metriche dal vivo.
local confronto = require('dattilo.confronto')
local metriche = require('dattilo.metriche')
local M = {}
local ns = vim.api.nvim_create_namespace('dattilo_batti')
local stati = {}

local function ora() return vim.uv.hrtime() / 1e6 end

local function opzioni(buf)
  local bo = vim.bo[buf]
  bo.expandtab, bo.tabstop, bo.shiftwidth, bo.softtabstop = true, 4, 4, 4
  bo.autoindent, bo.smartindent, bo.cindent = false, false, false
  bo.indentexpr, bo.indentkeys, bo.cinkeys = '', '', ''
  bo.formatoptions, bo.textwidth = '', 0
  bo.complete, bo.omnifunc = '', ''
end

function M.stato(buf) return stati[buf] end

function M.aggiorna(buf)
  local st = stati[buf]
  if not st or not vim.api.nvim_buf_is_valid(buf) then return end
  local righe = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local r = confronto.confronta(righe, st.bersaglio)
  local f = confronto.fantasma(righe, st.bersaglio)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local con_errori = {}
  for _, e in ipairs(r.errori) do
    vim.api.nvim_buf_set_extmark(buf, ns, e.riga, e.da, { end_col = e.a, hl_group = 'DattiloErrore', priority = 200 })
    con_errori[e.riga] = true
  end
  for riga in pairs(con_errori) do
    vim.api.nvim_buf_set_extmark(buf, ns, riga, 0, { sign_text = '●', sign_hl_group = 'DattiloSegnoErrore' })
  end
  for _, c in ipairs(f.coda) do
    vim.api.nvim_buf_set_extmark(buf, ns, c.riga, c.col, { virt_text = { { c.testo, 'DattiloGhost' } }, virt_text_pos = 'overlay', hl_mode = 'combine' })
  end
  if #f.sotto > 0 then
    local vl = {}
    for _, l in ipairs(f.sotto) do vl[#vl + 1] = { { l, 'DattiloGhost' } } end
    vim.api.nvim_buf_set_extmark(buf, ns, #righe - 1, 0, { virt_lines = vl })
  end
  st.errori = #r.errori
  if r.finito and not st.finito then
    st.finito = true
    st.metriche:fine(ora())
    if st.cb.su_finito then st.cb.su_finito(st) end
  end
  if st.cb.su_cambio then st.cb.su_cambio(st) end
end

-- Ogni modifica del buffer arriva qui (anche quando i tasti arrivano tutti insieme):
-- il testo inserito in insert viene confrontato con il bersaglio alla stessa colonna.
local function su_righe(st, buf, first, last_old, last_new)
  local nuove = vim.api.nvim_buf_get_lines(buf, first, last_new, false)
  if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' and not st.finito then
    if last_old - first == 1 and last_new - first == 1 then
      local da, testo = confronto.inseriti(st.prima[first + 1] or '', nuove[1])
      if da and st.salta and st.salta:sub(1, #testo) == testo then
        -- spazi messi dalla mappa di Invio, arrivano uno alla volta: non sono battuti
        st.salta = #st.salta > #testo and st.salta:sub(#testo + 1) or nil
      elseif da then
        st.salta = nil
        st.metriche:inserito(testo, (st.bersaglio[first + 1] or ''):sub(da + 1, da + #testo), ora())
      end
    elseif last_old - first == 1 and last_new - first == 2 then
      -- a capo: giusto se la riga lasciata ha la lunghezza di quella del bersaglio
      st.metriche:a_capo(#nuove[1] == #(st.bersaglio[first + 1] or ''), ora())
    end
  end
  local prima = {}
  for i = 1, first do prima[i] = st.prima[i] end
  for _, l in ipairs(nuove) do prima[#prima + 1] = l end
  for i = last_old + 1, #st.prima do prima[#prima + 1] = st.prima[i] end
  st.prima = prima
end

function M.avvia(buf, bersaglio, cb)
  M.stacca(buf)
  vim.cmd('filetype plugin indent off')
  local st = { bersaglio = bersaglio, cb = cb or {}, metriche = metriche.nuova(), finito = false, errori = 0,
    prima = vim.api.nvim_buf_get_lines(buf, 0, -1, false) }
  stati[buf] = st
  opzioni(buf)
  local g = vim.api.nvim_create_augroup('dattilo_batti_' .. buf, { clear = true })
  vim.api.nvim_create_autocmd('FileType', { group = g, buffer = buf, callback = function() opzioni(buf) end })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, { group = g, buffer = buf, callback = function() M.aggiorna(buf) end })
  vim.api.nvim_buf_attach(buf, false, { on_lines = function(_, b, _, first, last_old, last_new)
    if stati[b] ~= st then return true end
    su_righe(st, b, first, last_old, last_new)
  end })
  vim.api.nvim_create_autocmd('InsertLeave', { group = g, buffer = buf, callback = function() st.metriche:pausa(ora()) end })
  vim.api.nvim_create_autocmd('InsertEnter', { group = g, buffer = buf, callback = function() st.metriche:riprendi(ora()) end })
  vim.keymap.set('i', '<CR>', function()
    local r = vim.api.nvim_win_get_cursor(0)[1]
    local rientro = (st.bersaglio[r + 1] or ''):match('^%s*')
    st.salta = rientro ~= '' and rientro or nil
    return '\r' .. rientro
  end, { buffer = buf, expr = true, replace_keycodes = false, desc = 'dattilo: a capo con il rientro del bersaglio' })
  M.aggiorna(buf)
  return st
end

function M.stacca(buf)
  if not stati[buf] then return end
  stati[buf] = nil
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_batti_' .. buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    pcall(vim.keymap.del, 'i', '<CR>', { buffer = buf })
  end
end

return M
