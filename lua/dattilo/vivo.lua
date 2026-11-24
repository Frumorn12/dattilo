-- «Rifallo tu» dentro dattilo: la cartella di lezioni aperta con `dattilo vivo <cartella>`.
local guida = require('dattilo.guida')
local T = require('dattilo.guida_testi')

local M = {}
local acceso = false
local PACCHETTO = 'rifallo'

function M.attivo() return acceso end

local function fornitore()
  return {
    comandi = function(schermata) return T['comandi_' .. schermata] or '' end,
    fine = function() return false end,
    su_schermata = function() end,
    destra = function() return '' end,
  }
end

local function parti()
  if not acceso then return end
  local P = require('dattilo.pacchetti').carica(PACCHETTO)
  if P and #P.lezioni > 0 then M.apri(P.lezioni[1].id) else M.elenco() end
end

function M.avvia(cartella)
  acceso = true
  M.cartella = cartella
  guida.accendi(fornitore())
  -- all'avvio Neovim, finito init.lua, porta il fuoco sulla prima finestra, che è quella del
  -- riquadro: si parte a Neovim già avviato, così il fuoco resta sulla lezione
  if vim.v.vim_did_enter == 1 then return parti() end
  vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function() vim.schedule(parti) end })
end

-- Per le prove: spegne la guida e torna al dattilo di sempre.
function M.ferma()
  acceso = false
  guida.spegni()
end

function M.apri(id)
  local pacchetti = require('dattilo.pacchetti')
  pacchetti.dimentica()
  local P = pacchetti.carica(PACCHETTO)
  for n, L in ipairs(P and P.lezioni or {}) do
    if L.id == id then return require('dattilo.lezione').apri(PACCHETTO, n) end
  end
  M.elenco()
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
  local P = pacchetti.carica(PACCHETTO)
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
