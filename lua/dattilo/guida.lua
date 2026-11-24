-- La guida di «Rifallo tu»: il riquadro in alto, acceso in ogni schermata, che dice in italiano
-- che tasto premere adesso e cosa fa. Si accende solo con `dattilo vivo`.
local confronto = require('dattilo.confronto')
local ui = require('dattilo.ui')
local stato = require('dattilo.stato')
local T = require('dattilo.guida_testi')

local M = {}
-- La colonna delle etichette: «Controllo» più due spazi. Il dattilo di sempre ne usa 9 (ui.lua).
M.ETICHETTA = 11
local ALTO = 10 -- righe interne del riquadro, al massimo, prima di accorciare qualcosa
-- Queste due sezioni non si accorciano mai (G1): se lo spazio non basta, si accorciano le altre.
local INTERE = { Adesso = true, Comandi = true }

local f = nil          -- il fornitore
local ultimo = nil     -- l'ultimo riquadro disegnato
-- L'ultimo esito, per la sezione «Controllo»: { testo, righe?, ko?, adesso? }. `righe` è il testo di
-- Batti quando l'esito è arrivato: se il testo cambia l'esito non vale più. `ko` è il controllo che
-- non passa: la frase sta in «Adesso» (adesso), il titolo è IL CONTROLLO NON PASSA.
local controllo = nil
local more_prima = nil
-- [buf] = { righe, seq }: il testo all'ultima uscita dalla scrittura o all'ultimo cambio fatto da
-- dattilo, e il punto della storia degli annullamenti (undotree) in quel momento
local giuste = {}

local function lezione() return require('dattilo.lezione') end

-- Disegna il riquadro e lo ricorda. Conta le righe vere di ogni sezione e alza il riquadro fino
-- a ALTO righe; se non basta, toglie righe alle sezioni meno importanti (Blocco, Fin qui, Riga,
-- poi Controllo), mai ad Adesso e Comandi.
local function disegna(titolo, sezioni, tipo)
  local largo = vim.o.columns - 4 - M.ETICHETTA -- come ui.sezioni: i bordi e la colonna delle etichette
  local voci, intere, tot = {}, 0, 0
  for i, sz in ipairs(sezioni) do
    if sz.testo and sz.testo ~= '' then
      local n = #ui.a_capo(sz.testo, largo)
      voci[#voci + 1] = { i = i, sz = sz, n = n }
      tot = tot + n
      if INTERE[sz.etichetta] then intere = intere + n end
    end
  end
  local base = vim.o.lines >= 34 and 8 or 6
  -- Adesso e Comandi stanno sempre interi, anche oltre ALTO, finché resta un po' di codice sotto
  local alto = math.min(math.max(ALTO, math.min(intere, vim.o.lines - 11)), math.max(base, tot))
  -- le altre, dalla più importante: ognuna prende le righe che restano, almeno una, o non c'è
  local altre = vim.tbl_filter(function(v) return not INTERE[v.sz.etichetta] end, voci)
  table.sort(altre, function(a, b)
    local pa, pb = a.sz.priorita or 0, b.sz.priorita or 0
    if pa ~= pb then return pa > pb end
    return a.i < b.i
  end)
  local libere, via = alto - intere, {}
  for _, v in ipairs(altre) do
    if libere >= 1 then libere = libere - math.min(v.n, libere) else via[v.i] = true end
  end
  -- ui.sezioni dà le righe in più per priorità: Adesso e Comandi passano per prime
  local per_ui = {}
  for i, sz in ipairs(sezioni) do
    if not via[i] then
      per_ui[#per_ui + 1] = INTERE[sz.etichetta] and vim.tbl_extend('force', sz, { priorita = 100 }) or sz
    end
  end
  ui.altezza_tip(alto)
  ultimo = { titolo = titolo, sezioni = sezioni, tipo = tipo }
  ui.tip(titolo, per_ui, tipo, M.ETICHETTA)
end

-- Un errore dentro la guida non rompe la lezione e non arriva mai alla riga dei messaggi (G5): va
-- in «Controllo» come «Errore di dattilo: …». Il riquadro si rifà con quello che c'era, senza
-- passare dal codice che ha sbagliato.
local function errore(e)
  local msg = vim.trim((tostring(e):gsub('^[^\n]-:%d+: ', ''):gsub('%s+', ' ')))
  local s = lezione().s
  local righe = nil
  if s and s.passo == 'batti' and s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  end
  controllo = { testo = T.f('errore_dattilo', msg), righe = righe }
  pcall(function()
    local sez = {}
    for _, sz in ipairs(ultimo and ultimo.sezioni or {}) do
      if sz.etichetta ~= 'Controllo' then sez[#sez + 1] = sz end
      if sz.etichetta == 'Adesso' then sez[#sez + 1] = { etichetta = 'Controllo', testo = controllo.testo, priorita = 8 } end
    end
    if #sez == 0 then sez[1] = { etichetta = 'Controllo', testo = controllo.testo, priorita = 8 } end
    disegna(ultimo and ultimo.titolo or 'DATTILO', sez, ultimo and ultimo.tipo)
  end)
end

local function proteggi(fn)
  return function(...)
    local r = vim.F.pack_len(pcall(fn, ...))
    if not r[1] then errore(r[2]) return end
    return unpack(r, 2, r.n)
  end
end

-- fornitore = { comandi = fun(schermata), fine = fun(s), su_schermata = fun(s), destra = fun() }
function M.accendi(fornitore)
  f = fornitore
  more_prima = vim.o.more
  vim.o.more = false
  ultimo, controllo = nil, nil
  lezione().guida = M
  giuste = {}
  local g = vim.api.nvim_create_augroup('dattilo_guida', { clear = true })
  -- la finestra ha cambiato misura: le righe di ogni sezione vanno ricontate
  vim.api.nvim_create_autocmd('VimResized', { group = g, callback = proteggi(function()
    if ultimo and ui.tip_aperto() then disegna(ultimo.titolo, ultimo.sezioni, ultimo.tipo) end
  end) })
  -- Uscita dalla scrittura: il testo di adesso è quello «giusto», e un cambio in NORMAL si vede
  -- confrontandolo con questo. Si usa ModeChanged e non InsertLeave, che con Ctrl-c non scatta.
  vim.api.nvim_create_autocmd('ModeChanged', { group = g, callback = proteggi(function()
    local s = lezione().s
    local da, a = vim.v.event.old_mode or '', vim.v.event.new_mode or ''
    if s and s.passo == 'batti' and s.buf and vim.api.nvim_get_current_buf() == s.buf
      and da:match('^[iR]') and not a:match('^[iR]') then
      M.cambio_voluto(s.buf)
      M.tip(s)
    end
  end) })
  -- In NORMAL un movimento (2G, gg, h, un clic) cambia il punto, e con lui «Adesso». Una freccia
  -- premuta prima non è più «appena premuta».
  vim.api.nvim_create_autocmd('CursorMoved', { group = g, callback = proteggi(function(a)
    local s = lezione().s
    if s and s.passo == 'batti' and a.buf == s.buf then
      s.frecce = false
      M.tip(s)
    end
  end) })
end

function M.spegni()
  if not f then return end
  f = nil
  ultimo, controllo, giuste = nil, nil, {}
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_guida')
  if more_prima ~= nil then vim.o.more = more_prima end
  lezione().guida = nil
end

function M.attiva() return f ~= nil end

-- Il fornitore acceso (per le prove).
function M.fornitore() return f end

function M.ultimo() return ultimo end

local function comandi(schermata)
  return f and f.comandi and f.comandi(schermata) or ''
end

---------------------------------------------------------------- «Adesso» in Batti

-- I caratteri non ASCII che sulla tastiera italiana hanno un tasto.
local TASTIERA = {}
for _, ch in ipairs(vim.fn.split('àèéìòùç°£§€', '\\zs')) do TASTIERA[ch] = true end

local digrammi = nil -- [carattere] = la prima coppia di tasti ASCII stampabili che lo dà

-- Come si scrive in Vim un carattere che non è sulla tastiera (G11): il digramma (‹Ctrl-k› e due
-- tasti), oppure ‹Ctrl-v› ‹u› e quattro cifre, ‹Ctrl-v› ‹U› e otto sopra U+FFFF. nil se c'è il tasto.
function M.carattere(ch)
  if not ch or ch == '' or #ch == 1 or TASTIERA[ch] then return nil end
  if not digrammi then
    digrammi = {}
    for _, d in ipairs(vim.fn.digraph_getlist(true)) do
      if d[1]:match('^[!-~][!-~]$') and not digrammi[d[2]] then digrammi[d[2]] = d[1] end
    end
  end
  local coppia = digrammi[ch]
  if coppia then return '‹Ctrl-k› ‹' .. coppia:sub(1, 1) .. '› ‹' .. coppia:sub(2, 2) .. '›' end
  local n = vim.fn.char2nr(ch)
  local tasti = { '‹Ctrl-v›', n > 0xFFFF and '‹U›' or '‹u›' }
  for cifra in string.format(n > 0xFFFF and '%08X' or '%04X', n):gmatch('.') do tasti[#tasti + 1] = '‹' .. cifra .. '›' end
  return table.concat(tasti, ' ')
end

local function volte(n) return n == 1 and 'una volta' or (n .. ' volte') end

-- La frase di «Adesso» in Batti (3.3): vale il primo caso che si applica, dall'alto.
-- x = { codice, righe, r, c, modo, frecce?, cambiato?, annullato? }; c è la colonna in byte, da 0.
-- In quattro punti si scosta dalla tabella del progetto, perché lì la persona perderebbe lavoro
-- o andrebbe nel posto sbagliato:
-- - in INSERT ‹Fine› viene prima del rosso: col rosso a destra del cursore ‹Backspace›
--   cancellerebbe le lettere giuste a sinistra;
-- - in INSERT la riga da finire può stare anche sotto il cursore (k > r): ‹Invio› aprirebbe una
--   riga in più e tutto sotto diventerebbe rosso;
-- - in NORMAL, dopo un u di troppo (annullato), ‹g› ‹+› rimette il testo, e un altro ‹u› ne
--   toglierebbe ancora;
-- - in NORMAL annullato e cambiato vengono prima di «niente scritto»: ‹i› farebbe riscrivere
--   quello che ‹g› ‹+› o ‹u› rimettono.
function M.adesso_batti(x)
  local codice, righe, r, c = x.codice, x.righe, x.r, x.c
  local esito = confronto.confronta(righe, codice)
  local rosso, prima_rossa = {}, nil -- rosso[riga] = colonna del primo carattere rosso
  for _, e in ipairs(esito.errori) do
    local i = e.riga + 1
    if not rosso[i] or e.da < rosso[i] then rosso[i] = e.da end
    if not prima_rossa or i < prima_rossa then prima_rossa = i end
  end
  -- k: la prima riga diversa dal grigio; se sono tutte uguali (ma meno), l'ultima: lì si continua
  local k = #righe
  for i = 1, #righe do
    if righe[i] ~= codice[i] then k = i break end
  end
  local riga, grigio = righe[r] or '', codice[r] or ''

  if x.modo == 'i' then
    if x.frecce then return T.frecce end
    if esito.finito then return T.batti_finito_i end
    if c < #riga then return T.batti_cursore end
    if rosso[r] then
      local da = rosso[r]
      local scritto, atteso = riga:sub(da + 1, da + 1), grigio:sub(da + 1, da + 1)
      if atteso ~= '' and scritto ~= atteso and scritto == atteso:upper() then return T.batti_maiuscole end
      return T.batti_errore
    end
    if k == r - 1 and riga:match('^ *$') then
      return T.f('batti_spezzata', k, volte(math.ceil(#riga / 4) + 1), k)
    end
    if k ~= r then return T.f('batti_indietro_i', k, k, k) end
    local prossimo = grigio:sub(#riga + 1):match('^[%z\1-\127\194-\244][\128-\191]*')
    local tasti = M.carattere(prossimo)
    if tasti then return T.f('batti_carattere', prossimo, tasti) end
    if riga == grigio and codice[r + 1] == '' then return T.batti_riga_vuota end
    if riga == grigio then return T.batti_fine_riga end
    return T.batti_scrivi
  end

  -- NORMAL, e per ora ogni modo che non scrive: i posti sbagliati (3.4) arrivano prima, compito 5
  if x.annullato then return T.batti_annullato end
  if x.cambiato then return T.batti_cambiato end
  if #righe == 1 and righe[1] == '' then return T.batti_vuoto end
  if x.frecce then return T.frecce end
  if esito.finito then return T.batti_finito_n end
  if rosso[r] then return T.batti_rosso_qui end
  if prima_rossa then return T.f('batti_rosso_n', prima_rossa, prima_rossa, prima_rossa) end
  if k ~= r then return T.f('batti_indietro_n', k, k, k) end
  return T.batti_riprendi
end

local function seq(buf) return vim.fn.undotree(buf).seq_cur end

-- Il testo di adesso è quello «giusto»: dopo un cambio fatto da dattilo (la bozza rimessa) o
-- all'uscita dalla scrittura. In NORMAL un testo diverso da questo è un testo cambiato.
function M.cambio_voluto(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  giuste[buf] = { righe = vim.api.nvim_buf_get_lines(buf, 0, -1, false), seq = seq(buf) }
end

-- Il riquadro di Batti: titolo, «Adesso», «Controllo», le sezioni di tip_batti e «Comandi».
function M.tip(s)
  if s.passo ~= 'batti' or not s.st or not vim.api.nvim_buf_is_valid(s.buf) then return end
  local win = vim.api.nvim_win_get_buf(0) == s.buf and vim.api.nvim_get_current_win() or vim.fn.bufwinid(s.buf)
  if win == -1 then return end
  local modo = vim.api.nvim_get_mode().mode:sub(1, 1)
  local codice = s.L.batti.codice
  local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  local cur = vim.api.nvim_win_get_cursor(win)
  local cambiato, annullato = false, false
  local g = giuste[s.buf]
  if modo == 'n' and g and not vim.deep_equal(g.righe, righe) then
    cambiato = true
    -- sotto il punto salvato vuol dire che è stato annullato (u) del testo scritto
    annullato = seq(s.buf) < g.seq
  end
  -- l'esito di :w vale per il testo di quando è arrivato
  local c = controllo
  if c and c.righe and not vim.deep_equal(c.righe, righe) then controllo, c = nil, nil end
  local adesso = M.adesso_batti({ codice = codice, righe = righe, r = cur[1], c = cur[2], modo = modo,
    frecce = s.frecce, cambiato = cambiato, annullato = annullato })
  local titolo, sez = lezione().tip_batti(s, modo)
  if c and c.ko then adesso = c.adesso end
  local out = { { etichetta = 'Adesso', testo = adesso, priorita = 9 } }
  if c and not c.ko then out[#out + 1] = { etichetta = 'Controllo', testo = c.testo, priorita = 8 } end
  local r = math.min(cur[1], math.max(1, #codice))
  local riga_vuota = codice[r] and not codice[r]:match('%S') and not s.L.batti.suggerimenti[r]
  for _, x in ipairs(sez) do
    -- l'avviso su Vim e la sezione «Vim» li sostituisce «Adesso»; così la nota «Riga vuota», che
    -- dice ‹Invio› senza dire cosa fa (G3): sulla riga vuota «Adesso» dice già cosa premere
    if not x.avviso and x.etichetta ~= 'Vim' and not (riga_vuota and x.etichetta == 'Riga') then out[#out + 1] = x end
  end
  out[#out + 1] = { etichetta = 'Comandi', testo = comandi('batti'), priorita = 7 }
  local finito = confronto.confronta(righe, codice).finito
  local titolo_riquadro = finito and T.f('titoli.finito', #codice) or T.f('titoli.batti', titolo)
  if c and c.ko then
    disegna(T.titoli.ko, out, 'rosso')
  else
    disegna(titolo_riquadro, out)
  end
end

-- Il riquadro delle schermate di testo (briefing, spiegazione, esegui): titolo, «Adesso»,
-- «Controllo» se c'è un esito, «Comandi». Con un controllo che non passa, il titolo è rosso e la
-- frase sta in «Adesso».
local function disegna_testo(s)
  local titolo, adesso, cmd
  if s.passo == 'briefing' then
    titolo, adesso, cmd = T.f('titoli.briefing', s.L.breve), T.briefing, comandi('testo')
  elseif s.passo == 'spiegazione' then
    titolo, adesso, cmd = T.f('titoli.spiegazione', s.L.breve), T.spiegazione, comandi('testo')
  elseif s.passo == 'esegui' then
    -- il testo non è più quello di Batti: il codice va controllato col :w di sempre
    local righe = s.buf and vim.api.nvim_buf_is_valid(s.buf) and vim.api.nvim_buf_line_count(s.buf) or #s.L.batti.codice
    titolo, adesso, cmd = T.f('titoli.finito', righe), T.batti_finito_n, comandi('batti')
  else
    return
  end
  local c = controllo
  local tipo = nil
  if c and c.ko then titolo, adesso, tipo = T.titoli.ko, c.adesso, 'rosso' end
  local out = { { etichetta = 'Adesso', testo = adesso, priorita = 9 } }
  if c and not c.ko then out[#out + 1] = { etichetta = 'Controllo', testo = c.testo, priorita = 8 } end
  out[#out + 1] = { etichetta = 'Comandi', testo = cmd, priorita = 7 }
  disegna(titolo, out, tipo)
end

-- Chiamata in fondo a ogni schermata della lezione. L'esito dell'ultimo :w passa dalla Batti alla
-- spiegazione (così si legge «Node ha controllato il codice»); ogni altra schermata parte pulita.
function M.schermata(s)
  if not f then return end
  if f.destra then
    local extra = f.destra()
    if extra and extra ~= '' then
      stato.destra = (stato.destra or '') .. extra
      vim.cmd('redrawtabline')
    end
  end
  if s.passo ~= 'spiegazione' then controllo = nil end
  if s.passo == 'batti' then
    M.cambio_voluto(s.buf) -- il buffer appena aperto (vuoto) è il punto di partenza
    M.tip(s)
  else
    disegna_testo(s)
  end
  if f.su_schermata then f.su_schermata(s) end
end

-- Il riquadro delle schermate di vivo (elenco, attesa, riepilogo).
function M.mostra(titolo, adesso, cmd, altre)
  local out = { { etichetta = 'Adesso', testo = adesso, priorita = 9 } }
  for _, x in ipairs(altre or {}) do out[#out + 1] = x end
  out[#out + 1] = { etichetta = 'Comandi', testo = cmd, priorita = 7 }
  disegna(titolo, out)
end

-- La riga dell'errore di node: la prima con SyntaxError, o con un'altra «…Error:», o la prima non
-- vuota dopo la riga «$ …».
local function riga_errore(righe)
  local primo_errore, prima = nil, nil
  for _, l in ipairs(righe) do
    l = vim.trim(l)
    if l ~= '' and not l:find('^%$ ') then
      if l:find('SyntaxError', 1, true) then return l end
      if not primo_errore and l:find('Error:', 1, true) then primo_errore = l end
      prima = prima or l
    end
  end
  return primo_errore or prima or 'il controllo non è riuscito'
end

-- Gli esiti di :w e gli avvisi di dattilo vanno in «Controllo» (G5), mai nella riga dei messaggi.
-- Non mostra i chunks, a parte quelli che non sono l'esito di un controllo: guarda lo stato e
-- sceglie la frase. In Batti, col testo diverso dal grigio, il controllo non è partito.
function M.eco(chunks)
  local s = lezione().s
  local pezzi = {}
  for _, c in ipairs(chunks) do pezzi[#pezzi + 1] = c[1] end
  local testo = table.concat(pezzi)
  local righe, nuovo = nil, nil
  if s and s.passo == 'batti' and s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
    local codice = s.L.batti.codice
    local esito = confronto.confronta(righe, codice)
    if not esito.finito then
      local mancano = #table.concat(codice, '\n') - #table.concat(righe, '\n')
      if #esito.errori > 0 or mancano < 1 then nuovo = { testo = T.controllo_rosso }
      else nuovo = { testo = T.f('controllo_mancano', mancano) } end
    end
  end
  if not nuovo then
    if testo:find('^%$ ') and not (s and s.passo == 'rompi') then
      if testo:find('Sintassi corretta.', 1, true) then
        nuovo = { testo = T.controllo_ok }
      else
        local righe_errore = {}
        for i = 1, math.max(1, #pezzi - 1) do vim.list_extend(righe_errore, vim.split(pezzi[i], '\n')) end
        local riga = (riga_errore(righe_errore):gsub('%.$', ''))
        nuovo = { testo = '', ko = true, adesso = T.f('controllo_ko', riga) }
      end
    else
      nuovo = { testo = vim.trim((testo:gsub('%s+', ' '))) }
    end
  end
  nuovo.righe = righe
  controllo = nuovo
  if not s then return end
  if s.passo == 'batti' then M.tip(s) else disegna_testo(s) end
end

function M.fine(s) return f ~= nil and f.fine ~= nil and f.fine(s) end

-- Tutto quello che il resto di dattilo chiama gira protetto.
for _, nome in ipairs({ 'tip', 'schermata', 'mostra', 'eco', 'fine', 'cambio_voluto' }) do
  M[nome] = proteggi(M[nome])
end

return M
