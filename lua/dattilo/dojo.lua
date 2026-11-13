-- Dojo Vim: esercizi brevi di trasformazione sul C, con il par.
local M = {}

local SUM = { 'int sum(int a, int b) {', '    int c = a + b;', '    return c;', '}' }
local function con(righe, i, nuova) local t = vim.deepcopy(righe) t[i] = nuova return t end

M.ESERCIZI = {
  { titolo = 'Muoviti senza frecce', consegna = 'Porta il cursore sul + della seconda riga.', aiuto = '‹j› scende di una riga, ‹f+› salta al prossimo +.',
    partenza = SUM, pos = { 0, 0 }, cursore_obiettivo = { 1, 14 }, par = 3, soluzione = 'jf+', mostra = { 'j', 'f+' } },
  { titolo = 'Cambia una parola', consegna = 'Rinomina la funzione: sum diventa somma.', aiuto = '‹w› va alla parola dopo, ‹ciw› la cancella e ti mette in INSERT.',
    partenza = SUM, pos = { 0, 0 }, obiettivo = con(SUM, 1, 'int somma(int a, int b) {'), par = 10, soluzione = 'wciwsomma<Esc>', mostra = { 'w', 'ciw', 'somma', 'Esc' } },
  { titolo = 'Dentro le parentesi', consegna = 'Gli argomenti diventano (int x, int y).', aiuto = '‹f(› salta alla parentesi, ‹ci(› cambia tutto quello che c\'è dentro.',
    partenza = SUM, pos = { 0, 0 }, obiettivo = con(SUM, 1, 'int sum(int x, int y) {'), par = 18, soluzione = 'f(ci(int x, int y<Esc>', mostra = { 'f(', 'ci(', 'int x, int y', 'Esc' } },
  { titolo = 'Ripeti con il punto', consegna = 'Metti il ; mancante alla fine delle tre righe.', aiuto = '‹A› scrive a fine riga. Poi ‹j› scende e ‹.› ripete l\'ultima modifica.',
    partenza = { 'int a = 10', 'int b = 20', 'int c = a + b' }, pos = { 0, 0 }, obiettivo = { 'int a = 10;', 'int b = 20;', 'int c = a + b;' },
    par = 7, soluzione = 'A;<Esc>j.j.', mostra = { 'A', ';', 'Esc', 'j', '.', 'j', '.' } },
  { titolo = 'Scambia due righe', consegna = 'stdio.h deve venire prima di stdlib.h.', aiuto = '‹dd› taglia la riga, ‹p› la incolla sotto quella dove finisci.',
    partenza = { '#include <stdlib.h>', '#include <stdio.h>' }, pos = { 0, 0 }, obiettivo = { '#include <stdio.h>', '#include <stdlib.h>' },
    par = 3, soluzione = 'ddp', mostra = { 'dd', 'p' } },
  { titolo = 'Taglia la coda', consegna = 'Togli il commento alla fine del return.', aiuto = '‹f;› salta al punto e virgola, ‹l› uno a destra, ‹D› cancella fino a fine riga.',
    partenza = con(SUM, 3, '    return c; // la somma'), pos = { 2, 0 }, obiettivo = SUM, par = 4, soluzione = 'f;lD', mostra = { 'f;', 'l', 'D' } },
  { titolo = 'Duplica e cambia', consegna = 'Aggiungi sotto una seconda printf che stampa Bau.', aiuto = '‹yy› copia la riga, ‹p› la incolla sotto, ‹ci"› cambia il testo tra virgolette.',
    partenza = { 'int main(void) {', '    printf("Ciao\\n");', '    return 0;', '}' }, pos = { 0, 0 },
    obiettivo = { 'int main(void) {', '    printf("Ciao\\n");', '    printf("Bau\\n");', '    return 0;', '}' },
    par = 13, soluzione = 'jyypci"Bau\\n<Esc>', mostra = { 'j', 'yy', 'p', 'ci"', 'Bau\\n', 'Esc' } },
}

function M.chiudi()
  if M.e then
    local buf = M.e.buf
    require('dattilo.esercizio').chiudi(M.e)
    M.e = nil
    if vim.api.nvim_buf_is_valid(buf) then vim.bo[buf].modified = false end
  end
end

function M.apri(i)
  local esercizio = require('dattilo.esercizio')
  local schermo = require('dattilo.schermo')
  local stato = require('dattilo.stato')
  local ui = require('dattilo.ui')
  require('dattilo.lezione').chiudi()
  M.chiudi()
  i = (i - 1) % #M.ESERCIZI + 1
  M.i = i
  local ex = M.ESERCIZI[i]
  local buf = schermo.buffer('dojo.c')
  vim.bo[buf].buftype, vim.bo[buf].modifiable = 'acwrite', true
  vim.bo[buf].expandtab, vim.bo[buf].shiftwidth, vim.bo[buf].tabstop = true, 4, 4
  if not M.scrittura then
    M.scrittura = vim.api.nvim_create_autocmd('BufWriteCmd', { buffer = buf, callback = function()
      vim.bo[buf].modified = false
      vim.api.nvim_echo({ { 'Nel Dojo non si compila: basta arrivare all\'obiettivo.', 'DattiloGiallo' } }, false, {})
    end })
  end
  schermo.mostra(buf, 'editor')
  pcall(vim.treesitter.start, buf, 'c')
  vim.keymap.set('n', 'ZZ', '<Cmd>DattiloEsci<CR>', { buffer = buf })
  vim.keymap.set('n', 'ZQ', '<Cmd>DattiloEsci<CR>', { buffer = buf })
  stato.schermo, stato.file = 'dojo', 'dojo.c'
  stato.titolo = 'Dojo Vim · cintura bianca'
  local cintura = {}
  for k = 1, #M.ESERCIZI do cintura[k] = k < i and '●' or k == i and '◉' or '○' end
  stato.destra = table.concat(cintura) .. '  ' .. i .. '/' .. #M.ESERCIZI
  vim.cmd('redrawtabline')
  M.e = esercizio.avvia(vim.tbl_extend('force', ex, {
    buf = buf,
    su_aggiorna = function(e) if M.e == e then ui.tip(esercizio.testo_tip(e)) vim.cmd('redrawstatus') end end,
    su_fatto = function(tasti, n)
      vim.api.nvim_echo({ { ex.titolo .. ': fatto in ' .. tasti .. ' tasti. Par ' .. ex.par .. ' ' .. string.rep('★', n) .. string.rep('☆', 3 - n), 'DattiloVerde' },
        { '\nLa via corta: ' .. table.concat(ex.mostra, '  '), 'DattiloTesto' } }, true, {})
      vim.schedule(function() M.apri(i + 1) end)
    end,
  }))
  stato.metriche = function() return M.e and { 'tasti ' .. M.e.tasti, 'par ' .. ex.par } or {} end
  ui.tip(esercizio.testo_tip(M.e))
end

return M
