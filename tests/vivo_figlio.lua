-- Banco delle prove per le modalità di Vim: un Neovim figlio (--embed) pilotato via RPC,
-- con tutti gli XDG in cartelle temporanee. Si carica con dofile(RADICE .. '/tests/vivo_figlio.lua').
local M = {}
local F = {}
F.__index = F

local function copia(da, a)
  vim.fn.mkdir(a, 'p', tonumber('700', 8))
  for nome, tipo in vim.fs.dir(da) do
    if tipo == 'directory' then copia(da .. '/' .. nome, a .. '/' .. nome)
    else vim.uv.fs_copyfile(da .. '/' .. nome, a .. '/' .. nome) end
  end
end

-- Copia tests/fixture/<nome> (default 'rifallo') in una cartella nuova a 0700.
function M.cartella(nome)
  local dst = vim.fn.tempname()
  copia(RADICE .. '/tests/fixture/' .. (nome or 'rifallo'), dst)
  vim.uv.fs_chmod(dst, tonumber('700', 8))
  return dst
end

-- o: { cartella?, vivo?, righe? }
function M.avvia(o)
  o = o or {}
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, 'p', tonumber('700', 8))
  local env = {
    XDG_DATA_HOME = (o.cartella or tmp) .. '/dati',
    XDG_CONFIG_HOME = tmp .. '/config',
    XDG_STATE_HOME = tmp .. '/stato',
    XDG_CACHE_HOME = tmp .. '/cache',
    LANGUAGE = 'it',
  }
  if o.vivo then env.DATTILO_VIVO = o.cartella end
  local canale = vim.fn.jobstart(
    { 'nvim', '--clean', '--embed', '--headless', '-n', '-i', 'NONE', '-u', RADICE .. '/init.lua' },
    { rpc = true, env = env })
  assert(canale > 0, 'il figlio non parte')
  local self = setmetatable({ canale = canale, cartella = o.cartella, tmp = tmp }, F)
  self.pid = vim.fn.jobpid(canale)
  if o.righe then self:lua('vim.o.lines = ...', o.righe) end
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
  pcall(vim.fn.jobstop, self.canale)
  vim.fn.jobwait({ self.canale }, 3000)
end

return M
