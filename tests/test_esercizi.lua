local esercizio = require('dattilo.esercizio')
local dojo = require('dattilo.dojo')
local T = {}

local function prova_soluzione(ex)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, ex.partenza)
  vim.api.nvim_win_set_cursor(0, { ex.pos[1] + 1, ex.pos[2] })
  vim.api.nvim_feedkeys(vim.keycode(ex.soluzione), 'xt', false)
  return buf
end
_G.prova_soluzione = prova_soluzione

T['stelle'] = function()
  uguale({ esercizio.stelle(18, 18), esercizio.stelle(27, 18), esercizio.stelle(28, 18), esercizio.stelle(2, 3) }, { 3, 2, 1, 3 })
end
T['conta tasti: i nomi tra < > valgono uno'] = function()
  uguale(esercizio.conta_tasti('3jci"Ciao mondo\\n<Esc>'), 18)
  uguale(esercizio.conta_tasti('A;<Esc>j.j.'), 7)
  uguale(esercizio.conta_tasti('<C-r>u'), 2)
end
T['ogni esercizio del Dojo si risolve in par tasti'] = function()
  uguale(#dojo.ESERCIZI, 7)
  for _, ex in ipairs(dojo.ESERCIZI) do
    local buf = prova_soluzione(ex)
    if ex.obiettivo then
      uguale(vim.api.nvim_buf_get_lines(buf, 0, -1, false), ex.obiettivo, ex.titolo)
    else
      local c = vim.api.nvim_win_get_cursor(0)
      uguale({ c[1] - 1, c[2] }, ex.cursore_obiettivo, ex.titolo)
    end
    uguale(esercizio.conta_tasti(ex.soluzione), ex.par, ex.titolo .. ' (par)')
    vim.cmd('stopinsert')
  end
end
T['avvia conta i tasti e chiama fatto con le stelle'] = function()
  local ex = dojo.ESERCIZI[2]
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(buf)
  local esito
  local e = esercizio.avvia(vim.tbl_extend('force', ex, { buf = buf, su_fatto = function(t, s) esito = { t, s } end }))
  local segni = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true, type = 'sign' })
  uguale(#segni, 1)
  uguale(vim.trim(segni[1][4].sign_text), '~')
  vim.api.nvim_feedkeys(vim.keycode(ex.soluzione), 'xt', false)
  vim.api.nvim_exec_autocmds('TextChanged', { buffer = buf })
  uguale(esito, { 10, 3 })
  vero(e.fin ~= nil and vim.api.nvim_win_is_valid(e.fin))
  esercizio.chiudi(e)
  uguale(#vim.api.nvim_tabpage_list_wins(0), 1)
end
T['obiettivo di posizione: riuscito quando il cursore arriva'] = function()
  local ex = dojo.ESERCIZI[1]
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(buf)
  local esito
  local e = esercizio.avvia(vim.tbl_extend('force', ex, { buf = buf, su_fatto = function(t, s) esito = { t, s } end }))
  vim.api.nvim_feedkeys(vim.keycode(ex.soluzione), 'xt', false)
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
  uguale(esito, { 3, 3 })
  esercizio.chiudi(e)
end
T['ricomincia rimette la partenza e azzera i tasti'] = function()
  local ex = dojo.ESERCIZI[2]
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(buf)
  local e = esercizio.avvia(vim.tbl_extend('force', ex, { buf = buf, su_fatto = function() end }))
  vim.api.nvim_feedkeys(vim.keycode('dd'), 'xt', false)
  esercizio.ricomincia(e)
  uguale(vim.api.nvim_buf_get_lines(buf, 0, -1, false), ex.partenza)
  uguale(e.tasti, 0)
  esercizio.chiudi(e)
end
T['dopo il doppio del par il suggerimento mostra la soluzione'] = function()
  local ex = dojo.ESERCIZI[3]
  local e = { o = ex, tasti = 37 }
  local titolo, testo = esercizio.testo_tip(e)
  uguale(titolo, 'DENTRO LE PARENTESI')
  vero(testo:find('Soluzione: ‹f(› ‹ci(› ‹int x, int y› ‹Esc›', 1, true), testo)
  vero(testo:find('Tasti: 37 · par 18', 1, true), testo)
end
T['lezioni: il suggerimento a sezioni ha consegna, aiuto, perché e tasti'] = function()
  local ex = vim.tbl_extend('force', dojo.ESERCIZI[3], { motivo = 'Così la firma è completa.' })
  local titolo, sez = esercizio.sezioni_tip({ o = ex, tasti = 2 })
  uguale(titolo, 'DENTRO LE PARENTESI')
  local et = vim.tbl_map(function(x) return x.etichetta end, sez)
  uguale(et, { 'Consegna', 'Aiuto', 'Perché', 'Tasti' })
  uguale(sez[3].testo, 'Così la firma è completa.')
  local _, sez2 = esercizio.sezioni_tip({ o = ex, tasti = 37 })
  uguale(sez2[2].etichetta, 'Soluzione')
end
return T
