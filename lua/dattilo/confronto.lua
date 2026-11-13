-- Confronto tra il testo scritto e il bersaglio. Funzioni pure, colonne in byte (0 = prima).
local M = {}

-- Errori: intervalli di caratteri diversi dal bersaglio, più tutto ciò che va oltre.
function M.confronta(righe, bersaglio)
  local errori = {}
  for i, b in ipairs(righe) do
    local t = bersaglio[i]
    if t == nil then
      if #b > 0 then errori[#errori + 1] = { riga = i - 1, da = 0, a = #b } end
    else
      local da = nil
      for c = 1, #b do
        local diverso = c > #t or b:byte(c) ~= t:byte(c)
        if diverso and not da then da = c - 1 end
        if not diverso and da then
          errori[#errori + 1] = { riga = i - 1, da = da, a = c - 1 }
          da = nil
        end
      end
      if da then errori[#errori + 1] = { riga = i - 1, da = da, a = #b } end
    end
  end
  local finito = #righe == #bersaglio
  if finito then
    for i, b in ipairs(righe) do
      if b ~= bersaglio[i] then finito = false break end
    end
  end
  return { errori = errori, finito = finito }
end

-- Fantasma: quello che manca di ogni riga esistente e le righe del bersaglio ancora da scrivere.
function M.fantasma(righe, bersaglio)
  local coda, sotto = {}, {}
  for i, b in ipairs(righe) do
    local t = bersaglio[i]
    if t and #b < #t then coda[#coda + 1] = { riga = i - 1, col = #b, testo = t:sub(#b + 1) } end
  end
  for i = #righe + 1, #bersaglio do sotto[#sotto + 1] = bersaglio[i] end
  return { coda = coda, sotto = sotto }
end

local function prefisso(a, b)
  local n, p = math.min(#a, #b), 0
  while p < n and a:byte(p + 1) == b:byte(p + 1) do p = p + 1 end
  return p
end

local function suffisso(a, b, limite)
  local s = 0
  while s < limite and a:byte(#a - s) == b:byte(#b - s) do s = s + 1 end
  return s
end

-- Testo inserito in un solo punto passando da `prima` a `dopo`; nil se non è un inserimento puro.
function M.inseriti(prima, dopo)
  if #dopo <= #prima then return nil end
  local p = prefisso(prima, dopo)
  local s = suffisso(prima, dopo, #prima - p)
  if p + s ~= #prima then return nil end
  return p, dopo:sub(p + 1, #dopo - s)
end

-- Prefisso comune e fine (esclusa) della parte diversa in a e in b.
function M.diff_riga(a, b)
  local p = prefisso(a, b)
  local s = suffisso(a, b, math.min(#a, #b) - p)
  return p, #a - s, #b - s
end

return M
