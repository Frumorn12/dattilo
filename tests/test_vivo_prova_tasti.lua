-- La lista di sicurezza dei tasti: `dattilo vivo --prova` gira su lezioni scritte da un modello, e una soluzione che
-- apre la finestra dei comandi, il modo Ex o un registro d'espressione deve essere rifiutata PRIMA di eseguire qualcosa.
-- Ogni vettore prova a creare un marcatore innocuo in una cartella temporanea della prova: non deve comparire.
local T = {}
local A = dofile(RADICE .. '/tests/vivo_prova_aiuti.lua')
local formato = require('dattilo.formato')

-- { nome, tasti (@M@ = il marcatore), pezzo del motivo, vivo }
-- `vivo`: senza la lista questi tasti, nella sandbox, creerebbero davvero il marcatore (la prova «sono veri» lo controlla,
-- così il rifiuto non è un rifiuto a vuoto). false = non fa niente in Neovim 0.12, ma si rifiuta lo stesso.
local VETTORI = {
  -- quelli della revisione
  -- la finestra dei comandi: si modifica una riga della cronologia e si chiude con <Esc>, così il comando non si vede
  { 'q: la finestra dei comandi', ':s/a/b/<CR>q:kcccall system("touch @M@")<Esc><CR>', 'finestra dei comandi', true },
  { 'q/ la finestra della ricerca', 'q/:call system("touch @M@")<CR>', 'finestra dei comandi', true },
  { 'q? la finestra della ricerca all\'indietro', 'q?:call system("touch @M@")<CR>', 'finestra dei comandi', true },
  { 'gQ il modo Ex', 'gQcall system("touch @M@")<CR>visual<CR>', 'modo Ex', true },
  { '<c-r>= minuscolo', 'i<c-r>=system("touch @M@")<CR><Esc>', 'espressioni', true },
  { '<c-R>= misto', 'i<c-R>=system("touch @M@")<CR><Esc>', 'espressioni', true },
  { '<C-r>= nella ricerca', '/<C-r>=system("touch @M@")<CR>', 'espressioni', true },
  { '<Bar> in un comando', ':s/a/b/<Bar>call system("touch @M@")<CR>', '!', true },
  { '<bar> in un comando', ':s/a/b/<bar>call system("touch @M@")<CR>', '!', true },
  { '"= il registro delle espressioni', '"=system("touch @M@")<CR>p', 'espressioni', true },
  { '@= il registro delle espressioni', '@=system("touch @M@")<CR>', 'espressioni', true },
  { ':<C-r> e un registro', 'o!touch @M@<Esc>yy:<C-r>"<CR>', 'tasto speciale', true },
  -- gli stessi giri con altri modi di scrivere il tasto, e le vie vicine
  { '<C-f> apre la finestra dalla riga dei comandi', ':s/a/b/<CR>:<C-f>kcccall system("touch @M@")<Esc><CR>', 'finestra dei comandi', false }, -- col feedkeys <C-f> non apre la finestra: si rifiuta per prudenza
  { 'Invio del tastierino chiude il comando', ':s/a/b/<Bar>call system("touch @M@")<kEnter>', '!', true },
  { '<Char-13> chiude il comando', ':call system("touch @M@")<Char-13>', 'comando non ammesso', true },
  { ':= valuta Lua', ':=vim.fn.system("touch @M@")<CR>', 'comando non ammesso', true },
  { ':@a esegue un registro', 'o:call system("touch @M@")<Esc>"ayy:@a<CR>', 'comando non ammesso', true },
  { '<C-\\>e valuta un\'espressione', ':s/a/b/<C-\\>esystem("touch @M@")<CR>', 'espressioni', true },
  { 'un tasto speciale dentro il comando', ':s/a/b/ <C-b>call system("touch @M@")<CR>', 'tasto speciale', true },
  { 'un <C-r> vero (il byte, non scritto <C-r>)', 'i\18=system("touch @M@")<CR><Esc>', 'espressioni', true },
  { 'un <C-f> vero (il byte)', ':s/a/b/<CR>:\6kcccall system("touch @M@")<Esc><CR>', 'carattere di controllo', false },
  -- giro 2 (25/11): <Cmd> esegue un comando senza mai passare per il byte «:», e «::» salta il nome del comando
  { '<Cmd> esegue Ex senza il due punti', '<Cmd>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<cmd> minuscolo', '<cmd>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<CMD> maiuscolo', '<CMD>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<C-Cmd> con un modificatore', '<C-Cmd>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<S-Cmd> con un modificatore', '<S-Cmd>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<M-Cmd> con un modificatore', '<M-Cmd>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<t_\253h> è <Cmd> scritto come codice di terminale (il byte 0xFD, poi h)', '<t_\253h>call system("touch @M@")<CR>', 'UTF-8', true }, -- si ferma già il file intero: il byte 0xFD non è UTF-8
  { '<Cmd> con Lua', '<Cmd>lua os.execute("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<Cmd> dopo un testo', 'ix<Esc><Cmd>call system("touch @M@")<CR>', 'tasto speciale non ammesso', true },
  { '<Char-58> scrive il due punti', '<Char-58>call system("touch @M@")<CR>', 'comando non ammesso', true },
  { '<M-:> è un due punti con un modificatore', '<M-:>call system("touch @M@")<CR>', 'comando non ammesso', true },
  { '<Plug> non fa niente qui, ma non è nei tasti ammessi', '<Plug>x<CR>', 'tasto speciale non ammesso', false },
  { '<SNR> idem', '<SNR>1_x<CR>', 'tasto speciale non ammesso', false },
  { '<ScriptCmd> non esiste in Neovim: un nome di tasto che non si riconosce', '<ScriptCmd>call system("touch @M@")<CR>', 'nome di tasto sconosciuto', false },
  { '<Lua> idem', '<Lua>x<CR>', 'nome di tasto sconosciuto', false },
  { '<Foo> un nome inventato', 'ix<Foo><Esc>', 'nome di tasto sconosciuto', false },
  { '«::» con un due punti di troppo', '::call system("touch @M@")<CR>', 'comando non ammesso', true },
  { '«:::» con tre', ':::call system("touch @M@")<CR>', 'comando non ammesso', true },
  { '«: :» con uno spazio in mezzo', ': :call system("touch @M@")<CR>', 'comando non ammesso', true },
  { 'un intervallo davanti a un comando non ammesso', ':1,2call system("touch @M@")<CR>', 'comando non ammesso', true },
  { ':silent come modificatore', ':silent call system("touch @M@")<CR>', 'comando non ammesso', true },
  { ':sil abbreviato', ':sil call system("touch @M@")<CR>', 'comando non ammesso', true },
  { ':keepjumps come modificatore', ':keepjumps call system("touch @M@")<CR>', 'comando non ammesso', true },
  { ':silent! col punto esclamativo', ':silent! call system("touch @M@")<CR>', '!', true },
  { ':exe', ':exe "call system(\\"touch @M@\\")"<CR>', 'comando non ammesso', true },
  { ':norm', ':norm :call system("touch @M@")<CR><CR>', 'comando non ammesso', false },
  { ':lua', ':lua os.execute("touch @M@")<CR>', 'comando non ammesso', true },
  { 'un comando che non esiste', ':foo<CR>', 'comando non ammesso', false },
  { ':s e poi un altro comando sulla stessa riga con ::', ':s/a/b/<CR>::call system("touch @M@")<CR>', 'comando non ammesso', true },
  { 'l\'indirizzo \\/ (l\'ultima ricerca) davanti a un comando', '/a<CR>:\\/call system("touch @M@")<CR>', 'comando non ammesso', true },
}

local function tasti(v, marcatore) return (v[2]:gsub('@M@', function() return marcatore end)) end

T['la lista: i tasti ostili sono veri, senza la lista creerebbero il marcatore (nella sandbox)'] = A.con_sandbox(function()
  local compila = require('dattilo.compila')
  local appunti = A.tempname_pulita()
  vim.fn.mkdir(appunti, 'p')
  A.scrivi_byte(appunti .. '/prova.lua', [[
package.path = arg[1] .. '/lua/?.lua;' .. package.path
local f = assert(io.open(arg[2] .. '/tasti', 'rb'))
local sol = f:read('a')
f:close()
require('dattilo.controlla').prova_soluzione({ partenza = { 'a b', 'c d' }, pos = { 0, 0 }, soluzione = sol })
]])
  for i, v in ipairs(VETTORI) do
    local marcatore = appunti .. '/m' .. i
    A.scrivi_byte(appunti .. '/tasti', tasti(v, marcatore))
    local cmd = compila.argomenti_sandbox({ appunti }, { RADICE }, { 'nvim' })
    vim.list_extend(cmd, { '--chdir', appunti, '--', 'nvim', '--clean', '--headless', '-l', appunti .. '/prova.lua', RADICE, appunti })
    vim.system(cmd, { timeout = 10000 }):wait()
    local creato = vim.uv.fs_stat(marcatore) ~= nil
    if v[4] then vero(creato, 'il vettore «' .. v[1] .. '» non crea il marcatore: la prova sul rifiuto non dice niente') end
  end
end)

T['la lista: ogni vettore è rifiutato prima di eseguire qualcosa'] = A.con_sandbox(function()
  for i, v in ipairs(VETTORI) do
    local finti = A.finti()
    local marcatore = finti.appunti .. '/marcatore-' .. i
    local testo = A.con_soluzione(A.con_par_zero(), tasti(v, marcatore))
    local f, env = A.lezione(testo)
    local r = A.prova(f, env, finti.env)
    uguale(r.code, 1, v[1] .. ': ' .. r.stdout .. r.stderr)
    local d = A.json(r)
    uguale(d.ok, false, v[1])
    vero(d.motivo:find(v[3], 1, true), v[1] .. ': il motivo doveva dire «' .. v[3] .. '»: ' .. d.motivo)
    vero(vim.uv.fs_stat(marcatore) == nil, v[1] .. ': il marcatore c\'è, i tasti sono stati eseguiti')
    uguale(finti:chiamate_del_figlio(), {}, v[1] .. ': nemmeno il figlio nella sandbox doveva partire')
    uguale(A.leggi_byte(f), testo, v[1] .. ': il file è com\'era')
  end
end)

T['la lista: la macro qa…q@a resta ammessa, e il par è il numero dei tasti'] = A.con_sandbox(function()
  -- registra l'inserimento, lo annulla e lo rifà con @a: arriva allo stesso obiettivo
  local sol = '2G$qai.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>qu@a'
  local testo = A.con_soluzione(A.con_par_zero(), sol)
  local f, env = A.lezione(testo)
  local r = A.prova(f, env)
  uguale(r.code, 0, r.stdout .. r.stderr)
  local n = require('dattilo.esercizio').conta_tasti(sol)
  uguale(A.json(r), { ok = true, modifiche = { { tasti = n } } })
  uguale(A.leggi_byte(f), (A.cambia(testo, 'par: 0', 'par: ' .. n)))
end)

local function motivo(sol) return formato.soluzione_non_ammessa(sol) end

T['la lista: tasti e comandi innocui restano ammessi'] = function()
  for _, sol in ipairs({
    'qaA;<Esc>jq', 'qa0xjq3@a', 'qqddq@q', 'ci"Andrea<Esc>', ':%s/a/b/g<CR>', ':12<CR>', ':sort<CR>', ':noh<CR>', ':s/a/b/<CR>',
    ":'<,'>s/a/b/<CR>", ":'a,'bs/a/b/<CR>", ':.,+2s/a/b/<CR>', ':5,10sort<CR>', ':$<CR>', ':-1<CR>', ':%s#a#b#g<CR>',
    ':/foo/s/a/b/<CR>', ':*s/a/b/<CR>', ':/foo/;/bar/s/a/b/<CR>', 'A // nota: x<Esc>', 'ci{ color: 0x888888 <Esc>', '/foo<CR>n', 'yyp', 'Vjd',
    ':s/a/b/<Esc>dd', 'ia: b<Esc>', 'i<C-r>a<Esc>', 'i<C-r>"<Esc>', 'o<C-r><C-r>0<Esc>', 'gg<C-f>x'..'', '/a: {<CR>x',
  }) do
    if sol == 'gg<C-f>x' then
      vero(motivo(sol), '<C-f> si rifiuta ovunque: nessuna lezione lo usa')
    else
      uguale(motivo(sol), nil, 'rifiutato un tasto innocuo: ' .. sol)
    end
  end
end

T['la lista: le soluzioni vere del proprietario che toccano i tasti nuovi restano ammesse'] = function()
  for _, sol in ipairs({
    '/new THREE.Quaternion<CR>dw', -- Q maiuscola in una ricerca
    'qajddf[i?.<Esc>f]a?<Esc>q/getA<CR>@a', -- il q che chiude la macro e subito una ricerca
    '/"capsule": {<CR>$x', '/statue: {<CR>%F"a, show: false<Esc>', -- un : dentro una ricerca
    'qa/urls: "<CR>f"i[<Esc>2f"a]<Esc>q@a', 'qa/document.createElement("div<CR>jf"yi"ddk0fdcf)UI.createContainer({ classes: "<C-r>0" })<Esc>q2@a',
  }) do
    uguale(motivo(sol), nil, 'rifiutata una soluzione vera: ' .. sol)
  end
end

T['la lista: Q da sola resta ammessa (in Neovim 0.12 ripete la macro, il modo Ex è gQ), gQ no'] = function()
  uguale(motivo('qaxq@aQ'), nil)
  vero(motivo('gQ'), 'gQ')
  vero(motivo('ix<Esc>gQ'), 'gQ')
end

T['la lista: q: q/ q? fuori da una macro si rifiutano; qa e q@ no; q: si rifiuta sempre'] = function()
  for _, sol in ipairs({ 'q:', 'q/', 'q?', 'xq:', '3q/foo', 'qaxq:s/a/b/<CR>', 'qaxqq/foo<CR>' }) do vero(motivo(sol), sol) end
  for _, sol in ipairs({ 'qa', 'qaq', 'qaxq', 'q@a', 'qaxq/foo<CR>', 'qa/foo<CR>x?bar<CR>q' }) do uguale(motivo(sol), nil, sol) end
end

T['la lista: i tasti speciali dentro un comando : si rifiutano, anche scritti in un altro modo'] = function()
  for _, sol in ipairs({ ':<C-u>s/a/b/<CR>', ':s/a/b/<BS>x<CR>', ':s/<C-r><C-w>/b/<CR>', ':s/a/b/<Left>x<CR>', ':s/a/b/<Tab><CR>', ':s/a/<C-v>b/<CR>' }) do
    vero(motivo(sol), sol)
  end
  -- ma gli stessi tasti fuori da un comando : o in un comando che non parte non danno fastidio
  for _, sol in ipairs({ 'ix<BS>y<Esc>', ':s/a/<C-u><Esc>', 'dd<C-r>' }) do uguale(motivo(sol), nil, sol) end
end

-- Giro 2 (25/11): la lista è a negazione di default. Dei tasti speciali <…> passano solo quelli di un elenco chiuso,
-- dei comandi : solo :s, :sort, :noh e i numeri di riga; il resto si rifiuta, anche se non si riconosce.

T['tasti: quelli dell\'elenco chiuso passano, in tutti i modi di scriverli'] = function()
  for _, sol in ipairs({
    'ix<Esc>', 'ix<esc>', 'ix<ESC>', 'ix<EsC>', 'ix<CR>', 'ix<cr>', 'ix<BS>y<Esc>', 'ix<Tab>y<Esc>', 'ix<S-Tab>y<Esc>', 'ix<Del>',
    'ix<Space>y<Esc>', 'ix<Up><Down><Left><Right><Esc>', 'ix<Home><End><PageUp><PageDown><Esc>', '<C-a><C-x>', '<c-a>', '<C-A>',
    'i<C-r>a<Esc>', 'o<C-v>065<Esc>', 'i<C-o>x<Esc>', 'ia<lt>div><Esc>', 'qa<C-a>q@a', 'ia<Bar>b<Esc>', 'ia<bar>b<Esc>',
  }) do
    uguale(motivo(sol), nil, 'rifiutato un tasto dell\'elenco: ' .. sol)
  end
end

T['tasti: un tasto speciale fuori dall\'elenco si rifiuta, qualunque sia la scrittura (si guarda come lo legge Neovim)'] = function()
  for _, sol in ipairs({
    '<Cmd>x<CR>', '<cmd>x<CR>', '<CMD>x<CR>', '<CmD>x<CR>', '<C-Cmd>x<CR>', '<S-Cmd>x<CR>', '<M-Cmd>x<CR>', '<A-Cmd>x<CR>', '<D-Cmd>x<CR>',
    '<Plug>x', '<plug>x', '<PLUG>x', '<SNR>1_x', '<Nul>', '<C-@>', '<Char-58>', '<char-0x3a>', '<M-:>', '<A-:>', '<C-S-a>',
    '<M-a>', '<F1>', '<LeftMouse>', '<2-LeftMouse>', '<Leader>', '<LocalLeader>', '<kEnter>', '<NL>', '<Return>', '<Enter>', '<Bslash>',
    '<C-\\>', '<C-[>', '<C-]>', '<C-^>', '<C-_>', '<C-Space>', '<C-CR>', '<Ignore>', '<t_xx>', '<*Esc>', '<Insert>', '<Undo>', '<Help>',
    '<k0>', '<S-Del>', '<C-é>', '<t_\253h>x', '<t_ku>',
  }) do
    local m = motivo(sol)
    vero(m, 'passa un tasto fuori dall\'elenco: ' .. sol)
    vero(m:find('tasto speciale non ammesso', 1, true), sol .. ': ' .. tostring(m))
  end
end

T['tasti: un nome <…> che Neovim non riconosce si rifiuta; il testo che gli somiglia no'] = function()
  for _, sol in ipairs({ '<ScriptCmd>x<CR>', '<Lua>x', '<Lua12>', '<Foo>', 'ix<foo><Esc>', '<Nop>', '<script-cmd>', 'i<div><Esc>', 'i<T><Esc>', '<C-Foo>', '<C-ab>' }) do
    local m = motivo(sol)
    vero(m, 'passa un nome che non si riconosce: ' .. sol)
    vero(m:find('nome di tasto sconosciuto', 1, true), sol .. ': ' .. tostring(m))
  end
  -- questi per Neovim sono testo (lo si controlla sul risultato), e come testo passano
  for _, sol in ipairs({ '/\\<sn\\>x<CR>', '/\\<d\\>x<CR>', 'i< Cmd>x<Esc>', 'i<Cmd >x<Esc>', 'i<>x<Esc>', 'ia < b > c<Esc>', 'i#include <stdio.h><Esc>', 'i<a b><Esc>', 'iVec<T, U><Esc>', 'i<<<Esc>' }) do
    uguale(motivo(sol), nil, 'rifiutato un testo: ' .. sol)
    local k = vim.keycode(sol)
    vero(not k:find('\128', 1, true), 'Neovim lo legge come un tasto speciale: ' .. sol)
  end
  -- <lt> è il modo di scrivere un « < » vero, e quello che esce sono lettere, non un tasto: <lt>Cmd> è il testo «<Cmd>»
  uguale(motivo('i<lt>Cmd><Esc>'), nil)
  uguale(vim.keycode('i<lt>Cmd><Esc>'), 'i<Cmd>\27')
end

T['tasti: una catena lunga di modificatori davanti a Cmd è lo stesso <Cmd>, e si rifiuta'] = function()
  local lungo = '<' .. ('C-'):rep(40) .. 'Cmd>x<CR>'
  vero(vim.keycode(lungo):find('\128\253h', 1, true), 'Neovim non lo legge come <Cmd>: la prova non dice niente')
  vero(#lungo > 60, "più lungo del vecchio limite di 40 caratteri")
  local m = motivo(lungo)
  vero(m and m:find('tasto speciale non ammesso', 1, true), tostring(m))
end

-- vim.keycode non ritorna mai se nel testo c'è un byte NUL: un file di lezione con un NUL nella soluzione piantava il
-- padre (che gira fuori dalla sandbox e non ha tetto). Le prove usano `timeout -s KILL`: un nvim in quel giro non si ferma con SIGTERM.
T['un byte NUL nei tasti si rifiuta subito, senza chiedere niente a vim.keycode'] = function()
  local script = A.tempname_pulita() .. '.lua'
  A.scrivi_byte(script, "package.path = arg[1] .. '/lua/?.lua;' .. package.path\n"
    .. "io.stdout:write(tostring(require('dattilo.formato').soluzione_non_ammessa('ix\\0y<Esc>')))\n")
  local r = vim.system({ 'timeout', '-s', 'KILL', '8', 'nvim', '--clean', '--headless', '-l', script, RADICE }, { text = true }):wait()
  uguale(r.signal, 0, 'il padre non è tornato in 8 secondi: è stato ucciso dal timeout')
  uguale(r.code, 0, r.stderr)
  vero(r.stdout:find('carattere di controllo', 1, true), r.stdout)
end

T['un byte NUL in una lezione: vivo --prova dice di no subito (uscita 1) e il file non cambia'] = function()
  local testo = A.con_soluzione(A.con_par_zero(), 'ix\0y<Esc>')
  local f, env = A.lezione(testo)
  local r = vim.system({ 'timeout', '-s', 'KILL', '8', RADICE .. '/bin/dattilo', 'vivo', '--prova', f }, { env = env, text = true }):wait()
  uguale(r.signal, 0, 'vivo --prova non è tornato in 8 secondi: è stato ucciso dal timeout')
  uguale(r.code, 1, 'uscita ' .. r.code .. ' ' .. r.stdout .. r.stderr)
  local d = A.json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('carattere di controllo', 1, true), d.motivo)
  uguale(A.leggi_byte(f), testo)
end

T['tasti: tanti < e > di fila non fanno lavorare il padre più del dovuto'] = function()
  local t = vim.uv.hrtime()
  local m = motivo('i' .. ('<>'):rep(3000) .. ('<a'):rep(3000) .. ('>'):rep(3000) .. '<Esc>')
  local ms = (vim.uv.hrtime() - t) / 1e6
  vero(m, 'una serie di <a> è un nome di tasto sconosciuto')
  vero(ms < 1000, 'ci ha messo ' .. ms .. ' ms')
  t = vim.uv.hrtime()
  uguale(motivo('i' .. ('<>'):rep(6000) .. '<Esc>'), nil)
  ms = (vim.uv.hrtime() - t) / 1e6
  vero(ms < 1000, 'ci ha messo ' .. ms .. ' ms')
end

T['tasti: <SID> non fa uscire messaggi di errore dal padre'] = function()
  local m = motivo('<SID>x')
  vero(m and (m:find('tasto speciale non ammesso', 1, true) or m:find('nome di tasto sconosciuto', 1, true)), tostring(m))
end

T['comandi: un nome che non si riconosce si rifiuta, anche dietro due punti, spazi, intervalli e modificatori'] = function()
  for _, sol in ipairs({
    ':foo<CR>', '::lua x<CR>', ':::lua x<CR>', ': :lua x<CR>', ':  lua x<CR>', ':lua x<CR>', ':2,3lua x<CR>', ':%lua x<CR>', ':.,$lua x<CR>',
    ":'a,'blua x<CR>", ':/a/lua x<CR>', ':\\/lua x<CR>', ':\\?lua x<CR>', ':\\&lua x<CR>', ':1;+2lua x<CR>', ':silent lua x<CR>', ':sil lua x<CR>',
    ':keepjumps lua x<CR>', ':keepj lua x<CR>', ':exe "lua x"<CR>', ':execute "lua x"<CR>', ':norm x<CR>', ':normal x<CR>', ':vert lua x<CR>',
    ':noautocmd lua x<CR>', ':lockmarks lua x<CR>', ':so x<CR>', ':source x<CR>', ':let x=1<CR>', ':set x<CR>', ':map a b<CR>', ':au x<CR>',
    ':g/a/d<CR>', ':v/a/d<CR>', ':b<CR>', ':e x<CR>', ':w<CR>', ':q<CR>', ':call x()<CR>', ':echo 1<CR>', ':k a<CR>', ':ma a<CR>', ':d<CR>', ':y<CR>',
    ':sno/a/b/<CR>', ':sm/a/b/<CR>', ':sg<CR>', ':sa<CR>', ':sort<CR>:lua x<CR>', ':s/a/b/<CR>::lua x<CR>', 'ia<Esc>:lua x<CR>',
    ':<CR>:lua x<CR>', ':2<CR>:3:lua x<CR>', ':%s/a/b/g<CR>:%lua x<CR>',
  }) do
    local m = motivo(sol)
    if sol:match('^:sort<CR>$') then uguale(m, nil, sol) else
      vero(m, 'passa: ' .. sol)
      vero(m:find('comando non ammesso', 1, true), sol .. ': ' .. tostring(m))
    end
  end
end

T['comandi: :s, :sort, :noh, i numeri di riga e il testo con i due punti passano'] = function()
  for _, sol in ipairs({
    ':s/a/b/<CR>', ':%s/a/b/g<CR>', ':substitute/a/b/<CR>', ':sort<CR>', ':sor<CR>', ':sort u<CR>', ':2,4sort<CR>', ':noh<CR>',
    ':nohlsearch<CR>', ':12<CR>', ':$<CR>', ':.<CR>', ':+3<CR>', ':-1<CR>', ":'a<CR>", ':/foo/<CR>', ':/foo/s/a/b/<CR>', ':.,+2s/a/b/<CR>',
    ':*s/a/b/<CR>', ':%s#a#b#g<CR>', ':%s//json/g<CR>', ':<CR>', ': 1.0<CR>', ':  s/a/b/<CR>',
    -- il due punti dentro una ricerca o un testo non è un comando, e Neovim non ne leggerebbe uno (lo si sa dal nome non alfabetico)
    '/"capsule": {<CR>$x', '/statue: {<CR>%F"a, show: false<Esc>', 'qa/urls: "<CR>f"i[<Esc>q@a', '/url:<CR>x',
  }) do
    uguale(motivo(sol), nil, 'rifiutato: ' .. sol)
  end
end

T['comandi: la riga di un comando che sta per partire in Neovim (la guardia del figlio) vale la stessa lista, e più stretta'] = function()
  local ammessi = { 's/a/b/', '%s/a/b/g', '.,+2s/a/b/', 'sort', 'sort u', 'noh', 'nohlsearch', '12', '$', '+3', '&&', '&', 'normal! @a', 'normal! @@', 'normal! @q', 's/a:b/c/', '2,4sort' }
  for _, c in ipairs(ammessi) do uguale(formato.comando_che_parte_non_ammesso(c), nil, 'rifiutato: ' .. c) end
  uguale(formato.comando_che_parte_non_ammesso(''), nil, ':<CR> senza comando non fa niente')
  uguale(formato.comando_che_parte_non_ammesso('  '), nil, ':<CR> senza comando non fa niente')
  for _, c in ipairs({ 'lua x', '::lua x', ' lua x', 'silent s/a/b/', 'sil! s/a/b/', 'keepj s/a/b/', 'normal x', 'normal! x', 'normal @a', 'normal! @a x', 'normal! @=', '!ls', '.!ls',
    '=1', '@a', '*a', '<', '>', 's/a/b/ | lua x', 's/a/b/|lua x', 's/a/\\=system("x")/', 'sort | lua x', 'foo', '{', '"', 'b', 'so x', 's/a/b/\r', 'exe "x"' }) do
    vero(formato.comando_che_parte_non_ammesso(c), 'passa: ' .. c)
  end
end

-- La prova vera: una lezione che cerca di falsificare il verdetto del padre senza toccare il buffer. Lo fa sostituendo
-- vim.json.encode nel figlio, così quello che il padre legge in risultato.json sono le righe dell'obiettivo.
local FALSA = 'local e=vim.json.encode vim.json.encode=function(t) '
  .. 'local L=require("dattilo.formato").lezione(table.concat(vim.fn.readfile(arg[2]),"\\n"),"x",1) '
  .. 'for i,r in ipairs(t) do r.righe=L.modifiche[i].obiettivo end return e(t) end'

for _, v in ipairs({
  { 'con <Cmd>', '<Cmd>lua ' .. FALSA .. '<CR>', 'tasto speciale non ammesso' },
  { 'con ::lua', '::lua ' .. FALSA .. '<CR>', 'comando non ammesso' },
}) do
  T['il verdetto non si falsifica ' .. v[1] .. ': uscita 1, il par del file non cambia'] = A.con_sandbox(function()
    local finti = A.finti()
    local testo = A.con_soluzione(A.con_par_zero(), v[2])
    local f, env = A.lezione(testo)
    local r = A.prova(f, env, finti.env)
    uguale(r.code, 1, r.stdout .. r.stderr)
    local d = A.json(r)
    uguale(d.ok, false)
    vero(d.motivo:find(v[3], 1, true), d.motivo)
    uguale(A.leggi_byte(f), testo, 'il par del file è cambiato')
    uguale(finti:chiamate_del_figlio(), {}, 'il figlio nella sandbox non doveva nemmeno partire')
  end)
end

-- I byte 0x80 0xFD 0x68 sono <Cmd> in forma interna. Un registro che li contiene, eseguito con @a, li rimette tasti: la
-- guardia sulla riga dei comandi non li vede (<Cmd> non passa dalla riga dei comandi). Nel testo della lezione (le righe
-- di partenza sono testo non fidato) non possono stare: un byte 0xFD non esiste in UTF-8 valido, e senza quello nessuna
-- sequenza di tasti speciali pericolosi (Cmd, Plug, SNR, Lua, il mouse: tutti 0x80 0xFD …) arriva nel buffer.
T['utf8_valido: il testo UTF-8 passa, i byte che UTF-8 non ha no'] = function()
  for _, ok in ipairs({ '', 'abc', 'è', '─', '€', '😀', '\244\143\191\191', '\xC2\x80', 'a\xE2\x94\x80b', '\xEF\xBB\xBFtesto' }) do
    vero(formato.utf8_valido(ok), 'rifiutato un UTF-8 valido: ' .. vim.inspect(ok))
  end
  for _, no in ipairs({ '\128', '\253', '\128\253h', '\255', '\192\128', '\193\191', '\224\128\128', '\237\160\128', '\244\144\128\128', '\226\148',
    'a\226', '\245\128\128\128', '\226\148\128\253h', 'ix\128\253hy' }) do
    vero(not formato.utf8_valido(no), 'accettato un UTF-8 non valido: ' .. vim.inspect(no))
  end
end

local function con_riga_in_partenza(testo, riga)
  local da = testo:find('```js partenza\n', 1, true)
  assert(da, 'nella lezione non c\'è il blocco partenza')
  local chiusura = testo:find('\n```\n', da + 15, true)
  assert(chiusura, 'il blocco partenza non si chiude')
  return testo:sub(1, chiusura) .. riga .. '\n' .. testo:sub(chiusura + 1)
end

for _, v in ipairs({
  { 'un comando', function(m) return 'call system("touch ' .. m .. '")' end },
  { 'la falsificazione del verdetto', function() return 'lua ' .. FALSA end },
}) do
  T['byte che non sono UTF-8 nel testo della lezione: ' .. v[1] .. ' portato da un registro non parte, uscita 1, il par non cambia'] = A.con_sandbox(function()
    local finti = A.finti()
    local marcatore = finti.appunti .. '/marcatore'
    local testo = A.con_soluzione(A.con_par_zero(), 'G"ayy@a')
    testo = con_riga_in_partenza(testo, '\128\253h' .. v[2](marcatore))
    local f, env = A.lezione(testo)
    local r = A.prova(f, env, finti.env)
    uguale(r.code, 1, r.stdout .. r.stderr)
    local d = A.json(r)
    uguale(d.ok, false)
    vero(d.motivo:find('UTF-8', 1, true), d.motivo)
    vero(vim.uv.fs_stat(marcatore) == nil, 'il marcatore c\'è: il comando è partito')
    uguale(A.leggi_byte(f), testo, 'il par del file è cambiato')
    uguale(finti:chiamate_del_figlio(), {}, 'il figlio nella sandbox non doveva nemmeno partire')
  end)
end

T['byte che non sono UTF-8 nella soluzione: vivo --prova dice di no, uscita 1'] = A.con_sandbox(function()
  local testo = A.con_soluzione(A.con_par_zero(), 'ix\128\253hy<Esc>')
  local f, env = A.lezione(testo)
  local r = A.prova(f, env)
  uguale(r.code, 1, r.stdout .. r.stderr)
  vero(A.json(r).motivo:find('UTF-8', 1, true))
  uguale(A.leggi_byte(f), testo)
end)

T['il testo UTF-8 vero con byte 0x80 dentro (─, €) resta ammesso nel testo della lezione e nei tasti'] = A.con_sandbox(function()
  local testo = A.con_soluzione(A.con_par_zero(), '2G$i// ─ €<Esc>u' .. A.SOL:sub(5):gsub('<Esc>$', '') .. '<Esc>')
  testo = con_riga_in_partenza(testo, '// ─ € è così')
  local f, env = A.lezione(testo)
  local r = A.prova(f, env)
  -- non ci si aspetta che arrivi all'obiettivo (la partenza ha una riga in più): ci si aspetta un verdetto, non un rifiuto per UTF-8
  local d = A.json(r)
  vero(not (d.motivo or ''):find('UTF-8', 1, true), d.motivo)
end)

-- Quello che la lista dei testi non può vedere: comandi che nascono da un registro o dall'operatore !{movimento}, dove il
-- «:» non è nei tasti. Qui conta la guardia del figlio: ogni riga dei comandi che sta per partire passa dalla stessa lista.
local RUNTIME = {
  { 'un registro riempito con yy e poi eseguito con @a', 'o:call system("touch @M@")<Esc>"ayy@a' },
  { 'un registro che era una macro, riempito con yy e poi eseguito con @q', 'qqxqo:call system("touch @M@")<Esc>"qyy@q' },
  { 'un registro che era una macro, riempito con yy e poi eseguito con Q', 'qqxqo:call system("touch @M@")<Esc>"qyyQ' },
  { 'il testo appena scritto, eseguito con @.', 'i:call system("touch @M@")<Esc>@.<CR>' },
  { 'l\'operatore !{movimento} che apre :.,.+1! e vuole un comando della shell', 'jj!ktouch @M@<CR>' },
  { 'l\'operatore ! con un movimento di una riga', '!jtouch @M@<CR>' },
  { 'un registro riempito con yy e poi eseguito in Visual con @a', 'o:call system("touch @M@")<Esc>"ayyVj@a' },
}

T['la guardia: senza guardia questi comandi nascosti partono davvero nella sandbox'] = A.con_sandbox(function()
  local compila = require('dattilo.compila')
  local appunti = A.tempname_pulita()
  vim.fn.mkdir(appunti, 'p')
  A.scrivi_byte(appunti .. '/prova.lua', [[
package.path = arg[1] .. '/lua/?.lua;' .. package.path
local f = assert(io.open(arg[2] .. '/tasti', 'rb'))
local sol = f:read('a')
f:close()
require('dattilo.controlla').prova_soluzione({ partenza = { 'a b', 'c d', 'e f' }, pos = { 0, 0 }, soluzione = sol })
]])
  for i, v in ipairs(RUNTIME) do
    local marcatore = appunti .. '/m' .. i
    A.scrivi_byte(appunti .. '/tasti', tasti(v, marcatore))
    local cmd = compila.argomenti_sandbox({ appunti }, { RADICE }, { 'nvim' })
    vim.list_extend(cmd, { '--chdir', appunti, '--', 'nvim', '--clean', '--headless', '-l', appunti .. '/prova.lua', RADICE, appunti })
    vim.system(cmd, { timeout = 10000 }):wait()
    vero(vim.uv.fs_stat(marcatore) ~= nil, 'il vettore «' .. v[1] .. '» non crea il marcatore: la prova sulla guardia non dice niente')
  end
end)

T['la guardia: con la guardia del figlio nessuno di questi comandi parte, e il motivo lo dice'] = A.con_sandbox(function()
  local compila = require('dattilo.compila')
  local appunti = A.tempname_pulita()
  vim.fn.mkdir(appunti, 'p')
  A.scrivi_byte(appunti .. '/prova.lua', [[
package.path = arg[1] .. '/lua/?.lua;' .. package.path
local cli = dofile(arg[1] .. '/lua/dattilo/cli.lua')
local f = assert(io.open(arg[2] .. '/tasti', 'rb'))
local sol = f:read('a')
f:close()
local negati = cli.proteggi_figlio()
require('dattilo.controlla').prova_soluzione({ partenza = { 'a b', 'c d', 'e f' }, pos = { 0, 0 }, soluzione = sol })
local o = assert(io.open(arg[2] .. '/negati', 'wb'))
o:write(vim.json.encode(negati))
o:close()
]])
  for i, v in ipairs(RUNTIME) do
    local marcatore = appunti .. '/m' .. i
    A.scrivi_byte(appunti .. '/tasti', tasti(v, marcatore))
    vim.uv.fs_unlink(appunti .. '/negati')
    local cmd = compila.argomenti_sandbox({ appunti }, { RADICE }, { 'nvim' })
    vim.list_extend(cmd, { '--chdir', appunti, '--', 'nvim', '--clean', '--headless', '-l', appunti .. '/prova.lua', RADICE, appunti })
    vim.system(cmd, { timeout = 10000 }):wait()
    vero(vim.uv.fs_stat(marcatore) == nil, v[1] .. ': il marcatore c\'è, il comando è partito')
    local negati = vim.json.decode(A.leggi_byte(appunti .. '/negati'))
    vero(#negati >= 1, v[1] .. ': la guardia non ha fermato niente')
  end
end)

T['la guardia: con vivo --prova una lezione così non arriva a un verdetto buono e il par non cambia'] = A.con_sandbox(function()
  for _, v in ipairs(RUNTIME) do
    local finti = A.finti()
    local marcatore = finti.appunti .. '/marcatore'
    local testo = A.con_soluzione(A.con_par_zero(), tasti(v, marcatore))
    local f, env = A.lezione(testo)
    local r = A.prova(f, env, finti.env)
    uguale(r.code, 1, v[1] .. ': ' .. r.stdout .. r.stderr)
    local d = A.json(r)
    uguale(d.ok, false, v[1])
    vero(d.motivo:find('comando non ammesso', 1, true), v[1] .. ': ' .. d.motivo)
    vero(d.motivo:find('fermato', 1, true), v[1] .. ': il motivo doveva dire che il comando è stato fermato: ' .. d.motivo)
    vero(vim.uv.fs_stat(marcatore) == nil, v[1] .. ': il marcatore c\'è')
    uguale(A.leggi_byte(f), testo, v[1] .. ': il file è com\'era')
  end
end)

T['la guardia: &, @a in Visual (che passano per i comandi : delle mappature di Neovim) e Q funzionano come senza guardia'] = A.con_sandbox(function()
  local compila = require('dattilo.compila')
  local appunti = A.tempname_pulita()
  vim.fn.mkdir(appunti, 'p')
  A.scrivi_byte(appunti .. '/prova.lua', [[
package.path = arg[1] .. '/lua/?.lua;' .. package.path
local f = assert(io.open(arg[2] .. '/caso', 'rb'))
local caso = vim.json.decode(f:read('a'))
f:close()
local negati = {}
if arg[3] == 'con' then negati = dofile(arg[1] .. '/lua/dattilo/cli.lua').proteggi_figlio() end
local righe = require('dattilo.controlla').prova_soluzione({ partenza = caso.partenza, pos = { 0, 0 }, soluzione = caso.sol })
local o = assert(io.open(arg[2] .. '/uscita-' .. arg[3], 'wb'))
o:write(vim.json.encode({ righe = righe, negati = negati }))
o:close()
]])
  local function lancia(modo)
    local cmd = compila.argomenti_sandbox({ appunti }, { RADICE }, { 'nvim' })
    vim.list_extend(cmd, { '--chdir', appunti, '--', 'nvim', '--clean', '--headless', '-l', appunti .. '/prova.lua', RADICE, appunti, modo })
    vim.system(cmd, { timeout = 10000 }):wait()
    return vim.json.decode(A.leggi_byte(appunti .. '/uscita-' .. modo))
  end
  for _, c in ipairs({
    { sol = ':s/a/X/<CR>j&', partenza = { 'aaa', 'aaa' }, atteso = { 'Xaa', 'Xaa' } },
    { sol = 'qaA!<Esc>qjVj@a', partenza = { 'a', 'b', 'c' }, atteso = { 'a!', 'b!', 'c!' } },
    { sol = 'qaxqjQ', partenza = { 'abc', 'def' }, atteso = { 'bc', 'ef' } },
    { sol = 'qaA!<Esc>qjVjQ', partenza = { 'a', 'b', 'c' }, atteso = { 'a!', 'b!', 'c!' } }, -- Q in Visual-linea legge reg_recorded() con <C-r>=
    { sol = ':%s/a/b/g<CR>:noh<CR>:2<CR>:sort<CR>', partenza = { 'a', 'c', 'a' }, atteso = { 'b', 'b', 'c' } },
    -- % passa dai comandi : di matchit, che Neovim carica da solo (lezioni vere: aton 03-ui-html, javascript 10-classi…)
    { sol = '%x', partenza = { '(a)' }, atteso = { '(a' } },
    { sol = 'd%', partenza = { '(a) b' }, atteso = { ' b' } },
    { sol = 'v%d', partenza = { '(a) b' }, atteso = { ' b' } },
    { sol = '$g%x', partenza = { '(a) b)' }, atteso = { '(a) b' } },
    { sol = '$vg%d', partenza = { '(a) b' }, atteso = { '(a) ' } },
    { sol = 'f(]%x', partenza = { 'x (a) (b)' }, atteso = { 'x (a (b)' } },
    { sol = 'f)[%x', partenza = { 'x (a) (b)' }, atteso = { 'x a) (b)' } },
  }) do
    A.scrivi_byte(appunti .. '/caso', vim.json.encode(c))
    local senza, con = lancia('senza'), lancia('con')
    uguale(senza.righe, c.atteso, c.sol .. ' (senza la guardia)')
    uguale(con.negati, {}, c.sol .. ': la guardia ha fermato qualcosa')
    uguale(con.righe, c.atteso, c.sol .. ' (con la guardia)')
  end
end)

return T
