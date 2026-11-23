-- La guida di «Rifallo tu»: il riquadro in alto, acceso in ogni schermata, che dice in italiano
-- che tasto premere adesso e cosa fa. Si accende solo con `dattilo vivo`.
local ui = require('dattilo.ui')
local stato = require('dattilo.stato')
local T = require('dattilo.guida_testi')

local M = {}
local f = nil          -- il fornitore
local ultimo = nil     -- l'ultimo riquadro disegnato
local controllo = nil  -- l'ultimo esito, per la sezione «Controllo»
local more_prima = nil

local function lezione() return require('dattilo.lezione') end

-- fornitore = { comandi = fun(schermata), fine = fun(s), su_schermata = fun(s), destra = fun() }
function M.accendi(fornitore)
  f = fornitore
  more_prima = vim.o.more
  vim.o.more = false
  ultimo, controllo = nil, nil
  lezione().guida = M
end

function M.spegni()
  if not f then return end
  f = nil
  ultimo, controllo = nil, nil
  if more_prima ~= nil then vim.o.more = more_prima end
  lezione().guida = nil
end

function M.attiva() return f ~= nil end

function M.ultimo() return ultimo end

local function comandi(schermata)
  return f and f.comandi and f.comandi(schermata) or ''
end

local function righe_di(testo)
  local largo = math.max(10, vim.o.columns - 4 - 9) -- come ui.sezioni: bordi e colonna delle etichette
  return #ui.a_capo(testo, largo)
end

-- Disegna il riquadro e lo ricorda; alza il riquadro (fino a 10 righe) perché Adesso e Comandi stiano interi.
local function disegna(titolo, sezioni, tipo)
  local base = vim.o.lines >= 34 and 8 or 6
  local tot = 0
  for _, sz in ipairs(sezioni) do tot = tot + ((sz.etichetta == 'Adesso' or sz.etichetta == 'Comandi') and righe_di(sz.testo) or 1) end
  ui.altezza_tip(math.min(10, math.max(base, tot)))
  ultimo = { titolo = titolo, sezioni = sezioni, tipo = tipo }
  ui.tip(titolo, sezioni, tipo)
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
    if extra and extra ~= '' then stato.destra = (stato.destra or '') .. extra vim.cmd('redrawtabline') end
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
