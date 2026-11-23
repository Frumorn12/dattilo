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
      vero(vim.startswith(F:lua('return vim.env.' .. k), '/tmp/'), k)
    end
  end)
end

T['banco: il figlio si chiude anche se la prova fallisce'] = function()
  local canale
  local ok = pcall(M.con, {}, function(F) canale = F.canale error('apposta') end)
  uguale(ok, false)
  vero(vim.fn.jobwait({ canale }, 0)[1] ~= -1, 'il figlio è ancora vivo')
end

return T
