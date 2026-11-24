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
}

local function tasti(v, marcatore) return (v[2]:gsub('@M@', function() return marcatore end)) end

T['la lista: i tasti ostili sono veri, senza la lista creerebbero il marcatore (nella sandbox)'] = A.con_sandbox(function()
  local compila = require('dattilo.compila')
  local appunti = vim.fn.tempname()
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

return T
