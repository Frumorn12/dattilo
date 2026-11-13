local compila = require('dattilo.compila')
local T = {}

local function scrivi(codice)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile(vim.split(codice, '\n'), dir .. '/prova.c')
  return dir
end
local HELLO = '#include <stdio.h>\n\nint main(void) {\n    printf("Hello World\\n");\n    return 0;\n}'

T['Hello World compila e stampa'] = function()
  local r = compila.esegui(scrivi(HELLO), 'prova.c')
  uguale({ r.ok, r.compilato, r.warning, r.uscita, r.codice, r.scaduto }, { true, true, false, 'Hello World\n', 0, false })
  vero(r.comando:find('cc -Wall -Wextra -O2', 1, true), r.comando)
end
T['senza include è un errore'] = function()
  local r = compila.esegui(scrivi((HELLO:gsub('#include <stdio.h>\n', ''))), 'prova.c')
  uguale({ r.ok, r.compilato }, { false, false })
  vero(r.diagnostica:find('implicit declaration of function', 1, true) and r.diagnostica:find('printf', 1, true), r.diagnostica)
end
T['due %d e un argomento: compila con warning'] = function()
  local r = compila.esegui(scrivi('#include <stdio.h>\nint main(void) { printf("%d %d\\n", 1); return 0; }'), 'prova.c')
  uguale({ r.compilato, r.warning }, { true, true })
end
T['programma che non finisce viene fermato'] = function()
  local t0 = vim.uv.hrtime()
  local r = compila.esegui(scrivi('int main(void) { while (1) {} }'), 'prova.c', { timeout_esecuzione = 500 })
  uguale({ r.ok, r.scaduto }, { false, true })
  vero((vim.uv.hrtime() - t0) / 1e9 < 6)
end
T['codice di uscita diverso da zero'] = function()
  local r = compila.esegui(scrivi('int main(void) { return 3; }'), 'prova.c')
  uguale({ r.ok, r.compilato, r.codice }, { false, true, 3 })
end
T['cc mancante'] = function()
  local path = vim.env.PATH
  vim.env.PATH = '/nonesiste'
  local ok, r = pcall(compila.esegui, scrivi(HELLO), 'prova.c')
  vim.env.PATH = path
  vero(ok, tostring(r))
  uguale(r.ok, false)
  vero(r.diagnostica:find('cc', 1, true), r.diagnostica)
end
T['messaggio: comando, uscita e esito'] = function()
  local r = compila.esegui(scrivi(HELLO), 'prova.c')
  local chunks = compila.messaggio(r)
  vero(chunks[1][1]:find('^%$ cc'), chunks[1][1])
  local testo = table.concat(vim.tbl_map(function(c) return c[1] end, chunks))
  vero(testo:find('Hello World', 1, true) and testo:find('Compilato senza warning', 1, true), testo)
end
T['messaggio: le righe di errore sono rosse'] = function()
  local r = compila.esegui(scrivi((HELLO:gsub('#include <stdio.h>\n', ''))), 'prova.c')
  local rossi = vim.tbl_filter(function(c) return c[2] == 'DattiloRosso' and c[1]:find('error', 1, true) end, compila.messaggio(r))
  vero(#rossi >= 1)
end
return T
