-- Esercizi di modifica: testo di partenza, obiettivo, tasti contati contro il par.
local confronto = require('dattilo.confronto')
local M = {}
local ns_tasti = vim.api.nvim_create_namespace('dattilo_tasti')
local ns_segni = vim.api.nvim_create_namespace('dattilo_esercizio')
local ns_obiettivo = vim.api.nvim_create_namespace('dattilo_obiettivo')

function M.stelle(tasti, par)
  if tasti <= par then return 3 end
  if tasti <= math.ceil(par * 1.5) then return 2 end
  return 1
end

-- Numero di tasti di una sequenza in notazione Neovim: "<Esc>" vale uno.
function M.conta_tasti(seq)
  local n, i = 0, 1
  while i <= #seq do
    local j = seq:match('^<[^<>]+>()', i)
    i = j or (i + vim.str_utf_end(seq, i) + 1)
    n = n + 1
  end
  return n
end

function M.testo_tip(e)
  local o = e.o
  local testo
  if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
    testo = o.consegna .. ' Quando hai finito, ‹Esc›.'
  elseif e.tasti > 2 * o.par then
    testo = o.consegna .. ' Soluzione: ' .. table.concat(vim.tbl_map(function(k) return '‹' .. k .. '›' end, o.mostra), ' ')
  else
    testo = o.consegna .. ' ' .. o.aiuto
  end
  return (o.titolo or 'MODIFICA'):upper(), testo .. '\nTasti: ' .. e.tasti .. ' · par ' .. o.par .. ' · ‹:e!› ricomincia'
end

local function segni(e)
  if not vim.api.nvim_buf_is_valid(e.buf) then return end
  local o = e.o
  local righe = vim.api.nvim_buf_get_lines(e.buf, 0, -1, false)
  vim.api.nvim_buf_clear_namespace(e.buf, ns_segni, 0, -1)
  if o.obiettivo then
    for i = 1, #righe do
      if righe[i] ~= o.obiettivo[i] then
        vim.api.nvim_buf_set_extmark(e.buf, ns_segni, i - 1, 0, { sign_text = '~', sign_hl_group = 'DattiloSegnoDiverso' })
      end
    end
  elseif o.cursore_obiettivo then
    local r, c = o.cursore_obiettivo[1], o.cursore_obiettivo[2]
    if righe[r + 1] and #righe[r + 1] > c then
      vim.api.nvim_buf_set_extmark(e.buf, ns_segni, r, c, { end_col = c + 1, hl_group = 'DattiloMeta' })
    end
  end
  if e.gbuf and vim.api.nvim_buf_is_valid(e.gbuf) then
    vim.api.nvim_buf_clear_namespace(e.gbuf, ns_obiettivo, 0, -1)
    if o.obiettivo then
      for i, t in ipairs(o.obiettivo) do
        local p, _, sb = confronto.diff_riga(righe[i] or '', t)
        if righe[i] ~= t and sb > p then
          vim.api.nvim_buf_set_extmark(e.gbuf, ns_obiettivo, i - 1, p, { end_col = sb, hl_group = 'DattiloAggiunto' })
        end
      end
    else
      local r, c = o.cursore_obiettivo[1], o.cursore_obiettivo[2]
      vim.api.nvim_buf_set_extmark(e.gbuf, ns_obiettivo, r, c, { end_col = c + 1, hl_group = 'DattiloMeta' })
    end
  end
end

function M.verifica(e)
  if e.fatto or e.chiuso or not vim.api.nvim_buf_is_valid(e.buf) then return end
  if vim.api.nvim_get_mode().mode ~= 'n' then return end
  local o, ok = e.o, false
  if o.obiettivo then
    ok = vim.deep_equal(vim.api.nvim_buf_get_lines(e.buf, 0, -1, false), o.obiettivo)
  elseif vim.api.nvim_get_current_buf() == e.buf then
    local c = vim.api.nvim_win_get_cursor(0)
    ok = c[1] - 1 == o.cursore_obiettivo[1] and c[2] == o.cursore_obiettivo[2]
  end
  if ok then
    e.fatto = true
    if o.su_fatto then o.su_fatto(e.tasti, M.stelle(e.tasti, o.par)) end
  end
end

local function aggiorna(e)
  segni(e)
  if e.o.su_aggiorna then e.o.su_aggiorna(e) end
end

function M.ricomincia(e)
  -- partenza caricata senza storia: u non deve tornare all'esercizio prima
  local ul = vim.bo[e.buf].undolevels
  vim.bo[e.buf].undolevels = -1
  vim.api.nvim_buf_set_lines(e.buf, 0, -1, false, e.o.partenza)
  vim.bo[e.buf].undolevels = ul
  if vim.api.nvim_get_current_buf() == e.buf then
    vim.cmd('stopinsert')
    vim.api.nvim_win_set_cursor(0, { e.o.pos[1] + 1, e.o.pos[2] })
  end
  e.tasti, e.fatto = 0, false
  aggiorna(e)
end

function M.avvia(o)
  local e = { o = o, buf = o.buf, tasti = 0, fatto = false }
  M.ricomincia(e)
  -- finestra dell'obiettivo, in basso
  e.gbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(e.gbuf, 0, -1, false, o.obiettivo or o.partenza)
  vim.bo[e.gbuf].modifiable = false
  pcall(vim.treesitter.start, e.gbuf, o.linguaggio or 'c')
  e.fin = vim.api.nvim_open_win(e.gbuf, false, { split = 'below', win = -1, height = #(o.obiettivo or o.partenza) + 1 })
  local wo = vim.wo[e.fin]
  wo.number, wo.relativenumber, wo.cursorline, wo.winfixheight, wo.wrap = false, false, false, true, false
  wo.signcolumn, wo.statuscolumn = 'no', '    '
  wo.winbar = '%#DattiloObiettivo# OBIETTIVO %#DattiloBarra2# '
    .. (o.obiettivo and 'il testo deve diventare così' or 'il cursore deve finire sul giallo') .. ' %#DattiloBarra#'
  -- tasti contati come li batte la persona (prima delle mappe)
  vim.on_key(function(_, typed)
    if e.fatto or e.chiuso or not typed or typed == '' then return end
    if vim.api.nvim_get_current_buf() ~= e.buf then return end
    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'r' then return end
    e.tasti = e.tasti + 1
    vim.schedule(function() if not e.chiuso then aggiorna(e) end end)
  end, ns_tasti)
  local g = vim.api.nvim_create_augroup('dattilo_esercizio', { clear = true })
  e.gruppo = g
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, { group = g, buffer = e.buf, callback = function()
    aggiorna(e)
    M.verifica(e)
  end })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'ModeChanged' }, { group = g, buffer = e.buf, callback = function()
    M.verifica(e)
    if e.o.su_aggiorna then e.o.su_aggiorna(e) end
  end })
  vim.api.nvim_create_autocmd('WinEnter', { group = g, callback = function()
    if e.fin and vim.api.nvim_get_current_win() == e.fin then vim.schedule(function() pcall(vim.cmd, 'wincmd p') end) end
  end })
  aggiorna(e)
  return e
end

function M.chiudi(e)
  if not e or e.chiuso then return end
  e.chiuso = true
  vim.on_key(nil, ns_tasti)
  pcall(vim.api.nvim_del_augroup_by_id, e.gruppo)
  if e.fin and vim.api.nvim_win_is_valid(e.fin) then vim.api.nvim_win_close(e.fin, true) end
  if vim.api.nvim_buf_is_valid(e.buf) then vim.api.nvim_buf_clear_namespace(e.buf, ns_segni, 0, -1) end
  if e.gbuf and vim.api.nvim_buf_is_valid(e.gbuf) then vim.api.nvim_buf_delete(e.gbuf, { force = true }) end
end

return M
