-- Formato dei pacchetti: pacchetto.json e lezioni in Markdown. Solo lettura di dati, mai codice.
local M = {}

local TIPI = { compila = true, comando = true, controllo = true }

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
  attesa = true, cerca = true, dopo = true, titolo = true }

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

function M.lezione(testo, nome_file, indice)
  local err = {}
  local function e(riga, msg) err[#err + 1] = { file = nome_file, riga = riga, msg = msg } end
  local fm, corpo, prima, err_fm = M.front_matter(testo, nome_file)
  vim.list_extend(err, err_fm)
  if not fm.titolo or fm.titolo == '' then e(1, 'manca titolo nel front matter') end
  if not fm.file or fm.file == '' then e(1, 'manca file nel front matter') end
  local L = {
    id = nome_file:gsub('%.md$', ''), numero = indice, etichetta = fm.etichetta or string.format('%02d', indice),
    titolo = fm.titolo, breve = fm.breve or fm.titolo, file = fm.file, fonte = fm.fonte, tempo = fm.tempo,
    mosse = type(fm.mosse) == 'table' and fm.mosse or {}, concetti = type(fm.concetti) == 'table' and fm.concetti or {},
    briefing = '', modifiche = {}, esegui = {}, spiegazione = { note = {}, momenti = {} },
  }
  if fm.video then L.video = { id = fm.video, durata = fm.durata, da = fm.video_da or '00:00' } end
  if fm.esecuzione then L.esecuzione = { tipo = fm.esecuzione, comando = type(fm.comando) == 'table' and fm.comando or nil } end
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
      L.batti = { codice = s.blocchi[1] and s.blocchi[1].righe or {}, suggerimenti = {} }
      local sg = s.sotto['Suggerimenti']
      if sg then
        for _, r in ipairs(sg.testo) do
          local n, t = r.t:match('^(%d+):%s*(.*)$')
          if n then L.batti.suggerimenti[tonumber(n)] = t end
        end
      end
    elseif s.nome == 'Uscita' then
      if s.blocchi[1] then L.esegui = { atteso = table.concat(s.blocchi[1].righe, '\n') .. '\n' } end
    elseif s.nome == 'Modifica' then
      local kv = s.kv
      local m = { titolo = s.titolo, consegna = kv.consegna and kv.consegna.v or '', aiuto = kv.aiuto and kv.aiuto.v or '',
        soluzione = kv.soluzione and kv.soluzione.v, pos = { 0, 0 } }
      local par = kv.par and tonumber(kv.par.v)
      if not par then e(kv.par and kv.par.riga or s.riga, 'par mancante o non numerico') end
      m.par = par
      if not m.soluzione or m.soluzione == '' then e(s.riga, 'manca soluzione nella Modifica') end
      if not s.blocchi[1] then e(s.riga, 'la Modifica non ha il blocco con il testo obiettivo') end
      m.obiettivo = s.blocchi[1] and s.blocchi[1].righe or {}
      m.mostra = kv.mostra and vim.tbl_map(trim, vim.split(kv.mostra.v, ' · ', { plain = true })) or { m.soluzione }
      if kv.pos then
        local r, c = kv.pos.v:match('^(%d+):(%d+)$')
        if r then m.pos = { tonumber(r) - 1, tonumber(c) - 1 } else e(kv.pos.riga, 'pos deve essere riga:colonna, es. 3:5') end
      end
      L.modifiche[#L.modifiche + 1] = m
    elseif s.nome == 'Rompi' then
      local kv = s.kv
      L.rompi = { titolo = s.titolo or 'Rompilo', consegna = kv.consegna and kv.consegna.v or '', attesa = kv.attesa and kv.attesa.v or 'errore',
        cerca = kv.cerca and kv.cerca.v, dopo = kv.dopo and kv.dopo.v or '‹u› annulla, poi ‹:w›.', esempio = s.blocchi[1] and s.blocchi[1].righe }
      if L.rompi.attesa ~= 'errore' and L.rompi.attesa ~= 'warning' then e(kv.attesa.riga, 'attesa deve essere errore o warning') end
      if L.rompi.consegna == '' then e(s.riga, 'manca consegna nel Rompi') end
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
    m.partenza = partenza
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

function M.manifesto(testo, nome)
  local err = {}
  local function e(msg) err[#err + 1] = { file = nome, riga = 1, msg = msg } end
  local ok, m = pcall(vim.json.decode, testo)
  if not ok or type(m) ~= 'table' then
    e('JSON non valido: ' .. tostring(m):gsub('^.-: ', ''))
    return nil, err
  end
  if type(m.id) ~= 'string' or not m.id:match('^[a-z0-9%-]+$') then e('id mancante o non valido (solo minuscole, cifre e trattini)') end
  if type(m.titolo) ~= 'string' or m.titolo == '' then e('manca titolo') end
  if type(m.versione) ~= 'string' or m.versione == '' then e('manca versione') end
  local es = m.esecuzione
  if type(es) ~= 'table' or not TIPI[es.tipo] then e('esecuzione.tipo deve essere compila, comando o controllo')
  elseif es.tipo == 'compila' and (type(es.compila) ~= 'table' or type(es.esegui) ~= 'table') then e('esecuzione compila vuole gli array compila ed esegui')
  elseif es.tipo ~= 'compila' and type(es.comando) ~= 'table' then e('esecuzione ' .. es.tipo .. ' vuole l\'array comando') end
  if #err > 0 then return nil, err end
  m.richiede = type(m.richiede) == 'table' and m.richiede or {}
  m.in_arrivo = type(m.in_arrivo) == 'table' and m.in_arrivo or {}
  m.linguaggio = m.linguaggio or 'c'
  m.autore, m.descrizione = m.autore or '', m.descrizione or ''
  return m, err
end

return M
