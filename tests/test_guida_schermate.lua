-- La guida nelle altre schermate della lezione e l'esito di :w nel riquadro (compito 4), nel
-- Neovim figlio coi tasti veri: niente «Premi INVIO» e niente messaggi di dattilo (G5).
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local TT = require('dattilo.guida_testi')

local function scrivi(F, s) F:input((s:gsub('<', '<lt>'))) end

local function con(o, fn)
  o = vim.tbl_extend('keep', o or {}, { vivo = true })
  o.cartella = o.cartella or M.cartella()
  M.con(o, fn)
end

local function in_batti(F)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
  F:input('<CR>')
  uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
end

local function codice(F) return F:lua('return require("dattilo.lezione").s.L.batti.codice') end

-- Scrive nel buffer le righe date, una alla volta (l'Invio mette il rientro da solo).
local function batti_tutto(F, righe)
  F:input('i')
  for i, l in ipairs(righe) do
    scrivi(F, vim.trim(l))
    if i < #righe then F:input('<CR>') end
  end
end

local function passo(F) return F:lua('return require("dattilo.lezione").s.passo') end

T[':w a metà: Controllo dice quanti caratteri mancano, e niente nei messaggi'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Esc>')
    F:input(':w<CR>')
    local C = codice(F)
    local N = #table.concat(C, '\n') - #table.concat(F:righe(), '\n')
    local r = F:riquadro()
    uguale(r.sezioni.Controllo, TT.f('controllo_mancano', N))
    local m = F:messaggi()
    for _, x in ipairs({ 'Mancano', '$ node', 'salvato' }) do
      vero(not m:find(x, 1, true), 'nei messaggi c\'è «' .. x .. '»: ' .. m)
    end
    -- il riquadro è ancora quello di Batti, e si può continuare a scrivere
    uguale(passo(F), 'batti')
  end)
end

T['il Controllo vale solo per il testo che c era: scrivendo ancora sparisce'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Esc>')
    F:input(':w<CR>')
    vero(F:riquadro().sezioni.Controllo ~= nil)
    F:input('A')
    scrivi(F, 't')
    uguale(F:riquadro().sezioni.Controllo, nil)
  end)
end

T[':w col rosso: Controllo dice che c è del rosso'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'funx')
    F:input('<Esc>')
    F:input(':w<CR>')
    uguale(F:riquadro().sezioni.Controllo, TT.controllo_rosso)
  end)
end

T[':w col testo uguale: si va alla spiegazione senza il passo esegui'] = function()
  con({}, function(F)
    in_batti(F)
    F:lua([[
      local L = require('dattilo.lezione')
      local e = L.esegui
      _G.esegui_chiamata = false
      L.esegui = function(...) _G.esegui_chiamata = true return e(...) end]])
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:input(':w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end), 'passo: ' .. passo(F))
    uguale(F:lua('return _G.esegui_chiamata'), false)
    local r = F:riquadro()
    uguale(r.titolo, TT.f('titoli.spiegazione', 'somma'))
    uguale(r.sezioni.Adesso, TT.spiegazione)
    uguale(r.sezioni.Controllo, TT.controllo_ok)
    uguale(r.sezioni.Comandi, TT.comandi_testo)
    vero(not F:messaggi():find('$ node', 1, true), F:messaggi())
  end)
end

T[':w con node che rifiuta: il riquadro dice che l errore non è tuo'] = function()
  con({ cartella = M.cartella('rifallo-rotta') }, function(F)
    in_batti(F)
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:input(':w<CR>')
    local r = F:riquadro()
    uguale(r.titolo, TT.titoli.ko)
    uguale(r.tipo, 'rosso')
    local a = r.sezioni.Adesso
    uguale(a:sub(1, #'Node non accetta il codice: '), 'Node non accetta il codice: ')
    vero(a:find('SyntaxError', 1, true), a)
    vero(a:find('‹:salta› ‹Invio›', 1, true), a)
    vero(not F:messaggi():find('$ node', 1, true), F:messaggi())
    -- la lezione non va avanti, e si può ancora scrivere
    uguale(passo(F), 'batti')
  end)
end

-- Un nome lunghissimo dichiarato due volte: node risponde su più righe (il file, la riga, il
-- segno ^, «SyntaxError: Identifier '…' has already been declared», la versione), e la frase
-- dell'errore va a capo su più righe del riquadro a 80 colonne.
local NOME = 'unNomeDiVariabileMoltoLungoPerProvareIlRiquadroDellaGuidaAOttantaColonne'

T['un errore di sintassi lungo sta nel riquadro: niente righe nei messaggi, nessun Premi INVIO'] = function()
  local c = M.cartella('rifallo-rotta')
  local f = c .. '/dati/dattilo/pacchetti/rifallo/lezioni/001-rotta.md'
  local testo = table.concat(vim.fn.readfile(f), '\n'):gsub('function rotta%( {\n}',
    'const ' .. NOME .. ' = 1;\nconst ' .. NOME .. ' = 2;')
  vim.fn.writefile(vim.split(testo, '\n'), f)
  con({ cartella = c, righe = 24 }, function(F)
    F:lua('vim.o.columns = 80')
    in_batti(F)
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:input(':w<CR>')
    local r = F:riquadro()
    uguale(r.titolo, TT.titoli.ko)
    -- il messaggio di node era su più righe, e la frase va a capo su più righe del riquadro
    local a = r.sezioni.Adesso
    vero(a:find("SyntaxError: Identifier '" .. NOME .. "' has already been declared", 1, true), a)
    vero(#require('dattilo.ui').a_capo(a, 80 - 4 - 11) >= 4, a)
    local A = F:a_schermo()
    -- il nome, più largo della riga, è spezzato in due righe: le lettere ci sono tutte, in ordine
    uguale((A.sezioni.Adesso:gsub('%s', '')), (M.a_schermo(a):gsub('%s', '')))
    uguale(A.sezioni.Comandi, M.a_schermo(TT.comandi_batti))
    vero(A.finisce.Adesso:sub(-3) ~= '…' and A.finisce.Comandi:sub(-3) ~= '…', vim.inspect(A.righe))
    uguale(A.alto, #A.righe, 'la finestra non mostra tutto il riquadro')
    for _, riga in ipairs(A.righe) do uguale(vim.fn.strdisplaywidth(riga), 80, riga) end
    local m = F:messaggi()
    vero(not m:find('$ node', 1, true) and not m:find('SyntaxError', 1, true), m)
    -- il figlio non è fermo davanti a un «Premi INVIO»: risponde e il modo è NORMAL
    uguale(F:modo(), 'n')
    vero(not F:lua('return vim.api.nvim_get_mode().blocking'), 'Neovim è bloccato')
  end)
end

-- La frase del controllo che non passa, letta da «Adesso»: la riga dell'errore di node.
local function riga_ko(a) return a:match('^Node non accetta il codice: (.-)%. Il testo') end

T['il controllo che non passa, in INSERT: Adesso dice prima Esc'] = function()
  con({ cartella = M.cartella('rifallo-rotta') }, function(F)
    in_batti(F)
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:input(':w<CR>')
    local a = F:adesso()
    local riga = riga_ko(a)
    vero(riga and riga:find('SyntaxError', 1, true), a)
    uguale(a, TT.f('controllo_ko', riga))
    -- in scrittura senza cambiare niente: il titolo resta, «Adesso» vale per INSERT
    F:input('A')
    uguale(F:modo(), 'i')
    uguale(F:riquadro().titolo, TT.titoli.ko)
    uguale(F:adesso(), TT.f('controllo_ko_i', riga))
    F:premi_primo()
    uguale(F:modo(), 'n')
    uguale(F:adesso(), TT.f('controllo_ko', riga))
  end)
end

T['nel passo esegui un errore di node va in Controllo, e Adesso non dice che non è tuo'] = function()
  con({}, function(F)
    in_batti(F)
    F:lua('local L = require("dattilo.lezione") L.esegui(L.s)')
    uguale(passo(F), 'esegui')
    F:input('ifunction x( {<Esc>')
    F:input(':w<CR>')
    local r = F:riquadro()
    vero(r.titolo ~= TT.titoli.ko and r.tipo ~= 'rosso', vim.inspect(r))
    vero(r.sezioni.Controllo:find('^Node non accetta il codice: SyntaxError'), r.sezioni.Controllo)
    uguale(r.sezioni.Adesso, TT.esegui_cambiato)
    vero(not vim.inspect(r):find('non è tuo', 1, true), vim.inspect(r))
    vero(not F:messaggi():find('$ node', 1, true), F:messaggi())
    -- in scrittura «Adesso» dice di uscirne
    F:input('A')
    uguale(F:adesso(), TT.batti_finito_i)
    F:input('<Esc>')
    uguale(F:adesso(), TT.esegui_cambiato)
    -- ‹:e!› ‹Invio› rimette il codice della lezione, il Controllo di prima sparisce, e :w passa
    F:premi_primo()
    uguale(F:righe(), codice(F))
    uguale(F:riquadro().sezioni.Controllo, nil)
    uguale(F:adesso(), TT.batti_finito_n)
    F:premi_primo()
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end), 'passo: ' .. passo(F))
  end)
end

T['nel passo esegui col codice della lezione che node rifiuta: l errore non è tuo'] = function()
  con({ cartella = M.cartella('rifallo-rotta') }, function(F)
    in_batti(F)
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:lua('local L = require("dattilo.lezione") L.esegui(L.s)')
    F:input(':w<CR>')
    local r = F:riquadro()
    uguale(r.sezioni.Adesso, TT.esegui_ko)
    vero(r.sezioni.Controllo:find('^Node non accetta il codice: SyntaxError'), r.sezioni.Controllo)
    vero(r.titolo ~= TT.titoli.ko, r.titolo)
  end)
end

-- Una lezione con una Modifica (tempo B): il :w nel passo modifica non deve sparire.
local function con_modifica()
  local c = M.cartella()
  vim.fn.writefile({ '---', 'titolo: "Una costante"', 'breve: "costante"', 'etichetta: "Rifallo tu"', 'file: "costante.js"',
    'fonte: "src/c.js, riga 1"', 'tempo: "circa 1 minuto"', '---', '', '## Batti', '```js', 'const a = 1;', '```', '',
    '## Modifica', 'consegna: Metti 2 al posto di 1.', 'aiuto: ‹f1› va sull\'1, ‹r2› lo cambia.', 'par: 3',
    'soluzione: f1r2', 'mostra: f1 · r2', '```js', 'const a = 2;', '```' },
    c .. '/dati/dattilo/pacchetti/rifallo/lezioni/003-costante.md')
  return c
end

T['nel passo modifica un esito di :w compare nel riquadro, non nella riga dei comandi'] = function()
  con({ cartella = con_modifica() }, function(F)
    F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
    F:lua('require("dattilo.vivo").apri("003-costante")')
    F:input('<CR>')
    batti_tutto(F, { 'const a = 1;' })
    F:input('<Esc>')
    F:input(':w<CR>')
    vero(F:aspetta(function() return passo(F) == 'modifica' end), 'passo: ' .. passo(F))
    F:input(':w<CR>')
    uguale(F:riquadro().sezioni.Controllo, 'Prima finisci la modifica: Metti 2 al posto di 1.')
    vero(not F:messaggi():find('Prima finisci', 1, true), F:messaggi())
  end)
end

T['nel passo rompi un esito passato alla guida compare nel riquadro'] = function()
  con({}, function(F)
    in_batti(F)
    F:lua([[
      local L = require('dattilo.lezione')
      L.s.passo = 'rompi'
      require('dattilo.guida').eco({ { '$ node --check somma.js\n', 'DattiloMuto' }, { 'somma.js:1\n', 'DattiloTesto' },
        { 'Errore: leggi qui sopra.', 'DattiloRosso' } })]])
    local c = F:riquadro().sezioni.Controllo
    vero(c and c:find('Errore: leggi qui sopra.', 1, true), vim.inspect(F:riquadro()))
    vero(not F:messaggi():find('leggi qui sopra', 1, true), F:messaggi())
  end)
end

T['un errore nel disegno del riquadro resta registrato, e non arriva ai messaggi'] = function()
  con({}, function(F)
    in_batti(F)
    uguale(F:lua('return require("dattilo.guida").errore_disegno()'), vim.NIL)
    F:lua([[require('dattilo.ui').tip = function() error('apposta nel disegno') end]])
    F:input('i')
    local e = F:lua('return require("dattilo.guida").errore_disegno()')
    vero(type(e) == 'string' and e:find('apposta nel disegno', 1, true), vim.inspect(e))
    vero(not F:messaggi():find('apposta', 1, true), F:messaggi())
    vero(not F:lua('return vim.api.nvim_get_mode().blocking'), 'Neovim è bloccato')
    scrivi(F, 'fu')
    uguale(F:righe()[1], 'fu')
  end)
end

T['un errore nel salvataggio va nel riquadro, non in un errore di autocomando'] = function()
  con({}, function(F)
    in_batti(F)
    F:lua([[require('dattilo.compila').lancia = function() error('apposta nel salvataggio') end]])
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:input(':w<CR>')
    local c = F:riquadro().sezioni.Controllo
    vero(c and c:find('^Errore di dattilo: apposta nel salvataggio'), vim.inspect(F:riquadro()))
    local m = F:messaggi()
    vero(not m:find('apposta', 1, true) and not m:find('autocommand', 1, true) and not m:find('autocomando', 1, true), m)
    uguale(F:modo(), 'n')
    vero(not F:lua('return vim.api.nvim_get_mode().blocking'), 'Neovim è bloccato')
    uguale(passo(F), 'batti')
  end)
end

T['un errore della guida va nel riquadro, non nei messaggi'] = function()
  con({}, function(F)
    in_batti(F)
    F:lua([[require('dattilo.guida').fornitore().comandi = function() error('apposta') end]])
    F:input('i')
    local r = F:riquadro()
    uguale(r.sezioni.Controllo:sub(1, #'Errore di dattilo:'), 'Errore di dattilo:')
    vero(not F:messaggi():find('apposta', 1, true), F:messaggi())
    vero(not F:lua('return vim.api.nvim_get_mode().blocking'), 'Neovim è bloccato')
    -- la lezione non si è rotta: si scrive ancora
    scrivi(F, 'fu')
    uguale(F:righe()[1], 'fu')
  end)
end

T['la spiegazione col testo di Batti uguale non ha più la riga muta sulla home'] = function()
  con({}, function(F)
    in_batti(F)
    batti_tutto(F, codice(F))
    F:input('<Esc>')
    F:input(':w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end))
    local testo = F:lua([[
      local out = {}
      for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
        for _, l in ipairs(m[4].virt_lines or {}) do
          for _, c in ipairs(l) do out[#out + 1] = c[1] end
        end
      end
      return table.concat(out, ' ')]])
    vero(not testo:find('torna alla home', 1, true), testo)
  end)
end

T['il briefing non dice più che q torna alla home'] = function()
  con({}, function(F)
    F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
    local testo = table.concat(F:righe(), '\n')
    vero(not testo:find('torna alla home', 1, true), testo)
  end)
end

T['il passo esegui ha il suo riquadro: Adesso dice :w, Comandi li elenca'] = function()
  con({}, function(F)
    in_batti(F)
    F:lua('local L = require("dattilo.lezione") L.esegui(L.s)')
    local r = F:riquadro()
    uguale(r.titolo, TT.f('titoli.finito', 1))
    uguale(r.sezioni.Adesso, TT.batti_finito_n)
    uguale(r.sezioni.Comandi, TT.comandi_batti)
    -- col :w il controllo parte (il file è vuoto, e node lo accetta): si va alla spiegazione
    F:input(':w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end), 'passo: ' .. passo(F))
    uguale(F:riquadro().sezioni.Controllo, TT.controllo_ok)
    vero(not F:messaggi():find('$ node', 1, true), F:messaggi())
  end)
end

-- G1: Adesso e Comandi interi, a 80x24 e a 80x40, nella spiegazione e col controllo che non passa
for _, d in ipairs({ { 80, 24 }, { 80, 40 } }) do
  T[string.format('a %dx%d spiegazione e controllo che non passa hanno Adesso e Comandi interi', d[1], d[2])] = function()
    for _, caso in ipairs({ 'somma', 'rotta' }) do
      con({ cartella = M.cartella(caso == 'rotta' and 'rifallo-rotta' or nil), righe = d[2] }, function(F)
        F:lua('vim.o.columns = ...', d[1])
        in_batti(F)
        batti_tutto(F, codice(F))
        F:input('<Esc>')
        F:input(':w<CR>')
        F:aspetta(function() return F:riquadro().titolo ~= nil and (passo(F) == 'spiegazione' or F:riquadro().tipo == 'rosso') end)
        local A = F:a_schermo()
        local r = F:riquadro()
        local atteso = caso == 'rotta' and TT.titoli.ko or TT.f('titoli.spiegazione', 'somma')
        uguale(r.titolo, atteso)
        vero(A.sezioni.Adesso and A.sezioni.Comandi, vim.inspect(A.righe))
        vero(A.finisce.Adesso:sub(-3) ~= '…' and A.finisce.Comandi:sub(-3) ~= '…', vim.inspect(A.righe))
        uguale(A.sezioni.Comandi, M.a_schermo(caso == 'rotta' and TT.comandi_batti or TT.comandi_testo))
        uguale(A.alto, #A.righe, 'la finestra non mostra tutto il riquadro')
        for _, riga in ipairs(A.righe) do uguale(vim.fn.strdisplaywidth(riga), d[1], riga) end
      end)
    end
  end
end

return T
