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
local PASSO_BOZZA = 2000 -- ms: la bozza si riscrive al massimo così spesso mentre si scrive
local MAX_VUOI, MAX_STATO = 4096, 65536 -- byte
local JSON = { luanil = { object = true, array = true } }
local ORDINE = { 'lezione', 'schermo', 'nuove', 'prossima', 'ultima', 'aperte', 'fatte', 'saltate', 'eseguita' }
local SCHERMI = { briefing = 'briefing', batti = 'batti', modifica = 'modifica', esegui = 'modifica', rompi = 'modifica',
  spiegazione = 'spiegazione', fine = 'fatto' }
-- Il canale acceso: nil prima di `avvia` e dopo `ferma`. Campi:
--   eseguita  il `t` dell'ultima richiesta eseguita      dalvivo  'acceso' | 'spento' | 'finita'
--   aperte, saltate  liste di id (con `set`)             fatte  { [id] = true }, da progressi.json
--   P         le lezioni buone ({ lezioni = { {id} } })  coda  il risultato di M.coda
--   firma_*   com'erano i file all'ultima lettura buona  scritto  l'ultimo stato.json scritto, senza `t`
--   aggiunto  quello che `destra` ha messo in stato.destra
--   salvate   [id] = le righe dell'ultima bozza scritta (false: tolta); ultima_bozza  quando (ms) si è scritta
--   riprendi  l'id della lezione che si sta riaprendo con la sua bozza
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

-- La cartella delle bozze, a 0700 (la crea se manca, a meno che `senza_creare`); nil se `bozze` c'è ma
-- non è una cartella vera.
function M.dir_bozze(senza_creare)
  if not M.cartella then return nil end
  local d = M.cartella .. '/bozze'
  local st = uv.fs_lstat(d)
  if not st and not senza_creare and uv.fs_mkdir(d, 448) then st = uv.fs_lstat(d) end
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
  if v.azione ~= nil and v.azione ~= 'apri' and v.azione ~= 'ultima' then return false end
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

-- La frase giusta per `dalvivo` ('acceso', 'finita' o 'spento'): quando non arrivano più lezioni, le frasi
-- che promettono «la lezione si apre da sola» non sono vere.
local function per_dalvivo(dalvivo, acceso, finita, spento)
  if dalvivo == 'finita' then return finita end
  if dalvivo == 'spento' then return spento end
  return acceso
end

-- È il momento di cambiare schermata da soli? No se la persona ha qualcosa a metà che una schermata
-- nuova romperebbe: la riga dei comandi (anche con :w scritto), un operatore in attesa (d), la finestra dei
-- comandi (q:), «Premi INVIO» o un comando esterno. Sono stati di pochi secondi: la richiesta aspetta il
-- giro dopo, senza dire niente (il contratto: «se dattilo è occupato, legge al giro dopo»).
local function e_il_momento()
  local modo = vim.api.nvim_get_mode().mode
  if modo:match('^[cr!]') or modo:sub(1, 2) == 'no' then return false end
  return vim.fn.getcmdwintype() == ''
end

local function esegui_richiesta(v)
  -- «dalvivo» vale a ogni lettura, anche senza una richiesta nuova
  if v.dalvivo == 'acceso' or v.dalvivo == 'spento' or v.dalvivo == 'finita' then canale.dalvivo = v.dalvivo end
  if v.azione == nil or v.t <= canale.eseguita then return end
  -- non è il momento: la richiesta non si consuma (`eseguita` resta com'era) e il file si rilegge al giro dopo
  if not e_il_momento() then
    canale.firma_vuoi = nil
    return
  end
  canale.eseguita = v.t
  if v.azione == 'apri' then
    -- un id fuori modello, o una lezione che non c'è: niente (e nessuno è buttato fuori dalla sua lezione)
    if lezione_valida(v.lezione) and v.lezione ~= corrente() then apri_da_fuori(v.lezione) end
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
  if canale.dalvivo == 'finita' then return T.canale.finita end
  if canale.dalvivo == 'spento' then return T.canale.spenta end
  local n = canale.coda.nuove
  if n == 1 then return T.canale.nuova end
  if n > 1 then return string.format(T.canale.nuove, n) end
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
  if acceso and not dati_dentro() then return avviso(T.canale.dati_fuori) end
  for _, e in ipairs(P and P.errori or {}) do
    if e.file == id .. '.md' then return avviso(e.msg) end
  end
  avviso(T.canale.assente)
end

-- In «Attesa», appena c'è una lezione nuova si apre.
local function apri_da_attesa()
  if canale.dati_ok and not corrente() and nome_schermo() == 'attesa' and canale.coda.prossima and e_il_momento() then
    apri_da_fuori(canale.coda.prossima)
    ricalcola_coda()
  end
end

-- La barra subito, senza aspettare il giro del timer (alle schermate di vivo che non passano da guida.schermata).
local function barra_subito()
  if canale and canale.pronto then
    ricalcola_coda()
    aggiorna_barra()
  end
end

-- In «Attesa» la frase dipende da `dalvivo`: se cambia mentre si è lì (la sessione finisce, Dal vivo
-- si spegne) la schermata si rifà, perché «appena Claude cambia una funzione…» non sarebbe più vero.
-- Lo decide il timer, non la persona: aspetta il momento giusto come le richieste (con la finestra dei
-- comandi aperta darebbe E11), e `canale.attesa` resta com'era, quindi si riprova al giro dopo.
local function ridisegna_attesa()
  local a = canale.attesa
  if a and not corrente() and nome_schermo() == 'attesa' and a.dalvivo ~= canale.dalvivo and e_il_momento() then M.attesa(a.motivo) end
end

local disegna_fatto -- più sotto: il riepilogo

-- Lo stesso per il riepilogo: «la lezione si apre da sola» non è più vero se la sessione finisce mentre
-- lo si legge. Lo decide il timer (vuoi.json), non la persona: aspetta il momento giusto, e si riprova al
-- giro dopo. Si rifanno solo il testo e il riquadro: niente da registrare (`di_nuovo`).
local function ridisegna_fatto()
  local f = canale.fatto
  if not (f and f.dalvivo ~= canale.dalvivo and e_il_momento()) then return end
  local s = require('dattilo.lezione').s
  if s == f.s and s.passo == 'fine' then disegna_fatto(s, true) end
end

-- Un giro del timer: i dati, la richiesta di vuoi.json, la coda, la barra, stato.json. Si chiama anche dalle prove.
function M.controlla()
  if not (canale and canale.pronto) then return end
  aggiorna_dati()
  local v = leggi_vuoi()
  if v then esegui_richiesta(v) end
  ricalcola_coda()
  apri_da_attesa()
  ridisegna_attesa()
  ridisegna_fatto()
  aggiorna_barra()
  -- rete di sicurezza: una lezione aperta senza passare da `vivo.apri` conta fra le aperte
  if corrente() then aggiungi(canale.aperte, corrente()) end
  -- la bozza, se è cambiata, al massimo ogni 2 secondi
  local adesso = uv.hrtime() / 1e6
  if corrente() and adesso - canale.ultima_bozza >= PASSO_BOZZA and M.bozza_salva(corrente()) then canale.ultima_bozza = adesso end
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
    coda = { nuove = 0 }, aggiunto = '', salvate = {}, ultima_bozza = 0 }
  leggi_stato_vecchio()
end

-- Dopo VimEnter: una richiesta più nuova di quella eseguita vince; altrimenti la prima lezione non
-- fatta e non saltata; altrimenti «Attesa». Poi il timer.
local function parti_canale()
  -- un errore qui non arriva alla riga dei messaggi: va nel riquadro, e il timer parte lo stesso
  local ok, e = pcall(function()
    aggiorna_dati()
    local v = leggi_vuoi()
    if v then esegui_richiesta(v) end
    -- niente lezione e niente elenco: la richiesta non ha aperto niente (un elenco con l'avviso, sì)
    if not corrente() and require('dattilo.stato').file ~= 'elenco' then
      local prima = canale.dati_ok and canale.coda.prossima
      if prima then M.apri(prima) else M.attesa(not canale.dati_ok and T.canale.dati_fuori or nil) end
    end
    ricalcola_coda()
    aggiorna_barra()
    M.scrivi_stato()
  end)
  canale.pronto = true
  if not ok then
    canale.ultimo_errore = e
    guida.protetta(error, e, 0)
  end
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
    fine = function(s) return M.fatto(s) end,
    su_schermata = function(s) M.su_schermata(s) end,
    destra = destra_fornitore,
  }
end

local function parti()
  if not acceso then return end
  parti_canale()
end

---------------------------------------------------------------- la bozza (G8)

-- Il testo di Batti si salva in bozze/<id>.json (0600, in una cartella 0700): mentre si scrive (al
-- massimo ogni 2 s, dentro `controlla`), quando si esce dalla scrittura, quando si lascia la lezione
-- e alla chiusura di Neovim. Si rimette riaprendo la lezione, e si toglie quando la lezione è fatta.
-- Tutto passa da `dir_bozze`, `scrivi_atomico` e `leggi_sicuro`: un collegamento al posto di `bozze/`
-- o del file non si segue.
local MAX_BOZZA, MAX_RIGHE = 262144, 2000 -- byte e righe di una bozza che si legge

local function ha_testo(righe)
  for _, l in ipairs(righe) do
    if l ~= '' then return true end
  end
  return false
end

-- Il percorso della bozza di `id`; nil per un id fuori dal modello o se `bozze` non è una cartella vera.
-- Si crea la cartella solo per scrivere (`crea`): leggere o togliere una bozza non lascia niente in giro.
local function file_bozza(id, crea)
  if type(id) ~= 'string' or not id:match(ID) then return nil end
  local dir = M.dir_bozze(not crea)
  return dir and (dir .. '/' .. id .. '.json') or nil
end

-- La bozza di `id`: { passo, righe }, o nil se non c'è, non è un file normale, è troppo grande o non è fatta bene.
function M.bozza_leggi(id)
  local percorso = file_bozza(id)
  if not percorso then return nil end
  local testo = M.leggi_sicuro(percorso, MAX_BOZZA)
  if not testo then return nil end
  local ok, d = pcall(vim.json.decode, testo, JSON)
  if not ok or type(d) ~= 'table' or d.v ~= 1 or (d.passo ~= 'batti' and d.passo ~= 'modifica') then return nil end
  local righe = d.righe
  if type(righe) ~= 'table' then return nil end
  -- Un null fra le righe lascia un buco nella lista (con `luanil`), e `#` su una lista bucata può rendere
  -- un bordo qualunque, anche il numero degli elementi: si contano gli elementi con pairs e si guarda ogni
  -- posto da 1 a quanti. Un buco non è una stringa, come una riga che non lo è.
  local quante = 0
  for _ in pairs(righe) do quante = quante + 1 end
  if quante == 0 or quante > MAX_RIGHE then return nil end
  for i = 1, quante do
    local l = righe[i]
    -- una riga con un a capo non si può rimettere nel buffer
    if type(l) ~= 'string' or l:find('\n', 1, true) then return nil end
  end
  if not ha_testo(righe) then return nil end
  return { passo = d.passo, righe = righe }
end

-- Toglie la bozza di `id` (un collegamento al suo posto si toglie, il bersaglio no).
function M.bozza_togli(id)
  if canale then canale.salvate[id] = nil end
  local percorso = file_bozza(id)
  if percorso then uv.fs_unlink(percorso) end
end

-- Salva il testo di Batti della lezione aperta `id`. Solo nel passo batti, e solo se le righe sono
-- cambiate dall'ultima volta; un buffer rimasto vuoto toglie la bozza (una vecchia riporterebbe testo
-- che la persona ha cancellato). Vero se ha scritto.
function M.bozza_salva(id)
  local s = require('dattilo.lezione').s
  if not (canale and s and s.L.id == id and s.passo == 'batti' and s.buf and vim.api.nvim_buf_is_valid(s.buf)) then return false end
  local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  -- Con un'uccisione da fuori (SIGTERM, SIGHUP: il pannello chiuso) Neovim scarica i buffer prima di
  -- VimLeavePre, e il buffer risponde senza righe: l'ultimo testo che batti.lua ha visto è sempre lì.
  if #righe == 0 then
    local st = require('dattilo.batti').stato(s.buf)
    if st and st.prima then righe = vim.deepcopy(st.prima) end
  end
  if not ha_testo(righe) then
    if canale.salvate[id] ~= false then
      M.bozza_togli(id)
      canale.salvate[id] = false
    end
    return false
  end
  if vim.deep_equal(righe, canale.salvate[id]) then return false end
  local percorso = file_bozza(id, true)
  if not percorso then return false end
  -- i campi in quest'ordine, come nel contratto
  local testo = '{"v":1,"passo":"batti","righe":' .. vim.json.encode(righe) .. '}'
  if #testo > MAX_BOZZA or not M.scrivi_atomico(percorso, testo) then return false end
  canale.salvate[id] = righe
  return true
end

-- Si lascia la lezione aperta (per un'altra, l'elenco, l'attesa): il suo testo si salva prima di chiuderla.
local function lascia()
  local s = require('dattilo.lezione').s
  if canale and s then guida.protetta(M.bozza_salva, s.L.id) end
end

-- Il fornitore, in fondo a ogni schermata: se si sta riaprendo la lezione con la sua bozza e il buffer è
-- vuoto, le righe tornano, il cursore va in fondo e la guida dice «Ripreso». `cambio_voluto` prima di
-- ridisegnare: senza, in NORMAL la guida direbbe ‹u›, che annullerebbe la ripresa. Solo la riapertura
-- (`riprendi`): un `:e!` ricomincia da capo e non rimette la bozza.
function M.su_schermata(s)
  if not (canale and s.passo == 'batti' and canale.riprendi == s.L.id) then return end
  canale.riprendi = nil
  local b = M.bozza_leggi(s.L.id)
  if not (b and b.passo == 'batti' and s.buf and vim.api.nvim_buf_is_valid(s.buf)) then return end
  local vuoto = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  if not (#vuoto == 1 and vuoto[1] == '') then return end
  vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, b.righe)
  vim.api.nvim_win_set_cursor(require('dattilo.schermo').finestra(), { #b.righe, #b.righe[#b.righe] })
  canale.salvate[s.L.id] = b.righe
  require('dattilo.batti').aggiorna(s.buf)
  guida.cambio_voluto(s.buf)
  guida.avviso(T.ripreso)
end

local function crea_autocomandi_bozza()
  local g = vim.api.nvim_create_augroup('dattilo_bozza', { clear = true })
  -- uscendo dalla scrittura (con ‹Ctrl-c› InsertLeave non scatta, ModeChanged sì)
  vim.api.nvim_create_autocmd('ModeChanged', { group = g, callback = function()
    local da, a = vim.v.event.old_mode or '', vim.v.event.new_mode or ''
    if da:match('^[iR]') and not a:match('^[iR]') then lascia() end
  end })
  -- alla chiusura, anche quando il pannello si chiude da fuori (SIGHUP, SIGTERM): il testo e lo stato
  vim.api.nvim_create_autocmd('VimLeavePre', { group = g, callback = function()
    pcall(lascia)
    pcall(M.scrivi_stato)
  end })
end

---------------------------------------------------------------- i comandi :salta, :ultima ed :elenco

-- Come `:q` in init.lua: un comando con la maiuscola e l'abbreviazione in minuscolo, che vale solo
-- scrivendo il nome intero, anche con degli spazi davanti (`: salta`: la guida li legge uguale).
-- Esistono solo con `vivo` acceso.
local COMANDI = {
  { nome = 'salta', comando = 'DattiloSalta', desc = 'Lascia la lezione e apri la prossima' },
  { nome = 'ultima', comando = 'DattiloUltima', desc = 'Apri l\'ultima modifica di Claude' },
  { nome = 'elenco', comando = 'DattiloElenco', desc = 'Apri l\'elenco delle lezioni' },
}

local function crea_comandi()
  for _, c in ipairs(COMANDI) do
    -- un errore dentro il comando va nel riquadro, non nella riga dei messaggi (G5)
    vim.api.nvim_create_user_command(c.comando, function() guida.protetta(function() M[c.nome]() end) end, { desc = c.desc })
    vim.cmd(string.format("cnoreabbrev <expr> %s (getcmdtype() ==# ':' && trim(getcmdline()) ==# '%s') ? '%s' : '%s'", c.nome, c.nome, c.comando, c.nome))
  end
end

local function togli_comandi()
  for _, c in ipairs(COMANDI) do
    pcall(vim.api.nvim_del_user_command, c.comando)
    pcall(vim.cmd, 'cunabbrev ' .. c.nome)
  end
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_elenco')
end

function M.avvia(cartella)
  acceso = true
  M.cartella = cartella
  avvia_canale()
  guida.accendi(fornitore())
  crea_comandi()
  crea_autocomandi_bozza()
  -- all'avvio Neovim, finito init.lua, porta il fuoco sulla prima finestra, che è quella del
  -- riquadro: si parte a Neovim già avviato, così il fuoco resta sulla lezione
  if vim.v.vim_did_enter == 1 then return parti() end
  vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function() vim.schedule(parti) end })
end

-- Per le prove: spegne la guida e torna al dattilo di sempre.
function M.ferma()
  acceso = false
  ferma_canale()
  togli_comandi()
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_bozza')
  guida.spegni()
end

function M.apri(id)
  lascia()
  local pacchetti = require('dattilo.pacchetti')
  pacchetti.dimentica()
  local P = pacchetto()
  for n, L in ipairs(P and P.lezioni or {}) do
    if L.id == id and lezione_valida(id) then
      local lezione = require('dattilo.lezione')
      lezione.apri(PACCHETTO, n)
      nota_aperta(id)
      -- con una bozza di Batti si va dritti a Batti: `su_schermata` rimette il testo
      local b = canale and lezione.s and lezione.s.L.id == id and M.bozza_leggi(id)
      if b and b.passo == 'batti' then
        canale.riprendi = id
        lezione.batti(lezione.s)
        canale.riprendi = nil
      end
      return
    end
  end
  M.elenco()
  avviso_apri(id, P)
end

---------------------------------------------------------------- «Attesa»

-- Niente da fare finché Claude non cambia un'altra funzione: la prima lezione che arriva si apre da sola.
-- `motivo`: perché non si apre niente (i dati fuori dalla cartella), in «Controllo».
function M.attesa(motivo)
  lascia()
  local schermo, stato, ui = require('dattilo.schermo'), require('dattilo.stato'), require('dattilo.ui')
  require('dattilo.lezione').chiudi()
  require('dattilo.dojo').chiudi()
  ui.chiudi_tip()
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'home', 'Rifallo tu', '', 'attesa', nil
  vim.cmd('redrawtabline')
  local dalvivo = canale and canale.dalvivo or 'acceso'
  local buf = schermo.buffer('attesa')
  local corpo = per_dalvivo(dalvivo, T.canale.attesa, T.canale.attesa_finita, T.canale.attesa_spento)
  schermo.scrivi(buf, { {}, { { '   ' .. corpo, 'DattiloTesto' } } })
  schermo.mostra(buf, 'testo')
  if canale then canale.attesa = { dalvivo = dalvivo, motivo = motivo } end
  local adesso = per_dalvivo(dalvivo, T.attesa, T.attesa_finita, T.attesa_spento)
  guida.mostra(T.f('titoli.attesa'), adesso, T.comandi_attesa)
  barra_subito()
  if motivo then avviso(motivo) end
end

---------------------------------------------------------------- il riepilogo, la prossima, :salta, :ultima

local function tempo(ms) local sec = math.floor(ms / 1000 + 0.5) return string.format('%d:%02d', math.floor(sec / 60), sec % 60) end
local function perc(p) local x = string.format('%.1f', p):gsub('%.0$', ''):gsub('%.', ',') return x .. '%' end

-- I dati di adesso, per i comandi: una lezione scritta un attimo fa conta già.
local function fresca()
  if canale then aggiorna_dati() end
end

-- Cosa apre ‹Invio› nel riepilogo, `:salta` e «Attesa»: la prima lezione dopo la corrente, non fatta e
-- non saltata; se dopo non c'è niente, la prima fra quelle lasciate a metà. È la stessa regola in tutti e
-- tre i posti (l'attesa aprirebbe quella): così il riepilogo non dice «aspetti» e poi riapre una lezione.
local function da_aprire()
  if canale.coda.prossima then return canale.coda end
  return M.coda(canale.P, nil, canale.fatte, canale.saltate.set)
end

local function titolo_di(id)
  local P = pacchetto()
  for _, L in ipairs(P and P.lezioni or {}) do
    if L.id == id then return L.titolo or id end
  end
  return id
end

-- Disegna il riepilogo di `s`, la lezione appena fatta, e dice cosa fa ‹Invio›. `di_nuovo`: la schermata
-- c'è già e si rifà com'è adesso (la sessione è finita mentre la si leggeva): niente da mostrare di nuovo
-- né da mappare, il cursore e la finestra restano dove sono.
function disegna_fatto(s, di_nuovo)
  local L = s.L
  local ris = s.risultato or { wpm = 0, precisione = 100, tempo_ms = 0 }
  local schermo = require('dattilo.schermo')
  local coda = da_aprire()
  local dalvivo = canale.dalvivo
  local R = T.riepilogo
  local function etichetta(x) return string.format('   %-11s', x) end
  local righe = { {}, {
    { etichetta(R.etichetta_batti), 'DattiloTesto' },
    { T.f('riepilogo.batti', #L.batti.codice, tempo(ris.tempo_ms)), 'DattiloForte' },
    { '   ' .. T.f('riepilogo.velocita', ris.wpm, perc(ris.precisione)), 'DattiloVerde' },
  } }
  if #L.modifiche > 0 then
    righe[#righe + 1] = { { etichetta(R.etichetta_modifica), 'DattiloTesto' }, { T.f('riepilogo.modifica', s.tasti_modifica or 0), 'DattiloForte' } }
  end
  righe[#righe + 1] = {}
  local adesso
  if coda.prossima then
    local n = coda.nuove == 1 and T.fatto_nuova or T.f('fatto_nuove', coda.nuove)
    local titolo = titolo_di(coda.prossima)
    righe[#righe + 1] = { { etichetta(R.etichetta_prossima), 'DattiloTesto' }, { T.f('riepilogo.prossima', titolo), 'DattiloCiano' } }
    adesso = T.f('fatto_coda', titolo, n)
  else
    -- niente da aprire: la frase dipende da `dalvivo`, perché «si apre da sola» vale solo se Claude è ancora al lavoro
    righe[#righe + 1] = { { etichetta(R.etichetta_prossima), 'DattiloTesto' },
      { per_dalvivo(dalvivo, R.prossima_vuota, R.prossima_finita, R.prossima_spento), 'DattiloMuto' } }
    adesso = per_dalvivo(dalvivo, T.fatto_vuota, T.fatto_vuota_finita, T.fatto_vuota_spento)
  end
  local buf = schermo.buffer('rifallo-fatto')
  schermo.scrivi(buf, righe)
  canale.fatto = { s = s, dalvivo = dalvivo }
  if not di_nuovo then
    schermo.mostra(buf, 'testo')
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    -- i tasti valgono solo qui: la schermata rimasta in giro (‹Esc› ‹Ctrl-o›) non apre un'altra lezione mentre se ne scrive una
    local lezione = require('dattilo.lezione')
    local function qui(fn) return function() if lezione.s == s and s.passo == 'fine' then fn() end end end
    local function mappa(tasti, fn)
      for _, k in ipairs(tasti) do vim.keymap.set('n', k, qui(fn), { buffer = buf, nowait = true, silent = true }) end
    end
    mappa({ '<CR>', 'l' }, function() M.prossima() end)
    mappa({ 'r' }, function() M.rifai() end)
    mappa({ 'q' }, function() M.elenco() end)
  end
  guida.mostra(T.f('titoli.fatto', L.breve), adesso, T.comandi_fatto)
end

-- Il riepilogo di una lezione fatta (lo chiama lezione.fine con la guida accesa): registra il
-- risultato, mostra i numeri e dice cosa fa ‹Invio›.
function M.fatto(s)
  if not (acceso and canale) then return false end
  local L = s.L
  local ris = s.risultato or { wpm = 0, precisione = 100, tempo_ms = 0 }
  require('dattilo.progressi').registra(L.pacchetto .. '/' .. L.id,
    { wpm = ris.wpm, precisione = ris.precisione, tempo_ms = ris.tempo_ms, tasti_modifica = s.tasti_modifica })
  M.bozza_togli(L.id)
  local stato = require('dattilo.stato')
  stato.file, stato.metriche = 'lezione ' .. L.numero, function() return { 'completata' } end
  aggiorna_dati() -- la lezione appena fatta è già fra le fatte: la coda di adesso è quella giusta
  local extra = destra_fornitore()
  if extra ~= '' then stato.destra = (stato.destra or '') .. extra end
  vim.cmd('redrawtabline')
  disegna_fatto(s)
  return true
end

-- ‹Invio› nel riepilogo: la prossima, o l'attesa se non c'è niente da aprire.
function M.prossima()
  if not canale then return end
  fresca()
  local p = da_aprire().prossima
  if p then M.apri(p) else M.attesa() end
end

-- `:salta`: la lezione resta segnata come saltata (se non è fatta) e si apre la prossima.
function M.salta()
  local id = corrente()
  if not (canale and id) then return end
  if not canale.fatte[id] then M.segna_saltata(id) end
  M.prossima()
end

-- `:ultima`: la lezione non fatta più recente. Se non c'è, o è già quella, lo dice in «Controllo».
function M.ultima()
  if not canale then return end
  fresca()
  local id = canale.coda.ultima
  if not id then return guida.avviso(T.ultima_niente) end
  if id == corrente() then return guida.avviso(T.ultima_gia) end
  M.apri(id)
end

-- ‹r› nel riepilogo: la stessa lezione da capo.
function M.rifai()
  local id = corrente()
  if id then M.apri(id) end
end

---------------------------------------------------------------- l'elenco

local ns_scelta = vim.api.nvim_create_namespace('dattilo_elenco')

-- L'elenco: una riga per lezione, col segno (✓ fatta, ▸ da fare), il titolo, e a destra «nuova» o
-- «saltata». «Nuova» è come nel contratto per chi non ha una lezione aperta: non fatta e non saltata.
-- La riga scelta ha lo sfondo (non il segno ▸, che è delle lezioni da fare); ‹Invio› apre quella
-- dov'è il cursore, anche dopo un clic.
function M.elenco()
  lascia()
  local schermo, stato, ui = require('dattilo.schermo'), require('dattilo.stato'), require('dattilo.ui')
  require('dattilo.lezione').chiudi()
  require('dattilo.dojo').chiudi()
  ui.chiudi_tip()
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'home', 'Rifallo tu', '', 'elenco', nil
  vim.cmd('redrawtabline')
  require('dattilo.pacchetti').dimentica()
  fresca()
  local P = pacchetto()
  local lezioni = {}
  for _, L in ipairs(P and P.lezioni or {}) do
    if lezione_valida(L.id) then lezioni[#lezioni + 1] = L end
  end
  local fatte = canale and canale.fatte or {}
  local saltate = canale and canale.saltate.set or {}
  local largo = 0
  for _, L in ipairs(lezioni) do largo = math.max(largo, vim.fn.strdisplaywidth(L.titolo or L.id)) end
  largo = math.min(largo, math.max(10, vim.o.columns - 24))
  local function colonna(t)
    while vim.fn.strdisplaywidth(t) > largo do t = vim.fn.strcharpart(t, 0, vim.fn.strchars(t) - 1) end
    return t .. string.rep(' ', largo - vim.fn.strdisplaywidth(t))
  end
  local righe = { {} }
  for _, L in ipairs(lezioni) do
    local fatta = fatte[L.id]
    local marca = fatta and '' or (saltate[L.id] and T.elenco_saltata or T.elenco_nuova)
    righe[#righe + 1] = {
      { '   ' },
      { (fatta and '✓' or '▸') .. ' ', fatta and 'DattiloVerde' or 'DattiloAccento' },
      { colonna(L.titolo or L.id), fatta and 'DattiloMuto' or 'DattiloForte' },
      { fatta and '' or ('  ' .. marca), saltate[L.id] and 'DattiloGiallo' or 'DattiloCiano' },
    }
  end
  local n = #lezioni
  local buf = schermo.buffer('elenco')
  schermo.scrivi(buf, righe)
  schermo.mostra(buf, 'testo')
  local function riga_scelta() return math.max(2, math.min(n + 1, vim.api.nvim_win_get_cursor(0)[1])) end
  local function pinta()
    vim.api.nvim_buf_clear_namespace(buf, ns_scelta, 0, -1)
    if n > 0 then vim.api.nvim_buf_set_extmark(buf, ns_scelta, riga_scelta() - 1, 0, { line_hl_group = 'DattiloSelezione' }) end
  end
  local function sposta(d)
    if n > 0 then vim.api.nvim_win_set_cursor(0, { math.max(2, math.min(n + 1, riga_scelta() + d)), 0 }) end
    pinta()
  end
  local function mappa(tasti, fn)
    for _, k in ipairs(tasti) do vim.keymap.set('n', k, fn, { buffer = buf, nowait = true, silent = true }) end
  end
  mappa({ 'j', '<Down>' }, function() sposta(vim.v.count1) end)
  mappa({ 'k', '<Up>' }, function() sposta(-vim.v.count1) end)
  mappa({ '<CR>' }, function()
    -- l'elenco rimasto in giro (‹Ctrl-o›) non apre una lezione mentre se ne scrive un'altra
    if stato.schermo ~= 'home' then return end
    local L = lezioni[riga_scelta() - 1]
    if L then M.apri(L.id) end
  end)
  vim.api.nvim_create_autocmd('CursorMoved', { group = vim.api.nvim_create_augroup('dattilo_elenco', { clear = true }), buffer = buf, callback = pinta })
  vim.api.nvim_win_set_cursor(0, { math.min(2, #righe), 0 })
  pinta()
  guida.mostra(T.f('titoli.elenco'), n > 0 and T.elenco or T.elenco_vuoto, T.comandi_elenco)
  barra_subito()
end

return M
