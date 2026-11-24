-- «Adesso» in Batti, senza Neovim figlio: guida.adesso_batti e guida.carattere (progetto, 3.3 e G11).
local T = {}
local guida = require('dattilo.guida')
local TT = require('dattilo.guida_testi')

local P = require('dattilo.pacchetti').carica_cartella(RADICE .. '/tests/fixture/rifallo/dati/dattilo/pacchetti/rifallo')
local C = P.lezioni[1].batti.codice -- il Batti di 001-somma.md

local function adesso(righe, r, c, modo, altro, codice)
  return guida.adesso_batti(vim.tbl_extend('force', { codice = codice or C, righe = righe, r = r, c = c, modo = modo }, altro or {}))
end

T['il Batti di prova è quello di 001-somma'] = function()
  uguale(C, { 'function somma(a, b) {', '    if (typeof a !== "number") return 0;', '    return a + b;', '}' })
end

-- La tabella del compito 3, caso per caso.
T['01 NORMAL, niente scritto: i'] = function() uguale(adesso({ '' }, 1, 0, 'n'), TT.batti_vuoto) end
T['02 INSERT, a metà della riga: scrivi'] = function() uguale(adesso({ 'func' }, 1, 4, 'i'), TT.batti_scrivi) end
T['03 NORMAL dopo Esc: A, non i'] = function() uguale(adesso({ 'func' }, 1, 3, 'n'), TT.batti_riprendi) end
T['04 INSERT, riga finita: Invio'] = function() uguale(adesso({ C[1] }, 1, #C[1], 'i'), TT.batti_fine_riga) end
T['05 INSERT, rosso: Backspace'] = function() uguale(adesso({ 'funx' }, 1, 4, 'i'), TT.batti_errore) end
T['06 INSERT, rosso in maiuscolo: Bloc Maiusc'] = function() uguale(adesso({ 'FUNC' }, 1, 4, 'i'), TT.batti_maiuscole) end
T['07 INSERT, riga spezzata: Backspace contati'] = function()
  uguale(adesso({ C[1], '    if (t', '    ' }, 3, 4, 'i'), TT.f('batti_spezzata', 2, '2 volte', 2))
end
T['08 INSERT, una riga sopra non finita'] = function()
  uguale(adesso({ C[1], '    if (t', '    return a + b;' }, 3, 17, 'i'), TT.f('batti_indietro_i', 2, 2, 2))
end
T['09 NORMAL, una riga sopra non finita'] = function()
  uguale(adesso({ C[1], '    if (t', '    return a + b;' }, 3, 16, 'n'), TT.f('batti_indietro_n', 2, 2, 2))
end
T['10 tutto scritto, in INSERT e in NORMAL'] = function()
  uguale(adesso(C, 4, 1, 'i'), TT.batti_finito_i)
  uguale(adesso(C, 4, 1, 'n'), TT.batti_finito_n)
  uguale(adesso(C, 4, 0, 'n'), TT.batti_finito_n)
end
T['11 NORMAL, rosso su un\'altra riga'] = function()
  uguale(adesso({ C[1], '    if (typeof a !== "numbex' }, 1, 0, 'n'), TT.f('batti_rosso_n', 2, 2, 2))
end
T['11b NORMAL, rosso su questa riga'] = function()
  uguale(adesso({ C[1], '    if (typeof a !== "numbex' }, 2, 27, 'n'), TT.batti_rosso_qui)
end
T['12 NORMAL, testo cambiato: u'] = function() uguale(adesso({ 'fun' }, 1, 2, 'n', { cambiato = true }), TT.batti_cambiato) end
T['13 una freccia appena premuta'] = function() uguale(adesso({ 'fun' }, 1, 3, 'i', { frecce = true }), TT.posti.frecce.testo) end
T['14 INSERT, cursore a metà di quello che hai scritto: Fine'] = function() uguale(adesso({ 'functi' }, 1, 2, 'i'), TT.batti_cursore) end

T['15 INSERT, riga finita e la dopo è vuota nel grigio: Invio Invio'] = function()
  uguale(adesso({ 'const a = 1;' }, 1, 12, 'i', nil, { 'const a = 1;', '', 'const b = 2;' }), TT.batti_riga_vuota)
end

T['16 INSERT, il prossimo carattere non è sulla tastiera: il digramma'] = function()
  uguale(adesso({ 'const s = "' }, 1, 11, 'i', nil, { 'const s = "«ciao»";' }),
    TT.f('batti_carattere', '«', '‹Ctrl-k› ‹<› ‹<›', ''))
end

-- Oltre la tabella: i punti dove la tabella del progetto, presa alla lettera, farebbe perdere
-- lavoro o andrebbe nel posto sbagliato.

-- Con la riga 1 finita e il cursore lì (un clic, o Esc k A), «‹Invio›» aprirebbe una riga in più
-- fra la 1 e la 2: tutto sotto scenderebbe e diventerebbe rosso.
T['17 INSERT sopra la riga da finire: si torna giù, non si va a capo'] = function()
  uguale(adesso({ C[1], '    if (t' }, 1, #C[1], 'i'), TT.f('batti_indietro_i', 2, 2, 2))
end

-- Col rosso a destra del cursore, ‹Backspace› cancellerebbe le lettere giuste a sinistra e il
-- rosso resterebbe lì: prima ‹Fine›.
T['18 INSERT col rosso a destra del cursore: prima Fine'] = function()
  uguale(adesso({ 'funxtion' }, 1, 3, 'i'), TT.batti_cursore)
  uguale(adesso({ 'funxtion' }, 1, 8, 'i'), TT.batti_errore)
end

-- Il rosso su una riga dopo la fine del grigio (un Invio di troppo e una lettera).
T['19 rosso dopo la fine del grigio'] = function()
  local righe = vim.list_extend(vim.deepcopy(C), { 'x' })
  uguale(adesso(righe, 5, 1, 'i'), TT.batti_errore)
  uguale(adesso(righe, 5, 0, 'n'), TT.batti_rosso_qui)
  uguale(adesso(righe, 1, 0, 'n'), TT.f('batti_rosso_n', 5, 5, 5))
  -- cancellata la lettera, la riga vuota in fondo non conta: è tutto scritto
  uguale(adesso(vim.list_extend(vim.deepcopy(C), { '' }), 5, 0, 'i'), TT.batti_finito_i)
end

-- Dopo un ‹u› di troppo il testo scritto è stato annullato: un altro ‹u› ne toglierebbe ancora.
T['20 NORMAL, testo annullato con u: g +, prima di tutto'] = function()
  uguale(adesso({ '' }, 1, 0, 'n', { cambiato = true, annullato = true }), TT.batti_annullato)
  uguale(adesso({ 'fun' }, 1, 2, 'n', { cambiato = true, annullato = true }), TT.batti_annullato)
end

-- Cancellato tutto in NORMAL (per esempio dd): ‹u› lo rimette, ‹i› lo farebbe riscrivere.
T['21 NORMAL, testo cambiato fino a vuoto: u, non i'] = function()
  uguale(adesso({ '' }, 1, 0, 'n', { cambiato = true }), TT.batti_cambiato)
end

T['22 INSERT, riga spezzata: le volte del Backspace'] = function()
  uguale(adesso({ C[1], '    if (t', '' }, 3, 0, 'i'), TT.f('batti_spezzata', 2, 'una volta', 2))
  -- più spazi del rientro del grigio sono rosso: prima si cancellano quelli
  uguale(adesso({ C[1], '    if (t', '     ' }, 3, 5, 'i'), TT.batti_errore)
  local D = { 'if (a) {', '    if (b) {', '        c();', '    }', '}' }
  uguale(adesso({ D[1], '    if (', '        ' }, 3, 8, 'i', nil, D), TT.f('batti_spezzata', 2, '3 volte', 2))
end

T['23 in INSERT il cursore va in fondo anche prima del digramma'] = function()
  uguale(adesso({ 'const s = "' }, 1, 5, 'i', nil, { 'const s = "«ciao»";' }), TT.batti_cursore)
end

-- Un a capo a metà di quello che si era scritto: la coda scende nella riga dopo, col rientro.
-- ‹Fine› e poi ‹Backspace› cancellerebbero il testo buono sceso giù: i ‹Backspace› contati dalla
-- colonna del cursore riuniscono la riga, e la frase dice che si torna nel punto della spaccatura.
T['24 INSERT, riga spezzata a metà del testo scritto: Backspace contati, prima di Fine'] = function()
  uguale(adesso({ C[1], '    if (', '    typeof a' }, 3, 4, 'i'), TT.f('batti_spezzata_meta', 2, '2 volte', 2))
  uguale(adesso({ C[1], '    if (', 'typeof a' }, 3, 0, 'i'), TT.f('batti_spezzata_meta', 2, 'una volta', 2))
  uguale(adesso({ C[1], '    ', '    if (typeof a' }, 3, 4, 'i'), TT.f('batti_spezzata_meta', 2, '2 volte', 2))
  -- quello che è sceso non è l'inizio giusto del grigio: non è una riga spezzata
  uguale(adesso({ C[1], '    if (', '    xyz' }, 3, 4, 'i'), TT.batti_cursore)
  -- il cursore non è nel rientro: prima Fine
  uguale(adesso({ C[1], '    if (', '    typeof a' }, 3, 6, 'i'), TT.batti_cursore)
end

-- La riga da cui si continua è intera, solo è l'ultima scritta: «non è finita» sarebbe falso.
T['25 riga intera ma ultima scritta: si continua da lì, senza dire che non è finita'] = function()
  uguale(adesso({ C[1], C[2] }, 1, #C[1], 'i'), TT.f('batti_continua_i', 2, 2, 2))
  uguale(adesso({ C[1], C[2] }, 1, 3, 'n'), TT.f('batti_continua_n', 2, 2, 2))
  -- la riga 2 a metà resta «non è finita»
  uguale(adesso({ C[1], '    if (t' }, 1, 3, 'n'), TT.f('batti_indietro_n', 2, 2, 2))
end

-- Un clic a metà di una riga intera mentre un'altra è da finire: niente ‹Fine›, subito la frase
-- che porta alla riga da finire.
T['26 INSERT a metà di una riga intera, con un altra da finire: si va lì'] = function()
  uguale(adesso({ C[1], '    if (t' }, 1, 5, 'i'), TT.f('batti_indietro_i', 2, 2, 2))
  uguale(adesso({ C[1], C[2] }, 1, 5, 'i'), TT.f('batti_continua_i', 2, 2, 2))
end

T['27 NORMAL, una freccia appena premuta: la frase comincia da A'] = function()
  uguale(adesso({ 'fun' }, 1, 2, 'n', { frecce = true }), TT.frecce_n)
  vero(TT.frecce_n:find('^[^‹]*‹A›'), TT.frecce_n)
end

T['28 rientro di 2 spazi: il Backspace due volte'] = function()
  uguale(adesso({ 'if (', '  ' }, 2, 2, 'i', nil, { 'if (a) {', '  b();', '}' }), TT.f('batti_spezzata', 1, '2 volte', 1))
end

-- Le lettere maiuscole fra i tasti si dicono, come la G: ‹E› ‹'›, ‹*› ‹X›, ‹O› ‹K›, ‹Ctrl-v› ‹U›.
T['29 digrammi con le maiuscole: la frase le dice'] = function()
  local function due(ch) return { guida.carattere(ch) } end
  uguale(due('É'), { '‹Ctrl-k› ‹E› ‹\'›', '; E maiuscola' })
  uguale(due('×'), { '‹Ctrl-k› ‹*› ‹X›', '; X maiuscola' })
  uguale(due('✓'), { '‹Ctrl-k› ‹O› ‹K›', '; O e K maiuscole' })
  uguale(due('—'), { '‹Ctrl-k› ‹-› ‹M›', '; M maiuscola' })
  uguale(due('«'), { '‹Ctrl-k› ‹<› ‹<›', '' })
  uguale(due('🙂'), { '‹Ctrl-v› ‹U› ‹0› ‹0› ‹0› ‹1› ‹F› ‹6› ‹4› ‹2›', '; U maiuscola' })
  uguale(adesso({ 'const s = "' }, 1, 11, 'i', nil, { 'const s = "É";' }),
    TT.f('batti_carattere', 'É', '‹Ctrl-k› ‹E› ‹\'›', '; E maiuscola'))
  vero(TT.f('batti_carattere', 'É', '‹Ctrl-k› ‹E› ‹\'›', '; E maiuscola'):find('altri tasti; E maiuscola).', 1, true))
end

T['carattere: digrammi, tastiera italiana e Ctrl-v'] = function()
  uguale(guida.carattere('«'), '‹Ctrl-k› ‹<› ‹<›')
  uguale(guida.carattere('…'), '‹Ctrl-k› ‹,› ‹.›')
  uguale(guida.carattere('→'), '‹Ctrl-k› ‹-› ‹>›')
  uguale(guida.carattere('★'), '‹Ctrl-k› ‹*› ‹2›')
  uguale(guida.carattere('à'), nil)
  uguale(guida.carattere('a'), nil)
  for _, ch in ipairs({ 'è', 'é', 'ì', 'ò', 'ù', 'ç', '°', '£', '§', '€', '{', '~', '`' }) do uguale(guida.carattere(ch), nil, ch) end
  uguale(guida.carattere('🙂'), '‹Ctrl-v› ‹U› ‹0› ‹0› ‹0› ‹1› ‹F› ‹6› ‹4› ‹2›')
end

T['carattere: senza digramma sotto U+FFFF, Ctrl-v u e quattro cifre'] = function()
  -- U+2E18 (punto interrogativo rovesciato) non ha digramma in Neovim 0.12
  local ch = vim.fn.nr2char(0x2E18)
  local ha = false
  for _, d in ipairs(vim.fn.digraph_getlist(true)) do if d[2] == ch then ha = true end end
  uguale(ha, false)
  uguale(guida.carattere(ch), '‹Ctrl-v› ‹u› ‹2› ‹E› ‹1› ‹8›')
end

-- Ogni frase di «Adesso» in Batti comincia da un tasto o da una frase che dice dove si è, e il
-- primo tasto scritto è quello da premere: qui si controlla almeno che ogni frase abbia un tasto.
T['ogni frase di Adesso in Batti ha almeno un tasto'] = function()
  for _, nome in ipairs({ 'batti_vuoto', 'batti_cambiato', 'batti_annullato', 'batti_finito_i', 'batti_finito_n',
    'batti_maiuscole', 'batti_errore', 'batti_spezzata', 'batti_indietro_i', 'batti_rosso_qui', 'batti_rosso_n',
    'batti_indietro_n', 'batti_riprendi', 'batti_cursore', 'batti_riga_vuota', 'batti_fine_riga',
    'batti_scrivi', 'batti_spezzata_meta', 'batti_continua_i', 'batti_continua_n', 'frecce_n' }) do
    vero(TT[nome] and TT[nome]:find('‹', 1, true), nome)
  end
end

return T
