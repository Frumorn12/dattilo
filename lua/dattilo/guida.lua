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
local ultimo = nil     -- l'ultimo riquadro disegnato, com'è a schermo (anche nel posto sbagliato)
local base = nil       -- l'ultimo riquadro della schermata, prima del posto sbagliato
local mostrata = nil   -- l'ultima schermata di vivo (mostra): { titolo, adesso, cmd, altre }
-- L'ultimo esito, per la sezione «Controllo»: { testo, righe?, ko?, riga?, errore? }. `righe` è il
-- testo di Batti (o di esegui) quando l'esito è arrivato: se il testo cambia l'esito non vale più.
-- `ko` è il controllo che non passa in Batti: la frase sta in «Adesso», con la riga d'errore di node
-- (`riga`), e il titolo è IL CONTROLLO NON PASSA. `errore` è lo stesso fuori da Batti.
local controllo = nil
local more_prima = nil
-- [buf] = { righe, seq }: il testo all'ultima uscita dalla scrittura o all'ultimo cambio fatto da
-- dattilo, e il punto della storia degli annullamenti (undotree) in quel momento
local giuste = {}

local function lezione() return require('dattilo.lezione') end

---------------------------------------------------------------- I posti sbagliati (3.4)

local SINONIMI_Q = { q = true, ['q!'] = true, wq = true, x = true } -- tutti DattiloEsci (init.lua)
-- «Esci da tutto»: chiudono dattilo del tutto, con del testo non salvato e con un terminale acceso (DattiloEsciTutto)
local SINONIMI_QA = {}
for _, nome in ipairs({ 'qa', 'qall', 'quitall', 'wqa', 'wqall', 'xa', 'xall' }) do SINONIMI_QA[nome] = true end
-- Con `!` l'abbreviazione scatta appena si preme il `!`, e la riga dei comandi diventa questa
-- (anche :salta, :ultima ed :elenco: scritti con uno spazio dopo, l'abbreviazione è già scattata)
local ESPANSI = { DattiloEsci = 'q', ['DattiloEsci!'] = 'q', DattiloEsciTutto = 'qa', ['DattiloEsciTutto!'] = 'qa',
  DattiloSalta = 'salta', DattiloUltima = 'ultima', DattiloElenco = 'elenco' }
local COMANDO_DI = { salta = 'DattiloSalta', ultima = 'DattiloUltima', elenco = 'DattiloElenco', ['e!'] = 'DattiloRicomincia' }
local SELEZIONE = { v = true, V = true, ['\22'] = true, s = true, S = true, ['\19'] = true }

-- La finestra `win` è «in più» (3.4, riga 12): non è la principale della lezione, né il riquadro,
-- né l'OBIETTIVO, né una galleggiante.
local function e_in_piu(win)
  local principale = require('dattilo.schermo').principale
  if not principale or not vim.api.nvim_win_is_valid(principale) then return false end
  if not vim.api.nvim_win_is_valid(win) or win == principale then return false end
  if vim.api.nvim_win_get_config(win).relative ~= '' then return false end
  if ui.tip_aperto() and win == ui.finestra_tip() then return false end
  local s = lezione().s
  if s and s.e and s.e.fin == win then return false end
  return true
end

-- Dove sta il cursore rispetto alla lezione: 'in_piu' (in una finestra in più), 'altro' (nella
-- finestra della lezione, ma c'è un altro buffer: Ctrl-^, :e, :bn, un terminale…; il secondo valore
-- è il buffer che ci dovrebbe essere), 'con_altre' (nella finestra della lezione, col buffer giusto,
-- ma con altre finestre aperte: riga 12b), o nil. Il buffer giusto è l'ultimo messo da
-- schermo.mostra: il codice in Batti, il testo della schermata altrove.
local function posizione()
  local schermo = require('dattilo.schermo')
  local principale = schermo.principale
  if not principale or not vim.api.nvim_win_is_valid(principale) then return nil end
  local win = vim.api.nvim_get_current_win()
  if e_in_piu(win) then return 'in_piu' end
  local atteso = schermo.mostrato
  if win == principale and atteso and vim.api.nvim_buf_is_valid(atteso)
    and vim.api.nvim_win_get_buf(win) ~= atteso then
    return 'altro', atteso
  end
  if win == principale then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if e_in_piu(w) then return 'con_altre' end
    end
  end
  return nil
end

-- «Comandi» di un posto sbagliato che ha una sola uscita: in un altro buffer il ritorno a :b e il numero
-- del codice, in una finestra in più :q. La sezione della schermata offrirebbe ‹:w›, che lì scrive il file
-- sbagliato o dà un errore, e ‹:q›, che lascia la lezione. Vale in ogni momento in quel posto, anche
-- mentre si scrive il comando (la riga dei comandi, la finestra dei comandi): «Comandi» e «Adesso»
-- non si contraddicono. nil fuori da quei posti.
local function comandi_luogo()
  local pos, atteso = posizione()
  if pos == 'altro' then return T.f('comandi_altro', atteso) end
  if pos == 'in_piu' then return T.comandi_finestra end
  return nil
end

-- I comandi che valgono qui: quelli scritti in «Comandi» e in «Adesso» come ‹:nome› che esistono
-- davvero adesso (:salta, :ultima ed :elenco arrivano col compito 8), e :q, che vale sempre. In un
-- altro buffer vale :b e il numero del codice (è quello che dice la frase); in un altro buffer e in
-- una finestra in più :w e :e! non servono (scriverebbero o rifarebbero il buffer sbagliato).
local function comandi_validi(testo_comandi, pos, atteso)
  local v = { q = true }
  for nome in (testo_comandi or ''):gmatch('‹:([^›]+)›') do
    local cmd = COMANDO_DI[nome]
    if nome == 'w' or nome == 'q' or (cmd and vim.fn.exists(':' .. cmd) == 2) then v[nome] = true end
  end
  if pos == 'altro' or pos == 'in_piu' then v.w, v['e!'] = nil, nil end
  if pos == 'altro' then v['b' .. atteso] = true end
  return v
end

-- Nella lezione c'è del testo scritto: lasciarla lo perde (la bozza arriva col compito 9), e la
-- frase di :q lo dice prima dell'Invio.
local function ha_scritto()
  local s = lezione().s
  if not s or not (s.passo == 'batti' or s.passo == 'modifica' or s.passo == 'rompi' or s.passo == 'esegui') then return false end
  if not s.buf or not vim.api.nvim_buf_is_valid(s.buf) then return false end
  for _, l in ipairs(vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)) do
    if l ~= '' then return true end
  end
  return false
end

-- Cosa fa il comando noto `nome`, dove si è adesso (3.4, riga 3): :q chiude la finestra in più
-- se il cursore è lì, chiude dattilo nell'elenco, lascia la lezione altrove. :qa chiude dattilo.
local function spiega(nome, pos)
  if SINONIMI_Q[nome] then
    if pos == 'in_piu' then return T.spiega_comando.q_finestra end
    if require('dattilo.stato').schermo == 'home' then return T.spiega_comando.q_esci end
    return ha_scritto() and T.spiega_comando.q_scritto or T.spiega_comando.q
  end
  if SINONIMI_QA[nome] then return ha_scritto() and T.spiega_comando.qa_scritto or T.spiega_comando.qa end
  if nome:match('^b%d+$') then return T.spiega_comando.b end
  return T.spiega_comando[nome]
end

local function posto_di(nome, ...)
  local titolo, testo = T.posto(nome, ...)
  return { titolo = titolo, testo = testo, comandi = comandi_luogo() }
end

-- I tasti che mancano a `riga` per scrivere il comando `nome`: «‹b› ‹4›: finisci di scrivere :b4; poi ‹Invio›: …».
local function finisci(nome, riga, pos)
  local tasti = {}
  for ch in nome:sub(#riga + 1):gmatch('.') do tasti[#tasti + 1] = '‹' .. ch .. '›' end
  return T.f('cmd_finisci', table.concat(tasti, ' '), nome, spiega(nome, pos))
end

-- Dalla spiegazione :q, :qa, :salta e :ultima lasciano la lezione, e la lezione si segna come fatta solo al
-- riepilogo (lezione.fine): uscendo da qui non conta (:salta la segna «saltata»), e la frase lo dice prima
-- dell'Invio. In una finestra in più :q chiude solo quella (nessuna frase), ma :qa chiude dattilo lo stesso.
local function perde_il_fatto(nome, pos)
  local s = lezione().s
  if not s or s.passo ~= 'spiegazione' then return false end
  if SINONIMI_QA[nome] then return true end -- :qa chiude dattilo anche da una finestra in più
  if nome == 'salta' or nome == 'ultima' then return true end -- aprono un'altra lezione
  return (SINONIMI_Q[nome] and pos ~= 'in_piu' and require('dattilo.stato').schermo ~= 'home') or false
end

-- La frase di `perde_il_fatto`. «‹Esc›: annulli e resti qui; poi ‹Invio›: vai al riepilogo» vale solo con
-- il cursore nella finestra della spiegazione. Fuori (un altro file, un terminale, l'aiuto, una divisione)
-- ‹Esc› lascia il cursore dov'è e ‹Invio› non porta al riepilogo: prima si torna al codice, e la frase
-- dice come (in un altro file con :b e il numero del codice, in una finestra in più con :q).
local function frase_perde_il_fatto(pos)
  if pos == 'altro' then return 'cmd_noto_spiegazione_altro' end
  if pos == 'in_piu' then return 'cmd_noto_spiegazione_finestra' end
  return 'cmd_noto_spiegazione'
end

-- La riga dei comandi (3.4, righe 2-4): vuota, un comando che vale qui, a metà di uno, o un altro.
local function nella_riga_dei_comandi(riga, testo_comandi, pos, atteso)
  local validi = comandi_validi(testo_comandi, pos, atteso)
  riga = vim.trim(riga)
  riga = ESPANSI[riga] or riga
  riga = (riga:gsub('^b%s+(%d+)$', 'b%1')) -- :b 4 vale come :b4
  if riga == '' then
    -- in un posto sbagliato la strada è quella che la frase del posto ha indicato: i tasti che mancano al comando di ritorno
    local via = (pos == 'altro' and 'b' .. atteso) or (pos == 'in_piu' and 'q') or nil
    if via then return posto_di('cmd_vuota_ritorno', finisci(via, '', pos)) end
    return posto_di(validi.w and 'cmd_vuota' or 'cmd_vuota_testo')
  end
  if riga == 'w' and validi.w then return { titolo = T.posti.cmd_vuota.titolo, testo = T.cmd_w } end
  if SINONIMI_Q[riga] or SINONIMI_QA[riga] or (validi[riga] and riga ~= 'w') then
    if perde_il_fatto(riga, pos) then return posto_di(frase_perde_il_fatto(pos), riga, spiega(riga, pos), atteso) end
    return posto_di('cmd_noto', riga, spiega(riga, pos))
  end
  -- a metà di un comando che vale qui: le lettere che mancano (mai ‹Esc› per primo, che lo cancellerebbe)
  local finire = {}
  for nome in pairs(validi) do
    if #nome > #riga and nome:sub(1, #riga) == riga then finire[#finire + 1] = nome end
  end
  table.sort(finire)
  if #finire > 0 then
    local parti = {}
    for _, nome in ipairs(finire) do parti[#parti + 1] = finisci(nome, riga, pos) end
    return posto_di('cmd_parziale', riga, table.concat(parti, ' '))
  end
  return posto_di('cmd_ignoto', riga)
end

-- Il posto sbagliato in cui si è adesso, o nil. L'ordine conta: la finestra dei comandi, Ex (dove
-- anche getcmdtype() dà ':'), la riga dei comandi, la registrazione (in NORMAL e mentre si
-- scrive; negli altri modi prima si esce da quelli), le frecce, il terminale, la finestra in più o
-- un altro buffer nella finestra della lezione, poi il modo. `testo_comandi` sono le sezioni
-- «Comandi» e «Adesso» della schermata, che dicono quali comandi valgono.
local function posto_per(modo, testo_comandi)
  modo = modo or vim.api.nvim_get_mode().mode
  if vim.fn.getcmdwintype() ~= '' then return posto_di('cmdwin') end
  if modo == 'cv' or modo == 'ce' then return posto_di('ex') end
  local pos, atteso = posizione()
  local tipo = vim.fn.getcmdtype()
  if tipo == ':' then return nella_riga_dei_comandi(vim.fn.getcmdline(), testo_comandi, pos, atteso) end
  if tipo == '/' or tipo == '?' then return posto_di('ricerca') end
  if tipo ~= '' then return posto_di('sconosciuto', modo) end
  local m1 = modo:sub(1, 1)
  local reg = vim.fn.reg_recording()
  if reg ~= '' then
    if modo == 'n' then return posto_di('registra_n', reg) end
    if m1 == 'i' or m1 == 'R' then return posto_di('registra_i', reg) end
  end
  local s = lezione().s
  -- le frecce valgono solo nel codice: la mappa è di quel buffer
  if s and s.passo == 'batti' and s.frecce and vim.api.nvim_get_current_buf() == s.buf then
    if m1 == 'i' then return posto_di('frecce') end
    if modo == 'n' then return posto_di('frecce_n') end
  end
  if modo == 'nt' or modo == 'ntT' then
    -- il terminale in una finestra in più si chiude come ogni finestra in più; nella finestra della
    -- lezione il ritorno è :b e il numero del codice (‹Ctrl-^› con due terminali rimbalza)
    if pos == 'in_piu' then return posto_di('divisa') end
    if pos == 'altro' then return posto_di('terminale', atteso) end
    return posto_di('sconosciuto', modo)
  end
  -- fuori dal codice della lezione: una finestra in più (3.4, riga 12), un altro buffer nella
  -- finestra della lezione, o la finestra della lezione con altre aperte (riga 12b). In INSERT ‹:›
  -- è una lettera: la frase comincia da ‹Esc›.
  if pos == 'in_piu' and (modo == 'n' or m1 == 'i') then
    if m1 == 'i' then return posto_di('divisa_i') end
    return posto_di(vim.bo.buftype == 'help' and 'aiuto' or 'divisa')
  end
  if pos == 'altro' and (modo == 'n' or m1 == 'i') then
    return posto_di(m1 == 'i' and 'altro_buffer_i' or 'altro_buffer', atteso)
  end
  -- il cursore è nella finestra della lezione, ma un'altra finestra è aperta (3.4, riga 12b)
  if pos == 'con_altre' and modo == 'n' then return posto_di('divisa_principale') end
  -- NORMAL e INSERT (anche col completamento, ic e ix) non sono posti sbagliati; «Premi INVIO»
  -- (r…) e un comando esterno (!) non si possono ridisegnare
  if modo == 'n' or m1 == 'i' or m1 == 'r' or modo == '!' or m1 == 'c' then return nil end
  if SELEZIONE[m1] then return posto_di('visuale') end
  if m1 == 'R' then return posto_di('replace') end
  if modo:sub(1, 2) == 'no' then return posto_di('operatore', vim.v.operator) end
  if modo:sub(1, 2) == 'ni' then return posto_di('ctrl_o') end
  return posto_di('sconosciuto', modo)
end

-- Il posto sbagliato in cui si è adesso (3.4): nil o { titolo, testo }. `modo` (facoltativo, per
-- le prove) prende il posto di nvim_get_mode().
function M.posto(modo)
  local cmd = {}
  for _, sz in ipairs(base and base.sezioni or {}) do
    if sz.etichetta == 'Comandi' or sz.etichetta == 'Adesso' then cmd[#cmd + 1] = sz.testo end
  end
  return posto_per(modo, table.concat(cmd, ' '))
end

-- Una parola più larga della riga (un nome lunghissimo nell'errore di node, un percorso) uscirebbe
-- dal bordo: si spezza in pezzi che ci stanno. I tasti ‹…› sono corti e non si toccano.
local function spezza_lunghe(testo, largo)
  if largo < 2 then return testo end
  return (testo:gsub('%S+', function(p)
    if p:find('‹', 1, true) or vim.fn.strdisplaywidth(p) <= largo then return nil end
    local pezzi, n, i = {}, vim.fn.strchars(p), 0
    while i < n do
      local k = math.min(largo, n - i)
      while k > 1 and vim.fn.strdisplaywidth(vim.fn.strcharpart(p, i, k)) > largo do k = k - 1 end
      pezzi[#pezzi + 1] = vim.fn.strcharpart(p, i, k)
      i = i + k
    end
    return table.concat(pezzi, ' ')
  end))
end

-- Disegna il riquadro e lo ricorda. Conta le righe vere di ogni sezione e alza il riquadro fino
-- a ALTO righe; se non basta, toglie righe alle sezioni meno importanti (Blocco, Fin qui, Riga,
-- poi Controllo), mai ad Adesso e Comandi.
local function disegna_riquadro(titolo, originali, tipo)
  local largo = vim.o.columns - 4 - M.ETICHETTA -- come ui.sezioni: i bordi e la colonna delle etichette
  local sezioni = {}
  for i, sz in ipairs(originali) do
    sezioni[i] = sz.testo and vim.tbl_extend('force', sz, { testo = spezza_lunghe(sz.testo, largo) }) or sz
  end
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
  ultimo = { titolo = titolo, sezioni = originali, tipo = tipo }
  ui.tip(titolo, per_ui, tipo, M.ETICHETTA)
end

-- L'ultimo errore della guida che non si è potuto nemmeno disegnare nel riquadro (per le prove).
local errore_disegno = nil
function M.errore_disegno() return errore_disegno end

-- Disegna la schermata. In un posto sbagliato (3.4) il titolo e «Adesso» sono quelli del posto e
-- il bordo è rosso; le altre sezioni restano. La schermata senza il posto resta in `base`: quando
-- si torna, il riquadro torna com'era.
local function disegna(titolo, sezioni, tipo)
  base = { titolo = titolo, sezioni = sezioni, tipo = tipo }
  local ok, p = pcall(M.posto)
  if not ok then errore_disegno, p = tostring(p), nil end
  if not p then return disegna_riquadro(titolo, sezioni, tipo) end
  local sez = {}
  for i, sz in ipairs(sezioni) do
    if sz.etichetta == 'Adesso' then sez[i] = vim.tbl_extend('force', sz, { testo = p.testo })
    elseif sz.etichetta == 'Comandi' and p.comandi then sez[i] = vim.tbl_extend('force', sz, { testo = p.comandi })
    else sez[i] = sz end
  end
  disegna_riquadro(p.titolo, sez, 'rosso')
end

-- Le sezioni `sezioni` con «Controllo» che dice `testo` (subito dopo «Adesso»), o senza, se testo è nil.
local function con_controllo(sezioni, testo)
  local sez = {}
  for _, sz in ipairs(sezioni or {}) do
    if sz.etichetta ~= 'Controllo' then sez[#sez + 1] = sz end
    if sz.etichetta == 'Adesso' and testo then sez[#sez + 1] = { etichetta = 'Controllo', testo = testo, priorita = 8 } end
  end
  if #sez == 0 and testo then sez[1] = { etichetta = 'Controllo', testo = testo, priorita = 8 } end
  return sez
end

-- Il riquadro della schermata di prima, con «Controllo» di adesso e il posto sbagliato di adesso:
-- per i passi che la guida non disegna ancora da sé (modifica e rompi arrivano col tempo B) e
-- quando il buffer della lezione non si vede, così un esito non sparisce mai e il riquadro non resta vecchio.
local function disegna_di_nuovo()
  if not base then return end
  disegna(base.titolo, con_controllo(base.sezioni, controllo and controllo.testo), base.tipo)
end

-- Un errore dentro la guida non rompe la lezione e non arriva mai alla riga dei messaggi (G5): va
-- in «Controllo» come «Errore di dattilo: …». Il riquadro si rifà con quello che c'era, senza
-- passare dal codice che ha sbagliato. Se fallisce anche questo, l'errore resta in errore_disegno.
local function errore(e)
  local msg = vim.trim((tostring(e):gsub('^[^\n]-:%d+: ', ''):gsub('%s+', ' ')))
  local s = lezione().s
  local righe = nil
  if s and s.passo == 'batti' and s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  end
  controllo = { testo = T.f('errore_dattilo', msg), righe = righe }
  local ok, e2 = pcall(function()
    local sez = con_controllo(base and base.sezioni, controllo.testo)
    disegna_riquadro(base and base.titolo or 'DATTILO', sez, base and base.tipo)
  end)
  if not ok then errore_disegno = tostring(e) .. ' | nel disegno: ' .. tostring(e2) end
end

local function proteggi(fn)
  return function(...)
    local r = vim.F.pack_len(pcall(fn, ...))
    if not r[1] then errore(r[2]) return end
    return unpack(r, 2, r.n)
  end
end

-- Esegue fn(...) protetta, come le funzioni della guida: un errore va nel riquadro, mai nella riga
-- dei messaggi. La usa lezione.lua per il salvataggio (BufWritePost) quando la guida è accesa.
function M.protetta(fn, ...) return proteggi(fn)(...) end

local ridisegna -- più sotto: rifà il riquadro della schermata di adesso

-- Ricalcola il riquadro appena Neovim torna libero, e lo ridisegna subito: nella riga dei comandi,
-- con un operatore in attesa o in Ex Neovim non ridisegna lo schermo da solo. Gli eventi che
-- arrivano insieme fanno un giro solo. Davanti a «Premi INVIO» (r…) il riquadro si aggiorna ma lo
-- schermo no: ridisegnare cancellerebbe quello che Neovim sta mostrando, e dopo il tasto lo
-- ridisegna lui.
local in_coda = false
local function ricalcola()
  if in_coda then return end
  in_coda = true
  vim.schedule(function()
    in_coda = false
    if not f then return end
    proteggi(ridisegna)()
    local m = vim.api.nvim_get_mode().mode
    if not m:match('^r') and m ~= '!' then pcall(vim.cmd.redraw) end
  end)
end

-- Un avviso di dattilo in «Controllo», senza cambiare il titolo: vale per il testo di adesso (se il
-- testo di Batti cambia, sparisce) e per la schermata di adesso.
local function avviso(testo)
  local s = lezione().s
  local righe = nil
  if s and (s.passo == 'batti' or s.passo == 'esegui') and s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  end
  controllo = { testo = testo, righe = righe }
  ridisegna()
end

-- ‹Ctrl-z› (G9): in Neovim mette in pausa il programma, e nel pannello di «Rifallo tu» non c'è una
-- shell che lo riprenda. Qui scrive in «Controllo» perché è spento, e non cambia il titolo.
local function ctrl_z() avviso(T.ctrl_z) end

-- fornitore = { comandi = fun(schermata), fine = fun(s), su_schermata = fun(s), destra = fun() }
function M.accendi(fornitore)
  f = fornitore
  more_prima = vim.o.more
  vim.o.more = false
  ultimo, base, mostrata, controllo = nil, nil, nil, nil
  lezione().guida = M
  giuste = {}
  vim.keymap.set({ 'n', 'i', 'v' }, '<C-z>', proteggi(ctrl_z), { desc = 'dattilo: Ctrl-z non mette in pausa (G9)' })
  -- anche con un operatore in attesa (d, poi Ctrl-z) Neovim si metterebbe in pausa (visto in tmux,
  -- da una shell): qui ‹Esc› annulla l'operatore, e poi la frase
  vim.keymap.set('o', '<C-z>', function() vim.schedule(proteggi(ctrl_z)) return '<Esc>' end,
    { expr = true, desc = 'dattilo: Ctrl-z non mette in pausa (G9)' })
  -- ‹:qa› e gli altri «esci da tutto» chiudono dattilo: con del testo non salvato o un terminale
  -- acceso Vim darebbe un errore su più righe («Premi INVIO»). Il testo lo dice la frase prima dell'Invio.
  vim.api.nvim_create_user_command('DattiloEsciTutto', function() vim.cmd('qa!') end,
    { bang = true, desc = 'dattilo: chiude dattilo del tutto' })
  -- con degli spazi davanti (`: qa`) la guida legge lo stesso comando: anche l'abbreviazione, qui e per
  -- quelle di sempre (`: q`), altrimenti Vim farebbe il suo `:q` o `:qa` mentre la guida promette un'altra cosa
  for nome in pairs(SINONIMI_QA) do
    vim.cmd(string.format("cnoreabbrev <expr> %s (getcmdtype() ==# ':' && trim(getcmdline()) ==# '%s') ? 'DattiloEsciTutto' : '%s'", nome, nome, nome))
  end
  require('dattilo').abbreviazioni(true)
  local g = vim.api.nvim_create_augroup('dattilo_guida', { clear = true })
  -- i posti sbagliati (3.4): ogni evento che può portare dentro o fuori da uno ricalcola il riquadro
  -- (WinNew, WinEnter e WinClosed per la finestra in più, riga 12: aprirla non cambia il modo;
  -- BufEnter e BufWinEnter per un altro buffer nella finestra della lezione: ‹Ctrl-^›, :e, :bn,
  -- ‹Ctrl-o› non cambiano né il modo né il cursore)
  vim.api.nvim_create_autocmd({ 'ModeChanged', 'RecordingEnter', 'RecordingLeave', 'CmdlineEnter', 'CmdlineChanged',
    'CmdlineLeave', 'CmdwinEnter', 'CmdwinLeave', 'TextChanged', 'WinNew', 'WinEnter', 'WinClosed',
    'BufEnter', 'BufWinEnter' },
    { group = g, callback = function() ricalcola() end })
  -- la finestra ha cambiato misura: le righe di ogni sezione vanno ricontate
  vim.api.nvim_create_autocmd('VimResized', { group = g, callback = proteggi(function()
    if base and ui.tip_aperto() then disegna(base.titolo, base.sezioni, base.tipo) end
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
  ultimo, base, mostrata, controllo, giuste = nil, nil, nil, nil, {}
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_guida')
  for _, m in ipairs({ 'n', 'i', 'v', 'o' }) do pcall(vim.keymap.del, m, '<C-z>') end
  pcall(vim.api.nvim_del_user_command, 'DattiloEsciTutto')
  for nome in pairs(SINONIMI_QA) do pcall(vim.cmd, 'cunabbrev ' .. nome) end
  require('dattilo').abbreviazioni()
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

-- «; E maiuscola», «; O e K maiuscole» o niente: le lettere maiuscole fra i tasti, da dire (come la G).
local function nota_maiuscole(lettere)
  if lettere[2] == lettere[1] then lettere[2] = nil end
  if #lettere == 0 then return '' end
  if #lettere == 1 then return T.f('maiuscola', lettere[1]) end
  return T.f('maiuscole', lettere[1], lettere[2])
end

-- Come si scrive in Vim un carattere che non è sulla tastiera (G11): il digramma (‹Ctrl-k› e due
-- tasti), oppure ‹Ctrl-v› ‹u› e quattro cifre, ‹Ctrl-v› ‹U› e otto sopra U+FFFF. nil se c'è il tasto.
-- Il secondo valore è la nota sulle maiuscole (le cifre esadecimali vanno anche minuscole).
function M.carattere(ch)
  if not ch or ch == '' or #ch == 1 or TASTIERA[ch] then return nil end
  if not digrammi then
    digrammi = {}
    for _, d in ipairs(vim.fn.digraph_getlist(true)) do
      if d[1]:match('^[!-~][!-~]$') and not digrammi[d[2]] then digrammi[d[2]] = d[1] end
    end
  end
  local coppia = digrammi[ch]
  if coppia then
    local a, b = coppia:sub(1, 1), coppia:sub(2, 2)
    local lettere = {}
    for _, x in ipairs({ a, b }) do if x:match('%u') then lettere[#lettere + 1] = x end end
    return '‹Ctrl-k› ‹' .. a .. '› ‹' .. b .. '›', nota_maiuscole(lettere)
  end
  local n = vim.fn.char2nr(ch)
  local tasti = { '‹Ctrl-v›', n > 0xFFFF and '‹U›' or '‹u›' }
  for cifra in string.format(n > 0xFFFF and '%08X' or '%04X', n):gmatch('.') do tasti[#tasti + 1] = '‹' .. cifra .. '›' end
  return table.concat(tasti, ' '), nota_maiuscole(n > 0xFFFF and { 'U' } or {})
end

local function volte(n) return n == 1 and T.una_volta or T.f('volte', n) end

-- «La riga k non è finita», o, se la riga k è intera ed è solo l'ultima scritta, «si va avanti
-- dalla fine della riga k». modo: 'i' o 'n'.
local function indietro(modo, k, righe, codice)
  return T.f((righe[k] == codice[k] and 'batti_continua_' or 'batti_indietro_') .. modo, k, k, k)
end

-- La frase di «Adesso» in Batti (3.3, nell'ordine di «Cambiato costruendo»): vale il primo caso
-- che si applica, dall'alto. x = { codice, righe, r, c, modo, frecce?, cambiato?, annullato? };
-- c è la colonna in byte, da 0. Dove si scosta dalla prima tabella del progetto è perché lì la
-- persona perderebbe lavoro o resterebbe ferma:
-- - in INSERT, una riga spezzata a metà di quello che si era scritto (il resto è sceso, col
--   rientro, nella riga dopo) si riunisce coi ‹Backspace› contati, prima di tutto il resto: ‹Fine›
--   e poi ‹Backspace› cancellerebbero il testo buono sceso giù;
-- - in INSERT ‹Fine› viene prima del rosso: col rosso a destra del cursore ‹Backspace›
--   cancellerebbe le lettere giuste a sinistra;
-- - in INSERT la riga da finire può stare anche sotto il cursore (k > r): ‹Invio› aprirebbe una
--   riga in più e tutto sotto diventerebbe rosso; a metà di una riga intera si va subito lì;
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
    -- un a capo a metà di quello che si era scritto: il cursore è nel rientro della riga dopo
    -- quella da finire, e quello che ha a destra, rimesso in fondo alla riga sopra, è ancora
    -- l'inizio giusto del grigio. Ogni ‹Backspace› toglie fino a 4 spazi (softtabstop), l'ultimo riunisce.
    local destra = riga:sub(c + 1)
    if k == r - 1 and destra ~= '' and riga:sub(1, c):match('^ *$')
      and vim.startswith(codice[k] or '', righe[k] .. destra) then
      return T.f('batti_spezzata_meta', k, volte(math.ceil(c / 4) + 1), k)
    end
    if c < #riga then
      -- a metà di una riga intera, con un'altra da finire: subito la frase che porta lì
      if riga == grigio and k ~= r then return indietro('i', k, righe, codice) end
      return T.batti_cursore
    end
    if rosso[r] then
      local da = rosso[r]
      local scritto, atteso = riga:sub(da + 1, da + 1), grigio:sub(da + 1, da + 1)
      if atteso ~= '' and scritto ~= atteso and scritto == atteso:upper() then return T.batti_maiuscole end
      return T.batti_errore
    end
    if k == r - 1 and riga:match('^ *$') then
      return T.f('batti_spezzata', k, volte(math.ceil(#riga / 4) + 1), k)
    end
    if k ~= r then return indietro('i', k, righe, codice) end
    local prossimo = grigio:sub(#riga + 1):match('^[%z\1-\127\194-\244][\128-\191]*')
    local tasti, nota = M.carattere(prossimo)
    if tasti then return T.f('batti_carattere', prossimo, tasti, nota) end
    if riga == grigio and codice[r + 1] == '' then return T.batti_riga_vuota end
    if riga == grigio then return T.batti_fine_riga end
    return T.batti_scrivi
  end

  -- NORMAL. Gli altri modi (VISUAL, REPLACE, la riga dei comandi…) sono posti sbagliati (3.4): nel
  -- riquadro il titolo e «Adesso» li dà posto(), che vale prima di questa frase.
  if x.annullato then return T.batti_annullato end
  if x.cambiato then return T.batti_cambiato end
  if #righe == 1 and righe[1] == '' then return T.batti_vuoto end
  if x.frecce then return T.frecce_n end
  if esito.finito then return T.batti_finito_n end
  if rosso[r] then return T.batti_rosso_qui end
  if prima_rossa then return T.f('batti_rosso_n', prima_rossa, prima_rossa, prima_rossa) end
  if k ~= r then return indietro('n', k, righe, codice) end
  return T.batti_riprendi
end

local function seq(buf) return vim.fn.undotree(buf).seq_cur end

-- Il testo di adesso è quello «giusto»: dopo un cambio fatto da dattilo (la bozza rimessa) o
-- all'uscita dalla scrittura. In NORMAL un testo diverso da questo è un testo cambiato.
function M.cambio_voluto(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  giuste[buf] = { righe = vim.api.nvim_buf_get_lines(buf, 0, -1, false), seq = seq(buf) }
end

local disegna_testo

-- Il riquadro di Batti: titolo, «Adesso», «Controllo», le sezioni di tip_batti e «Comandi».
-- Nel passo esegui, che ha lo stesso buffer, il riquadro del passo (cambia col modo). Rende vero
-- se ha disegnato: non lo fa se il buffer della lezione non si vede.
function M.tip(s)
  if s.passo == 'esegui' then return disegna_testo(s) end
  if s.passo ~= 'batti' or not s.st or not vim.api.nvim_buf_is_valid(s.buf) then return false end
  local win = vim.api.nvim_win_get_buf(0) == s.buf and vim.api.nvim_get_current_win() or vim.fn.bufwinid(s.buf)
  if win == -1 then return false end
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
  -- tip_batti guarda il cursore della finestra corrente: nella finestra dei comandi (q:) è
  -- un'altra, e si chiede alla finestra della lezione
  -- (nvim_win_call rende un valore solo: i due si prendono dentro)
  local titolo, sez
  if win == vim.api.nvim_get_current_win() then titolo, sez = lezione().tip_batti(s, modo)
  else vim.api.nvim_win_call(win, function() titolo, sez = lezione().tip_batti(s, modo) end) end
  -- il controllo che non passa: «Adesso» vale per il modo in cui si è
  if c and c.ko then adesso = T.f(modo == 'i' and 'controllo_ko_i' or 'controllo_ko', c.riga) end
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
  return true
end

-- Il testo finale della lezione (come lezione.lua): l'obiettivo dell'ultima modifica, o Batti.
local function finale(L)
  if L.rompi then return L.rompi.ripara end
  return #L.modifiche > 0 and L.modifiche[#L.modifiche].obiettivo or L.batti.codice
end

-- «Adesso» nel passo esegui (tempo B): il testo non è più quello di Batti, e il codice va
-- controllato col :w di sempre. Dopo un errore, dipende da chi l'ha scritto.
local function adesso_esegui(s, c)
  if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then return T.batti_finito_i end
  if c and c.errore then
    local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
    return vim.deep_equal(righe, finale(s.L)) and T.esegui_ko or T.esegui_cambiato
  end
  return T.batti_finito_n
end

-- Il riquadro delle schermate di testo (briefing, spiegazione, esegui): titolo, «Adesso»,
-- «Controllo» se c'è un esito, «Comandi». Rende false per i passi che non sono di testo.
function disegna_testo(s)
  local titolo, adesso, cmd
  local c = controllo
  if s.passo == 'briefing' then
    titolo, adesso, cmd = T.f('titoli.briefing', s.L.breve), T.briefing, comandi('testo')
  elseif s.passo == 'spiegazione' then
    titolo, adesso, cmd = T.f('titoli.spiegazione', s.L.breve), T.spiegazione, comandi('spiegazione')
  elseif s.passo == 'esegui' and s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    -- l'esito di :w vale per il testo di quando è arrivato
    if c and c.righe and not vim.deep_equal(c.righe, vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)) then
      controllo, c = nil, nil
    end
    titolo, adesso, cmd = T.f('titoli.finito', vim.api.nvim_buf_line_count(s.buf)), adesso_esegui(s, c), comandi('batti')
  else
    return false
  end
  local out = { { etichetta = 'Adesso', testo = adesso, priorita = 9 } }
  if c then out[#out + 1] = { etichetta = 'Controllo', testo = c.testo, priorita = 8 } end
  out[#out + 1] = { etichetta = 'Comandi', testo = cmd, priorita = 7 }
  disegna(titolo, out)
  return true
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
  mostrata = nil
  if s.passo == 'batti' then
    M.cambio_voluto(s.buf) -- il buffer appena aperto (vuoto) è il punto di partenza
    M.tip(s)
  else
    disegna_testo(s)
  end
  if f.su_schermata then f.su_schermata(s) end
end

-- Il riquadro della schermata di vivo di adesso, con «Controllo» se c'è (Ctrl-z, un avviso).
local function disegna_mostrata()
  local m = mostrata
  local out = { { etichetta = 'Adesso', testo = m.adesso, priorita = 9 } }
  if controllo and controllo.testo ~= '' then out[#out + 1] = { etichetta = 'Controllo', testo = controllo.testo, priorita = 8 } end
  for _, x in ipairs(m.altre or {}) do out[#out + 1] = x end
  out[#out + 1] = { etichetta = 'Comandi', testo = m.cmd, priorita = 7 }
  disegna(m.titolo, out)
end

-- Il riquadro delle schermate di vivo (elenco, attesa, riepilogo). Una schermata nuova parte senza
-- l'esito di prima: un avviso per questa schermata si passa a eco dopo.
function M.mostra(titolo, adesso, cmd, altre)
  controllo = nil
  mostrata = { titolo = titolo, adesso = adesso, cmd = cmd, altre = altre }
  disegna_mostrata()
end

-- Rifà il riquadro della schermata di adesso: la lezione (Batti, esegui, le schermate di testo),
-- una schermata di vivo, o il riquadro di prima quando la guida non ne ha uno suo (modifica,
-- rompi, il buffer della lezione che non si vede). Il posto sbagliato lo mette disegna.
function ridisegna()
  local s = lezione().s
  if s then
    if s.passo == 'batti' or s.passo == 'esegui' then
      if M.tip(s) then return end
    elseif disegna_testo(s) then
      return
    end
    return disegna_di_nuovo()
  end
  if mostrata then return disegna_mostrata() end
  disegna_di_nuovo()
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
  return primo_errore or prima or T.controllo_muto
end

-- Gli esiti di :w e gli avvisi di dattilo vanno in «Controllo» (G5), mai nella riga dei messaggi.
-- Non mostra i chunks, a parte quelli che non sono l'esito di un controllo: guarda lo stato e
-- sceglie la frase. In Batti, col testo diverso dal grigio, il controllo non è partito; col testo
-- uguale e node che rifiuta, l'errore non è della persona (ko). Negli altri passi l'errore di node
-- va in «Controllo», e «Adesso» lo dice il passo.
function M.eco(chunks)
  local s = lezione().s
  local pezzi = {}
  for _, c in ipairs(chunks) do pezzi[#pezzi + 1] = c[1] end
  local testo = table.concat(pezzi)
  local righe, nuovo = nil, nil
  if s and (s.passo == 'batti' or s.passo == 'esegui') and s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  end
  if s and s.passo == 'batti' and righe then
    local codice = s.L.batti.codice
    local esito = confronto.confronta(righe, codice)
    if not esito.finito then
      local mancano = #table.concat(codice, '\n') - #table.concat(righe, '\n')
      if #esito.errori > 0 or mancano < 1 then nuovo = { testo = T.controllo_rosso }
      else nuovo = { testo = T.f('controllo_mancano', mancano) } end
    end
  end
  if not nuovo then
    if testo:find('^%$ ') and s and s.passo ~= 'rompi' then
      if testo:find('Sintassi corretta.', 1, true) then
        nuovo = { testo = T.controllo_ok }
      else
        local righe_errore = {}
        for i = 1, math.max(1, #pezzi - 1) do vim.list_extend(righe_errore, vim.split(pezzi[i], '\n')) end
        local riga = (riga_errore(righe_errore):gsub('%.$', ''))
        if s.passo == 'batti' then nuovo = { testo = '', ko = true, riga = riga }
        else nuovo = { testo = T.f('controllo_errore', riga), errore = true } end
      end
    else
      nuovo = { testo = vim.trim((testo:gsub('%s+', ' '))) }
    end
  end
  nuovo.righe = righe
  controllo = nuovo
  ridisegna()
end

function M.fine(s) return f ~= nil and f.fine ~= nil and f.fine(s) end

-- Un avviso per la schermata di adesso, in «Controllo» (per `:ultima` che non porta da nessuna parte).
-- Non passa da `eco`, che in Batti sceglie la frase da solo.
function M.avviso(testo) return avviso(testo) end

---------------------------------------------------------------- le finestre in più (G7)

-- `:q` (DattiloEsci) in una finestra in più chiude solo quella e riporta nella finestra della
-- lezione; vero se l'ha fatto. Nella finestra dei comandi (q:) fa quello che fa Vim: la chiude.
function M.esci_da_finestra_in_piu()
  if not f then return false end
  local win = vim.api.nvim_get_current_win()
  if not e_in_piu(win) then return false end
  if vim.fn.getcmdwintype() ~= '' then
    pcall(vim.cmd, 'quit')
    return true
  end
  -- il testo non salvato di un buffer qualunque non la trattiene (hidden), ma se una finestra non si
  -- chiude in modo gentile si chiude con la forza
  if not pcall(vim.api.nvim_win_close, win, false) then pcall(vim.api.nvim_win_close, win, true) end
  local principale = require('dattilo.schermo').principale
  if principale and vim.api.nvim_win_is_valid(principale) then vim.api.nvim_set_current_win(principale) end
  return true
end

-- La finestra della lezione è stata chiusa in un altro modo (‹Ctrl-w› ‹c›, ‹Ctrl-w› ‹o› da una
-- finestra in più, :quit scritto per intero). Con una lezione aperta la lezione si rimette nella
-- finestra che resta, invece di tornare alla home (schermo.lua); vero se l'ha fatto. `cur` è la
-- finestra corrente dopo la chiusura: se è il riquadro e ce n'è un'altra, la lezione va nell'altra.
-- `buf` è il buffer della finestra chiusa, che poteva essere un altro: il buffer giusto è l'ultimo
-- messo da schermo.mostra.
function M.riprendi(cur, buf)
  if not f then return false end
  local s = lezione().s
  if not s then return false end
  local schermo = require('dattilo.schermo')
  -- la finestra che resta non deve essere il riquadro né l'OBIETTIVO (tempo B), se c'è altro
  local function di_servizio(w)
    return (ui.tip_aperto() and w == ui.finestra_tip()) or (s.e and s.e.fin == w) or false
  end
  local win = cur
  if di_servizio(win) then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if w ~= win and vim.api.nvim_win_get_config(w).relative == '' and not di_servizio(w) then win = w break end
    end
  end
  ui.dimentica_tip(win)
  if s.e and s.e.fin == win then s.e.fin = nil end -- l'OBIETTIVO si riapre col compito 15
  schermo.principale = win
  local wo = vim.wo[win]
  wo.winfixheight, wo.winbar, wo.statuscolumn = false, '', ''
  local giusto = schermo.mostrato
  if not (giusto and vim.api.nvim_buf_is_valid(giusto)) then giusto = buf end
  local editor = s.passo == 'batti' or s.passo == 'modifica' or s.passo == 'rompi' or s.passo == 'esegui'
  schermo.mostra(giusto, editor and 'editor' or 'testo')
  vim.o.cmdheight = 1
  ridisegna()
  return true
end

-- Tutto quello che il resto di dattilo chiama gira protetto.
for _, nome in ipairs({ 'tip', 'schermata', 'mostra', 'eco', 'fine', 'avviso', 'cambio_voluto', 'esci_da_finestra_in_piu', 'riprendi' }) do
  M[nome] = proteggi(M[nome])
end

return M
