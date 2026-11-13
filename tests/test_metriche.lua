local metriche = require('dattilo.metriche')
local T = {}

T['conta giusti e sbagliati per carattere'] = function()
  local m = metriche.nuova()
  m:inserito('int', 'int', 0)
  m:inserito('x', 'y', 0)
  uguale({ m.giusti, m.sbagliati }, { 3, 1 })
  uguale(m:precisione(), 75)
end
T['atteso più corto conta come errore'] = function()
  local m = metriche.nuova()
  m:inserito('ab', 'a', 0)
  uguale({ m.giusti, m.sbagliati }, { 1, 1 })
end
T['precisione con un decimale e 100 senza tasti'] = function()
  local m = metriche.nuova()
  uguale(m:precisione(), 100)
  m:inserito('aab', 'aaa', 0)
  uguale(m:precisione(), 66.7)
end
T['il tempo parte dal primo inserimento'] = function()
  local m = metriche.nuova()
  uguale(m.inizio, nil)
  uguale(m:tempo(5000), 0)
  m:inserito('a', 'a', 1000)
  uguale(m.inizio, 1000)
  uguale(m:tempo(4000), 3000)
end
T['parole al minuto: giusti / 5 / minuti'] = function()
  local m = metriche.nuova()
  m:inserito(string.rep('a', 250), string.rep('a', 250), 0)
  uguale(m:wpm(60000), 50)
end
T['parole al minuto zero sotto il secondo'] = function()
  local m = metriche.nuova()
  m:inserito('abcdefghij', 'abcdefghij', 0)
  uguale(m:wpm(900), 0)
end
T['a capo giusto o sbagliato'] = function()
  local m = metriche.nuova()
  m:a_capo(true, 0)
  m:a_capo(false, 0)
  uguale({ m.giusti, m.sbagliati, m.inizio }, { 1, 1, 0 })
end
T['la pausa non conta nel tempo'] = function()
  local m = metriche.nuova()
  m:inserito('a', 'a', 0)
  m:pausa(10000)
  uguale(m:tempo(15000), 10000)
  m:riprendi(20000)
  uguale(m:tempo(30000), 20000)
end
T['riprendi senza pausa non cambia nulla'] = function()
  local m = metriche.nuova()
  m:inserito('a', 'a', 0)
  m:riprendi(5000)
  uguale(m:tempo(8000), 8000)
end
T['dopo la fine il tempo si ferma'] = function()
  local m = metriche.nuova()
  m:inserito('a', 'a', 0)
  m:fine(12000)
  uguale(m.finito, true)
  uguale(m:tempo(99000), 12000)
end
return T
