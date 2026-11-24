-- Banco delle prove per le modalità di Vim: un Neovim figlio (--embed) pilotato via RPC,
-- con tutti gli XDG in cartelle temporanee. Si carica con dofile(RADICE .. '/tests/vivo_figlio.lua').
local M = {}
local F = {}
F.__index = F

local function copia(da, a)
  vim.fn.mkdir(a, 'p', tonumber('700', 8))
  for nome, tipo in vim.fs.dir(da) do
    if tipo == 'directory' then copia(da .. '/' .. nome, a .. '/' .. nome)
    else assert(vim.uv.fs_copyfile(da .. '/' .. nome, a .. '/' .. nome)) end
  end
end

-- Copia tests/fixture/<nome> (default 'rifallo') in una cartella nuova a 0700.
function M.cartella(nome)
  local dst = vim.fn.tempname()
  copia(RADICE .. '/tests/fixture/' .. (nome or 'rifallo'), dst)
  vim.uv.fs_chmod(dst, tonumber('700', 8))
  return dst
end

-- o: { cartella?, vivo?, righe?, tetto? }  (tetto: ms prima che il figlio venga fermato, default 15000)
function M.avvia(o)
  o = o or {}
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, 'p', tonumber('700', 8))
  vim.fn.mkdir(tmp .. '/home', 'p', tonumber('700', 8))
  -- ambiente del figlio: quello del padre, ma con HOME nostra e senza DATTILO_VIVO se non serve
  local env = vim.fn.environ()
  env.DATTILO_VIVO = nil
  env.HOME = tmp .. '/home'
  env.XDG_DATA_HOME = (o.cartella or tmp) .. '/dati'
  env.XDG_CONFIG_HOME = tmp .. '/config'
  env.XDG_STATE_HOME = tmp .. '/stato'
  env.XDG_CACHE_HOME = tmp .. '/cache'
  env.LANGUAGE = 'it'
  if o.vivo then env.DATTILO_VIVO = o.cartella end
  local canale = vim.fn.jobstart(
    { 'nvim', '--clean', '--embed', '--headless', '-n', '-i', 'NONE', '-u', RADICE .. '/init.lua' },
    { rpc = true, env = env, clear_env = true })
  assert(canale > 0, 'il figlio non parte')
  local self = setmetatable({ canale = canale, cartella = o.cartella, tmp = tmp }, F)
  self.pid = vim.fn.jobpid(canale)
  -- guardia: se il figlio resta bloccato, lo si ferma e la rpcrequest esce con errore
  self.guardia = vim.uv.new_timer()
  local pid = self.pid
  self.guardia:start(o.tetto or 15000, 0, function() pcall(vim.uv.kill, pid, 'sigterm') end)
  local ok, err = pcall(function()
    if o.righe then self:lua('vim.o.lines = ...', o.righe) end
  end)
  if not ok then
    self:chiudi()
    error(err, 0)
  end
  return self
end

-- Avvia il figlio, esegue fn(F), chiude sempre, poi rilancia l'errore.
function M.con(o, fn)
  local f = M.avvia(o)
  local ok, err = xpcall(fn, debug.traceback, f)
  f:chiudi()
  if not ok then error(err, 0) end
end

function F:input(tasti)
  vim.rpcrequest(self.canale, 'nvim_input', tasti)
  vim.rpcrequest(self.canale, 'nvim_get_mode') -- il figlio ha digerito i tasti
end

function F:modo() return vim.rpcrequest(self.canale, 'nvim_get_mode').mode end

function F:lua(codice, ...) return vim.rpcrequest(self.canale, 'nvim_exec_lua', codice, { ... }) end

function F:righe() return vim.rpcrequest(self.canale, 'nvim_buf_get_lines', 0, 0, -1, false) end

function F:aspetta(cond, ms)
  return (vim.wait(ms or 3000, function() return cond(self) end, 20))
end

-- Un clic col tasto sinistro nella finestra corrente, sulla riga `riga` (da 1) e la colonna `col`
-- (da 0) del testo: un clic vero, con nvim_input_mouse.
function F:clic(riga, col)
  local w = self:lua('local i = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1] return { i.winrow, i.wincol, i.textoff, i.topline }')
  local r, c = w[1] - 1 + riga - w[4], w[2] - 1 + w[3] + col
  vim.rpcrequest(self.canale, 'nvim_input_mouse', 'left', 'press', '', 0, r, c)
  vim.rpcrequest(self.canale, 'nvim_input_mouse', 'left', 'release', '', 0, r, c)
  vim.rpcrequest(self.canale, 'nvim_get_mode')
end

-- Trascina col tasto sinistro nella finestra corrente, sulla riga `riga` (da 1), dalla colonna `da`
-- alla colonna `a` (da 0): con mouse=a apre VISUAL, come per chi seleziona col mouse.
function F:trascina(riga, da, a)
  local w = self:lua('local i = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1] return { i.winrow, i.wincol, i.textoff, i.topline }')
  local r, c = w[1] - 1 + riga - w[4], w[2] - 1 + w[3]
  -- un evento alla volta: mandati insieme, Neovim non vede il trascinamento
  for _, x in ipairs({ { 'press', da }, { 'drag', a }, { 'release', a } }) do
    vim.rpcrequest(self.canale, 'nvim_input_mouse', 'left', x[1], '', 0, r, c + x[2])
    vim.rpcrequest(self.canale, 'nvim_get_mode')
  end
end

function F:messaggi() return vim.rpcrequest(self.canale, 'nvim_exec2', 'messages', { output = true }).output end

-- L'ultimo riquadro della guida: { titolo, sezioni = { [etichetta] = testo }, tipo }; nil se non c'è ancora.
function F:riquadro()
  local r = self:lua([[
    local ok, g = pcall(require, 'dattilo.guida')
    return ok and g.ultimo() or nil]])
  if r == nil or r == vim.NIL then return nil end
  local sezioni = {}
  for _, sz in ipairs(r.sezioni) do sezioni[sz.etichetta] = sz.testo end
  return { titolo = r.titolo, sezioni = sezioni, tipo = r.tipo }
end

-- Il riquadro com'è a schermo, letto dal buffer della sua finestra: { alto, righe, sezioni, finisce },
-- dove alto è l'altezza della finestra, sezioni[etichetta] è il testo delle sue righe messe in fila
-- e finisce[etichetta] è la sua ultima riga. nil se il riquadro è chiuso.
function F:a_schermo()
  local r = self:lua([[
    local ui = require('dattilo.ui')
    if not ui.tip_aperto() then return nil end
    local w = ui.finestra_tip()
    return { alto = vim.api.nvim_win_get_height(w), etichetta = require('dattilo.guida').ETICHETTA,
      righe = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false) }]])
  if r == nil or r == vim.NIL then return nil end
  local sezioni, finisce, cur = {}, {}, nil
  for i = 2, #r.righe - 1 do
    local dentro = r.righe[i]:sub(#'│ ' + 1, #r.righe[i] - #' │')
    local etichetta = vim.trim(dentro:sub(1, r.etichetta))
    local testo = vim.trim(dentro:sub(r.etichetta + 1))
    if etichetta ~= '' then cur = etichetta end
    if cur and testo ~= '' then
      sezioni[cur] = sezioni[cur] and (sezioni[cur] .. ' ' .. testo) or testo
      finisce[cur] = testo
    end
  end
  for k, v in pairs(sezioni) do sezioni[k] = (v:gsub('%s+', ' ')) end
  return { alto = r.alto, righe = r.righe, sezioni = sezioni, finisce = finisce }
end

-- «Adesso» dell'ultimo riquadro (nil se non c'è).
function F:adesso()
  local r = self:riquadro()
  return r and r.sezioni.Adesso
end

-- La prima fila di tasti di una frase, nella notazione di Neovim: «‹2› ‹G›: …» → '2G'.
function M.prima_fila(s)
  local TT = require('dattilo.guida_testi')
  local tasti, i = {}, s:find('‹', 1, true)
  while i do
    local _, f, k = s:find('^‹([^›]*)›', i)
    if not f then break end
    tasti[#tasti + 1] = TT.neovim(k)
    if s:find('^ ‹', f + 1) then i = f + 2 else break end
  end
  return table.concat(tasti)
end

-- Il robot di chi non sa niente: preme la prima fila di tasti di «Adesso», tante volte quante
-- dice la frase («premilo 2 volte»). Rende la frase letta.
function F:premi_primo()
  local a = self:adesso()
  vero(a, 'nessun Adesso nel riquadro')
  local volte = tonumber(a:match('premilo (%d+) volte')) or 1
  local fila = M.prima_fila(a)
  vero(fila ~= '', 'nessun tasto in: ' .. a)
  for _ = 1, volte do self:input(fila) end
  return a
end

-- Segue «Adesso» premendo ogni volta la sua prima fila, finché `fatto(F)`; al massimo `max` passi.
-- Rende le frasi lette, in ordine.
function F:segui(fatto, max)
  local visti = {}
  for _ = 1, max or 10 do
    if fatto(self) then return visti end
    visti[#visti + 1] = self:premi_primo()
  end
  vero(fatto(self), 'seguendo la guida non ci si arriva: ' .. vim.inspect(visti))
  return visti
end

-- Il testo di una frase della guida come lo mostra il riquadro, con gli spazi messi in fila:
-- ‹k› diventa « k », come in ui.segmenti.
function M.a_schermo(testo)
  return vim.trim((testo:gsub('‹(.-)›', ' %1 '):gsub('%s+', ' ')))
end

function F:chiudi()
  if self.chiuso then return end
  self.chiuso = true
  if self.guardia then self.guardia:stop() self.guardia:close() self.guardia = nil end
  pcall(vim.fn.jobstop, self.canale)
  local r = vim.fn.jobwait({ self.canale }, 3000)[1]
  if r == -1 then
    pcall(vim.uv.kill, self.pid, 'sigkill')
    vim.fn.jobwait({ self.canale }, 2000)
  end
end

return M
