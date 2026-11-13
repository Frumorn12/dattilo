local c = require('dattilo.confronto')
local T = {}

T['riga incompleta senza errori'] = function()
  local r = c.confronta({ 'int' }, { 'int x;' })
  uguale(r.errori, {})
  uguale(r.finito, false)
end
T['carattere sbagliato'] = function()
  uguale(c.confronta({ 'imt' }, { 'int' }).errori, { { riga = 0, da = 1, a = 2 } })
end
T['riga in più oltre il bersaglio'] = function()
  local r = c.confronta({ 'int x;', 'extra' }, { 'int x;' })
  uguale(r.errori, { { riga = 1, da = 0, a = 5 } })
  uguale(r.finito, false)
end
T['spazi in più a fine riga'] = function()
  uguale(c.confronta({ 'int x;  ' }, { 'int x;' }).errori, { { riga = 0, da = 6, a = 8 } })
end
T['errori non contigui restano separati'] = function()
  uguale(c.confronta({ 'axcx' }, { 'abcd' }).errori, { { riga = 0, da = 1, a = 2 }, { riga = 0, da = 3, a = 4 } })
end
T['testo uguale al bersaglio è finito'] = function()
  local b = { '#include <stdio.h>', '', '}' }
  local r = c.confronta(b, b)
  uguale(r.errori, {})
  uguale(r.finito, true)
end
T['fantasma: coda della riga e righe sotto'] = function()
  uguale(c.fantasma({ 'int m' }, { 'int main', '}' }), { coda = { { riga = 0, col = 5, testo = 'ain' } }, sotto = { '}' } })
end
T['fantasma: buffer vuoto'] = function()
  uguale(c.fantasma({ '' }, { 'a', 'b' }), { coda = { { riga = 0, col = 0, testo = 'a' } }, sotto = { 'b' } })
end
T['fantasma: righe più lunghe non hanno coda'] = function()
  uguale(c.fantasma({ 'abcdef', 'x' }, { 'abc' }), { coda = {}, sotto = {} })
end
T['inseriti: un carattere in mezzo'] = function()
  local da, testo = c.inseriti('prntf', 'printf')
  uguale({ da, testo }, { 2, 'i' })
end
T['inseriti: più caratteri in fondo'] = function()
  local da, testo = c.inseriti('in', 'int x')
  uguale({ da, testo }, { 2, 't x' })
end
T['inseriti: cancellazione non è inserimento'] = function()
  uguale({ c.inseriti('ab', 'a') }, {})
end
T['diff_riga'] = function()
  uguale({ c.diff_riga('Hello World', 'Ciao mondo') }, { 0, 11, 10 })
  uguale({ c.diff_riga('printf("Hello\\n");', 'printf("Ciao\\n");') }, { 8, 12, 11 })
  uguale({ c.diff_riga('uguale', 'uguale') }, { 6, 6, 6 })
end
return T
