-- dattilo vivo: il comando, l'avvio sulla prima lezione e i testi della guida.
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')

local function env_finto()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, 'p', tonumber('700', 8))
  return {
    XDG_DATA_HOME = tmp .. '/dati', XDG_CONFIG_HOME = tmp .. '/config',
    XDG_STATE_HOME = tmp .. '/stato', XDG_CACHE_HOME = tmp .. '/cache',
  }
end

T['vivo --dove stampa vivo 1 e la radice'] = function()
  local r = vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--dove' }, { env = env_finto(), text = true }):wait()
  uguale(r.code, 0, r.stderr)
  uguale(vim.json.decode(r.stdout), { vivo = 1, radice = RADICE })
end

T['vivo senza cartella esce con 1 e dice come si usa'] = function()
  local r = vim.system({ RADICE .. '/bin/dattilo', 'vivo' }, { env = env_finto(), text = true }):wait()
  uguale(r.code, 1)
  vero(r.stderr:find('uso: dattilo vivo <cartella> [opzioni di nvim]', 1, true), r.stderr)
end

T['senza vivo la guida resta spenta'] = function()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo').avvia({ radice = RADICE })
  local lezione = require('dattilo.lezione')
  lezione.apri('corso-c-antirez', 1)
  uguale(lezione.guida, nil)
  uguale(#vim.api.nvim_tabpage_list_wins(0), 1)
  uguale(vim.fn.exists(':DattiloSalta'), 0)
  lezione.chiudi()
end

T['con vivo si parte dal briefing della prima lezione, col riquadro'] = function()
  local TT = require('dattilo.guida_testi')
  local c = M.cartella()
  M.con({ cartella = c, vivo = true }, function(F)
    local r
    F:aspetta(function() r = F:riquadro() return r ~= nil end)
    uguale(r.titolo, TT.f('titoli.briefing', 'somma'))
    uguale(r.titolo, 'COMINCIA · somma')
    uguale(r.sezioni.Adesso, TT.briefing)
    uguale(r.sezioni.Comandi, TT.comandi_testo)
  end)
end

T['Invio porta a Batti con la guida'] = function()
  local TT = require('dattilo.guida_testi')
  local c = M.cartella()
  M.con({ cartella = c, vivo = true }, function(F)
    F:aspetta(function() return F:riquadro() ~= nil end)
    F:input('<CR>')
    uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
    local r = F:riquadro()
    uguale(r.titolo:sub(1, #'SCRIVI · '), 'SCRIVI · ')
    uguale(r.sezioni.Adesso, TT.batti_vuoto)
    uguale(r.sezioni.Comandi, TT.comandi_batti)
  end)
end

-- G3, prova a: ogni fila di tasti ‹…› è seguita da «:» nella stessa frase.
local function controlla_g3(nome, s, mancanti)
  local i = 1
  while true do
    local da = s:find('‹', i, true)
    if not da then break end
    -- la fila: ‹…› poi, a distanza di uno spazio, altri ‹…›
    local fine = da
    while true do
      local _, f = s:find('^‹[^›]*›', fine)
      if not f then break end
      fine = f + 1
      local _, g = s:find('^ ‹[^›]*›', fine)
      if not g then break end
      fine = fine + 1
    end
    if s:sub(fine, fine) ~= ':' then mancanti[#mancanti + 1] = nome .. ': ' .. s:sub(da, fine + 5) end
    i = fine
  end
end

T['guida_testi: ogni fila di tasti è seguita dai due punti'] = function()
  local TT = require('dattilo.guida_testi')
  local mancanti, visti = {}, 0
  local function visita(nome, v)
    if type(v) == 'string' then
      visti = visti + 1
      controlla_g3(nome, v, mancanti)
    elseif type(v) == 'table' then
      for k, x in pairs(v) do visita(nome .. '.' .. tostring(k), x) end
    end
  end
  visita('T', TT)
  vero(visti > 60, 'pochi testi controllati: ' .. visti)
  uguale(mancanti, {})
end

T['guida_testi: f e posto formattano, neovim traduce i tasti'] = function()
  local TT = require('dattilo.guida_testi')
  uguale(TT.f('batti_riga', 3) == nil, true) -- nome sconosciuto: nil, non un errore
  vero(TT.f('batti_spezzata', 3, 'due volte', 2):find('La riga 3', 1, true))
  local titolo, testo = TT.posto('registra_n', 'a')
  uguale(titolo, 'STAI REGISTRANDO (@a)')
  vero(testo:find('l\'ha aperta q seguito da a', 1, true), testo)
  uguale(TT.neovim('Invio'), '<CR>')
  uguale(TT.neovim('Ctrl-k'), '<C-k>')
  uguale(TT.neovim('<'), '<lt>')
  uguale(TT.neovim('Fine'), '<End>')
  uguale(TT.neovim('A'), 'A')
end

return T
