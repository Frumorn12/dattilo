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

function F:messaggi() return vim.rpcrequest(self.canale, 'nvim_exec2', 'messages', { output = true }).output end

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
