-- Metriche di battitura. Il tempo arriva da fuori (millisecondi), così i test sono deterministici.
local M = {}
local Metriche = {}
Metriche.__index = Metriche

function M.nuova()
  return setmetatable({ giusti = 0, sbagliati = 0, inizio = nil, in_pausa = nil, pause = 0, fine_ms = nil, finito = false }, Metriche)
end

function Metriche:_parti(ora)
  if not self.inizio then self.inizio = ora end
end

function Metriche:inserito(testo, atteso, ora)
  self:_parti(ora)
  for i = 1, #testo do
    if atteso and testo:byte(i) == atteso:byte(i) then self.giusti = self.giusti + 1
    else self.sbagliati = self.sbagliati + 1 end
  end
end

function Metriche:a_capo(giusto, ora)
  self:_parti(ora)
  if giusto then self.giusti = self.giusti + 1 else self.sbagliati = self.sbagliati + 1 end
end

function Metriche:pausa(ora)
  if self.inizio and not self.in_pausa and not self.finito then self.in_pausa = ora end
end

function Metriche:riprendi(ora)
  if self.in_pausa then
    self.pause = self.pause + (ora - self.in_pausa)
    self.in_pausa = nil
  end
end

function Metriche:fine(ora)
  self:riprendi(ora)
  self.fine_ms = ora
  self.finito = true
end

function Metriche:tempo(ora)
  if not self.inizio then return 0 end
  local fine = self.fine_ms or self.in_pausa or ora
  return math.max(0, fine - self.inizio - self.pause)
end

function Metriche:wpm(ora)
  local ms = self:tempo(ora)
  if ms < 1000 then return 0 end
  return math.floor(self.giusti / 5 / (ms / 60000) + 0.5)
end

function Metriche:precisione()
  local tot = self.giusti + self.sbagliati
  if tot == 0 then return 100 end
  return math.floor(self.giusti / tot * 1000 + 0.5) / 10
end

return M
