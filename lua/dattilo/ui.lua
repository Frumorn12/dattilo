-- Colori, riquadro dei suggerimenti, tabline e statusline.
local stato = require('dattilo.stato')
local M = {}
local ns = vim.api.nvim_create_namespace('dattilo_tip')
local dw = vim.fn.strdisplaywidth

-- tokyonight-night: lo stesso tema di Neovim e del terminale di Andrea
local C = {
  bg = '#1a1b26', bg_dark = '#16161e', hl = '#292e42', fg = '#c0caf5', fg2 = '#a9b1d6', comment = '#565f89',
  ghost = '#545c7e', gutter = '#3b4261', blue = '#7aa2f7', cyan = '#7dcfff', green = '#9ece6a', magenta = '#bb9af7',
  orange = '#ff9e64', yellow = '#e0af68', red = '#f7768e', red_bg = '#4b2533', green_bg = '#23332a', border = '#29a4bd', key = '#2f344f',
}
M.C = C

function M.colori()
  local h = function(n, o) vim.api.nvim_set_hl(0, n, o) end
  h('DattiloGhost', { fg = C.ghost })
  h('DattiloErrore', { fg = C.red, bg = C.red_bg, undercurl = true, sp = C.red })
  h('DattiloSegnoErrore', { fg = C.red })
  h('DattiloSegnoDiverso', { fg = C.orange })
  h('DattiloTasto', { fg = C.fg, bg = C.key, bold = true })
  h('DattiloTesto', { fg = C.fg2 })
  h('DattiloForte', { fg = C.fg, bold = true })
  h('DattiloMuto', { fg = C.comment })
  h('DattiloAccento', { fg = C.orange, bold = true })
  h('DattiloCiano', { fg = C.cyan })
  h('DattiloVerde', { fg = C.green })
  h('DattiloGiallo', { fg = C.yellow })
  h('DattiloRosso', { fg = C.red, bold = true })
  h('DattiloBordo', { fg = C.border })
  h('DattiloBordoRosso', { fg = C.red })
  h('DattiloBordoVerde', { fg = C.green })
  h('DattiloApp', { fg = C.bg, bg = C.orange, bold = true })
  h('DattiloBarra', { fg = C.fg2, bg = C.bg_dark })
  h('DattiloBarra2', { fg = C.fg, bg = C.hl })
  h('DattiloModoNormal', { fg = C.bg, bg = C.blue, bold = true })
  h('DattiloModoInsert', { fg = C.bg, bg = C.green, bold = true })
  h('DattiloModoVisual', { fg = C.bg, bg = C.magenta, bold = true })
  h('DattiloModoCommand', { fg = C.bg, bg = C.yellow, bold = true })
  h('DattiloObiettivo', { fg = C.bg, bg = C.magenta, bold = true })
  h('DattiloAggiunto', { fg = C.green, bg = C.green_bg })
  h('DattiloMeta', { fg = C.bg, bg = C.yellow })
  h('DattiloStella', { fg = C.yellow })
  h('DattiloSelezione', { fg = C.fg, bg = C.hl, bold = true })
end

-- "‹k›" diventa un tasto evidenziato " k ".
function M.segmenti(testo, hl)
  local out, ultimo = {}, 1
  for inizio, tasto, fine in testo:gmatch('()‹(.-)›()') do
    if inizio > ultimo then out[#out + 1] = { testo:sub(ultimo, inizio - 1), hl } end
    out[#out + 1] = { ' ' .. tasto .. ' ', 'DattiloTasto' }
    ultimo = fine
  end
  if ultimo <= #testo then out[#out + 1] = { testo:sub(ultimo), hl } end
  return out
end

local function larghezza_resa(parola)
  return dw((parola:gsub('‹(.-)›', ' %1 ')))
end

function M.a_capo(testo, larghezza)
  local out = {}
  for paragrafo in (testo .. '\n'):gmatch('(.-)\n') do
    local riga, lung = '', 0
    -- gli spazi dentro ‹…› non spezzano il tasto
    local protetto = paragrafo:gsub('‹(.-)›', function(k) return '‹' .. k:gsub(' ', '\1') .. '›' end)
    for parola in protetto:gmatch('%S+') do
      parola = parola:gsub('\1', ' ')
      local l = larghezza_resa(parola)
      if lung > 0 and lung + 1 + l > larghezza then
        out[#out + 1] = riga
        riga, lung = '', 0
      end
      if lung > 0 then riga, lung = riga .. ' ', lung + 1 end
      riga, lung = riga .. parola, lung + l
    end
    out[#out + 1] = riga
  end
  return out
end

function M.riquadro(titolo, testo, larghezza, righe_interne, tipo)
  local bordo = tipo == 'rosso' and 'DattiloBordoRosso' or tipo == 'verde' and 'DattiloBordoVerde' or 'DattiloBordo'
  local interna = larghezza - 4
  local righe, segni = {}, {}
  local testa = '─ ' .. titolo .. ' '
  righe[1] = '╭' .. testa .. string.rep('─', math.max(0, larghezza - 2 - dw(testa))) .. '╮'
  segni[#segni + 1] = { riga = 0, da = 0, a = #righe[1], hl = bordo }
  local corpo = M.a_capo(testo, interna)
  for i = 1, righe_interne do
    local segs = M.segmenti(corpo[i] or '', 'DattiloTesto')
    local riga, col = '│ ', #'│ '
    segni[#segni + 1] = { riga = i, da = 0, a = col, hl = bordo }
    local largo = 0
    for _, s in ipairs(segs) do
      riga = riga .. s[1]
      segni[#segni + 1] = { riga = i, da = col, a = col + #s[1], hl = s[2] }
      col = col + #s[1]
      largo = largo + dw(s[1])
    end
    riga = riga .. string.rep(' ', math.max(0, interna - largo))
    segni[#segni + 1] = { riga = i, da = #riga, a = #riga + #' │', hl = bordo }
    righe[#righe + 1] = riga .. ' │'
  end
  righe[#righe + 1] = '╰' .. string.rep('─', larghezza - 2) .. '╯'
  segni[#segni + 1] = { riga = #righe - 1, da = 0, a = #righe[#righe], hl = bordo }
  return righe, segni
end

-- Finestra del suggerimento: split fisso in alto, non prende il fuoco.
local tip = { win = nil, buf = nil, args = nil }

function M.finestra_tip()
  if tip.win and vim.api.nvim_win_is_valid(tip.win) then return tip.win end
  if not (tip.buf and vim.api.nvim_buf_is_valid(tip.buf)) then
    tip.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[tip.buf].bufhidden = 'hide'
  end
  tip.win = vim.api.nvim_open_win(tip.buf, false, { split = 'above', win = -1, height = 4 })
  local wo = vim.wo[tip.win]
  wo.number, wo.relativenumber, wo.cursorline, wo.wrap, wo.list = false, false, false, false, false
  wo.signcolumn, wo.foldcolumn, wo.statuscolumn, wo.winfixheight = 'no', '0', '', true
  wo.winbar = ''
  return tip.win
end

function M.chiudi_tip()
  if tip.win and vim.api.nvim_win_is_valid(tip.win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.api.nvim_win_close(tip.win, true)
  end
  tip.win, tip.args = nil, nil
end

local function disegna_tip()
  if not tip.args then return end
  local win = M.finestra_tip()
  local righe, segni = M.riquadro(tip.args[1], tip.args[2], vim.o.columns, 2, tip.args[3])
  vim.bo[tip.buf].modifiable = true
  vim.api.nvim_buf_set_lines(tip.buf, 0, -1, false, righe)
  vim.bo[tip.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(tip.buf, ns, 0, -1)
  for _, s in ipairs(segni) do
    vim.api.nvim_buf_set_extmark(tip.buf, ns, s.riga, s.da, { end_col = s.a, hl_group = s.hl })
  end
  if vim.api.nvim_win_get_height(win) ~= 4 then vim.api.nvim_win_set_height(win, 4) end
end

function M.tip(titolo, testo, tipo)
  local nuovi = { titolo, testo, tipo }
  if tip.args and vim.deep_equal(tip.args, nuovi) and tip.win and vim.api.nvim_win_is_valid(tip.win) then return end
  tip.args = nuovi
  disegna_tip()
end

local gruppo = vim.api.nvim_create_augroup('dattilo_ui', { clear = true })
vim.api.nvim_create_autocmd('VimResized', { group = gruppo, callback = function()
  if tip.args then disegna_tip() end
end })
vim.api.nvim_create_autocmd('WinEnter', { group = gruppo, callback = function()
  if tip.win and vim.api.nvim_get_current_win() == tip.win then
    vim.schedule(function() if vim.api.nvim_get_current_win() == tip.win then vim.cmd('wincmd p') end end)
  end
end })

-- Barre
local function protetto(s) return (tostring(s):gsub('%%', '%%%%')) end

function M.tabline()
  local s = '%#DattiloApp# dattilo %#DattiloBarra2# ' .. protetto(stato.titolo or '') .. ' %#DattiloBarra#%='
  if stato.destra and stato.destra ~= '' then s = s .. ' ' .. protetto(stato.destra) .. ' ' end
  return s
end

local MODI = { n = { 'NORMAL', 'Normal' }, i = { 'INSERT', 'Insert' }, v = { 'VISUAL', 'Visual' }, V = { 'V-LINE', 'Visual' },
  ['\22'] = { 'V-BLOCK', 'Visual' }, c = { 'COMMAND', 'Command' }, R = { 'REPLACE', 'Insert' }, t = { 'TERMINAL', 'Command' } }

function M.statusline()
  local m = MODI[vim.api.nvim_get_mode().mode:sub(1, 1)] or MODI.n
  local hl = '%#DattiloModo' .. m[2] .. '#'
  local s = hl .. ' ' .. m[1] .. ' %#DattiloBarra2# ' .. protetto(stato.file or '') .. ' %#DattiloBarra#%='
  if stato.metriche then
    for _, x in ipairs(stato.metriche()) do s = s .. ' ' .. protetto(x) .. ' ' end
  end
  return s .. hl .. ' %l:%c '
end

return M
