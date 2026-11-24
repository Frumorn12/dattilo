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
local controllo = nil  -- l'ultimo esito, per la sezione «Controllo»
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
  vim.api.nvim_create_autocmd('VimResized', { group = g, callback = function()
    if ultimo and ui.tip_aperto() then disegna(ultimo.titolo, ultimo.sezioni, ultimo.tipo) end
  end })
  -- Uscita dalla scrittura: il testo di adesso è quello «giusto», e un cambio in NORMAL si vede
  -- confrontandolo con questo. Si usa ModeChanged e non InsertLeave, che con Ctrl-c non scatta.
  vim.api.nvim_create_autocmd('ModeChanged', { group = g, callback = function()
    local s = lezione().s
    local da, a = vim.v.event.old_mode or '', vim.v.event.new_mode or ''
    if s and s.passo == 'batti' and s.buf and vim.api.nvim_get_current_buf() == s.buf
      and da:match('^[iR]') and not a:match('^[iR]') then
      M.cambio_voluto(s.buf)
      M.tip(s)
    end
  end })
  -- In NORMAL un movimento (2G, gg, h, un clic) cambia il punto, e con lui «Adesso». Una freccia
  -- premuta prima non è più «appena premuta».
  vim.api.nvim_create_autocmd('CursorMoved', { group = g, callback = function(a)
    local s = lezione().s
    if s and s.passo == 'batti' and a.buf == s.buf then
      s.frecce = false
      M.tip(s)
    end
  end })
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
  local adesso = M.adesso_batti({ codice = codice, righe = righe, r = cur[1], c = cur[2], modo = modo,
    frecce = s.frecce, cambiato = cambiato, annullato = annullato })
  local titolo, sez = lezione().tip_batti(s, modo)
  local out = { { etichetta = 'Adesso', testo = adesso, priorita = 9 } }
  if controllo then out[#out + 1] = { etichetta = 'Controllo', testo = controllo, priorita = 8 } end
  local r = math.min(cur[1], math.max(1, #codice))
  local riga_vuota = codice[r] and not codice[r]:match('%S') and not s.L.batti.suggerimenti[r]
  for _, x in ipairs(sez) do
    -- l'avviso su Vim e la sezione «Vim» li sostituisce «Adesso»; così la nota «Riga vuota», che
    -- dice ‹Invio› senza dire cosa fa (G3): sulla riga vuota «Adesso» dice già cosa premere
    if not x.avviso and x.etichetta ~= 'Vim' and not (riga_vuota and x.etichetta == 'Riga') then out[#out + 1] = x end
  end
  out[#out + 1] = { etichetta = 'Comandi', testo = comandi('batti'), priorita = 7 }
  local finito = confronto.confronta(righe, codice).finito
  disegna(finito and T.f('titoli.finito', #codice) or T.f('titoli.batti', titolo), out)
end

-- Chiamata in fondo a ogni schermata della lezione.
function M.schermata(s)
  if not f then return end
  if f.destra then
    local extra = f.destra()
    if extra and extra ~= '' then
      stato.destra = (stato.destra or '') .. extra
      vim.cmd('redrawtabline')
    end
  end
  controllo = nil
  if s.passo == 'briefing' then
    disegna(T.f('titoli.briefing', s.L.breve), {
      { etichetta = 'Adesso', testo = T.briefing, priorita = 9 },
      { etichetta = 'Comandi', testo = comandi('testo'), priorita = 7 },
    })
  elseif s.passo == 'batti' then
    M.cambio_voluto(s.buf) -- il buffer appena aperto (vuoto) è il punto di partenza
    M.tip(s)
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

-- Gli esiti di :w e gli avvisi di dattilo vanno in «Controllo», non nella riga dei messaggi.
function M.eco(chunks)
  local pezzi = {}
  for _, c in ipairs(chunks) do pezzi[#pezzi + 1] = c[1] end
  controllo = vim.trim(table.concat(pezzi))
  local s = lezione().s
  if s then M.tip(s) end
end

function M.fine(s) return f ~= nil and f.fine ~= nil and f.fine(s) end

return M
