text_texture = {}

-- Initialize character texture cache
local ctexcache = {}
local ctexcache_wide = {}

-- CONSTANTS

-- Path to the textures.
local TP = mcl_more_signs.path .. "/textures"
-- Font file formatter
local CHAR_FILE = "%s_%02x.png"
local CHAR_FILE_WIDE = "%s_%s.png"
local UNIFONT_TEX = "signs_lib_uni%02x.png\\^[sheet\\:16x16\\:%d,%d"
-- Fonts path
local CHAR_PATH = TP .. "/" .. CHAR_FILE
local CHAR_PATH_WIDE = TP .. "/" .. CHAR_FILE_WIDE

-- Lots of overkill here. KISS advocates, go away, shoo! ;) -- kaeza
local PNG_HDR = string.char(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

-- 4 rows, max 80 chars per, plus a bit of fudge to
-- avoid excess trimming (e.g. due to color codes)
local MAX_INPUT_CHARS = 400

-- helper functions to trim sign text input/output
function mcl_more_signs.trim_input(text)
	return text:sub(1, math.min(MAX_INPUT_CHARS, text:len()))
end

-- check if a file does exist
-- to avoid reopening file after checking again
-- pass TRUE as second argument
local function file_exists(name, return_handle, mode)
	mode = mode or "r";
	local f = io.open(name, mode)
	if f ~= nil then
		if (return_handle) then
			return f
		end
		io.close(f)
		return true
	else
		return false
	end
end

-- Read the image size from a PNG file.
-- Returns image_w, image_h.
-- Only the LSB is read from each field!
function mcl_more_signs.read_image_size(filename)
	local f = file_exists(filename, true, "rb")
	-- file might not exist (don't crash the game)
	if (not f) then
		return 0, 0
	end
	f:seek("set", 0x0)
	local hdr = f:read(string.len(PNG_HDR))
	if hdr ~= PNG_HDR then
		f:close()
		return
	end
	f:seek("set", 0x13)
	local ws = f:read(1)
	f:seek("set", 0x17)
	local hs = f:read(1)
	f:close()
	return ws:byte(), hs:byte()
end

-- Используется для корректного размещения текста на знаках (табличках).
-- 1. Создаёт таблицу ширин символов для обычных и широких знаков.
-- 2. Определяет среднюю ширину символов (важно для вычисления переноса строк).
-- 3. Считывает размеры фонового изображения.
-- 4. Возвращает эти данные для использования в рендеринге знаков.
local function build_char_db(font_size)
	local cw = {}
	local cw_wide = {}

	-- To calculate average char width.
	local total_width = 0
	local char_count = 0

	for c = 32, 255 do
		local w, h = mcl_more_signs.read_image_size(CHAR_PATH:format("signs_lib_font_"..font_size.."px", c))
		if w and h then
			local ch = string.char(c)
			cw[ch] = w
			total_width = total_width + w
			char_count = char_count + 1
		end
	end

	for i = 1, #mcl_more_signs.wide_character_codes do
		local ch = mcl_more_signs.wide_character_codes[i]
		local w, h = mcl_more_signs.read_image_size(CHAR_PATH_WIDE:format("signs_lib_font_"..font_size.."px", ch))
		if w and h then
			cw_wide[ch] = w
			total_width = total_width + w
			char_count = char_count + 1
		end
	end

	local cbw, cbh = mcl_more_signs.read_image_size(TP.."/signs_lib_color_"..font_size.."px_n.png")
	assert(cbw and cbh, "error reading bg dimensions")
	return cw, cbw, cbh, (total_width / char_count), cw_wide
end

mcl_more_signs.charwidth16,
mcl_more_signs.colorbgw16,
mcl_more_signs.lineheight16,
mcl_more_signs.avgwidth16,
mcl_more_signs.charwidth_wide16 = build_char_db(16)

mcl_more_signs.charwidth32,
mcl_more_signs.colorbgw32,
mcl_more_signs.lineheight32,
mcl_more_signs.avgwidth32,
mcl_more_signs.charwidth_wide32 = build_char_db(32)

-- some local helper functions
local math_max = math.max

-- Она заполняет строку таблички сплошной цветной текстурой, используя размер шрифта и цвет.
-- Используется для раскрашивания фона текста на знаках.
local function fill_line(x, y, w, c, font_size, colorbgw)
	c = c or "0"
	local tex = { }
	for xx = x, w, colorbgw do
		table.insert(tex, (":%d,%d=signs_lib_color_" .. font_size .. "px_%s.png"):format(xx, y, c))
	end
	return table.concat(tex)
end

-- make char texture file name
-- if texture file does not exist use fallback texture instead
local function char_tex(font_name, ch)
	if ctexcache[font_name..ch] then
		return ctexcache[font_name..ch], true
	else
		local c = ch:byte()
		local exists = file_exists(CHAR_PATH:format(font_name, c))
		local tex
		if exists and c ~= 14 then
			tex = CHAR_FILE:format(font_name, c)
		else
			tex = CHAR_FILE:format(font_name, 0x0)
		end
		ctexcache[font_name..ch] = tex
		return tex, exists
	end
end

-- Функция char_tex_wide(font_name, ch):
--	Проверяет, есть ли уже текстура символа в кеше.
--	Если нет — проверяет, существует ли файл текстуры на диске.
--	Если файл есть — использует его, если нет — подставляет подстановочный символ (_).
--	Сохраняет результат в кеш и возвращает текстуру.
-- Эта функция нужна для обработки широких символов (wide font) при отображении текста на табличках.
local function char_tex_wide(font_name, ch)
	if ctexcache_wide[font_name .. ch] then
		return ctexcache_wide[font_name .. ch], true
	else
		local exists = file_exists(CHAR_PATH_WIDE:format(font_name, ch))
		local tex
		if exists then
			tex = CHAR_FILE_WIDE:format(font_name, ch)
		else
			tex = CHAR_FILE:format(font_name, 0x5f)
		end
		ctexcache_wide[font_name .. ch] = tex
		return tex, exists
	end
end

-- Функция для получения индекса цвета из mcl_dye
local function get_dye_color(dye_name)
	local dyes_table = {
		{ "mcl_dye:black", "0" },
		{ "mcl_dye:blue", "1" },
		{ "mcl_dye:brown", "2" },
		{ "mcl_dye:cyan", "3"},
		{ "mcl_dye:dark_green", "4"},
		{ "mcl_dye:dark_grey", "5"},
		{ "mcl_dye:green", "6" },
		{ "mcl_dye:grey", "7" },
		{ "mcl_dye:lightblue", "8" },
		{ "mcl_dye:magenta", "9" },
		{ "mcl_dye:orange", "A" },
		{ "mcl_dye:pink", "B" },
		{ "mcl_dye:red", "C" },
		{ "mcl_dye:violet", "D" },
		{ "mcl_dye:yellow", "E"},
		{ "mcl_dye:white", "F"},
	}
	
	for d = 1, #dyes_table do
		if dyes_table[d][1] == dye_name then
			return dyes_table[d][2]
		end
	end
	return "0" -- Берем черний цвет, если dye_name нет в словаре
end

-- Функция make_line_texture выполняет несколько задач:
-- 1) Разбивает строку на слова и символы, учитывая специальные символы для изменения цвета и шрифта.
-- 2) Вычисляет ширину каждого символа с учётом шрифта и специальных символов.
-- 3) Формирует текстуру для отображения текста на табличке, обрабатывая все символы, их цвета и позиции.
-- 4) Возвращает итоговую текстуру строки.
-- Эта функция используется для динамического создания текстуры строки для таблички, 
-- учитывая различные параметры шрифта, цвет и размеры символов.
local function make_line_texture(line, lineno, pos, line_width, line_height, cwidth_tab, font_size, colorbgw, cwidth_tab_wide, text_color)
	local width = 0
	local maxw = 0
	local font_name = "signs_lib_font_" .. font_size .. "px"

	local words = { }
	local node = minetest.get_node(pos)
	local def = minetest.registered_items[node.name]
	local cur_color = text_color

	-- We check which chars are available here.
	for word_i, word in ipairs(line) do
		local chars = { }
		local ch_offs = 0
		local word_l = #word
		local i = 1
		local escape = 0
		while i <= word_l  do
			local wide_type, wide_c = string.match(word:sub(i), "^&#([xu])(%x+);")
			local c = word:sub(i, i)
			local c2 = word:sub(i+1, i+1)

			if escape > 0 then escape = escape - 1 end
			if c == "^" and escape == 0 and c2:find("[1-8a-h]") then
				c = string.char(tonumber(c2,18)+0x80)
				i = i + 1
			end

			local wide_skip = 0
			if wide_c then
				wide_skip = #wide_c + 3
			end

			if wide_c then
				local w, code
				if wide_type == "x" then
					w = cwidth_tab_wide[wide_c]
				elseif wide_type == "u" and #wide_c <= 4 then
					w = font_size
					code = tonumber(wide_c, 16)
					if mcl_more_signs.unifont_halfwidth[code] then
						w = math.floor(w / 2)
					end
				end
				if w then
					width = width + w
					if width > line_width then
						width = 0
					else
						maxw = math_max(width, maxw)
					end
					if #chars < MAX_INPUT_CHARS then
						local tex
						if wide_type == "u" then
							local page = math.floor(code / 256)
							local idx = code % 256
							local x = idx % 16
							local y = math.floor(idx / 16)
							tex = UNIFONT_TEX:format(page, x, y)
							if font_size == 32 then
								tex = tex .. "\\^[resize\\:32x32"
							end
						else
							tex = char_tex_wide(font_name, wide_c)
						end
						table.insert(chars, {
							off = ch_offs,
							tex = tex,
							col = cur_color,
							w = w,
						})
					end
					ch_offs = ch_offs + w
				end
				i = i + wide_skip
			else
				local w = cwidth_tab[c]
				if w then
					width = width + w
					if width > line_width then
						width = 0
					else
						maxw = math_max(width, maxw)
					end
					if #chars < MAX_INPUT_CHARS then
						table.insert(chars, {
							off = ch_offs,
							tex = char_tex(font_name, c),
							col = cur_color,
							w = w,
						})
					end
					ch_offs = ch_offs + w
				end
			end
			i = i + 1
		end
		width = width + cwidth_tab[" "]
		maxw = math_max(width, maxw)
		table.insert(words, { chars=chars, w=ch_offs })
	end

	-- Okay, we actually build the "line texture" here.
	local texture = { }

	local start_xpos = math.max(0, math.floor((line_width - maxw) / 2)) + def.x_offset
	local end_xpos = math.min(start_xpos + maxw, line_width)

	local xpos = start_xpos
	local ypos = (line_height + def.line_spacing)* lineno + def.y_offset

	cur_color = nil

	for word_i, word in ipairs(words) do
		local xoffs = (xpos - start_xpos)
		if (xoffs > 0) and ((xoffs + word.w) > end_xpos) then
			table.insert(texture, fill_line(xpos, ypos, end_xpos, "n", font_size, colorbgw))
			xpos = start_xpos
			ypos = ypos + line_height + def.line_spacing
			lineno = lineno + 1
			if lineno >= def.number_of_lines then break end
			table.insert(texture, fill_line(xpos, ypos, end_xpos, cur_color, font_size, colorbgw))
		end
		for ch_i, ch in ipairs(word.chars) do
			if xpos + ch.off + ch.w > end_xpos then
				table.insert(texture, fill_line(xpos + ch.off, ypos, end_xpos, "n", font_size, colorbgw))
				break
			end
			if ch.col ~= cur_color then
				cur_color = ch.col
				table.insert(texture, fill_line(xpos + ch.off, ypos, end_xpos, cur_color, font_size, colorbgw))
			end
			table.insert(texture, (":%d,%d=%s"):format(xpos + ch.off, ypos, ch.tex))
		end
		xpos = xpos + word.w
		if xpos < end_xpos then
			table.insert(texture, (":%d,%d="):format(xpos, ypos) .. char_tex(font_name, " "))
			xpos = xpos + cwidth_tab[" "]
		end
	end

	table.insert(texture, fill_line(xpos, ypos, end_xpos, "n", font_size, colorbgw))

	return table.concat(texture), lineno
end

-- Функция mcl_more_signs.make_sign_texture(lines, pos) выполняет следующие шаги: 
-- 1) Проверяет параметры таблички, включая шрифт и настройки метаданных. 
-- 2) Рассчитывает параметры шрифта, ширины и высоты строк, в зависимости от настроек. 
-- 3) Преобразует каждую строку в текстуру с учетом всех параметров (ширина, высота, шрифт). 
-- 4) Возвращает итоговую текстуру, которая будет отображаться на табличке в игре.
-- Эта функция используется для динамического создания текстуры для таблички в игре, 
-- отображающей текст с учетом различных параметров шрифта и размера.
function mcl_more_signs.make_sign_texture(lines, pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)

	local def = minetest.registered_items[node.name]
	if not def or not def.entity_info then return end

	local font_size
	local line_width
	local line_height
	local char_width
	local char_width_wide
	local colorbgw
	local widemult = meta:get_int("widefont") == 1 and 0.5 or 1

	if def.font_size and (def.font_size == 32 or def.font_size == 31) then
		font_size = 32
		line_width = math.floor(mcl_more_signs.avgwidth32 * def.chars_per_line) * (def.horiz_scaling * widemult)
		line_height = mcl_more_signs.lineheight32
		char_width = mcl_more_signs.charwidth32
		char_width_wide = mcl_more_signs.charwidth_wide32
		colorbgw = mcl_more_signs.colorbgw32
	else
		font_size = 16
		line_width = math.floor(mcl_more_signs.avgwidth16 * def.chars_per_line) * (def.horiz_scaling * widemult)
		line_height = mcl_more_signs.lineheight16
		char_width = mcl_more_signs.charwidth16
		char_width_wide = mcl_more_signs.charwidth_wide16
		colorbgw = mcl_more_signs.colorbgw16
	end

	local dye_color = meta:get_string("dye_color")
	local text_color = get_dye_color(dye_color)

	local texture = { ("[combine:%dx%d"):format(line_width, (line_height + def.line_spacing) * def.number_of_lines * def.vert_scaling) }

	local lineno = 0
	for i = 1, #lines do
		if lineno >= def.number_of_lines then break end
		local linetex, ln = make_line_texture(lines[i], lineno, pos, line_width, line_height, char_width, font_size, colorbgw, char_width_wide, text_color)
		table.insert(texture, linetex)
		lineno = ln + 1
	end
	table.insert(texture, "^[makealpha:0,0,0")
	return table.concat(texture, "")
end