-- Il giro «da chi non sa niente» (G2): un robot che fa solo quello che la guida dice (la prima fila
-- di tasti di «Adesso») attraversa le due lezioni della fixture dal briefing al riepilogo, nel Neovim
-- figlio coi tasti veri. Per strada fa gli errori di chi non sa Vim, e la guida deve riportarlo
-- indietro ogni volta. Se la prova fallisce il guasto sta in una frase o nella scelta di «Adesso»,
-- non nel robot: il robot non si tocca per farla passare.
--
-- GIRO_TRACCIA=1 stampa tutti i passi (passo, tasti premuti, titolo, «Adesso»).
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')

local MAX_PASSI = 400
local MAX_FERMO = 3 -- passi di fila che partono dallo stesso riquadro e dalle stesse righe
local FINALE = 'FATTO · saluta'
local GRIGIO = 'Scrivi il testo grigio'

-- Gli errori di chi non sa. Ognuno scatta una volta sola, al primo passo da `da` in poi in cui il
-- robot è in Batti, in INSERT e in nessun posto sbagliato (il riquadro è quello di Batti, «SCRIVI»).
-- `serve`: una condizione in più, perché l'errore abbia senso.
local ERRORI = {
  { nome = 'x al posto della lettera giusta', da = 10, tasti = 'x', serve = 'lettera_diversa' },
  { nome = 'Invio a metà riga', da = 25, tasti = '<CR>', serve = 'meta_riga' },
  { nome = 'Esc', da = 40, tasti = '<Esc>' },
  { nome = 'Esc e v', da = 55, tasti = '<Esc>v' },
  { nome = 'Esc e qa', da = 70, tasti = '<Esc>qa' },
  { nome = 'Esc e F1', da = 85, tasti = '<Esc><F1>' },
  { nome = 'freccia su', da = 100, tasti = '<Up>' },
}

-- Un riquadro «che sta fermo»: due letture uguali di fila (il ridisegno parte da un vim.schedule).
local function riquadro_fermo(F)
  local prima = F:riquadro()
  for _ = 1, 50 do
    vim.wait(15)
    local ora = F:riquadro()
    if vim.deep_equal(ora, prima) then return ora end
    prima = ora
  end
  return prima
end

-- Quello che serve al robot per scegliere e per accorgersi dei giri a vuoto.
local function leggi(F)
  return F:lua([[
    local s = require('dattilo.lezione').s
    local r = { modo = vim.api.nvim_get_mode().mode, righe = vim.api.nvim_buf_get_lines(0, 0, -1, false),
      cursore = vim.api.nvim_win_get_cursor(0) }
    if s then
      r.passo, r.id, r.codice = s.passo, s.L.id, s.L.batti.codice
    end
    return r]])
end

-- La prossima lettera del grigio: quella dopo il testo della riga del cursore.
local function prossima_lettera(st)
  local riga = st.righe[st.cursore[1]] or ''
  local grigio = (st.codice or {})[st.cursore[1]] or ''
  return grigio:sub(#riga + 1):match('^[%z\1-\127\194-\244][\128-\191]*')
end

local function progressi(c)
  local f = c .. '/dati/dattilo/progressi.json'
  if vim.fn.filereadable(f) == 0 then return {} end
  return vim.json.decode(table.concat(vim.fn.readfile(f), '\n')).lezioni or {}
end

T['chi fa solo quello che dice la guida arriva in fondo a due lezioni'] = function()
  local c = M.cartella()
  local traccia, fatti, pendenti = {}, {}, vim.deepcopy(ERRORI)
  local function stampa(da)
    return table.concat(vim.list_slice(traccia, math.max(1, da or 1)), '\n')
  end
  local function fallisci(msg)
    error(msg .. '\n--- gli ultimi passi del robot:\n' .. stampa(#traccia - 24), 0)
  end

  local ok, err = pcall(M.con, { cartella = c, vivo = true, tetto = 30000 }, function(F)
    -- la prima lezione si apre da sola
    F:aspetta(function() return F:riquadro() ~= nil end, 5000)
    local fermi, fermo_max, prima_snap, passi, dal = 0, 0, nil, 0, 1
    local finito = false

    for passo = 1, MAX_PASSI do
      -- G1: a ogni passo c'è un riquadro, e ha «Adesso»
      local r = riquadro_fermo(F)
      if not r then fallisci(string.format('passo %d: non c\'è nessun riquadro della guida (G1)', passo)) end
      local adesso = r.sezioni.Adesso
      if not adesso or adesso == '' then
        fallisci(string.format('passo %d: il riquadro «%s» non ha «Adesso» (G1): %s', passo, r.titolo, vim.inspect(r.sezioni)))
      end
      local st = leggi(F)

      -- si ferma quando è arrivato in fondo
      if r.titolo == FINALE then
        finito = true
        passi = passo - 1
        break
      end

      -- il giro a vuoto: stesso riquadro e stesse righe, di fila
      local snap = { r, st.righe }
      if prima_snap and vim.deep_equal(snap, prima_snap) then fermi = fermi + 1 else fermi, dal = 1, passo end
      prima_snap = snap
      fermo_max = math.max(fermo_max, fermi)
      if fermi > MAX_FERMO then
        fallisci(string.format('dal passo %d al %d: %d passi di fila con lo stesso riquadro e le stesse righe (la guida non porta avanti): «%s» · %s',
          dal, passo, fermi, r.titolo, adesso))
      end

      -- il robot sbaglia apposta, una volta per errore, quando è in Batti, in INSERT e in nessun posto sbagliato
      local scrive = adesso:sub(1, #GRIGIO) == GRIGIO
      local lettera = prossima_lettera(st)
      local in_batti_insert = st.passo == 'batti' and st.modo == 'i' and r.titolo:find('^SCRIVI') ~= nil
      local errore
      if in_batti_insert then
        for i, e in ipairs(pendenti) do
          if passo >= e.da then
            local riga = st.righe[st.cursore[1]] or ''
            local serve = true
            if e.serve == 'lettera_diversa' then serve = scrive and lettera ~= nil and lettera ~= 'x' end
            if e.serve == 'meta_riga' then serve = scrive and riga:match('%S') ~= nil end
            if serve then errore = table.remove(pendenti, i) break end
          end
        end
      end

      -- `tasti` è quello che si preme; `mostra` quello che finisce nella traccia
      local mostra, nota
      if errore then
        nota = 'ERRORE: ' .. errore.nome
        mostra = errore.tasti
        fatti[#fatti + 1] = { nome = errore.nome, passo = passo }
        F:input(errore.tasti)
      elseif scrive then
        vero(lettera, string.format('passo %d: «%s» ma il grigio è finito (riga %d)', passo, GRIGIO, st.cursore[1]))
        mostra = lettera == ' ' and '␣' or lettera
        F:input((lettera:gsub('<', '<lt>')))
      else
        local fila = M.prima_fila(adesso)
        if fila == '' then fallisci(string.format('passo %d: nessun tasto in «Adesso»: %s', passo, adesso)) end
        local volte = tonumber(adesso:match('premilo (%d+) volte')) or 1
        mostra = volte > 1 and (fila .. ' x' .. volte) or fila
        for _ = 1, volte do F:input(fila) end
      end
      traccia[#traccia + 1] = string.format('%3d  %-16s %-28s %s', passo, mostra, r.titolo,
        (nota and (nota .. ' | ') or '') .. adesso)
    end

    if vim.env.GIRO_TRACCIA then
      print(string.format('== giro: %d passi, al più %d di fila fermi', passi, fermo_max))
      print(stampa())
    end
    if not finito then fallisci(string.format('dopo %d passi il titolo non è mai stato «%s»', MAX_PASSI, FINALE)) end
    vero(passi < MAX_PASSI, 'troppi passi: ' .. passi)

    -- gli errori li ha fatti tutti: una prova che non sbaglia non prova niente
    if #pendenti > 0 then
      local nomi = {}
      for _, e in ipairs(pendenti) do nomi[#nomi + 1] = e.nome .. ' (dal passo ' .. e.da .. ')' end
      fallisci('il robot è arrivato in fondo in ' .. passi .. ' passi senza fare questi errori: ' .. table.concat(nomi, ', '))
    end
    uguale(#fatti, #ERRORI)

    -- le due lezioni sono segnate come fatte
    F:aspetta(function() return progressi(c)['rifallo/002-saluto'] ~= nil end, 3000)
    local p = progressi(c)
    vero(p['rifallo/001-somma'] ~= nil, 'progressi.json non ha 001-somma: ' .. vim.inspect(p))
    vero(p['rifallo/002-saluto'] ~= nil, 'progressi.json non ha 002-saluto: ' .. vim.inspect(p))

    -- niente nei messaggi: né righe di dattilo (un esito di :w, un errore) né un errore di Vim causato da un
    -- tasto che la guida ha detto di premere, né un «Premi INVIO» rimasto lì. Oggi :messages è vuoto.
    local m = F:messaggi()
    if vim.env.GIRO_TRACCIA then print('== :messages alla fine: «' .. m .. '»') end
    vero(vim.trim(m) == '', 'a fine giro :messages non è vuoto:\n' .. m)
  end)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

return T
