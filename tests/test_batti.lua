local batti = require('dattilo.batti')
local T = {}
local ns = vim.api.nvim_create_namespace('dattilo_batti')

local function nuovo(bersaglio, cb)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  local st = batti.avvia(buf, bersaglio, cb or {})
  return buf, st
end
local function marks(buf)
  return vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
end

T['errore evidenziato e righe fantasma sotto'] = function()
  local buf = nuovo({ 'int x;', '}' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'imt' })
  batti.aggiorna(buf)
  local errori, sotto = {}, nil
  for _, m in ipairs(marks(buf)) do
    if m[4].hl_group == 'DattiloErrore' then errori[#errori + 1] = { m[2], m[3], m[4].end_col } end
    if m[4].virt_lines then sotto = m[4].virt_lines end
  end
  uguale(errori, { { 0, 1, 2 } })
  uguale(sotto, { { { '}', 'DattiloGhost' } } })
end
T['la coda della riga è testo virtuale sovrapposto'] = function()
  local buf = nuovo({ 'int main' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'int m' })
  batti.aggiorna(buf)
  local coda = vim.tbl_filter(function(m) return m[4].virt_text ~= nil end, marks(buf))[1]
  uguale({ coda[2], coda[3], coda[4].virt_text_pos, coda[4].virt_text[1][1] }, { 0, 5, 'overlay', 'ain' })
end
T['righe oltre il bersaglio non rompono nulla'] = function()
  local buf = nuovo({ 'int x;', '}' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'int x;', '}', 'z' })
  batti.aggiorna(buf)
  local r = vim.tbl_filter(function(m) return m[4].hl_group == 'DattiloErrore' end, marks(buf))
  uguale(#r, 1)
  uguale(r[1][2], 2)
end
T['finito chiamato una volta sola'] = function()
  local volte = 0
  local buf, st = nuovo({ 'a', 'b' }, { su_finito = function() volte = volte + 1 end })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'a', 'b' })
  batti.aggiorna(buf)
  batti.aggiorna(buf)
  uguale(volte, 1)
  uguale(st.finito, true)
end
T['opzioni del buffer: niente rientro automatico'] = function()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.c')
  vim.api.nvim_set_current_buf(buf)
  batti.avvia(buf, { 'x' }, {})
  vim.bo[buf].filetype = 'c'
  local bo = vim.bo[buf]
  uguale({ bo.expandtab, bo.tabstop, bo.shiftwidth, bo.softtabstop, bo.autoindent, bo.smartindent, bo.cindent, bo.indentexpr, bo.formatoptions, bo.textwidth },
    { true, 4, 4, 4, false, false, false, '', '', 0 })
end
T['Invio mette il rientro della riga bersaglio successiva'] = function()
  local buf = nuovo({ 'int main(void) {', '    return 0;', '}' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'int main(void) {' })
  vim.api.nvim_win_set_cursor(0, { 1, 16 })
  local m = vim.fn.maparg('<CR>', 'i', false, true)
  uguale(m.callback(), '\r    ')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'int main(void) {', '    return 0;' })
  vim.api.nvim_win_set_cursor(0, { 2, 13 })
  uguale(m.callback(), '\r')
end
T['Tab mette quattro spazi'] = function()
  local buf = nuovo({ '    x' })
  vim.api.nvim_feedkeys(vim.keycode('i<Tab><Esc>'), 'xt', false)
  uguale(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { '    ' })
end
T['le metriche contano la battitura vera'] = function()
  local buf, st = nuovo({ 'int x;', '}' })
  vim.api.nvim_feedkeys(vim.keycode('iimt x;<CR>}<Esc>'), 'xt', false)
  uguale(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { 'imt x;', '}' })
  uguale({ st.metriche.giusti, st.metriche.sbagliati }, { 7, 1 })
end
T['il rientro messo da Invio non conta come battuto'] = function()
  local buf, st = nuovo({ 'int main(void) {', '    return 0;' })
  vim.api.nvim_feedkeys(vim.keycode('iint main(void) {<CR>return 0;<Esc>'), 'xt', false)
  uguale(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { 'int main(void) {', '    return 0;' })
  batti.aggiorna(buf)
  uguale({ st.metriche.giusti, st.metriche.sbagliati, st.finito }, { 26, 0, true })
end
T['stacca toglie segni e mappa'] = function()
  local buf = nuovo({ 'abc' })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'x' })
  batti.aggiorna(buf)
  batti.stacca(buf)
  uguale(#marks(buf), 0)
  uguale(vim.fn.maparg('<CR>', 'i'), '')
end
return T
