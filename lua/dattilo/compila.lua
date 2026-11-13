-- Compila il file della lezione con cc e lo esegue, con un tempo massimo.
local M = {}

function M.esegui(dir, file, o)
  o = o or {}
  local nome = file:gsub('%.c$', '')
  local cmd = { 'cc', '-Wall', '-Wextra', '-O2', '-fdiagnostics-color=never', '-o', nome, file }
  local r = { comando = table.concat(cmd, ' '), nome = nome, ok = false, compilato = false, warning = false,
    diagnostica = '', uscita = '', errori = '', codice = nil, scaduto = false, troncato = false }
  if vim.fn.executable('cc') == 0 then
    r.diagnostica = 'cc non trovato nel PATH: serve un compilatore C (pacchetto gcc)'
    return r
  end
  local c = vim.system(cmd, { cwd = dir, text = true, timeout = o.timeout_compila or 10000 }):wait()
  r.diagnostica = (c.stderr or '') .. (c.stdout or '')
  r.compilato = c.code == 0
  r.warning = r.diagnostica:find('warning:', 1, true) ~= nil
  if not r.compilato then return r end
  -- l'uscita si legge a pezzi con un tetto: un ciclo infinito con printf non deve bloccare Neovim
  local limite = o.limite_uscita or 64 * 1024
  local pezzi, errori, tot, tot_err, proc = {}, {}, 0, 0, nil
  local function taglia()
    r.troncato = true
    if proc then pcall(proc.kill, proc, 9) end
  end
  proc = vim.system({ './' .. nome }, {
    cwd = dir, text = true, timeout = o.timeout_esecuzione or 5000,
    stdout = function(_, dati)
      if not dati or r.troncato then return end
      if tot + #dati > limite then pezzi[#pezzi + 1] = dati:sub(1, limite - tot) tot = limite taglia()
      else pezzi[#pezzi + 1] = dati tot = tot + #dati end
    end,
    stderr = function(_, dati)
      if not dati or tot_err >= limite then return end
      errori[#errori + 1] = dati:sub(1, limite - tot_err)
      tot_err = tot_err + #dati
    end,
  })
  local p = proc:wait()
  r.uscita, r.errori, r.codice = table.concat(pezzi), table.concat(errori), p.code
  r.scaduto = p.code == 124
  r.ok = r.codice == 0 and not r.scaduto and not r.troncato
  return r
end

local function righe(testo)
  local out = {}
  for l in (testo:gsub('\n$', '') .. '\n'):gmatch('(.-)\n') do out[#out + 1] = l end
  if testo == '' then return {} end
  return out
end

-- Pezzi per nvim_echo: con più righe Neovim mostra il prompt "Premi INVIO".
function M.messaggio(r)
  local out = {}
  local function riga(t, hl) out[#out + 1] = { t .. '\n', hl } end
  riga('$ ' .. r.comando .. (r.compilato and (' && ./' .. r.nome) or ''), 'DattiloMuto')
  for _, l in ipairs(righe(r.diagnostica)) do
    local hl = l:find('error', 1, true) and 'DattiloRosso' or l:find('warning', 1, true) and 'DattiloGiallo'
      or l:find('note:', 1, true) and 'DattiloCiano' or 'DattiloTesto'
    riga(l, hl)
  end
  local MAX = 40
  local function elenco(testo, hl)
    local rr = righe(testo)
    for i = 1, math.min(#rr, MAX) do riga(rr[i], hl) end
    if #rr > MAX then riga('… altre ' .. (#rr - MAX) .. ' righe, uscita troncata', 'DattiloMuto') end
  end
  elenco(r.uscita, 'DattiloForte')
  elenco(r.errori, 'DattiloRosso')
  local esito, hl
  if not r.compilato then esito, hl = 'Non compila: leggi l\'errore qui sopra.', 'DattiloRosso'
  elseif r.troncato then esito, hl = 'Il programma stampava senza fermarsi: fermato dopo 64 KB di uscita (uscita troncata).', 'DattiloGiallo'
  elseif r.scaduto then esito, hl = 'Il programma non è finito in tempo ed è stato fermato.', 'DattiloGiallo'
  elseif r.codice ~= 0 then esito, hl = 'Il programma è uscito con codice ' .. tostring(r.codice) .. '.', 'DattiloGiallo'
  elseif r.warning then esito, hl = 'Compilato con warning: il compilatore ti sta avvisando di qualcosa.', 'DattiloGiallo'
  else esito, hl = 'Compilato senza warning.', 'DattiloVerde' end
  out[#out + 1] = { esito, hl }
  return out
end

return M
