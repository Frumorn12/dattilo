-- Le correzioni della revisione del compito 7 (il canale): una richiesta aspetta il momento giusto,
-- e le prove che mancavano (FIFO, ordine dei campi, id ostili, atomicità, errori nel timer).
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local vivo = require('dattilo.vivo')
local lezione = require('dattilo.lezione')
local pacchetti = require('dattilo.pacchetti')
local guida = require('dattilo.guida')
local uv = vim.uv

local function lezioni_dir(c) return c .. '/dati/dattilo/pacchetti/rifallo/lezioni' end
local function leggi(percorso) return table.concat(vim.fn.readfile(percorso), '\n') end

local function stato_json(c)
  return vim.json.decode(leggi(c .. '/stato.json'), { luanil = { object = true, array = true } })
end

-- vuoi.json come lo scrive la mod: un file nuovo e poi il rename
local function vuoi(c, campi)
  local tmp = c .. '/vuoi.json.tmp'
  vim.fn.writefile({ vim.json.encode(vim.tbl_extend('force', { v = 1 }, campi)) }, tmp)
  assert(uv.fs_rename(tmp, c .. '/vuoi.json'))
end

local function nil_se_vuoto(r) if r == vim.NIL then return nil end return r end
local function id(F) return nil_se_vuoto(F:lua('local s = require("dattilo.lezione").s return s and s.L.id')) end
local function titolo(F) local r = F:riquadro() return r and r.titolo end

local function briefing(F)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
end

local function senza_lezioni(c)
  for _, f in ipairs(vim.fn.glob(lezioni_dir(c) .. '/*.md', false, true)) do vim.fn.delete(f) end
end

-- Il figlio con vivo acceso su una cartella copiata dalla fixture; `prepara(c)` la cambia prima di partire.
local function con(fn, prepara, tetto)
  local c = M.cartella()
  if prepara then prepara(c) end
  local ok, err = xpcall(M.con, debug.traceback, { cartella = c, vivo = true, tetto = tetto }, function(F) fn(F, c) end)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

-- Come in test_vivo_canale: con la guida accesa nel processo delle prove, e tutto rimesso a posto alla fine.
local function in_processo(fn, prepara)
  local c = M.cartella()
  local altre = prepara and prepara(c) or {}
  local stato = require('dattilo.stato')
  local prima = { xdg = vim.env.XDG_DATA_HOME, stato = vim.deepcopy(stato), rename = uv.fs_rename,
    carica = pacchetti.carica_cartella, controlla = vivo.controlla }
  vim.env.XDG_DATA_HOME = c .. '/dati'
  pacchetti.dimentica()
  local ok, err = xpcall(fn, debug.traceback, c)
  vivo.ferma()
  lezione.chiudi()
  require('dattilo.ui').chiudi_tip()
  uv.fs_rename, pacchetti.carica_cartella, vivo.controlla = prima.rename, prima.carica, prima.controlla
  vim.env.XDG_DATA_HOME = prima.xdg
  for k in pairs(stato) do stato[k] = nil end
  for k, v in pairs(prima.stato) do stato[k] = v end
  pacchetti.dimentica()
  vim.fn.delete(c, 'rf')
  for _, d in ipairs(altre) do vim.fn.delete(d, 'rf') end
  if not ok then error(err, 0) end
end

local function sezione(etichetta)
  local r = guida.ultimo()
  for _, sz in ipairs(r and r.sezioni or {}) do if sz.etichetta == etichetta then return sz.testo end end
end

---------------------------------------------------------------- il momento giusto

-- Una richiesta che arriva mentre la persona è nella riga dei comandi, ha un operatore in attesa o la
-- finestra dei comandi aperta non si esegue e non si consuma: si riprova al giro dopo (il contratto:
-- «se dattilo è occupato, legge al giro dopo»).
T['una richiesta aspetta se la riga dei comandi è aperta con :w scritto'] = function()
  con(function(F, c)
    briefing(F)
    F:input('<CR>')
    F:input('ifunc<Esc>:w')
    uguale(F:modo(), 'c')
    vuoi(c, { t = 10, azione = 'apri', lezione = '002-saluto' })
    vim.wait(1300)
    uguale(F:modo(), 'c', 'la riga dei comandi è stata chiusa')
    uguale(id(F), '001-somma')
    local st = stato_json(c)
    uguale({ st.lezione, st.schermo, st.eseguita }, { '001-somma', 'batti', 0 })
    F:input('<Esc>')
    vero(not F:messaggi():find('E382', 1, true), F:messaggi())
    -- finita la riga dei comandi, la richiesta si esegue, una volta
    vero(F:aspetta(function() return id(F) == '002-saluto' end, 1500), 'la richiesta non si è eseguita: ' .. tostring(id(F)))
    vero(F:aspetta(function() return stato_json(c).eseguita == 10 end, 1500))
    vero(not F:messaggi():find('E382', 1, true) and not F:messaggi():find('E21', 1, true), F:messaggi())
  end)
end

T['una richiesta aspetta se c è un operatore in attesa'] = function()
  con(function(F, c)
    briefing(F)
    F:input('<CR>')
    F:input('ifunc<Esc>d')
    uguale(F:modo(), 'no')
    vuoi(c, { t = 10, azione = 'apri', lezione = '002-saluto' })
    vim.wait(1300)
    uguale(F:modo(), 'no')
    uguale(id(F), '001-somma')
    uguale(stato_json(c).eseguita, 0)
    F:input('<Esc>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end, 1500), tostring(id(F)))
    vero(not F:messaggi():find('E21', 1, true), F:messaggi())
  end)
end

T['una richiesta aspetta se la finestra dei comandi è aperta'] = function()
  con(function(F, c)
    briefing(F)
    F:input('<CR>')
    F:input('ifunc<Esc>q:')
    uguale(F:lua('return vim.fn.getcmdwintype()'), ':')
    vuoi(c, { t = 10, azione = 'apri', lezione = '002-saluto' })
    vim.wait(1300)
    -- finché è aperta, lo stato dice ancora la lezione di prima e dalla finestra non è partito nessun errore
    uguale(F:lua('return vim.fn.getcmdwintype()'), ':')
    uguale(stato_json(c).lezione, '001-somma')
    uguale(stato_json(c).eseguita, 0)
    vero(not F:messaggi():find('E11', 1, true), F:messaggi())
    F:input('<C-c>')
    F:input('<Esc>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end, 1500), tostring(id(F)))
    vero(F:aspetta(function() return stato_json(c).lezione == '002-saluto' and stato_json(c).eseguita == 10 end, 1500))
  end)
end

T['una lezione che arriva in attesa non si apre sotto un operatore in attesa'] = function()
  con(function(F, c)
    F:aspetta(function() return titolo(F) == require('dattilo.guida_testi').titoli.attesa end)
    F:input('d')
    uguale(F:modo(), 'no')
    assert(uv.fs_copyfile(RADICE .. '/tests/fixture/rifallo/dati/dattilo/pacchetti/rifallo/lezioni/001-somma.md', lezioni_dir(c) .. '/001-somma.md'))
    vim.wait(1500)
    uguale(id(F), nil)
    uguale(F:modo(), 'no')
    F:input('<Esc>')
    vero(F:aspetta(function() return id(F) == '001-somma' end, 1500), tostring(id(F)))
  end, senza_lezioni)
end

---------------------------------------------------------------- le prove che mancavano

T['un FIFO al posto di vuoi.json si ignora, senza restare appesi'] = function()
  con(function(F, c)
    -- se dattilo aprisse il FIFO, resterebbe appeso in `open`: il figlio non risponderebbe
    vero(F:aspetta(function() return F:riquadro() ~= nil end, 3000), 'dattilo non risponde: sta aspettando il FIFO')
    uguale(id(F), '001-somma')
    vim.wait(1100)
    uguale(id(F), '001-somma')
    uguale(stato_json(c).lezione, '001-somma')
  end, function(c)
    local r = vim.system({ 'mkfifo', c .. '/vuoi.json' }):wait()
    assert(r.code == 0, 'mkfifo: ' .. tostring(r.stderr))
  end, 6000)
end

T['stato.json: i campi stanno nell ordine del contratto, nel testo'] = function()
  con(function(F, c)
    briefing(F)
    local testo
    vero(F:aspetta(function() testo = leggi(c .. '/stato.json') return testo ~= '' end))
    local atteso = '^{"v":1,"t":%d+,"lezione":"001%-somma","schermo":"briefing","nuove":1,"prossima":"002%-saluto",'
      .. '"ultima":"002%-saluto","aperte":%["001%-somma"%],"fatte":%[%],"saltate":%[%],"eseguita":0}$'
    vero(testo:find(atteso), testo)
  end)
end

-- Un'esca: un file di lezione vero ma fuori da lezioni/, a cui porterebbero l'id «../x» e «x».
T['gli id ostili non aprono niente, nemmeno se un file c è davvero'] = function()
  local function esca(c)
    local pk = c .. '/dati/dattilo/pacchetti/rifallo'
    assert(uv.fs_copyfile(pk .. '/lezioni/002-saluto.md', pk .. '/x.md'))
    assert(uv.fs_copyfile(pk .. '/lezioni/002-saluto.md', pk .. '/lezioni/x.md'))
  end
  con(function(F, c)
    briefing(F)
    local t = 20
    for _, ostile in ipairs({ '../x', 'x', '../lezioni/002-saluto', '002-saluto/../../x' }) do
      t = t + 1
      vuoi(c, { t = t, azione = 'apri', lezione = ostile })
      vero(F:aspetta(function() return stato_json(c).eseguita == t end, 2000), 'richiesta non vista: ' .. ostile)
      uguale(id(F), '001-somma', ostile)
      uguale(stato_json(c).lezione, '001-somma', ostile)
    end
  end, esca)
end

-- stato.json non si scrive mai sul posto: un file nuovo `stato.json.<pid>` e un rename (se al suo posto c'era
-- un collegamento, il rename lo sostituisce senza seguirlo).
T['stato.json si scrive con un rename da stato.json.<pid>'] = function()
  in_processo(function(c)
    vivo.avvia(c)
    local visti = {}
    local orig = uv.fs_rename
    uv.fs_rename = function(da, a)
      visti[#visti + 1] = { da, a }
      return orig(da, a)
    end
    vivo.segna_saltata('001-somma')
    uv.fs_rename = orig
    local di_stato = vim.tbl_filter(function(x) return x[2] == c .. '/stato.json' end, visti)
    uguale(di_stato, { { c .. '/stato.json.' .. uv.os_getpid(), c .. '/stato.json' } })
    uguale(uv.fs_stat(c .. '/stato.json.' .. uv.os_getpid()), nil, 'il temporaneo è rimasto')
    uguale(uv.fs_stat(c .. '/stato.json').mode % 512, 384)
  end)
end

T['un errore dentro il timer va nel riquadro, una volta, e non nella riga dei messaggi'] = function()
  con(function(F)
    briefing(F)
    F:lua([[require('dattilo.vivo').controlla = function() error('guasto finto di prova') end]])
    vero(F:aspetta(function() return (F:riquadro().sezioni.Controllo or ''):find('guasto finto di prova', 1, true) ~= nil end, 2000),
      vim.inspect(F:riquadro()))
    vero((F:riquadro().sezioni.Controllo or ''):find('Errore di dattilo', 1, true), F:riquadro().sezioni.Controllo)
    vero(not F:messaggi():find('guasto finto', 1, true), F:messaggi())
    -- si può andare avanti: il briefing è ancora lì
    uguale(id(F), '001-somma')
  end)
end

---------------------------------------------------------------- i minori

T['una richiesta con un azione sconosciuta si scarta come per i tipi sbagliati'] = function()
  in_processo(function(c)
    vivo.avvia(c)
    vuoi(c, { t = 5, azione = 'chiudi', dalvivo = 'finita' })
    vivo.controlla()
    uguale(stato_json(c).eseguita, 0)
    vero(not vivo.destra():find('sessione finita', 1, true), vivo.destra())
    -- e riscritto giusto, si esegue
    vuoi(c, { t = 6, azione = 'ultima' })
    vivo.controlla()
    uguale(stato_json(c).eseguita, 6)
  end)
end

T['la lezione corrente entra in aperte a ogni giro, anche se non l ha aperta vivo'] = function()
  in_processo(function(c)
    vivo.avvia(c)
    lezione.apri('rifallo', 2)
    vivo.controlla()
    uguale(stato_json(c).aperte, { '001-somma', '002-saluto' })
  end)
end

T['un errore all avvio va nel riquadro, e il canale parte lo stesso'] = function()
  in_processo(function(c)
    pacchetti.carica_cartella = function() error('guasto all\'avvio') end
    local ok, e = pcall(vivo.avvia, c)
    vero(ok, 'avvia ha dato un errore: ' .. tostring(e))
    vero((sezione('Controllo') or ''):find('guasto all\'avvio', 1, true), tostring(sezione('Controllo')))
  end)
end

T['la frase di una lezione che non c è più parla del file'] = function()
  local TT = require('dattilo.guida_testi')
  uguale(TT.canale.assente, 'il file non c\'è più')
end

return T
