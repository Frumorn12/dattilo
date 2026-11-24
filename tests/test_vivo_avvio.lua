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

T['vivo con un percorso che non è una cartella esce con 1 e dice come si usa'] = function()
  local r = vim.system({ RADICE .. '/bin/dattilo', 'vivo', vim.fn.tempname() }, { env = env_finto(), text = true }):wait()
  uguale(r.code, 1)
  vero(r.stderr:find('uso: dattilo vivo <cartella> [opzioni di nvim]', 1, true), r.stderr)
end

T['vivo con una cartella relativa passa a Neovim percorsi assoluti'] = function()
  local base = vim.fn.tempname()
  vim.fn.mkdir(base .. '/una cartella', 'p', tonumber('700', 8))
  local out = base .. '/visti'
  local env = env_finto()
  env.HOME = base .. '/casa'
  -- -c gira prima di VimEnter: si scrive l'ambiente e si esce prima che si apra una lezione
  local r = vim.system({ RADICE .. '/bin/dattilo', 'vivo', './una cartella', '--headless',
    '-c', "call writefile([$DATTILO_VIVO, $XDG_DATA_HOME], '" .. out .. "')", '-c', 'qa!' },
    { env = env, cwd = base, text = true }):wait(10000)
  uguale(r.code, 0, r.stderr)
  uguale(vim.fn.readfile(out), { base .. '/una cartella', base .. '/una cartella/dati' })
end

-- Nel figlio: l'ambiente, i comandi e le abbreviazioni che avvia accende restano lì, non nel
-- processo delle prove.
T['senza vivo la guida resta spenta'] = function()
  M.con({}, function(F)
    uguale(F:lua('return vim.env.DATTILO_VIVO'), vim.NIL)
    F:lua('require("dattilo.lezione").apri("corso-c-antirez", 1)')
    uguale(F:lua('return require("dattilo.lezione").guida == nil'), true)
    uguale(F:lua('return require("dattilo.guida").attiva()'), false)
    uguale(F:lua('return #vim.api.nvim_tabpage_list_wins(0)'), 1)
    uguale(F:lua('return vim.fn.exists(":DattiloSalta")'), 0)
    -- nessun autocomando della guida
    uguale(F:lua('return vim.fn.exists("#dattilo_guida")'), 0)
  end)
end

local LUNGO = 'Node non accetta il codice: SyntaxError: Unexpected token, expected "," (riga 3, colonna 12): '
  .. 'controlla le parentesi e le virgole di quella riga.'

-- In Batti della prima lezione, con le dimensioni date e un Controllo lungo.
local function batti_con_controllo(F, colonne, righe)
  F:aspetta(function() return F:riquadro() ~= nil end)
  F:lua('vim.o.columns, vim.o.lines = ...', colonne, righe)
  F:input('<CR>')
  F:lua('require("dattilo.guida").eco({ { ... } })', LUNGO)
end

for _, d in ipairs({ { 80, 24 }, { 120, 40 } }) do
  T[string.format('a %dx%d un Controllo lungo non toglie righe ad Adesso e Comandi', d[1], d[2])] = function()
    local TT = require('dattilo.guida_testi')
    M.con({ cartella = M.cartella(), vivo = true }, function(F)
      batti_con_controllo(F, d[1], d[2])
      local A = F:a_schermo()
      uguale(A.sezioni.Adesso, M.a_schermo(TT.batti_vuoto))
      uguale(A.sezioni.Comandi, M.a_schermo(TT.comandi_batti))
      vero(A.sezioni.Controllo, vim.inspect(A.righe))
      vero(A.finisce.Adesso:sub(-3) ~= '…' and A.finisce.Comandi:sub(-3) ~= '…', vim.inspect(A.righe))
      uguale(A.alto, #A.righe, 'la finestra non mostra tutto il riquadro')
      for _, r in ipairs(A.righe) do uguale(vim.fn.strdisplaywidth(r), d[1], r) end
      -- l'etichetta Controllo è staccata dal suo testo (col testo di Batti vuoto, dopo il compito 4,
      -- eco dice che il testo non è ancora uguale al grigio)
      local riga
      for _, r in ipairs(A.righe) do if r:find('Controllo', 1, true) then riga = r end end
      vero(riga:find('│ Controllo  Salvato', 1, true), riga)
    end)
  end
end

T['ridimensionando la finestra il riquadro si rimisura'] = function()
  local TT = require('dattilo.guida_testi')
  M.con({ cartella = M.cartella(), vivo = true }, function(F)
    batti_con_controllo(F, 120, 40)
    local prima = F:a_schermo()
    F:lua('vim.o.columns, vim.o.lines = 80, 24')
    local dopo = F:a_schermo()
    vero(dopo.alto ~= prima.alto, 'stessa altezza a 120x40 e a 80x24: ' .. prima.alto)
    uguale(dopo.alto, #dopo.righe, 'la finestra non mostra tutto il riquadro')
    uguale(dopo.sezioni.Adesso, M.a_schermo(TT.batti_vuoto))
    uguale(dopo.sezioni.Comandi, M.a_schermo(TT.comandi_batti))
    -- un ridisegno qualunque non cambia più niente: la misura è già quella di 80x24
    F:lua('require("dattilo.lezione").tip()')
    uguale(F:a_schermo().alto, dopo.alto)
  end)
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
