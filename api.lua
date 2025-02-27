-- mcl_more_signs api, backported from street_signs

local S = mcl_more_signs.S
local FS = function(...) return minetest.formspec_escape(S(...)) end
local unicode_enabled = false -- Включаем/отключаем кнопку unicode

local function log(level, messagefmt, ...)
	minetest.log(level, "[mcl_more_signs] " .. messagefmt:format(...))
end

local function get_sign_formspec() end

mcl_more_signs.glow_item = "basic_materials:energy_crystal_simple"

mcl_more_signs.lbm_restore_nodes = {}
mcl_more_signs.old_fenceposts = {}
mcl_more_signs.old_fenceposts_replacement_signs = {}
mcl_more_signs.old_fenceposts_with_signs = {}

-- Settings used for a standard wood or steel wall sign
mcl_more_signs.standard_lines = 6
mcl_more_signs.standard_hscale = 1
mcl_more_signs.standard_vscale = 1
mcl_more_signs.standard_lspace = 1
mcl_more_signs.standard_fsize = 16
mcl_more_signs.standard_xoffs = 4
mcl_more_signs.standard_yoffs = 0
mcl_more_signs.standard_cpl = 35

mcl_more_signs.standard_steel_groups = table.copy({axey = 1, handy = 2, choppy = 1, oddly_breakable_by_hand = 1})
mcl_more_signs.standard_steel_groups.attached_node = nil

mcl_more_signs.standard_stone_groups = table.copy({axey = 1, handy = 2, choppy = 1, stone = 1, oddly_breakable_by_hand = 1})
mcl_more_signs.standard_stone_groups.attached_node = nil

mcl_more_signs.standard_steel_sign_sounds = table.copy(mcl_sounds.node_sound_metal_defaults() or {})
mcl_more_signs.standard_stone_sign_sounds = table.copy(mcl_sounds.node_sound_stone_defaults() or {})

mcl_more_signs.default_text_scale = {x=10, y=10}

mcl_more_signs.old_widefont_signs = {}

mcl_more_signs.block_list = {}
mcl_more_signs.totalblocks = 0

mcl_more_signs.standard_yaw = {
	0,
	math.pi / -2,
	math.pi,
	math.pi / 2,
}

mcl_more_signs.wallmounted_yaw = {
	nil,
	nil,
	math.pi / -2,
	math.pi / 2,
	0,
	math.pi,
}

mcl_more_signs.fdir_to_back = {
	{  0, -1 },
	{ -1,  0 },
	{  0,  1 },
	{  1,  0 },
}

mcl_more_signs.fdir_to_back_left = {
	[0] = { -1,  1 },
	[1] = {  1,  1 },
	[2] = {  1, -1 },
	[3] = { -1, -1 }
}

mcl_more_signs.wall_fdir_to_back_left = {
	[2] = {  1,  1 },
	[3] = { -1, -1 },
	[4] = { -1,  1 },
	[5] = {  1, -1 }
}

mcl_more_signs.rotate_walldir = {
	[0] = 4,
	[1] = 0,
	[2] = 5,
	[3] = 1,
	[4] = 2,
	[5] = 3
}

mcl_more_signs.rotate_walldir_simple = {
	[0] = 4,
	[1] = 4,
	[2] = 5,
	[3] = 4,
	[4] = 2,
	[5] = 3
}

mcl_more_signs.rotate_facedir = {
	[0] = 1,
	[1] = 2,
	[2] = 3,
	[3] = 4,
	[4] = 6,
	[5] = 6,
	[6] = 0
}

mcl_more_signs.rotate_facedir_simple = {
	[0] = 1,
	[1] = 2,
	[2] = 3,
	[3] = 0,
	[4] = 0,
	[5] = 0
}

-- entity handling
minetest.register_entity("mcl_more_signs:text", {
	initial_properties = {
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		visual = "mesh",
		mesh = "signs_lib_standard_sign_entity_wall.obj",
		textures = {},
		static_save = true,
		backface_culling = false,
	},
	on_activate = function(self)
		local node = minetest.get_node(self.object:get_pos())
		if minetest.get_item_group(node.name, "sign") == 0 then
			self.object:remove()
		end
	end,
	on_blast = function(self, damage)
		return false, false, {}
	end,
})

-- Удаляет entity с текстом, если они существуют.
function mcl_more_signs.delete_objects(pos)
	local objects = minetest.get_objects_inside_radius(pos, 0.5)
	for _, v in ipairs(objects) do
		if v then
			local e = v:get_luaentity()
			if e and e.name == "mcl_more_signs:text" then
				v:remove()
			end
		end
	end
end

-- ucsigns
--Text entity handling
function mcl_more_signs.get_text_entity(pos, force_remove)
	local objects = minetest.get_objects_inside_radius(pos, 0.5)
	local text_entity
	if #objects > 0 then
		local i = 0
		for _, v in pairs(objects) do
			local entity = v:get_luaentity()
			if entity and entity.name == "mcl_more_signs:text" then
				i = i + 1
				if i > 1 or force_remove == true then
					v:remove()
				else
					text_entity = v
				end
			end
		end
	end
	return text_entity
end

-- Создает entity, на которой будет размещен текст таблички.
function mcl_more_signs.spawn_entity(pos, texture, glow)
	local node = minetest.get_node(pos)
	local def = minetest.registered_items[node.name]
	if not def or not def.entity_info then return end

	local text_scale = (node.text_scale) or mcl_more_signs.default_text_scale

	-- Получаем текстовую сущность (или создаем новую)
	local text_entity = mcl_more_signs.get_text_entity(pos)
	if not text_entity then
		text_entity = minetest.add_entity(pos, "mcl_more_signs:text")
	end

	-- Установка угла поворота по умолчанию
	local yaw = 0
	local pitch = 0

	-- Настройка поворота для разных типов табличек
	if def.paramtype2 == "degrotate" then
		-- перевод param2 (0-239) в радианы
		yaw = (node.param2 or 0) * (math.pi * 2 / 240)
		 -- Если угол слишком мал, используем минимум для yaw
		--local yaw_before = yaw
		if math.abs(yaw) < 0.05 then
			yaw = 1
		end
		--minetest.log("node.name=" .. dump(node.name) ..  " yaw_before=" .. yaw_before .. " yaw=" .. yaw)
	elseif def.paramtype2 == "facedir" then
		local facedir_to_yaw = {
			[0] = 0,
			[1] = math.pi / 2,
			[2] = math.pi,
			[3] = -math.pi / 2,
		}
		yaw = facedir_to_yaw[node.param2 % 4] or 0
	elseif def.paramtype2 == "wallmounted" then
		local rot90 = math.pi / 2
		if node.param2 == 1 then -- на полу
			pitch = -rot90
			yaw = 0
		elseif node.param2 == 0 then -- на потолке
			pitch = rot90
			yaw = math.pi
		end
	end

	-- Если у таблички есть особый угол в entity_info
	if def.entity_info and def.entity_info.yaw then
		yaw = def.entity_info.yaw[node.param2 + 1] or yaw
	end

	-- Применяем поворот
	text_entity:set_rotation({x = pitch, y = yaw, z = 0})

	-- Настройка текстуры и размера
	local props = {
		mesh = def.entity_info.mesh,
		visual_size = text_scale,
	}
	if texture then
		props.textures = {texture}
	end
	text_entity:set_properties(props)

	-- Настройка свечения, если указано
	if glow and glow ~= "" then
		text_entity:set_properties({glow = tonumber(glow) * 5})
	end
end

-- Функция выполняет разбиение текста:
-- 1. Сначала на строки (по символу новой строки \n),
-- 2. Затем каждую строку на слова (по пробелам).
-- 3. Возвращает таблицу, где каждая строка — это список слов.
-- Это полезно для обработки текстов на табличках, когда нужно работать с отдельными строками и словами.
function mcl_more_signs.split_lines_and_words(text)
	if not text then return end
	local lines = { }
	for _, line in ipairs(text:split("\n", true)) do
		table.insert(lines, line:split(" "))
	end
	return lines
end

-- Используется при изменении текста на табличке, обновляя её отображение.
-- 1. Преобразует текст в ANSI (если он в Unicode).
-- 2. Удаляет предыдущий текст с таблички.
-- 3. Если текст не пустой, создаёт новую текстуру с текстом.
-- 4. Отображает текст на табличке, создавая объект-надпись.
function mcl_more_signs.set_obj_text(pos, text, glow)
	local split = mcl_more_signs.split_lines_and_words
	local text_ansi = mcl_more_signs.Utf8ToAnsi(text)
	mcl_more_signs.delete_objects(pos)
	-- only create sign entity for actual text
	if text_ansi and text_ansi ~= "" then
		local text_texture = mcl_more_signs.make_sign_texture(split(text_ansi), pos)
		mcl_more_signs.spawn_entity(pos, text_texture, glow)
	end
end

-- rotation
function mcl_more_signs.handle_rotation(pos, node, user, mode)
	if not mcl_more_signs.can_modify(pos, user) or 
		mode ~= screwdriver.ROTATE_FACE then
		return false
	end
	local newparam2
	local tpos = pos
	local def = minetest.registered_items[node.name]

	if string.match(node.name, "_onpole") then
		newparam2 = mcl_more_signs.rotate_walldir_simple[node.param2] or 4
		local t = mcl_more_signs.wall_fdir_to_back_left

		if def.paramtype2 ~= "wallmounted" then
			newparam2 = mcl_more_signs.rotate_facedir_simple[node.param2] or 0
			t  = mcl_more_signs.fdir_to_back_left
		end

		tpos = {
			x = pos.x + t[node.param2][1],
			y = pos.y,
			z = pos.z + t[node.param2][2]
		}

		local node2 = minetest.get_node(tpos)
		local def2 = minetest.registered_items[node2.name]
		if not def2 or not def2.buildable_to then return true end -- undefined, or not buildable_to.

		minetest.set_node(tpos, {name = node.name, param2 = newparam2})
		minetest.get_meta(tpos):from_table(minetest.get_meta(pos):to_table())
		minetest.remove_node(pos)
		mcl_more_signs.delete_objects(pos)
	elseif string.match(node.name, "_hanging") then
		minetest.swap_node(tpos, { name = node.name, param2 = mcl_more_signs.rotate_facedir_simple[node.param2] or 0 })
	elseif minetest.registered_items[node.name].paramtype2 == "wallmounted" then
		minetest.swap_node(tpos, { name = node.name, param2 = mcl_more_signs.rotate_walldir[node.param2] or 0 })
	elseif minetest.registered_items[node.name].paramtype2 == "degrotate" then
		local rotation_step_in_degrees = 45 -- Шаг поворота можно сделать: 15, 45, 90 градусов
		local current_rotation_in_degrees = node.param2 or 0 -- Получаем текущее значение degrotate (0-359 градусов)
		local new_rotation = (current_rotation_in_degrees + rotation_step_in_degrees) % 360
		minetest.swap_node(tpos, {name = node.name, param2 = new_rotation})
	else
		minetest.swap_node(tpos, { name = node.name, param2 = mcl_more_signs.rotate_facedir[node.param2] or 0 })
	end

	mcl_more_signs.update_sign(tpos)
	return true
end

-- infinite stacks
if not minetest.settings:get_bool("creative_mode") then
	mcl_more_signs.expect_infinite_stacks = false
else
	mcl_more_signs.expect_infinite_stacks = true
end

--Функция mcl_more_signs.rightclick_sign(pos, node, player, itemstack, pointed_thing) выполняет следующие шаги:
--1) Проверяет, может ли игрок изменять табличку (есть ли у него соответствующие права).
--2) Проверяет, что у игрока есть возможность получить метаданные.
--3) Сохраняет в метаданных игрока позицию таблички, по которой он кликнул.
--4) Открывает форму редактирования таблички для игрока, где он может изменить текст и другие параметры.
--Эта функция позволяет игроку правым кликом открыть интерфейс для редактирования таблички.
function mcl_more_signs.rightclick_sign(pos, node, player, itemstack, pointed_thing)
	if not player or not mcl_more_signs.can_modify(pos, player) then 
		return 
	end

	if not player.get_meta then 
		return 
	end

	player:get_meta():set_string("signslib:pos", minetest.pos_to_string(pos))
	minetest.show_formspec(player:get_player_name(), "mcl_more_signs:sign", get_sign_formspec(pos, node.name))
end

--Функция mcl_more_signs.destruct_sign(pos) делает следующее:
-- 1) Проверяет, была ли у таблички функция свечения (glow).
-- 2) Если свечение было и игрок не в креативе – дропает предмет свечения (glow_item).
-- 3) Вызывает delete_objects(pos), чтобы убрать все связанные объекты (например, 3D-текст).
--Когда вызывается?
--  При разрушении таблички (рукой, инструментом, взрывом и т. д.).
--  Когда заменяется табличка другим блоком.
-- Функция предотвращает потерю ресурсов, если игрок использовал предмет для свечения!
function mcl_more_signs.destruct_sign(pos)
	local meta = minetest.get_meta(pos)
	local glow = meta:get_string("glow")
	if glow ~= "" and not minetest.is_creative_enabled("") then
		local num = tonumber(glow)
		minetest.add_item(pos, ItemStack(mcl_more_signs.glow_item .. " " .. num))
	end
	mcl_more_signs.delete_objects(pos)
end

-- Функция mcl_more_signs.blast_sign(pos, intensity) выполняет следующие действия:
-- 1) Проверяет, можно ли разрушить табличку (учитывает защиту).
-- 2) Получает данные о табличке (какой блок в pos).
-- 3) Определяет дроп (что выпадет при взрыве).
-- 4) Удаляет табличку из мира.
-- 5) Возвращает список дропа (что выпало).
-- Используется для разрушения табличек при взрыве (TNT, динамит и т.д.).
function mcl_more_signs.blast_sign(pos, intensity)
	if mcl_more_signs.can_modify(pos, "") then
		local node = minetest.get_node(pos)
		local drops = minetest.get_node_drops(node, "tnt:blast")
		minetest.remove_node(pos)
		return drops
	end
end

-- Функция обрабатывает текст таблички перед отображением в инфотексте.
-- 1) Удаляет лишние пробелы.
-- 2) Разбивает текст на строки и слова.
-- 3) Фильтрует символы # и ^, предотвращая баги.
-- 4) Собирает текст обратно и возвращает готовый вариант.
local function make_infotext(text)
	text = mcl_more_signs.trim_input(text)
	local lines = mcl_more_signs.split_lines_and_words(text) or {}
	local lines2 = { }
	for _, line in ipairs(lines) do
		table.insert(lines2, (table.concat(line, " "):gsub("#[0-9a-fA-F#^]", function (s)
			return s:sub(2):find("[#^]") and s:sub(2) or ""
		end)))
	end
	return table.concat(lines2, "\n")
end

-- Эта функция увеличивает уровень свечения таблички (до максимума 3), 
-- если игрок ударил по ней специальным предметом:
-- 1. Проверяет защиту территории.
-- 2. Работает только с определённым предметом (glow_item).
-- 3. Повышает свечение (glow), но не выше 3.
-- 4. В режиме выживания тратит ресурс.
-- 5. Сохраняет уровень свечения в метаданных таблички.
function mcl_more_signs.glow(pos, node, puncher)
	local name = puncher:get_player_name()
	if minetest.is_protected(pos, name) then
		return
	end
	local tool = puncher:get_wielded_item()
	if tool:get_name() == mcl_more_signs.glow_item then
		local meta = minetest.get_meta(pos)
		local glow = tonumber(meta:get_string("glow"))
		if not glow then
			glow = 1
		elseif glow < 3 then
			glow = glow + 1
		else
			return -- already at brightest level
		end
		if not minetest.is_creative_enabled(name) then
			tool:take_item()
			puncher:set_wielded_item(tool)
		end
		meta:set_string("glow", glow)
	end
end

local function get_signmeta(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	if not def or minetest.get_item_group(node.name, "_mcl_more_signs") < 1 then
		return 
	end

	local meta = minetest.get_meta(pos)
	local text = meta:get_string("text")
	local glow = meta:get_string("glow")
	local owner = meta:get_string("owner")
	local formspec = meta:get_string("formspec")
	local infotext = meta:get_string("infotext")

	--[[
	if glow == "true" then 
		glow = true 
	else 
		glow = false 
	end
	]]

	-- legacy udpate
	if formspec ~= "" then 
		formspec = ""
	end

	local yaw
	if def.paramtype2  == "wallmounted" then
		local dir = minetest.wallmounted_to_dir(node.param2)
		yaw = minetest.dir_to_yaw(dir)
	else
		yaw = math.rad(((node.param2 * 1.5 ) + 1 ) % 360)
	end

	return {
		text = text,
		glow = glow,
		owner = owner,
		formspec = formspec,
		infotext = infotext,
		yaw = yaw,
	}
end

local function set_signmeta(pos, data)
	local meta = minetest.get_meta(pos)

	if data.text then meta:set_string("text", data.text) end
	--if def.color then meta:set_string("color", def.color) end
	if data.glow then meta:set_string("glow", data.glow) end
	if data.owner then meta:set_string("owner", data.owner) end
	if data.formspec then meta:set_string("formspec", data.formspec) end
	if data.infotext then meta:set_string("infotext", data.infotext) end
end

-- Эта функция обновляет текст на табличке, обрабатывает переносы строк, 
-- добавляет инфотекст и меняет отображение 3D-модели:
-- 1) Заменяет старый formspec (устаревший метод).
-- 2) Обрабатывает вводимый текст (обрезает пробелы, исправляет переносы строк).
-- 3) Если табличка "закрыта", указывает владельца.
-- 4) Поддерживает подсветку (glow).
-- 5) Обновляет текст, отображаемый на 3D-модели таблички.
function mcl_more_signs.update_sign(pos, fields)
	local data = get_signmeta(pos)
	if not data then return end

	local text = fields and fields.text or data.text
	text = mcl_more_signs.trim_input(text)

	-- Fix pasting from Windows: CR instead of LF
	text = string.gsub(text, "\r\n?", "\n")

	data.text = text

	local ownstr = ""
	if data.owner ~= "" then 
		ownstr = S("Locked sign, owned by @1\n", data.owner) 
	end

	data.infotext = ownstr .. make_infotext(text) .. " "

	set_signmeta(pos, data)

	mcl_more_signs.set_obj_text(pos, text, data.glow)
end

-- Эта функция разрешает или запрещает изменение табличек (или других объектов), проверяя:
-- 1. Защищена ли территория (is_protected).
-- 2. Кто является владельцем (owner).
-- 3. Есть ли у игрока нужные права (edit_priv).
function mcl_more_signs.can_modify(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local playername
	if type(player) == "userdata" then
		playername = player:get_player_name()
	elseif type(player) == "string" then
		playername = player
	else
		playername = ""
	end

	if minetest.is_protected(pos, playername) then
		minetest.record_protection_violation(pos, playername)
		return false
	end

	--[[
	if owner == "" or 
		playername == owner or 
		minetest.get_player_privs(playername)[mcl_more_signs.edit_priv] or 
		(playername == minetest.settings:get("name")) then
		return true
	end
	]]

	if owner == "" or 
		playername == owner or 
		minetest.get_player_privs(playername)[mcl_more_signs.edit_priv] then
		return true
	end

	minetest.record_protection_violation(pos, playername)
	return false
end

-- make selection boxes
-- sizex/sizey specified in inches because that's what MUTCD uses.
function mcl_more_signs.make_selection_boxes(sizex, sizey, xoffs, yoffs, zoffs, is_facedir)
	local tx = (sizex * 0.0254 ) / 2
	local ty = (sizey * 0.0254 ) / 2
	local xo = xoffs and xoffs * 0.0254 or 0
	local yo = yoffs and yoffs * 0.0254 or 0
	local zo = zoffs and zoffs * 0.0254 or 0

	if is_facedir then
		return {
			type = "fixed",
			fixed = { -tx + xo, -ty + yo, 0.5 + zo, tx + xo, ty + yo, 0.4375 + zo}
		}
	else
		return {
			type = "wallmounted",
			wall_side =   { -0.5 + zo, -ty + yo, -tx + xo, -0.4375 + zo, ty + yo, tx + xo },
			wall_top =    { -tx - xo, 0.5 + zo, -ty + yo, tx - xo, 0.4375 + zo, ty + yo},
			wall_bottom = { -tx - xo, -0.5 + zo, -ty + yo, tx - xo, -0.4375 + zo, ty + yo }
		}
	end
end

-- Функция проверяет, можно ли разместить объект на fence.
function mcl_more_signs.check_for_pole(pos, pointed_thing)
	local ppos = minetest.get_pointed_thing_position(pointed_thing)
	local pnode = minetest.get_node(ppos)
	local pdef = minetest.registered_items[pnode.name]

	if not pdef then return end

	if mcl_more_signs.check_for_ceiling(pointed_thing) or mcl_more_signs.check_for_floor(pointed_thing) then
		return false
	end

	if type(pdef.check_for_pole) == "function" then
		local node = minetest.get_node(pos)
		local def = minetest.registered_items[node.name]
		return pdef.check_for_pole(pos, node, def, ppos, pnode, pdef)
	elseif pdef.check_for_pole or 
		pdef.drawtype == "fencelike" or 
		string.find(pnode.name, "_fence") then
		return true
	end
end

-- Она проверяет, целится ли игрок в нижнюю сторону блока,
-- то есть пытается ли разместить объект на потолке.
function mcl_more_signs.check_for_ceiling(pointed_thing)
	if pointed_thing.above.x == pointed_thing.under.x and 
		pointed_thing.above.z == pointed_thing.under.z and 
		pointed_thing.above.y < pointed_thing.under.y then
		return true
	end
end

-- Она проверяет, целится ли игрок в верхнюю сторону блока,
-- то есть пытается ли разместить объект на полу.
function mcl_more_signs.check_for_floor(pointed_thing)
	if pointed_thing.above.x == pointed_thing.under.x and 
		pointed_thing.above.z == pointed_thing.under.z and 
		pointed_thing.above.y > pointed_thing.under.y then
		return true
	end
end

-- Функция для перевода радиан в градусы
local function radians_to_degrees(radians)
	return radians * 180 / math.pi
end

-- currently have to do this, because of how the base node placement works.
function mcl_more_signs.on_place(itemstack, placer, pointed_thing)
	local pos = pointed_thing.above
	local above = pointed_thing.above -- это позиция, куда игрок пытается поставить новый блок.
	local under = pointed_thing.under -- это позиция блока, на который игрок кликнул.
	local controls = placer:get_player_control()
	local signname = itemstack:get_name()
	local playername = placer:get_player_name()
	local node_placed = false

	-- Use pointed node's on_rightclick function first, if present
	local node_under = minetest.get_node(under)
	if placer and not placer:get_player_control().sneak then
		if minetest.registered_nodes[node_under.name] and minetest.registered_nodes[node_under.name].on_rightclick then
			return minetest.registered_nodes[node_under.name].on_rightclick(under, node_under, placer, itemstack) or itemstack
		end
	end

	-- Only build when it's legal
	local abovenodedef = minetest.registered_nodes[minetest.get_node(above).name]
	if not abovenodedef or abovenodedef.buildable_to == false then
		return itemstack
	end

	local dir = vector.subtract(under, above)
	local def = minetest.registered_items[signname]

	if def.allow_onpole and mcl_more_signs.check_for_pole(pos, pointed_thing) and not controls.sneak then
		-- Sign on fence
		local newparam2 = minetest.dir_to_wallmounted(dir)
		minetest.swap_node(pos, {name = signname .. "_onpole", param2 = newparam2})
		node_placed = true
	elseif def.allow_hanging and mcl_more_signs.check_for_ceiling(pointed_thing) and not controls.sneak then
		-- Hanging sign
		local newparam2 = minetest.dir_to_facedir(placer:get_look_dir())
		minetest.swap_node(pos, {name = signname .. "_hanging", param2 = newparam2})
		node_placed = true
	elseif def.allow_yard and mcl_more_signs.check_for_floor(pointed_thing) and not controls.sneak then
		-- Standing sign
		local yaw = radians_to_degrees(placer:get_look_horizontal())
		-- Переводим градусы в шаги так как param2 хранит знаечения в шагах в диапзоне (0-239), 1 шаг = 1.5 градуса.
		local newparam2 = math.floor((yaw % 360) / 1.5) 
		minetest.swap_node(pos, {name = signname, param2 = newparam2})
		node_placed = true
	elseif def.allow_wall then
		-- Wall sign
		local newparam2 = minetest.dir_to_wallmounted(dir)
		minetest.swap_node(pos, {name = signname .. "_wall", param2 = newparam2})
		node_placed = true
	end

	if node_placed and def.locked then
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", playername)
		meta:set_string("infotext", S("Locked sign, owned by @1\n", playername))
	end

	-- Уменьшение количества в инвентаре, если табличка установлена
	if node_placed and not minetest.is_creative_enabled(playername) then
		itemstack:take_item()
		placer:set_wielded_item(itemstack) -- обновляет предмет в руке игрока
	end

	return itemstack
end

function mcl_more_signs.register_fence_with_sign()
	log("warning", "Attempt to call no longer used function mcl_more_signs.register_fence_with_sign()")
end

local use_glow = function(pos, node, puncher, pointed_thing)
	if puncher then -- if e.g. a machine tries to punch; only a real person should change the lighting
		mcl_more_signs.glow(pos, node, puncher)
	end
	return mcl_more_signs.update_sign(pos)
end

local glow_drops = function(pos, oldnode, oldmetadata, digger)
	if digger and minetest.is_creative_enabled(digger:get_player_name()) then
		return
	end
	local glow = oldmetadata and oldmetadata.fields and oldmetadata.fields.glow
	if glow then
		minetest.add_item(pos, ItemStack(mcl_more_signs.glow_item .. " " .. glow))
	end
end

function mcl_more_signs.register_wall_sign(name, def, raw_def)
	local wall_def = table.copy(def)
	wall_def.paramtype2 = "wallmounted"

	local sbox = mcl_more_signs.make_selection_boxes(35, 25)

	wall_def.selection_box = table.copy(raw_def.selection_box or sbox)
	wall_def.node_box = table.copy(raw_def.node_box or raw_def.selection_box or sbox)
	wall_def.groups.not_in_creative_inventory = 1

	wall_def.tiles[3] = "signs_lib_blank.png" -- 3. Текстура для крепления к столбу (по умолчанию)
	wall_def.tiles[4] = "signs_lib_blank.png" -- 4. Текстура для подвесных цепей (по умолчанию)
	wall_def.tiles[5] = "signs_lib_blank.png" -- 5. Текстура для стойки в виде дворового знака (yard sign)
	wall_def.tiles[6] = "signs_lib_blank.png"

	minetest.register_node(":" .. name .. "_wall", wall_def)
	table.insert(mcl_more_signs.lbm_restore_nodes, name .. "_wall")
end

function mcl_more_signs.register_onpole_sign(name, def, raw_def)
	local othermounts_def = table.copy(def)
	othermounts_def.paramtype2 = "wallmounted"

	local offset = 0.3125
	if othermounts_def.uses_slim_pole_mount then
		offset = 0.35
	end

	local sbox = mcl_more_signs.make_selection_boxes(35, 25)

	othermounts_def.selection_box = table.copy(raw_def.onpole_selection_box or sbox)
	othermounts_def.node_box = table.copy(raw_def.onpole_node_box or sbox)
	othermounts_def.groups.not_in_creative_inventory = 1

	if othermounts_def.paramtype2 == "wallmounted" then
		othermounts_def.node_box.wall_side[1] = sbox.wall_side[1] - offset
		othermounts_def.node_box.wall_side[4] = sbox.wall_side[4] - offset

		othermounts_def.selection_box.wall_side[1] = sbox.wall_side[1] - offset
		othermounts_def.selection_box.wall_side[4] = sbox.wall_side[4] - offset
	else
		--[[
		othermounts_def.node_box.fixed[3] = def.selection_box.fixed[3] + offset
		othermounts_def.node_box.fixed[6] = def.selection_box.fixed[6] + offset

		othermounts_def.selection_box.fixed[3] = def.selection_box.fixed[3] + offset
		othermounts_def.selection_box.fixed[6] = def.selection_box.fixed[6] + offset
		]]
	end

	othermounts_def.mesh = raw_def.onpole_mesh or string.gsub(othermounts_def.mesh, "wall.obj$", "onpole.obj")

	if othermounts_def.entity_info then
		othermounts_def.entity_info.mesh = string.gsub(othermounts_def.entity_info.mesh, "entity_wall.obj$", "entity_onpole.obj")
	end

	-- setting one of item 3 or 4 to a texture and leaving the other "blank",
	-- reveals either the vertical or horizontal pole mount part of the model
	othermounts_def.tiles[3] = raw_def.tiles[3] or "signs_lib_pole_mount.png"
	othermounts_def.tiles[4] = "signs_lib_blank.png"
	othermounts_def.tiles[5] = "signs_lib_blank.png"
	othermounts_def.tiles[6] = "signs_lib_blank.png"

	minetest.register_node(":" .. name .. "_onpole", othermounts_def)
	table.insert(mcl_more_signs.lbm_restore_nodes, name .. "_onpole")
end

function mcl_more_signs.register_hanging_sign(name, def, raw_def)
	local hanging_def = table.copy(def)
	hanging_def.paramtype2 = "facedir"

	local sbox = mcl_more_signs.make_selection_boxes(35, 32, 0, 3, -18.5, true)

	hanging_def.selection_box = table.copy(raw_def.hanging_selection_box or sbox)
	hanging_def.node_box = table.copy(raw_def.hanging_node_box or raw_def.hanging_selection_box or sbox)
	hanging_def.groups.not_in_creative_inventory = 1

	hanging_def.tiles[3] = raw_def.tiles[4] or "signs_lib_hangers.png"
	hanging_def.tiles[4] = "signs_lib_blank.png"
	hanging_def.tiles[5] = "signs_lib_blank.png"
	hanging_def.tiles[6] = "signs_lib_blank.png"

	hanging_def.mesh = raw_def.hanging_mesh or string.gsub(string.gsub(hanging_def.mesh, "wall.obj$", "hanging.obj"), "_facedir", "")

	if hanging_def.entity_info then
		hanging_def.entity_info.mesh = string.gsub(string.gsub(hanging_def.entity_info.mesh, "entity_wall.obj$", "entity_hanging.obj"), "_facedir", "")
		hanging_def.entity_info.yaw = mcl_more_signs.standard_yaw
	end

	minetest.register_node(":" .. name .. "_hanging", hanging_def)
	table.insert(mcl_more_signs.lbm_restore_nodes, name .. "_hanging")
end

function mcl_more_signs.register_yard_sign(name, def, raw_def)
	local yard_def = table.copy(def)
	yard_def.paramtype2 = "degrotate"

	local sbox = { type = "fixed", fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 } }

	yard_def.selection_box = table.copy(raw_def.yard_selection_box or sbox)
	yard_def.node_box = table.copy(raw_def.yard_node_box or raw_def.yard_selection_box or sbox)
	yard_def.groups.not_in_creative_inventory = 0

	yard_def.tiles[3] = raw_def.tiles[5] or "default_wood.png"
	yard_def.tiles[4] = "signs_lib_blank.png"
	yard_def.tiles[5] = "signs_lib_blank.png"
	yard_def.tiles[6] = "signs_lib_blank.png"

	yard_def.mesh = raw_def.yard_mesh or string.gsub(string.gsub(yard_def.mesh, "wall.obj$", "yard.obj"), "_facedir", "")

	if yard_def.entity_info then
		yard_def.entity_info.mesh = string.gsub(string.gsub(yard_def.entity_info.mesh, "entity_wall.obj$", "entity_yard.obj"), "_facedir", "")
		yard_def.entity_info.yaw = mcl_more_signs.standard_yaw
	end

	minetest.register_node(":" .. name, yard_def)
	table.insert(mcl_more_signs.lbm_restore_nodes, name)
end

function mcl_more_signs.register_sign(name, raw_def)
	local def = table.copy(raw_def)
	-- Этот блок не будет заменён при генерации мира. Если поставить true, блок может исчезнуть или замениться 
	-- чем-то другим при генерации, например, если он будет находиться в зоне формирования пещеры.
	def.is_ground_content = false 

	-- Этот параметр задаёт твёрдость блока, которая определяет, как быстро блок будет разрушаться при взаимодействии 
	-- с инструментами. Блоки с большей твёрдостью требуют больше времени или специальных 
	-- инструментов для разрушения. Например, камень имеет большую твёрдость, чем земля.
	def._mcl_hardness = 1

	-- Этот параметр отвечает за стойкость блока к взрывам. Чем выше значение blast_resistance, тем менее вероятно, что 
	-- блок будет разрушен взрывом (например, от динамита или дракона).
	def._mcl_blast_resistance = 1

	def.walkable = false

	if raw_def.entity_info == "standard" then
		def.entity_info = {
			mesh = "signs_lib_standard_sign_entity_wall.obj",
			yaw = mcl_more_signs.wallmounted_yaw
		}
	elseif raw_def.entity_info then
		def.entity_info = raw_def.entity_info
	end

	def.on_blast = raw_def.on_blast or mcl_more_signs.blast_sign
	
	if raw_def.entity_info then
		if def.allow_glow ~= false then
			def.on_punch = raw_def.on_punch or use_glow
			def.after_dig_node = raw_def.after_dig_node or glow_drops
		else
			def.on_punch = raw_def.on_punch or mcl_more_signs.update_sign
		end

		def.on_rightclick = raw_def.on_rightclick or mcl_more_signs.rightclick_sign
		def.on_destruct = raw_def.on_destruct or mcl_more_signs.destruct_sign
		def.number_of_lines = raw_def.number_of_lines or mcl_more_signs.standard_lines
		def.horiz_scaling = raw_def.horiz_scaling or mcl_more_signs.standard_hscale
		def.vert_scaling = raw_def.vert_scaling or mcl_more_signs.standard_vscale
		def.line_spacing = raw_def.line_spacing or mcl_more_signs.standard_lspace
		def.font_size = raw_def.font_size or mcl_more_signs.standard_fsize
		def.x_offset = raw_def.x_offset or mcl_more_signs.standard_xoffs
		def.y_offset = raw_def.y_offset or mcl_more_signs.standard_yoffs
		def.chars_per_line = raw_def.chars_per_line or mcl_more_signs.standard_cpl
		def.default_color = raw_def.default_color or "0"
		if not raw_def.on_place then
			def.on_place = function(itemstack, placer, pointed_thing)
				mcl_more_signs.on_place(itemstack, placer, pointed_thing)
			end
		end
	end

	def.paramtype = raw_def.paramtype or "light"
	def.drawtype = raw_def.drawtype or "mesh"
	def.mesh = raw_def.mesh or "signs_lib_standard_sign_wall.obj"
	def.wield_image = raw_def.wield_image or def.inventory_image
	def.drop = raw_def.drop or name
	def.sounds = raw_def.sounds or mcl_more_signs.standard_stone_sign_sounds
	def.on_rotate = raw_def.on_rotate or mcl_more_signs.handle_rotation
	
	if raw_def.groups then
		def.groups = raw_def.groups
	else
		def.groups = mcl_more_signs.standard_wood_groups
	end

	def.groups._mcl_more_signs = 1

	-- force all signs into the sign group
	def.groups.sign = def.groups.sign or 1

	if def.sunlight_propagates ~= false then
		-- Cолнечный свет может проходить через этот блок (например, стекло, листья, воздух).
		-- Выставляя sunlight_propagates = true, разработчики делают освещение более естественным. 
		-- Если бы табличка блокировала свет, это выглядело бы странно, особенно в интерьерах и на улицах.
		def.sunlight_propagates = true
	end

	if raw_def.allow_onpole then
		mcl_more_signs.register_onpole_sign(name, def, raw_def)
	end
	
	if raw_def.allow_wall then
		mcl_more_signs.register_wall_sign(name, def, raw_def)
	end

	if raw_def.allow_hanging then
		mcl_more_signs.register_hanging_sign(name, def, raw_def)
	end

	if raw_def.allow_yard then
		mcl_more_signs.register_yard_sign(name, def, raw_def)
	end

	--[[
	if raw_def.allow_widefont then
		table.insert(mcl_more_signs.old_widefont_signs, name .. "_widefont")
		table.insert(mcl_more_signs.old_widefont_signs, name .. "_widefont_onpole")
		table.insert(mcl_more_signs.old_widefont_signs, name .. "_widefont_hanging")
		table.insert(mcl_more_signs.old_widefont_signs, name .. "_widefont_yard")
	end
	]]
end

-- restore signs' text after /clearobjects and the like, the next time
-- a block is reloaded by the server.
minetest.register_lbm({
	nodenames = mcl_more_signs.lbm_restore_nodes,
	name = "mcl_more_signs:restore_sign_text",
	label = "Restore sign text",
	run_at_every_load = true,
	action = function(pos, node)
		mcl_more_signs.update_sign(pos, nil, nil, node)
	end
})

-- Convert old signs on fenceposts into signs on.. um.. fence posts :P
minetest.register_lbm({
	nodenames = mcl_more_signs.old_fenceposts_with_signs,
	name = "mcl_more_signs:fix_fencepost_signs",
	label = "Change single-node signs on fences into normal",
	run_at_every_load = true,
	action = function(pos, node)
		local fdir = node.param2 % 8
		local signpos = {
			x = pos.x + mcl_more_signs.fdir_to_back[fdir+1][1],
			y = pos.y,
			z = pos.z + mcl_more_signs.fdir_to_back[fdir+1][2]
		}

		if minetest.get_node(signpos).name == "air" then
			local new_wmdir = minetest.dir_to_wallmounted(minetest.facedir_to_dir(fdir))
			local oldfence =  mcl_more_signs.old_fenceposts[node.name]
			local newsign =   mcl_more_signs.old_fenceposts_replacement_signs[node.name]

			mcl_more_signs.delete_objects(pos)

			local oldmeta = minetest.get_meta(pos):to_table()
			minetest.set_node(pos, {name = oldfence})
			minetest.set_node(signpos, { name = newsign, param2 = new_wmdir })
			local newmeta = minetest.get_meta(signpos)
			newmeta:from_table(oldmeta)
			mcl_more_signs.update_sign(signpos)
		end
	end
})

-- Convert widefont sign nodes to use one base node with meta flag to select wide mode
minetest.register_lbm({
	nodenames = mcl_more_signs.old_widefont_signs,
	name = "mcl_more_signs:convert_widefont_signs",
	label = "Convert widefont sign nodes",
	run_at_every_load = false,
	action = function(pos, node)
		local basename = string.gsub(node.name, "_widefont", "")
		minetest.swap_node(pos, {name = basename, param2 = node.param2})
		local meta = minetest.get_meta(pos)
		meta:set_int("widefont", 1)
		mcl_more_signs.update_sign(pos)
	end
})

-- Maintain a list of currently-loaded blocks
minetest.register_lbm({
	nodenames = {"group:sign"},
	name = "mcl_more_signs:update_block_list",
	label = "Update list of loaded blocks, log only those with signs",
	run_at_every_load = true,
	action = function(pos, node)
		-- yeah, yeah... I know I'm hashing a block pos, but it's still just a set of coords
		local hash = minetest.hash_node_position(vector.floor(vector.divide(pos, minetest.MAP_BLOCKSIZE)))
		if not mcl_more_signs.block_list[hash] then
			mcl_more_signs.block_list[hash] = true
			mcl_more_signs.totalblocks = mcl_more_signs.totalblocks + 1
		end
	end
})

minetest.register_chatcommand("regen_signs", {
	params = "",
	privs = {server = true},
	description = S("Skims through all currently-loaded sign-bearing mapblocks, clears away any entities within each sign's node space, and regenerates their text entities, if any."),
	func = function(player_name, params)
		local allsigns = {}
		local totalsigns = 0
		for b in pairs(mcl_more_signs.block_list) do
			local blockpos = minetest.get_position_from_hash(b)
			local pos1 = vector.multiply(blockpos, minetest.MAP_BLOCKSIZE)
			local pos2 = vector.add(pos1, minetest.MAP_BLOCKSIZE - 1)
			if minetest.get_node_or_nil(vector.add(pos1, minetest.MAP_BLOCKSIZE/2)) then
				local signs_in_block = minetest.find_nodes_in_area(pos1, pos2, {"group:sign"})
				allsigns[#allsigns + 1] = signs_in_block
				totalsigns = totalsigns + #signs_in_block
			else
				mcl_more_signs.block_list[b] = nil -- if the block is no longer loaded, remove it from the table
				mcl_more_signs.totalblocks = mcl_more_signs.totalblocks - 1
			end
		end
		if mcl_more_signs.totalblocks < 0 then mcl_more_signs.totalblocks = 0 end
		if totalsigns == 0 then
			minetest.chat_send_player(player_name, S("There are no signs in the currently-loaded terrain."))
			mcl_more_signs.block_list = {}
			return
		end

		minetest.chat_send_player(player_name, S("Found a total of @1 sign nodes across @2 blocks.", totalsigns, mcl_more_signs.totalblocks))
		minetest.chat_send_player(player_name, S("Regenerating sign entities ..."))

		for _, b in pairs(allsigns) do
			for _, pos in ipairs(b) do
				mcl_more_signs.delete_objects(pos)
				local node = minetest.get_node(pos)
				local def = minetest.registered_items[node.name]
				if def and def.entity_info then
					mcl_more_signs.update_sign(pos)
				end
			end
		end
		minetest.chat_send_player(player_name, S("Finished."))
	end
})

minetest.register_on_mods_loaded(function()
	if not minetest.registered_privileges[mcl_more_signs.edit_priv] then
		minetest.register_privilege(mcl_more_signs.edit_priv, {
			description = "Allows editing of locked signs",
			give_to_singleplayer = false, -- отключает привилегию для одиночной игры
		})
	end
end)

--
-- local functions
--
function get_sign_formspec(pos, nodename)
	local meta = minetest.get_meta(pos)
	local txt = meta:get_string("text")
	local state = meta:get_int("unifont") == 1 and "on" or "off"

	local formspec = {
		"size[6,4]",
		"background[-0.5,-0.5;7,5;signs_lib_sign_bg.png]",
		"image[0.1,2.4;7,1;signs_lib_sign_color_palette.png]",
		"textarea[0.15,-0.2;6.3,2.8;text;;" .. minetest.formspec_escape(txt) .. "]",
		"button_exit[3.7,3.4;2,1;ok;" .. S("Write") .. "]",
	}

	-- Добавление кнопки Unicode, если unicode_enabled = true
	if unicode_enabled then
		table.insert(formspec, "label[0.3,3.4;" .. FS("Unicode font") .. "]")
		table.insert(formspec, "image_button[0.6,3.7;1,0.6;signs_lib_switch_" .. state .. ".png;uni_" .. 
			state .. ";;;false;signs_lib_switch_interm.png]")
	end

	if minetest.registered_nodes[nodename].allow_widefont then
		state = meta:get_int("widefont") == 1 and "on" or "off"
		formspec[#formspec+1] = "label[2.1,3.4;" .. FS("Wide font") .. "]"
		formspec[#formspec+1] = "image_button[2.3,3.7;1,0.6;signs_lib_switch_" .. state .. ".png;wide_" .. 
			state .. ";;;false;signs_lib_switch_interm.png]"
	end

	return table.concat(formspec, "")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mcl_more_signs:sign" then return end

	local pos_string = player:get_meta():get_string("signslib:pos")
	local pos = minetest.string_to_pos(pos_string)
	local playername = player:get_player_name()

	if fields.text and fields.ok then
		log("action", "%s wrote %q to sign at %s",
			(playername or ""),
			fields.text:gsub("\n", "\\n"),
			pos_string
		)
		mcl_more_signs.update_sign(pos, fields)
	elseif fields.wide_on or fields.wide_off or fields.uni_on or fields.uni_off then
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		local change_wide
		local change_uni

		if fields.wide_on and meta:get_int("widefont") == 1 then
			meta:set_int("widefont", 0)
			change_wide = true
		elseif fields.wide_off and meta:get_int("widefont") == 0 then
			meta:set_int("widefont", 1)
			change_wide = true
		end
		if fields.uni_on and meta:get_int("unifont") == 1 then
			meta:set_int("unifont", 0)
			change_uni = true
		elseif fields.uni_off and meta:get_int("unifont") == 0 then
			meta:set_int("unifont", 1)
			change_uni = true
		end

		if change_wide then
			log("action", "%s flipped the wide-font switch to %q at %s",
				(playername or ""),
				(fields.wide_on and "off" or "on"),
				minetest.pos_to_string(pos)
			)
			mcl_more_signs.update_sign(pos, fields)
			minetest.show_formspec(playername, "mcl_more_signs:sign", get_sign_formspec(pos, node.name))
		end
		if change_uni then
			log("action", "%s flipped the unicode-font switch to %q at %s",
				(playername or ""),
				(fields.uni_on and "off" or "on"),
				minetest.pos_to_string(pos)
			)
			mcl_more_signs.update_sign(pos, fields)
			minetest.show_formspec(playername, "mcl_more_signs:sign", get_sign_formspec(pos, node.name))
		end
	end
end)