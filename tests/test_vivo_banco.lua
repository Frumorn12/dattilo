local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')

T['banco: la cartella finta è a 0700 e ha due lezioni lette senza errori'] = function()
  local c = M.cartella()
  uguale(vim.uv.fs_stat(c).mode % 512, 448)
  local P = require('dattilo.pacchetti').carica_cartella(c .. '/dati/dattilo/pacchetti/rifallo')
  uguale({ #P.lezioni, #P.errori }, { 2, 0 }, vim.inspect(P.errori))
end

T['banco: il figlio entra in INSERT e ne esce'] = function()
  local c = M.cartella()
  M.con({ cartella = c }, function(F)
    F:lua('require("dattilo.lezione").apri("rifallo", 1)')
    F:input('<CR>')
    uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
    F:input('i')
    uguale(F:modo(), 'i')
    F:input('function')
    uguale(F:righe()[1], 'function')
    F:input('<Esc>')
    uguale(F:modo(), 'n')
  end)
end

T['banco: gli XDG del figlio stanno nella cartella temporanea'] = function()
  local c = M.cartella()
  M.con({ cartella = c }, function(F)
    uguale(F:lua('return vim.env.XDG_DATA_HOME'), c .. '/dati')
    uguale(F:lua('return vim.env.LANGUAGE'), 'it')
    for _, k in ipairs({ 'XDG_CONFIG_HOME', 'XDG_STATE_HOME', 'XDG_CACHE_HOME' }) do
      vero(vim.startswith(F:lua('return vim.env.' .. k), vim.fs.dirname(vim.fn.tempname())), k)
    end
  end)
end

T['banco: il figlio si chiude anche se la prova fallisce'] = function()
  local canale
  local ok = pcall(M.con, {}, function(F) canale = F.canale error('apposta') end)
  uguale(ok, false)
  vero(vim.fn.jobwait({ canale }, 0)[1] ~= -1, 'il figlio è ancora vivo')
end

local function morto(pid) return vim.uv.kill(pid, 0) ~= 0 end

T['banco: un figlio bloccato viene fermato dal tetto e non resta vivo'] = function()
  local F = M.avvia({ tetto = 1500 })
  local t0 = vim.uv.now()
  local ok = pcall(F.lua, F, 'vim.wait(60000)')
  uguale(ok, false)
  vero(vim.uv.now() - t0 < 6000, 'ci ha messo troppo')
  F:chiudi()
  vim.wait(500, function() return morto(F.pid) end)
  vero(morto(F.pid), 'il figlio è vivo')
end

T['banco: se avvia fallisce dopo jobstart non resta nessun figlio'] = function()
  local pids, orig = {}, vim.fn.jobpid
  vim.fn.jobpid = function(c) local p = orig(c) pids[#pids + 1] = p return p end
  local ok = pcall(M.con, { righe = 'non un numero' }, function() end)
  vim.fn.jobpid = orig
  uguale(ok, false)
  uguale(#pids, 1)
  vim.wait(500, function() return morto(pids[1]) end)
  vero(morto(pids[1]), 'il figlio è ancora vivo')
end

T['banco: HOME del figlio è temporanea e DATTILO_VIVO non passa se vivo è falso'] = function()
  local vera = vim.env.HOME
  vim.env.DATTILO_VIVO = '/non/deve/passare'
  local ok, err = pcall(M.con, {}, function(F)
    local h = F:lua('return vim.env.HOME')
    vero(vim.startswith(h, vim.fs.dirname(vim.fn.tempname())), h)
    vero(h ~= vera, 'HOME vera')
    uguale(F:lua('return vim.env.DATTILO_VIVO'), vim.NIL)
  end)
  vim.env.DATTILO_VIVO = nil
  vero(ok, err)
end

return T
