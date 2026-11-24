-- «Adesso» in Batti nel Neovim figlio, coi tasti veri: ogni situazione della tabella della 3.3, e
-- per ognuna il primo tasto scritto in «Adesso», premuto, porta dove la frase dice (G2).
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local TT = require('dattilo.guida_testi')
local C = { 'function somma(a, b) {', '    if (typeof a !== "number") return 0;', '    return a + b;', '}' }

-- Per nvim_input: il testo così com'è, con < scritto come <lt>.
local function scrivi(F, s) F:input((s:gsub('<', '<lt>'))) end

local function adesso(F) return F:riquadro().sezioni.Adesso end

local function errori(F)
  return F:lua('return require("dattilo.batti").stato(require("dattilo.lezione").s.buf).errori')
end

local function cursore(F) return F:lua('return vim.api.nvim_win_get_cursor(0)') end

-- Va in Batti della lezione `id` (senza id, la prima, che si apre da sola).
local function in_batti(F, id)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
  if id then F:lua('require("dattilo.vivo").apri(...)', id) end
  F:input('<CR>')
  uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
end

-- Il robot di chi non sa niente (tests/vivo_figlio.lua): la prima fila di «Adesso», e seguirla.
local function premi_primo(F) return F:premi_primo() end
local function segui(F, fatto, max) return F:segui(fatto, max) end

local function con(o, fn)
  o = vim.tbl_extend('keep', o or {}, { vivo = true })
  o.cartella = o.cartella or M.cartella()
  M.con(o, fn)
end

---------------------------------------------------------------- le prove del compito

T['Esc in fondo e poi la frase: si riprende senza rosso'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Esc>')
    uguale(adesso(F), TT.batti_riprendi)
    F:input(TT.neovim('A'))
    F:input('t')
    uguale(F:righe()[1], 'funct')
    uguale(errori(F), 0)
  end)
end

T['Invio presto: i Backspace contati riuniscono la riga'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (t')
    F:input('<CR>')
    uguale(adesso(F), TT.f('batti_spezzata', 2, '2 volte', 2))
    F:input('<BS><BS>')
    uguale(#F:righe(), 2)
    uguale(F:righe()[2], '    if (t')
    scrivi(F, 'ypeof a !== "number") return 0;')
    uguale(F:righe()[2], C[2])
    uguale(errori(F), 0)
  end)
end

T['in NORMAL un movimento cambia Adesso'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (t')
    F:input('<CR>')
    scrivi(F, 'return a + b;')
    F:input('<Esc>')
    uguale(F:righe(), { C[1], '    if (t', '    return a + b;' })
    uguale(cursore(F), { 3, 16 })
    uguale(adesso(F), TT.f('batti_indietro_n', 2, 2, 2))
    F:input('2G')
    uguale(adesso(F), TT.batti_riprendi)
    F:input('A')
    uguale(F:modo(), 'i')
    uguale(cursore(F), { 2, #'    if (t' })
  end)
end

T['Esc dopo aver scritto non è un testo cambiato'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Esc>')
    vero(adesso(F) ~= TT.batti_cambiato, adesso(F))
    F:input('x')
    uguale(F:righe(), { 'fun' })
    uguale(adesso(F), TT.batti_cambiato)
    F:input('u')
    uguale(F:righe(), { 'func' })
    uguale(adesso(F), TT.batti_riprendi)
  end)
end

T['il digramma scrive il carattere'] = function()
  con({}, function(F)
    in_batti(F, '002-saluto')
    F:input('i')
    scrivi(F, 'function saluta(nome) {')
    F:input('<CR>')
    scrivi(F, 'return "')
    vero(adesso(F):find('‹Ctrl-k› ‹<› ‹<›', 1, true), adesso(F))
    uguale(adesso(F), TT.f('batti_carattere', '«', '‹Ctrl-k› ‹<› ‹<›', ''))
    F:input('<C-k><lt><lt>')
    uguale(F:righe()[2], '    return "«')
    uguale(errori(F), 0)
    -- anche la chiusa: la guida dice il suo digramma, e premuto scrive »
    scrivi(F, '" + nome + "')
    uguale(adesso(F), TT.f('batti_carattere', '»', '‹Ctrl-k› ‹>› ‹>›', ''))
    premi_primo(F)
    uguale(F:righe()[2], '    return "«" + nome + "»')
    uguale(errori(F), 0)
  end)
end

-- G1: Adesso e Comandi interi, letti dalle righe del riquadro, in stati con frasi corte e lunghe.
for _, alte in ipairs({ 24, 40 }) do
  T[string.format('a 80x%d Adesso e Comandi stanno interi', alte)] = function()
    con({ righe = alte }, function(F)
      F:lua('vim.o.columns = 80')
      in_batti(F)
      local function interi(cosa)
        local A = F:a_schermo()
        uguale(A.sezioni.Adesso, M.a_schermo(adesso(F)), cosa)
        uguale(A.sezioni.Comandi, M.a_schermo(TT.comandi_batti), cosa)
        vero(A.finisce.Adesso:sub(-3) ~= '…' and A.finisce.Comandi:sub(-3) ~= '…', cosa)
        uguale(A.alto, #A.righe, cosa .. ': la finestra non mostra tutto il riquadro')
        for _, r in ipairs(A.righe) do uguale(vim.fn.strdisplaywidth(r), 80, r) end
      end
      interi('vuoto')
      F:input('i')
      scrivi(F, 'func')
      interi('scrivi')
      F:input('<Up>')
      uguale(adesso(F), TT.frecce)
      interi('frecce')
      F:input('<Esc>A<BS><BS><BS><BS>')
      scrivi(F, C[1])
      F:input('<CR>')
      scrivi(F, 'if (t')
      F:input('<CR>')
      scrivi(F, 'return a')
      uguale(adesso(F), TT.f('batti_indietro_i', 2, 2, 2))
      interi('indietro')
    end)
  end
end

T['la decima lezione dice le stesse cose della prima'] = function()
  local c = M.cartella()
  local lezioni = {}
  for i = 1, 10 do lezioni[string.format('rifallo/%03d-fatta', 100 + i)] = { volte = 1, completata = true, migliore_wpm = 40 } end
  vim.fn.writefile({ vim.json.encode({ lezioni = lezioni, sessioni = {}, sbloccate = vim.empty_dict() }) },
    c .. '/dati/dattilo/progressi.json')
  con({ cartella = c }, function(F)
    uguale(F:lua('return vim.tbl_count(require("dattilo.progressi").carica().lezioni)'), 10)
    in_batti(F)
    uguale(adesso(F), TT.batti_vuoto)
    F:input('i')
    uguale(adesso(F), TT.batti_scrivi)
  end)
end

---------------------------------------------------------------- ogni situazione, coi tasti veri

T['situazione: niente scritto, ‹i› entra in scrittura'] = function()
  con({}, function(F)
    in_batti(F)
    uguale(adesso(F), TT.batti_vuoto)
    premi_primo(F)
    uguale(F:modo(), 'i')
    uguale(adesso(F), TT.batti_scrivi)
  end)
end

T['situazione: riga finita, ‹Invio› va a capo col rientro'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    uguale(adesso(F), TT.batti_fine_riga)
    premi_primo(F)
    uguale(F:righe(), { C[1], '    ' })
    uguale(errori(F), 0)
    uguale(adesso(F), TT.batti_scrivi)
  end)
end

T['situazione: rosso, ‹Backspace› lo toglie'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'funx')
    uguale(adesso(F), TT.batti_errore)
    premi_primo(F)
    uguale(F:righe(), { 'fun' })
    uguale(errori(F), 0)
  end)
end

T['situazione: rosso in maiuscolo, la frase del Bloc Maiusc e poi ‹Backspace›'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'FUNC')
    uguale(adesso(F), TT.batti_maiuscole)
    segui(F, function() return errori(F) == 0 end)
    uguale(F:righe(), { '' })
  end)
end

T['situazione: tutto scritto, titolo FINITO, e ‹Esc› porta alla frase di :w'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    for i, l in ipairs(C) do
      scrivi(F, vim.trim(l))
      if i < #C then F:input('<CR>') end
    end
    uguale(F:righe(), C)
    uguale(adesso(F), TT.batti_finito_i)
    uguale(F:riquadro().titolo, 'FINITO · 4 righe scritte')
    premi_primo(F)
    uguale(F:modo(), 'n')
    uguale(adesso(F), TT.batti_finito_n)
    uguale(F:riquadro().titolo, 'FINITO · 4 righe scritte')
  end)
end

T['situazione: rosso sulla riga del cursore in NORMAL, ‹A› e poi ‹Backspace›'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'funx')
    F:input('<Esc>')
    uguale(adesso(F), TT.batti_rosso_qui)
    premi_primo(F)
    uguale(F:modo(), 'i')
    uguale(cursore(F), { 1, 4 })
    uguale(adesso(F), TT.batti_errore)
  end)
end

T['situazione: rosso su un\'altra riga in NORMAL, ‹2› ‹G› ci porta'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (typeof a !== "numbex')
    F:input('<Esc>gg')
    uguale(adesso(F), TT.f('batti_rosso_n', 2, 2, 2))
    premi_primo(F)
    uguale(cursore(F)[1], 2)
    uguale(adesso(F), TT.batti_rosso_qui)
    segui(F, function() return errori(F) == 0 end)
    uguale(F:righe()[2], '    if (typeof a !== "numbe')
  end)
end

T['situazione: riga sopra non finita in INSERT, seguendo la guida si torna lì'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (t')
    F:input('<CR>')
    scrivi(F, 'return a + b;')
    uguale(adesso(F), TT.f('batti_indietro_i', 2, 2, 2))
    local visti = segui(F, function() return F:modo() == 'i' and cursore(F)[1] == 2 end)
    uguale(visti, { TT.f('batti_indietro_i', 2, 2, 2), TT.f('batti_indietro_n', 2, 2, 2), TT.batti_riprendi })
    uguale(cursore(F), { 2, #'    if (t' })
    scrivi(F, 'ypeof a !== "number") return 0;')
    uguale(errori(F), 0)
  end)
end

T['situazione: testo cambiato in NORMAL, ‹u› lo rimette'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'function')
    F:input('<Esc>')
    F:input('dd')
    uguale(F:righe(), { '' })
    uguale(adesso(F), TT.batti_cambiato)
    premi_primo(F)
    uguale(F:righe(), { 'function' })
    uguale(adesso(F), TT.batti_riprendi)
  end)
end

T['situazione: freccia, la frase delle frecce e poi ‹Esc›'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Up>')
    uguale(adesso(F), TT.frecce)
    premi_primo(F)
    uguale(F:modo(), 'n')
    uguale(adesso(F), TT.batti_riprendi)
    -- in NORMAL la freccia dà la frase che comincia da ‹A› (lì ‹Esc› non fa niente), e un
    -- movimento con h la toglie
    F:input('<Left>')
    uguale(adesso(F), TT.frecce_n)
    F:input('h')
    uguale(adesso(F), TT.batti_riprendi)
  end)
end

-- In NORMAL ‹Esc› non fa niente e non toglierebbe la frase: «premo, e mi dice di ripremere la
-- stessa cosa». La frase comincia da ‹A›, e fatta la mossa se ne va.
T['freccia in NORMAL: il primo tasto della frase la fa andare via'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Esc>')
    F:input('<Left>')
    uguale(adesso(F), TT.frecce_n)
    premi_primo(F)
    uguale(F:modo(), 'i')
    vero(adesso(F) ~= TT.frecce_n, adesso(F))
    uguale(adesso(F), TT.batti_scrivi)
    uguale(cursore(F), { 1, 4 })
    scrivi(F, 'tion')
    uguale(F:righe(), { 'function' })
    uguale(errori(F), 0)
  end)
end

T['situazione: cursore a metà di quello che hai scritto, ‹Fine›'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'functi')
    F:input('<Esc>hhhi')
    uguale(cursore(F), { 1, 2 })
    uguale(adesso(F), TT.batti_cursore)
    premi_primo(F)
    uguale(cursore(F), { 1, 6 })
    uguale(adesso(F), TT.batti_scrivi)
    scrivi(F, 'on')
    uguale(F:righe(), { 'function' })
  end)
end

T['situazione: riga vuota nel grigio, ‹Invio› ‹Invio›'] = function()
  local c = M.cartella()
  vim.fn.writefile({ '---', 'titolo: "Due costanti"', 'breve: "costanti"', 'etichetta: "Rifallo tu"', 'file: "costanti.js"',
    'fonte: "src/c.js, righe 1-3"', 'tempo: "circa 1 minuto"', '---', '', '## Batti', '```js', 'const a = 1;', '', 'const b = 2;', '```' },
    c .. '/dati/dattilo/pacchetti/rifallo/lezioni/003-costanti.md')
  con({ cartella = c }, function(F)
    in_batti(F, '003-costanti')
    F:input('i')
    scrivi(F, 'const a = 1;')
    uguale(adesso(F), TT.batti_riga_vuota)
    -- a metà dei due Invio, sulla riga vuota: «Adesso» dice l'Invio che manca, e la nota «Riga
    -- vuota» di oggi (‹Invio› senza i due punti, G3) non c'è
    F:input('<CR>')
    uguale(adesso(F), TT.batti_fine_riga)
    uguale(F:riquadro().sezioni.Riga, nil)
    F:input('<BS>')
    uguale(F:righe(), { 'const a = 1;' })
    premi_primo(F)
    uguale(F:righe(), { 'const a = 1;', '', '' })
    uguale(cursore(F), { 3, 0 })
    uguale(adesso(F), TT.batti_scrivi)
    scrivi(F, 'const b = 2;')
    uguale(adesso(F), TT.batti_finito_i)
  end)
end

---------------------------------------------------------------- i punti dove si perderebbe lavoro

T['Ctrl-c come Esc: la guida non fa premere u su testo buono'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<C-c>') -- da solo: nvim_input scarta i tasti in attesa quando arriva Ctrl-c
    uguale(F:modo(), 'n')
    uguale(F:righe(), { 'func' })
    uguale(adesso(F), TT.batti_riprendi)
    premi_primo(F)
    F:input('t')
    uguale(F:righe(), { 'funct' })
    uguale(errori(F), 0)
  end)
end

T['un u di troppo: ‹g› ‹+› rimette il testo, un altro u lo toglierebbe'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'func')
    F:input('<Esc>u')
    uguale(F:righe(), { '' })
    uguale(adesso(F), TT.batti_annullato)
    premi_primo(F)
    uguale(F:righe(), { 'func' })
    uguale(adesso(F), TT.batti_riprendi)
    -- x, poi ‹u› come dice la guida, poi un u di troppo
    F:input('x')
    uguale(adesso(F), TT.batti_cambiato)
    F:input('uu')
    uguale(F:righe(), { '' })
    uguale(adesso(F), TT.batti_annullato)
    segui(F, function() return adesso(F) == TT.batti_riprendi end)
    uguale(F:righe(), { 'func' })
  end)
end

T['sulla riga finita sopra quella da finire: niente Invio che aprirebbe una riga in più'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (t')
    F:input('<Esc>kA')
    uguale(cursore(F), { 1, #C[1] })
    uguale(F:modo(), 'i')
    uguale(adesso(F), TT.f('batti_indietro_i', 2, 2, 2))
    segui(F, function() return F:modo() == 'i' and cursore(F)[1] == 2 end)
    uguale(F:righe(), { C[1], '    if (t' })
    uguale(cursore(F), { 2, #'    if (t' })
  end)
end

T['rosso a destra del cursore: prima ‹Fine›, poi ‹Backspace› fino al rosso'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'funxtion')
    F:input('<Esc>hhhhi')
    uguale(cursore(F), { 1, 3 })
    uguale(adesso(F), TT.batti_cursore)
    segui(F, function() return errori(F) == 0 end)
    uguale(F:righe(), { 'fun' })
    uguale(adesso(F), TT.batti_scrivi)
  end)
end

-- Col mouse (mouse=a) un clic mentre si scrive sposta il cursore e resta in INSERT: è così che
-- chi non sa Vim finisce a metà riga o su una riga sopra.
T['un clic a metà riga mentre si scrive: ‹Fine›, e il Backspace non tocca le lettere giuste'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, 'funxtion')
    F:clic(1, 2)
    uguale(F:modo(), 'i')
    uguale(cursore(F), { 1, 2 })
    uguale(adesso(F), TT.batti_cursore)
    segui(F, function() return errori(F) == 0 end)
    uguale(F:righe(), { 'fun' })
  end)
end

T['un clic sulla riga sopra mentre si scrive: si torna giù, senza righe in più'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (t')
    F:clic(1, #C[1] + 5) -- oltre la fine della riga 1: il cursore va in fondo
    uguale(F:modo(), 'i')
    uguale(cursore(F), { 1, #C[1] })
    uguale(adesso(F), TT.f('batti_indietro_i', 2, 2, 2))
    segui(F, function() return F:modo() == 'i' and cursore(F)[1] == 2 end)
    uguale(F:righe(), { C[1], '    if (t' })
    uguale(cursore(F), { 2, #'    if (t' })
  end)
end

-- Un clic a metà di quello che si era scritto e poi ‹Invio›: la coda della riga scende nella riga
-- dopo, col rientro. ‹Fine› e poi ‹Backspace› la cancellerebbero: i ‹Backspace› contati la riuniscono.
T['Invio a metà del testo scritto: seguendo la guida la riga torna intera'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (typeof a')
    F:clic(2, 8)
    uguale(cursore(F), { 2, 8 })
    F:input('<CR>')
    uguale(F:righe(), { C[1], '    if (', '    typeof a' })
    uguale(cursore(F), { 3, 4 })
    uguale(adesso(F), TT.f('batti_spezzata_meta', 2, '2 volte', 2))
    local visti = segui(F, function() return #F:righe() == 2 end)
    uguale(visti, { TT.f('batti_spezzata_meta', 2, '2 volte', 2) })
    uguale(F:righe(), { C[1], '    if (typeof a' })
    -- il cursore è nel punto della spaccatura, come dice la frase; poi ‹Fine› e si continua
    uguale(cursore(F), { 2, 8 })
    uguale(adesso(F), TT.batti_cursore)
    premi_primo(F)
    scrivi(F, ' !== "number") return 0;')
    uguale(F:righe()[2], C[2])
    uguale(errori(F), 0)
  end)
end

T['un clic a metà di una riga intera, con un altra da finire: si va subito lì'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, 'if (t')
    F:clic(1, 5)
    uguale(cursore(F), { 1, 5 })
    uguale(F:modo(), 'i')
    uguale(adesso(F), TT.f('batti_indietro_i', 2, 2, 2))
    segui(F, function() return F:modo() == 'i' and cursore(F)[1] == 2 end)
    uguale(F:righe(), { C[1], '    if (t' })
    uguale(cursore(F), { 2, #'    if (t' })
  end)
end

-- La riga 2 è intera ed è l'ultima scritta: la frase non dice che «non è finita».
T['sopra l ultima riga scritta, intera: si continua da lì'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    scrivi(F, C[1])
    F:input('<CR>')
    scrivi(F, vim.trim(C[2]))
    F:clic(1, #C[1])
    uguale(adesso(F), TT.f('batti_continua_i', 2, 2, 2))
    local visti = segui(F, function() return F:modo() == 'i' and cursore(F)[1] == 2 end)
    uguale(visti, { TT.f('batti_continua_i', 2, 2, 2), TT.f('batti_continua_n', 2, 2, 2), TT.batti_riprendi })
    uguale(cursore(F), { 2, #C[2] })
    uguale(adesso(F), TT.batti_fine_riga)
  end)
end

T['rosso dopo la fine del grigio: ‹Backspace› e il testo è finito'] = function()
  con({}, function(F)
    in_batti(F)
    F:input('i')
    for _, l in ipairs(C) do
      scrivi(F, vim.trim(l))
      F:input('<CR>')
    end
    scrivi(F, 'x')
    uguale(#F:righe(), 5)
    uguale(adesso(F), TT.batti_errore)
    premi_primo(F)
    uguale(errori(F), 0)
    uguale(adesso(F), TT.batti_finito_i)
  end)
end

return T
