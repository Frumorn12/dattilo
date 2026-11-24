-- Formato dei pacchetti: pacchetto.json e lezioni in Markdown. Solo lettura di dati, mai codice.
local M = {}

local TIPI = { compila = true, comando = true, controllo = true }

-- I pacchetti si scambiano: i comandi che possono chiedere sono una lista chiusa.
local COMPILATORI = { cc = true, gcc = true, clang = true }
local OPZIONI_CC = { '^%-W[%w%-=]*$', '^%-O[0-3sgz]?$', '^%-g%d?$', '^%-std=[%w+]+$', '^%-fdiagnostics%-color=%a+$',
  '^%-fsanitize=[%a,]+$', '^%-pedantic$', '^%-l%w+$' }

local function comando_compila_ok(c)
  if type(c) ~= 'table' or not COMPILATORI[c[1]] then return false, 'compila deve iniziare con cc, gcc o clang' end
  local i = 2
  while i <= #c do
    local a = c[i]
    if a == '-o' then
      if c[i + 1] ~= '{nome}' then return false, '-o deve essere seguito da {nome}' end
      i = i + 1
    elseif a ~= '{file}' and a ~= '{nome}' then
      local ok = false
      for _, p in ipairs(OPZIONI_CC) do if type(a) == 'string' and a:match(p) then ok = true break end end
      if not ok then return false, 'opzione del compilatore non ammessa: ' .. tostring(a) end
    end
    i = i + 1
  end
  return true
end

local function comando_node_ok(c)
  if type(c) ~= 'table' or c[1] ~= 'node' then return false, 'il comando deve essere node' end
  local file = false
  for i = 2, #c do
    if c[i] == '{file}' then file = true
    elseif c[i] ~= '--check' then return false, 'argomento di node non ammesso: ' .. tostring(c[i]) end
  end
  if not file then return false, 'il comando deve contenere {file}' end
  return true
end

-- Controlla un'esecuzione: ritorna nil se va bene, altrimenti il motivo.
function M.esecuzione_non_ammessa(es)
  if type(es) ~= 'table' or not TIPI[es.tipo] then return 'esecuzione.tipo deve essere compila, comando o controllo' end
  if es.tipo == 'compila' then
    local ok, msg = comando_compila_ok(es.compila)
    if not ok then return msg end
    if type(es.esegui) ~= 'table' or #es.esegui ~= 1 or es.esegui[1] ~= './{nome}' then return 'esegui deve essere ["./{nome}"]' end
    return nil
  end
  local ok, msg = comando_node_ok(es.comando)
  if not ok then return msg end
  return nil
end

local ESTENSIONI_CODICE = { c = true, js = true, mjs = true, cjs = true }

-- Le soluzioni le esegue il verificatore: dei comandi ':' sono ammessi solo questi (più i numeri di riga).
local EX_PERMESSI = { s = true, substitute = true, sor = true, sort = true, noh = true, nohlsearch = true }

local INVIO = { cr = true, enter = true, ['return'] = true, nl = true, ['c-m'] = true, ['c-j'] = true }

-- Comandi ':' che la soluzione esegue davvero (chiusi da un Invio), con i tasti speciali in mezzo.
local function comandi_eseguiti(sol)
  local out, i = {}, 1
  while true do
    local p = sol:find(':', i, true)
    if not p then break end
    local j, testo, eseguito = p + 1, '', false
    while j <= #sol do
      local tok = sol:match('^<[^<>]+>', j)
      if tok then
        local t = tok:sub(2, -2):lower()
        if INVIO[t] then eseguito = true break end
        if t == 'esc' or t == 'c-c' or t == 'c-[' then break end
        testo, j = testo .. tok, j + #tok
      else
        testo, j = testo .. sol:sub(j, j), j + 1
      end
    end
    if eseguito then out[#out + 1] = testo i = j + 1 else i = p + 1 end
  end
  return out
end

function M.soluzione_non_ammessa(sol)
  if sol:find('<C-r>=', 1, true) or sol:find('<C-R>=', 1, true) or sol:find('\\=', 1, true) or sol:find('!!', 1, true) then
    return 'la soluzione usa espressioni o filtri della shell'
  end
  if sol:find('[\r\n]') then return 'la soluzione contiene un a capo vero: usa <CR>' end
  for _, testo in ipairs(comandi_eseguiti(sol)) do
    if testo:find('[!|]') then return 'la soluzione usa un comando con ! o |' end
    local nome = testo:gsub('<[^<>]+>', ''):match("^[%s%d,.%%$'<>]*(%a+)")
    if nome and not EX_PERMESSI[nome] then return 'comando non ammesso nella soluzione: :' .. nome .. ' (ammessi :s, :sort, :noh e i numeri di riga)' end
  end
  return nil
end


local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end

-- Toglie le virgolette da un valore; "..." accetta \" e \\.
local function scalare(v)
  v = trim(v)
  local d = v:match('^"(.*)"$')
  if d then return (d:gsub('\\(.)', '%1')) end
  local s = v:match("^'(.*)'$")
  if s then return s end
  return v
end

local function valore(v)
  v = trim(v)
  local dentro = v:match('^%[(.*)%]$')
  if not dentro then return scalare(v) end
  local out, cur, q, i = {}, '', nil, 1
  while i <= #dentro do
    local c = dentro:sub(i, i)
    if q then
      if c == '\\' and q == '"' then cur = cur .. c .. dentro:sub(i + 1, i + 1) i = i + 1
      elseif c == q then q = nil cur = cur .. c
      else cur = cur .. c end
    elseif c == '"' or c == "'" then q = c cur = cur .. c
    elseif c == ',' then out[#out + 1] = scalare(cur) cur = ''
    else cur = cur .. c end
    i = i + 1
  end
  if trim(cur) ~= '' then out[#out + 1] = scalare(cur) end
  return out
end

-- Front matter tra due righe '---'. Ritorna tabella, righe del corpo, numero della prima riga del corpo, errori.
function M.front_matter(testo, nome)
  testo = testo:gsub('^\239\187\191', ''):gsub('\r\n', '\n') -- BOM e fine riga di Windows
  local righe = vim.split(testo, '\n', { plain = true })
  local err = {}
  if righe[1] ~= '---' then return {}, righe, 1, err end
  local fm = {}
  for i = 2, #righe do
    if righe[i] == '---' then
      return fm, vim.list_slice(righe, i + 1), i + 1, err
    end
    local k, v = righe[i]:match('^([%w_]+):%s*(.*)$')
    if k then fm[k] = valore(v)
    elseif righe[i]:match('%S') then err[#err + 1] = { file = nome, riga = i, msg = 'riga non valida nel front matter' } end
  end
  err[#err + 1] = { file = nome, riga = 1, msg = 'front matter senza --- di chiusura' }
  return fm, {}, #righe + 1, err
end

local CHIAVI = { consegna = true, aiuto = true, par = true, soluzione = true, mostra = true, pos = true,
  attesa = true, cerca = true, dopo = true, titolo = true, motivo = true }

-- Divide il corpo in sezioni ## e sottosezioni ###, con blocchi di codice e coppie chiave: valore.
local function sezioni(righe, prima)
  local out, sez, sotto = {}, nil, nil
  local i = 1
  local function bersaglio() return sotto or sez end
  while i <= #righe do
    local l, n = righe[i], prima + i - 1
    local apertura, info = l:match('^(```+)%s*(.-)%s*$')
    if apertura and sez then
      local blocco = { info = info, righe = {}, riga = n }
      i = i + 1
      while i <= #righe and not righe[i]:match('^' .. apertura .. '`*%s*$') do
        blocco.righe[#blocco.righe + 1] = righe[i]
        i = i + 1
      end
      local b = bersaglio()
      b.blocchi[#b.blocchi + 1] = blocco
    elseif l:match('^## ') then
      local nome = trim(l:sub(4))
      local base, titolo = nome:match('^(%S+):%s*(.+)$')
      sez = { nome = base or nome, titolo = titolo, riga = n, testo = {}, kv = {}, blocchi = {}, sotto = {} }
      sotto = nil
      out[#out + 1] = sez
    elseif l:match('^### ') and sez then
      sotto = { nome = trim(l:sub(5)), riga = n, testo = {}, kv = {}, blocchi = {} }
      sez.sotto[sotto.nome] = sotto
    elseif sez then
      local k, v = l:match('^([%w_]+):%s*(.*)$')
      local b = bersaglio()
      if k and CHIAVI[k] and not sotto then b.kv[k] = { v = v, riga = n }
      else b.testo[#b.testo + 1] = { t = l, riga = n } end
    end
    i = i + 1
  end
  return out
end

local function testo_unico(righe)
  local parti = {}
  for _, r in ipairs(righe) do if r.t:match('%S') then parti[#parti + 1] = trim(r.t) end end
  return table.concat(parti, ' ')
end

local function corto(s, n)
  s = s:gsub('‹(.-)›', '%1')
  if vim.fn.strchars(s) <= n then return s end
  return vim.fn.strcharpart(s, 0, n - 1) .. '…'
end

-- Le righe di `### Tasti`: `- <tasti> | <cosa fanno>`, divise al primo ' | '.
-- I tasti restano com'è scritto (anche uno spazio davanti: fa parte dei tasti), la spiegazione si ripulisce.
-- Ritorna la lista { { tasti, cosa } }, o nil dopo aver segnalato le righe non valide.
local function leggi_tasti(sotto, e)
  local out, valida = {}, true
  for _, r in ipairs(sotto.testo) do
    if r.t:match('%S') then
      local resto = r.t:match('^%- (.*)$')
      local da, a
      if resto then da, a = resto:find(' | ', 1, true) end
      local tasti = da and resto:sub(1, da - 1)
      local cosa = da and trim(resto:sub(a + 1))
      if tasti and tasti ~= '' and cosa ~= '' then
        out[#out + 1] = { tasti = tasti, cosa = cosa }
      else
        e(r.riga, 'riga non valida nei Tasti: scrivi - tasti | cosa fanno')
        valida = false
      end
    end
  end
  return valida and out or nil
end

function M.lezione(testo, nome_file, indice, opzioni)
  local err = {}
  local function e(riga, msg) err[#err + 1] = { file = nome_file, riga = riga, msg = msg } end
  local fm, corpo, prima, err_fm = M.front_matter(testo, nome_file)
  vim.list_extend(err, err_fm)
  for _, k in ipairs({ 'titolo', 'breve', 'file', 'tempo', 'fonte', 'etichetta', 'video', 'durata', 'video_da', 'esecuzione' }) do
    if fm[k] ~= nil and type(fm[k]) ~= 'string' then e(1, k .. ' deve essere un testo') fm[k] = nil end
  end
  for _, k in ipairs({ 'mosse', 'concetti', 'comando' }) do
    if fm[k] ~= nil and (type(fm[k]) ~= 'table' or #vim.tbl_filter(function(x) return type(x) ~= 'string' end, fm[k]) > 0) then
      e(1, k .. ' deve essere una lista di testi, es. [a, b]') fm[k] = nil
    end
  end
  if fm.video == '' then e(1, 'video vuoto') fm.video = nil end
  if fm.video_da and not fm.video_da:match('^%d+:%d%d$') then e(1, 'video_da deve essere mm:ss') end
  if not fm.titolo or fm.titolo == '' then e(1, 'manca titolo nel front matter') end
  if not fm.file or fm.file == '' then e(1, 'manca file nel front matter')
  else
    local ext = type(fm.file) == 'string' and fm.file:match('^[%w][%w_%-]*%.(%w+)$')
    if not ext or not ESTENSIONI_CODICE[ext] then e(1, 'file deve essere un nome semplice come main.js o hello.c') end
  end
  local L = {
    id = nome_file:gsub('%.md$', ''), numero = indice, etichetta = fm.etichetta or string.format('%02d', indice),
    titolo = fm.titolo, breve = fm.breve or fm.titolo, file = fm.file, fonte = fm.fonte, tempo = fm.tempo,
    mosse = type(fm.mosse) == 'table' and fm.mosse or {}, concetti = type(fm.concetti) == 'table' and fm.concetti or {},
    briefing = '', modifiche = {}, esegui = {}, spiegazione = { note = {}, momenti = {} },
  }
  if fm.video then L.video = { id = fm.video, durata = fm.durata, da = fm.video_da or '00:00' } end
  if fm.esecuzione then
    L.esecuzione = { tipo = fm.esecuzione, comando = type(fm.comando) == 'table' and fm.comando or nil }
    if fm.esecuzione == 'compila' then e(1, 'una lezione non può cambiare la compilazione del pacchetto')
    elseif L.esecuzione.comando then
      local motivo = M.esecuzione_non_ammessa(L.esecuzione)
      if motivo then e(1, motivo) end
    elseif not TIPI[fm.esecuzione] then e(1, 'esecuzione deve essere comando o controllo') end
  end
  local passi
  for _, s in ipairs(sezioni(corpo, prima)) do
    if s.nome == 'Briefing' then
      L.briefing = testo_unico(s.testo)
    elseif s.nome == 'Passi' then
      passi = {}
      for _, r in ipairs(s.testo) do
        local a, b = r.t:match('^%-%s*(.-)%s*|%s*(.*)$')
        if a then passi[#passi + 1] = { a, b } end
      end
    elseif s.nome == 'Batti' then
      if not s.blocchi[1] then e(s.riga, 'la sezione Batti non ha un blocco di codice') end
      L.batti = { codice = s.blocchi[1] and s.blocchi[1].righe or {}, suggerimenti = {}, blocchi = {} }
      local codice = L.batti.codice
      local sg = s.sotto['Suggerimenti']
      if sg then
        for _, r in ipairs(sg.testo) do
          local n, t = r.t:match('^(%d+):%s*(.*)$')
          if n then
            n = tonumber(n)
            if n < 1 or n > #codice then e(r.riga, 'suggerimento sulla riga ' .. n .. ', fuori dal codice (' .. #codice .. ' righe)')
            elseif not codice[n]:match('%S') then e(r.riga, 'suggerimento sulla riga ' .. n .. ', che è vuota')
            else L.batti.suggerimenti[n] = t end
          end
        end
      end
      local bl = s.sotto['Blocchi']
      if bl then
        local fine = 0
        for _, r in ipairs(bl.testo) do
          local da, a, t = r.t:match('^(%d+)%-(%d+):%s*(.*)$')
          if not da then
            local solo
            solo, t = r.t:match('^(%d+):%s*(.*)$')
            da, a = solo, solo
          end
          if da then
            da, a = tonumber(da), tonumber(a)
            local parti = vim.tbl_map(trim, vim.split(' ' .. t .. ' ', ' | ', { plain = true }))
            if da > a then e(r.riga, 'blocco ' .. da .. '-' .. a .. ': la prima riga viene dopo l\'ultima')
            elseif da < 1 or a > #codice then e(r.riga, 'blocco ' .. da .. '-' .. a .. ' fuori dal codice (' .. #codice .. ' righe)')
            elseif da <= fine then e(r.riga, 'blocco ' .. da .. '-' .. a .. ' sovrapposto o fuori ordine (il precedente finisce alla riga ' .. fine .. ')')
            elseif (parti[1] or '') == '' then e(r.riga, 'blocco ' .. da .. '-' .. a .. ' senza titolo')
            else
              L.batti.blocchi[#L.batti.blocchi + 1] = { da = da, a = a, titolo = parti[1], cosa = parti[2] ~= '' and parti[2] or nil,
                quadro = parti[3] ~= '' and parti[3] or nil }
              fine = a
            end
          elseif r.t:match('%S') then e(r.riga, 'riga non valida nei Blocchi: scrivi da-a: Titolo | cosa fa | quadro')
          end
        end
      end
    elseif s.nome == 'Uscita' then
      if s.blocchi[1] then L.esegui = { atteso = table.concat(s.blocchi[1].righe, '\n') .. '\n' } end
    elseif s.nome == 'Modifica' then
      local kv = s.kv
      local m = { titolo = s.titolo, consegna = kv.consegna and kv.consegna.v or '', aiuto = kv.aiuto and kv.aiuto.v or '',
        soluzione = kv.soluzione and kv.soluzione.v, pos = { 0, 0 }, motivo = kv.motivo and kv.motivo.v ~= '' and kv.motivo.v or nil }
      local par = kv.par and tonumber(kv.par.v)
      if not par then e(kv.par and kv.par.riga or s.riga, 'par mancante o non numerico') end
      m.par = par
      if not m.soluzione or m.soluzione == '' then e(s.riga, 'manca soluzione nella Modifica')
      else
        local motivo = M.soluzione_non_ammessa(m.soluzione)
        if motivo then e(kv.soluzione.riga, motivo) end
      end
      -- il blocco con `partenza` nell'info è il codice da cui si parte; l'obiettivo è il primo blocco senza
      local partenza_propria, obiettivo
      for _, b in ipairs(s.blocchi) do
        if b.info:match('%f[%w]partenza$') then
          if partenza_propria then e(b.riga, 'la Modifica ha due blocchi partenza') else partenza_propria = b end
        elseif not obiettivo then obiettivo = b end
      end
      if not obiettivo then e(s.riga, 'la Modifica non ha il blocco con il testo obiettivo') end
      m.obiettivo = obiettivo and obiettivo.righe or {}
      m.blocco = obiettivo and { riga = obiettivo.riga, n = #obiettivo.righe } -- per dattilo riempi
      m.partenza_propria = partenza_propria and partenza_propria.righe
      m.par_riga = kv.par and kv.par.riga
      m.mostra = kv.mostra and vim.tbl_map(trim, vim.split(kv.mostra.v, ' · ', { plain = true })) or { m.soluzione }
      local tasti = s.sotto['Tasti']
      if tasti then
        m.tasti = leggi_tasti(tasti, e)
        if m.tasti then
          m.mostra = vim.tbl_map(function(t) return t.tasti end, m.tasti)
          if m.soluzione and table.concat(m.mostra) ~= m.soluzione then
            e(tasti.riga, 'i Tasti messi in fila non sono la soluzione')
          end
        end
      end
      if kv.pos then
        local r, c = kv.pos.v:match('^(%d+):(%d+)$')
        if r then m.pos, m.pos_riga = { tonumber(r) - 1, tonumber(c) - 1 }, kv.pos.riga else e(kv.pos.riga, 'pos deve essere riga:colonna, es. 3:5') end
      end
      L.modifiche[#L.modifiche + 1] = m
    elseif s.nome == 'Rompi' then
      local kv = s.kv
      L.rompi = { titolo = s.titolo or 'Rompilo', consegna = kv.consegna and kv.consegna.v or '', attesa = kv.attesa and kv.attesa.v or 'errore',
        cerca = kv.cerca and kv.cerca.v, dopo = kv.dopo and kv.dopo.v or '‹u› annulla, poi ‹:w›.', esempio = s.blocchi[1] and s.blocchi[1].righe }
      -- facoltativa: i tasti che rompono il codice, usati da dattilo riempi per scrivere l'esempio
      if kv.soluzione and kv.soluzione.v ~= '' then
        L.rompi.soluzione = kv.soluzione.v
        local motivo = M.soluzione_non_ammessa(kv.soluzione.v)
        if motivo then e(kv.soluzione.riga, motivo) end
      end
      L.rompi.blocco = s.blocchi[1] and { riga = s.blocchi[1].riga, n = #s.blocchi[1].righe }
      if L.rompi.attesa ~= 'errore' and L.rompi.attesa ~= 'warning' then e(kv.attesa.riga, 'attesa deve essere errore o warning') end
      if L.rompi.consegna == '' then e(s.riga, 'manca consegna nel Rompi') end
      if not L.rompi.esempio then e(s.riga, 'Rompi vuole un blocco con il testo rotto d\'esempio') end
    elseif s.nome == 'Spiegazione' then
      for _, r in ipairs(s.testo) do
        local n, t = r.t:match('^(%d+):%s*(.*)$')
        if n then L.spiegazione.note[tonumber(n)] = vim.tbl_map(trim, vim.split(t, ' | ', { plain = true })) end
      end
      local mo = s.sotto['Momenti']
      if mo then
        for _, r in ipairs(mo.testo) do
          local t, cosa = r.t:match('^%-%s*(%d+:%d+)%s+(.*)$')
          if t then L.spiegazione.momenti[#L.spiegazione.momenti + 1] = { t, cosa } end
        end
      end
      if s.sotto['Trappola'] then L.spiegazione.trappola = testo_unico(s.sotto['Trappola'].testo) end
      if s.sotto['Prova'] then L.spiegazione.prova = testo_unico(s.sotto['Prova'].testo) end
    end
  end
  if not L.batti then e(prima, 'manca la sezione ## Batti') end
  -- ogni modifica parte dall'obiettivo della precedente
  local partenza = L.batti and L.batti.codice or {}
  for i, m in ipairs(L.modifiche) do
    m.partenza = m.partenza_propria or partenza -- con un blocco partenza proprio si parte da lì
    local riga = m.partenza[m.pos[1] + 1]
    -- dattilo riempi legge la lezione mentre i blocchi obiettivo sono ancora da scrivere
    if (not riga or m.pos[2] > math.max(0, #riga - 1)) and not (opzioni and opzioni.riempi) then e(m.pos_riga or 1, 'pos fuori dal testo di partenza') end
    m.titolo = m.titolo or ('Modifica ' .. i .. '/' .. #L.modifiche)
    partenza = m.obiettivo
  end
  if L.rompi then L.rompi.ripara = partenza end
  if not passi then
    passi = { { 'Batti il codice', 'il codice è in grigio, lo copri scrivendo' } }
    for _, m in ipairs(L.modifiche) do passi[#passi + 1] = { m.titolo, corto(m.consegna, 48) } end
    if L.rompi then passi[#passi + 1] = { L.rompi.titolo, 'leggi l\'errore vero, poi riparalo' } end
    passi[#passi + 1] = { 'Capisci', 'riga per riga' }
  end
  L.passi = passi
  if #err > 0 then return nil, err end
  return L, err
end

-- Controlli che servono l'esecuzione effettiva della lezione (quella del pacchetto o la sua).
function M.coerenza(L)
  if L.rompi and L.rompi.attesa == 'warning' and (not L.esecuzione or L.esecuzione.tipo ~= 'compila') then
    return 'attesa: warning vale solo per i pacchetti che compilano (C)'
  end
  return nil
end

local function nullo(x) return x == nil or x == vim.NIL end

function M.manifesto(testo, nome)
  testo = testo:gsub('^\239\187\191', '')
  local err = {}
  local function e(msg) err[#err + 1] = { file = nome, riga = 1, msg = msg } end
  local ok, m = pcall(vim.json.decode, testo)
  if not ok or type(m) ~= 'table' then
    e('JSON non valido: ' .. tostring(m):gsub('^.-: ', ''))
    return nil, err
  end
  if type(m.id) ~= 'string' or not m.id:match('^[a-z0-9%-]+$') then e('id mancante o non valido (solo minuscole, cifre e trattini)') end
  if type(m.titolo) ~= 'string' or m.titolo == '' then e('manca titolo') end
  if type(m.versione) ~= 'string' or not m.versione:match('^[%w.%-]+$') then e('versione mancante o non valida (es. 0.1.0)') end
  for _, k in ipairs({ 'autore', 'descrizione', 'linguaggio', 'percorso' }) do
    if nullo(m[k]) then m[k] = nil elseif type(m[k]) ~= 'string' then e(k .. ' deve essere un testo') end
  end
  if nullo(m.richiede) then m.richiede = nil
  elseif type(m.richiede) ~= 'table' or #vim.tbl_filter(function(x) return type(x) ~= 'string' or not x:match('^[a-z0-9%-]+$') end, m.richiede) > 0 then
    e('richiede deve essere una lista di id, es. ["aton"]')
  end
  if nullo(m.in_arrivo) then m.in_arrivo = nil
  elseif type(m.in_arrivo) ~= 'table' then e('in_arrivo deve essere una lista')
  else
    for _, x in ipairs(m.in_arrivo) do
      if type(x) ~= 'table' then e('ogni voce di in_arrivo deve essere un oggetto') break end
      for _, k in ipairs({ 'etichetta', 'titolo', 'durata', 'video' }) do
        if x[k] ~= nil and type(x[k]) ~= 'string' then e('in_arrivo: ' .. k .. ' deve essere un testo') break end
      end
    end
  end
  local motivo = M.esecuzione_non_ammessa(m.esecuzione)
  if motivo then e(motivo) end
  if #err > 0 then return nil, err end
  m.richiede = type(m.richiede) == 'table' and m.richiede or {}
  m.in_arrivo = type(m.in_arrivo) == 'table' and m.in_arrivo or {}
  m.linguaggio = m.linguaggio or 'c'
  m.autore, m.descrizione = m.autore or '', m.descrizione or ''
  return m, err
end

return M
