-- «Rifallo tu» dentro dattilo: la cartella di lezioni aperta con `dattilo vivo <cartella>`.
local guida = require('dattilo.guida')
local T = require('dattilo.guida_testi')

local M = {}
local acceso = false
local PACCHETTO = 'rifallo'

function M.attivo() return acceso end

---------------------------------------------------------------- il canale con l'app: vuoi.json e stato.json
-- La cartella si guarda ogni 500 ms (il timer chiama `M.controlla`). `vuoi.json` lo scrive un altro
-- programma: si legge con prudenza (un file normale, piccolo, JSON giusto) e quello che non torna si
-- ignora senza dire niente. `stato.json` lo scrive dattilo, con un file nuovo e un rename.

local uv = vim.uv
local ID = '^%d%d%d%-[a-z0-9%-]+$' -- gli id ammessi: per le lezioni e per le richieste
local PASSO = 500 -- ms fra un controllo e l'altro
local MAX_VUOI, MAX_STATO = 4096, 65536 -- byte
local JSON = { luanil = { object = true, array = true } }
local ORDINE = { 'lezione', 'schermo', 'nuove', 'prossima', 'ultima', 'aperte', 'fatte', 'saltate', 'eseguita' }
local SCHERMI = { briefing = 'briefing', batti = 'batti', modifica = 'modifica', esegui = 'modifica', rompi = 'modifica',
  spiegazione = 'spiegazione', fine = 'fatto' }
-- Le frasi del canale. Stanno qui e non in guida_testi.lua perché lì sta lavorando un altro compito:
-- si spostano là quando i due lavori si uniscono.
local TESTI = {
  nuova = ' · 1 nuova',
  nuove = ' · %d nuove',
  finita = ' · sessione finita: niente lezioni nuove',
  spenta = ' · Dal vivo spento: niente lezioni nuove',
  dati_fuori = 'la cartella dei dati non è dentro quella di Rifallo tu',
  assente = 'la lezione non c\'è',
  attesa = 'Aspetto la prossima modifica di Claude a un file JavaScript…',
}

-- Il canale acceso: nil prima di `avvia` e dopo `ferma`. Campi:
--   eseguita  il `t` dell'ultima richiesta eseguita      dalvivo  'acceso' | 'spento' | 'finita'
--   aperte, saltate  liste di id (con `set`)             fatte  { [id] = true }, da progressi.json
--   P         le lezioni buone ({ lezioni = { {id} } })  coda  il risultato di M.coda
--   firma_*   com'erano i file all'ultima lettura buona  scritto  l'ultimo stato.json scritto, senza `t`
--   aggiunto  quello che `destra` ha messo in stato.destra
local canale = nil

local function corrente()
  local s = require('dattilo.lezione').s
  return s and s.L.id
end

local function firma(st)
  if not st then return '-' end
  return string.format('%d.%09d:%d:%d', st.mtime.sec, st.mtime.nsec, st.size, st.ino)
end

-- Il testo di un file normale e piccolo; nil per tutto il resto: manca, è un collegamento, una
-- cartella, è troppo grande, o è stato cambiato fra il controllo e l'apertura.
function M.leggi_sicuro(percorso, massimo)
  local st = uv.fs_lstat(percorso)
  if not st or st.type ~= 'file' or st.size > massimo then return nil end
  local fd = uv.fs_open(percorso, 'r', 0)
  if not fd then return nil end
  local dentro = uv.fs_fstat(fd)
  local testo = nil
  if dentro and dentro.type == 'file' and dentro.ino == st.ino and dentro.dev == st.dev and dentro.size <= massimo then
    testo = uv.fs_read(fd, massimo + 1, 0)
  end
  uv.fs_close(fd)
  return testo
end

-- Scrive `testo` in un file nuovo a 0600 e poi lo rinomina: mai un file a metà. Se al suo posto c'era
-- un collegamento, il rename lo sostituisce e non lo segue.
function M.scrivi_atomico(percorso, testo)
  local tmp = percorso .. '.' .. uv.os_getpid()
  uv.fs_unlink(tmp)
  local fd = uv.fs_open(tmp, 'wx', 384)
  if not fd then return false end
  local ok = uv.fs_write(fd, testo, 0) == #testo
  uv.fs_close(fd)
  ok = ok and uv.fs_rename(tmp, percorso) and true or false
  if not ok then uv.fs_unlink(tmp) end
  return ok
end

-- La cartella delle bozze, a 0700 (la crea se manca); nil se `bozze` c'è ma non è una cartella vera.
function M.dir_bozze()
  if not M.cartella then return nil end
  local d = M.cartella .. '/bozze'
  local st = uv.fs_lstat(d)
  if not st and uv.fs_mkdir(d, 448) then st = uv.fs_lstat(d) end
  if not st or st.type ~= 'directory' then return nil end
  return d
end

local function dir_pacchetto() return require('dattilo.progressi').cartella() .. '/pacchetti/' .. PACCHETTO end

-- I dati (XDG_DATA_HOME) devono stare dentro la cartella di Rifallo tu, anche dopo aver seguito i
-- collegamenti: altrimenti non si apre niente. Una cartella che non c'è ancora va bene.
local function dati_dentro()
  if not M.cartella then return true end
  local radice = uv.fs_realpath(M.cartella)
  if not radice then return false end
  for _, p in ipairs({ M.cartella .. '/dati', require('dattilo.progressi').cartella() }) do
    local r = uv.fs_realpath(p)
    if r and r:sub(1, #radice + 1) ~= radice .. '/' then return false end
  end
  return true
end

-- Il pacchetto delle lezioni, o nil quando i dati sono fuori dalla cartella.
local function pacchetto()
  if acceso and not dati_dentro() then return nil end
  return require('dattilo.pacchetti').carica(PACCHETTO)
end

-- Una lezione che si può aprire per id: l'id è giusto e il suo file è un file normale, non un collegamento.
local function lezione_valida(id)
  if type(id) ~= 'string' or not id:match(ID) then return false end
  local st = uv.fs_lstat(dir_pacchetto() .. '/lezioni/' .. id .. '.md')
  return st ~= nil and st.type == 'file'
end

-- La coda. P: { lezioni = { { id }, … } } (le lezioni lette senza errori). Rende:
--   nuove     quante, dopo la corrente, non fatte e non saltate (senza corrente: tutte quelle);
--   prossima  la prima di quelle;
--   ultima    la più recente non fatta (anche saltata): quella di :ultima.
function M.coda(P, corrente_id, fatte, saltate)
  fatte, saltate = fatte or {}, saltate or {}
  local ids = {}
  for _, L in ipairs(P and P.lezioni or {}) do
    if type(L.id) == 'string' and L.id:match(ID) then ids[#ids + 1] = L.id end
  end
  local posto = nil
  for i, id in ipairs(ids) do if id == corrente_id then posto = i end end
  local r = { nuove = 0 }
  for i, id in ipairs(ids) do
    if not fatte[id] then r.ultima = id end
    -- «dopo» la corrente: per posto, o per id se il suo file non c'è più (gli id hanno il numero davanti)
    local dopo = corrente_id == nil or (posto and i > posto) or (not posto and id > corrente_id)
    if dopo and not fatte[id] and not saltate[id] then
      r.nuove = r.nuove + 1
      r.prossima = r.prossima or id
    end
  end
  return r
end

local function aggiungi(lista, id)
  if type(id) == 'string' and id:match(ID) and not lista.set[id] then
    lista.set[id] = true
    lista[#lista + 1] = id
  end
end

local function nota_aperta(id)
  if canale then aggiungi(canale.aperte, id) end
end

local function ricalcola_coda()
  canale.coda = M.coda(canale.P, corrente(), canale.fatte, canale.saltate.set)
end

-- Le lezioni di stato.json di una sessione di prima: `aperte`, `saltate` e `eseguita`.
local function leggi_stato_vecchio()
  local testo = M.leggi_sicuro(M.cartella .. '/stato.json', MAX_STATO)
  if not testo then return end
  local ok, d = pcall(vim.json.decode, testo, JSON)
  if not ok or type(d) ~= 'table' then return end
  if type(d.eseguita) == 'number' and d.eseguita >= 0 then canale.eseguita = d.eseguita end
  for _, nome in ipairs({ 'aperte', 'saltate' }) do
    if type(d[nome]) == 'table' then
      for _, id in ipairs(d[nome]) do aggiungi(canale[nome], id) end
    end
  end
end

-- Le lezioni fatte: le chiavi `rifallo/<id>` di progressi.json, riletto solo se il file è cambiato.
local function leggi_progressi()
  local progressi = require('dattilo.progressi')
  local f = canale.dati_ok and firma(uv.fs_stat(progressi.cartella() .. '/progressi.json')) or 'fuori'
  if f == canale.firma_progressi then return end
  canale.firma_progressi = f
  canale.fatte = {}
  if not canale.dati_ok then return end
  for chiave in pairs(progressi.carica().lezioni) do
    local id = chiave:match('^' .. PACCHETTO .. '/(.+)$')
    if id and id:match(ID) then canale.fatte[id] = true end
  end
end

-- Com'è la cartella delle lezioni: il manifesto, la cartella e ogni lezione (data, dimensione, inode).
local function firma_cartella()
  local dir = dir_pacchetto()
  local parti = { firma(uv.fs_lstat(dir .. '/pacchetto.json')), firma(uv.fs_lstat(dir .. '/lezioni')) }
  local nomi = {}
  local h = uv.fs_scandir(dir .. '/lezioni')
  while h do
    local nome = uv.fs_scandir_next(h)
    if not nome then break end
    if nome:match('%.md$') then nomi[#nomi + 1] = nome end
  end
  table.sort(nomi)
  for _, nome in ipairs(nomi) do parti[#parti + 1] = nome .. ' ' .. firma(uv.fs_lstat(dir .. '/lezioni/' .. nome)) end
  return table.concat(parti, '|')
end

-- Le lezioni buone del pacchetto, lette dalla cartella; nil se manca qualcosa o non è una cosa normale.
local function carica_lezioni()
  local dir = dir_pacchetto()
  local m, l = uv.fs_lstat(dir .. '/pacchetto.json'), uv.fs_lstat(dir .. '/lezioni')
  if not (m and m.type == 'file' and l and l.type == 'directory') then return nil end
  local P = require('dattilo.pacchetti').carica_cartella(dir)
  if not (P.m and P.m.id == PACCHETTO) then return nil end
  local buone = {}
  for _, L in ipairs(P.lezioni) do
    if lezione_valida(L.id) then buone[#buone + 1] = { id = L.id } end
  end
  return { lezioni = buone }
end

-- Un giro di controllo dei dati: i collegamenti, la cartella delle lezioni (se è cambiata si rilegge
-- e si butta la cache dei pacchetti), i progressi, la coda.
local function aggiorna_dati()
  canale.dati_ok = dati_dentro()
  local f = canale.dati_ok and firma_cartella() or 'fuori'
  if f ~= canale.firma_dir then
    canale.firma_dir = f
    require('dattilo.pacchetti').dimentica()
    canale.P = canale.dati_ok and carica_lezioni() or nil
  end
  leggi_progressi()
  ricalcola_coda()
end

local function richiesta_valida(v)
  if type(v) ~= 'table' or v.v ~= 1 then return false end
  local t = v.t
  if t ~= nil and not (type(t) == 'number' and t >= 0 and t < 2 ^ 53 and t == math.floor(t)) then return false end
  if v.azione ~= nil and type(v.azione) ~= 'string' then return false end
  if v.lezione ~= nil and type(v.lezione) ~= 'string' then return false end
  if v.dalvivo ~= nil and type(v.dalvivo) ~= 'string' then return false end
  if v.azione ~= nil and t == nil then return false end
  if v.azione == 'apri' and v.lezione == nil then return false end
  return true
end

-- La richiesta di vuoi.json, se il file è cambiato dall'ultima lettura buona e adesso è giusto.
-- Finché non si legge bene si rilegge a ogni giro, anche se il file non cambia.
local function leggi_vuoi()
  local percorso = M.cartella .. '/vuoi.json'
  local f = firma(uv.fs_lstat(percorso))
  if f == canale.firma_vuoi then return nil end
  canale.firma_vuoi = nil
  local testo = M.leggi_sicuro(percorso, MAX_VUOI)
  if not testo then return nil end
  local ok, v = pcall(vim.json.decode, testo, JSON)
  if not ok or not richiesta_valida(v) then return nil end
  canale.firma_vuoi = f
  return v
end

-- Apre una lezione per una richiesta che arriva da fuori (la mod, o la prima lezione che arriva in
-- «Attesa»). La persona può stare scrivendo in Batti, in INSERT: la schermata nuova non si scrive, e
-- restare in INSERT darebbe E21 al primo tasto, senza che la guida lo spieghi.
local function apri_da_fuori(id)
  vim.cmd('stopinsert')
  M.apri(id)
end

local function esegui_richiesta(v)
  -- «dalvivo» vale a ogni lettura, anche senza una richiesta nuova
  if v.dalvivo == 'acceso' or v.dalvivo == 'spento' or v.dalvivo == 'finita' then canale.dalvivo = v.dalvivo end
  if v.azione == nil or v.t <= canale.eseguita then return end
  canale.eseguita = v.t
  if v.azione == 'apri' then
    -- un id fuori modello, o una lezione che non c'è: niente (e nessuno è buttato fuori dalla sua lezione)
    local st = v.lezione:match(ID) and uv.fs_lstat(dir_pacchetto() .. '/lezioni/' .. v.lezione .. '.md')
    if st and st.type == 'file' and v.lezione ~= corrente() then apri_da_fuori(v.lezione) end
  elseif v.azione == 'ultima' then
    local id = canale.coda.ultima
    if id and id ~= corrente() then apri_da_fuori(id) end
  end
end

local function nome_schermo()
  local s = require('dattilo.lezione').s
  if s then return SCHERMI[s.passo] or 'batti' end
  return require('dattilo.stato').file == 'attesa' and 'attesa' or 'elenco'
end

-- Il pezzo in fondo alla barra: « · 2 nuove», o perché non ne arrivano più.
function M.destra()
  if not canale then return '' end
  if canale.dalvivo == 'finita' then return TESTI.finita end
  if canale.dalvivo == 'spento' then return TESTI.spenta end
  local n = canale.coda.nuove
  if n == 1 then return TESTI.nuova end
  if n > 1 then return string.format(TESTI.nuove, n) end
  return ''
end

-- Il fornitore della guida: la guida lo aggiunge a stato.destra a ogni schermata, e qui si ricorda cosa.
local function destra_fornitore()
  if not canale then return '' end
  ricalcola_coda() -- la lezione che si apre adesso è già la corrente
  canale.aggiunto = M.destra()
  return canale.aggiunto
end

-- Rimette in stato.destra il pezzo di adesso al posto di quello di prima.
local function aggiorna_barra()
  local stato = require('dattilo.stato')
  local ora, base = stato.destra or '', stato.destra or ''
  if canale.aggiunto ~= '' and ora:sub(-#canale.aggiunto) == canale.aggiunto then base = ora:sub(1, #ora - #canale.aggiunto) end
  local pezzo = M.destra()
  if base == '' then pezzo = pezzo:gsub('^ · ', '') end
  canale.aggiunto = pezzo
  if base .. pezzo ~= ora then
    stato.destra = base .. pezzo
    vim.cmd('redrawtabline')
  end
end

-- Riscrive stato.json, ma solo se è cambiato qualcosa oltre a `t`.
function M.scrivi_stato()
  if not canale then return end
  local fatte = vim.tbl_keys(canale.fatte)
  table.sort(fatte)
  local saltate = {}
  for _, id in ipairs(canale.saltate) do
    if not canale.fatte[id] then saltate[#saltate + 1] = id end
  end
  local nuovo = {
    lezione = corrente() or vim.NIL, schermo = nome_schermo(), nuove = canale.coda.nuove,
    prossima = canale.coda.prossima or vim.NIL, ultima = canale.coda.ultima or vim.NIL,
    aperte = vim.list_slice(canale.aperte), fatte = fatte, saltate = saltate, eseguita = canale.eseguita,
  }
  if vim.deep_equal(nuovo, canale.scritto) then return end
  local s, us = uv.gettimeofday()
  local pezzi = { '"v":1', string.format('"t":%.0f', s * 1000 + math.floor(us / 1000)) }
  for _, k in ipairs(ORDINE) do pezzi[#pezzi + 1] = vim.json.encode(k) .. ':' .. vim.json.encode(nuovo[k]) end
  if M.scrivi_atomico(M.cartella .. '/stato.json', '{' .. table.concat(pezzi, ',') .. '}') then canale.scritto = nuovo end
end

-- Una lezione lasciata con :salta: non conta più fra le nuove, e la ricorda anche dopo la chiusura.
function M.segna_saltata(id)
  if not canale then return end
  aggiungi(canale.saltate, id)
  ricalcola_coda()
  M.scrivi_stato()
end

-- Dice perché una lezione non si apre, nel riquadro («Controllo»).
local function avviso(motivo)
  guida.eco({ { T.f('non_si_apre', (tostring(motivo):gsub('%.$', ''))), 'DattiloGiallo' } })
end

local function avviso_apri(id, P)
  if acceso and not dati_dentro() then return avviso(TESTI.dati_fuori) end
  for _, e in ipairs(P and P.errori or {}) do
    if e.file == id .. '.md' then return avviso(e.msg) end
  end
  avviso(TESTI.assente)
end

-- «Attesa»: niente da fare finché Claude non cambia un'altra funzione. La prima lezione che arriva si apre da sola.
local function attesa(motivo)
  local schermo, stato, ui = require('dattilo.schermo'), require('dattilo.stato'), require('dattilo.ui')
  require('dattilo.lezione').chiudi()
  require('dattilo.dojo').chiudi()
  ui.chiudi_tip()
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'home', 'Rifallo tu', '', 'attesa', nil
  vim.cmd('redrawtabline')
  local buf = schermo.buffer('attesa')
  schermo.scrivi(buf, { {}, { { '   ' .. TESTI.attesa, 'DattiloTesto' } } })
  schermo.mostra(buf, 'testo')
  guida.mostra(T.f('titoli.attesa'), (canale and canale.dalvivo ~= 'acceso') and T.attesa_finita or T.attesa, T.comandi_attesa)
  if motivo then avviso(motivo) end
end

-- In «Attesa», appena c'è una lezione nuova si apre.
local function apri_da_attesa()
  if canale.dati_ok and not corrente() and nome_schermo() == 'attesa' and canale.coda.prossima then
    apri_da_fuori(canale.coda.prossima)
    ricalcola_coda()
  end
end

-- Un giro del timer: i dati, la richiesta di vuoi.json, la coda, la barra, stato.json. Si chiama anche dalle prove.
function M.controlla()
  if not (canale and canale.pronto) then return end
  aggiorna_dati()
  local v = leggi_vuoi()
  if v then esegui_richiesta(v) end
  ricalcola_coda()
  apri_da_attesa()
  aggiorna_barra()
  M.scrivi_stato()
end

local function ferma_canale()
  if canale and canale.timer then
    canale.timer:stop()
    canale.timer:close()
  end
  canale = nil
end

local function avvia_canale()
  ferma_canale()
  canale = { eseguita = 0, dalvivo = 'acceso', aperte = { set = {} }, saltate = { set = {} }, fatte = {},
    coda = { nuove = 0 }, aggiunto = '' }
  leggi_stato_vecchio()
end

-- Dopo VimEnter: una richiesta più nuova di quella eseguita vince; altrimenti la prima lezione non
-- fatta e non saltata; altrimenti «Attesa». Poi il timer.
local function parti_canale()
  aggiorna_dati()
  local v = leggi_vuoi()
  if v then esegui_richiesta(v) end
  -- niente lezione e niente elenco: la richiesta non ha aperto niente (un elenco con l'avviso, sì)
  if not corrente() and require('dattilo.stato').file ~= 'elenco' then
    local prima = canale.dati_ok and canale.coda.prossima
    if prima then M.apri(prima) else attesa(not canale.dati_ok and TESTI.dati_fuori or nil) end
  end
  ricalcola_coda()
  canale.pronto = true
  aggiorna_barra()
  M.scrivi_stato()
  local timer = uv.new_timer()
  canale.timer = timer
  timer:start(PASSO, PASSO, vim.schedule_wrap(function()
    local ok, e = pcall(M.controlla)
    -- un errore non arriva mai alla riga dei messaggi: va nel riquadro, una volta per errore
    if not ok and canale and e ~= canale.ultimo_errore then
      canale.ultimo_errore = e
      guida.protetta(error, e, 0)
    end
  end))
end

local function fornitore()
  return {
    comandi = function(schermata) return T['comandi_' .. schermata] or '' end,
    fine = function() return false end,
    su_schermata = function() end,
    destra = destra_fornitore,
  }
end

local function parti()
  if not acceso then return end
  parti_canale()
end

function M.avvia(cartella)
  acceso = true
  M.cartella = cartella
  avvia_canale()
  guida.accendi(fornitore())
  -- all'avvio Neovim, finito init.lua, porta il fuoco sulla prima finestra, che è quella del
  -- riquadro: si parte a Neovim già avviato, così il fuoco resta sulla lezione
  if vim.v.vim_did_enter == 1 then return parti() end
  vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function() vim.schedule(parti) end })
end

-- Per le prove: spegne la guida e torna al dattilo di sempre.
function M.ferma()
  acceso = false
  ferma_canale()
  guida.spegni()
end

function M.apri(id)
  local pacchetti = require('dattilo.pacchetti')
  pacchetti.dimentica()
  local P = pacchetto()
  for n, L in ipairs(P and P.lezioni or {}) do
    if L.id == id and lezione_valida(id) then
      require('dattilo.lezione').apri(PACCHETTO, n)
      return nota_aperta(id)
    end
  end
  M.elenco()
  avviso_apri(id, P)
end

-- L'elenco nudo: una riga per lezione, ‹Invio› apre.
function M.elenco()
  local schermo, stato, ui = require('dattilo.schermo'), require('dattilo.stato'), require('dattilo.ui')
  require('dattilo.lezione').chiudi()
  require('dattilo.dojo').chiudi()
  ui.chiudi_tip()
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'home', 'Rifallo tu', '', 'elenco', nil
  vim.cmd('redrawtabline')
  local pacchetti = require('dattilo.pacchetti')
  pacchetti.dimentica()
  local P = pacchetto()
  local lezioni = P and P.lezioni or {}
  local righe = { {} }
  for _, L in ipairs(lezioni) do righe[#righe + 1] = { { '   ▸ ' .. L.id .. '  ' .. (L.titolo or ''), 'DattiloTesto' } } end
  local buf = schermo.buffer('elenco')
  schermo.scrivi(buf, righe)
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { math.min(2, #righe), 0 })
  vim.keymap.set('n', '<CR>', function()
    -- l'elenco rimasto in giro (‹Ctrl-o›) non apre una lezione mentre se ne scrive un'altra
    if stato.schermo ~= 'home' then return end
    local L = lezioni[vim.api.nvim_win_get_cursor(0)[1] - 1]
    if L then M.apri(L.id) end
  end, { buffer = buf, nowait = true, silent = true })
  guida.mostra(T.f('titoli.elenco'), T.elenco, T.comandi_elenco)
end

return M
