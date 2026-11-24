-- La guida di «Rifallo tu»: il riquadro in alto, acceso in ogni schermata, che dice in italiano
-- che tasto premere adesso e cosa fa. Si accende solo con `dattilo vivo`.
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
  local g = vim.api.nvim_create_augroup('dattilo_guida', { clear = true })
  -- la finestra ha cambiato misura: le righe di ogni sezione vanno ricontate
  vim.api.nvim_create_autocmd('VimResized', { group = g, callback = function()
    if ultimo and ui.tip_aperto() then disegna(ultimo.titolo, ultimo.sezioni, ultimo.tipo) end
  end })
end

function M.spegni()
  if not f then return end
  f = nil
  ultimo, controllo = nil, nil
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_guida')
  if more_prima ~= nil then vim.o.more = more_prima end
  lezione().guida = nil
end

function M.attiva() return f ~= nil end

function M.ultimo() return ultimo end

local function comandi(schermata)
  return f and f.comandi and f.comandi(schermata) or ''
end

local function adesso_batti(s)
  local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  if #righe == 1 and righe[1] == '' then return T.batti_vuoto end
  return T.batti_scrivi
end

function M.tip(s)
  if s.passo ~= 'batti' or not s.st then return end
  local titolo, sez = lezione().tip_batti(s, vim.api.nvim_get_mode().mode:sub(1, 1))
  local out = { { etichetta = 'Adesso', testo = adesso_batti(s), priorita = 9 } }
  if controllo then out[#out + 1] = { etichetta = 'Controllo', testo = controllo, priorita = 8 } end
  for _, x in ipairs(sez) do
    if not x.avviso and x.etichetta ~= 'Vim' then out[#out + 1] = x end
  end
  out[#out + 1] = { etichetta = 'Comandi', testo = comandi('batti'), priorita = 7 }
  disegna(T.f('titoli.batti', titolo), out)
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
