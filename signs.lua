-- Definitions for additional VoxeLibre signs

local S = mcl_more_signs.S

mcl_more_signs.register_sign("mcl_more_signs:sign_granite", {
	description = S("Granite Sign"),
	inventory_image = "signs_lib_sign_wall_granite_inv.png",
	tiles = {
		"signs_lib_sign_wall_granite.png",
		"signs_lib_sign_wall_granite_edges.png",
		-- items 3 - 5 are not set, so mcl_more_signs will use its standard pole
		-- mount, hanging, and yard sign stick textures.
		"default_wood.png" -- for the yard sign's stick
	},
	groups = mcl_more_signs.standard_stone_groups,
	sounds = mcl_more_signs.standard_stone_sign_sounds,
	entity_info = "standard",
	allow_hanging = true,
	allow_widefont = true,
	allow_onpole = true,
	allow_yard = true,
	allow_wall = true,
	use_texture_alpha = "clip"
})

minetest.register_craft({
	output = "mcl_more_signs:sign_granite",
	recipe = {
		{"mcl_core:granite_smooth", "mcl_core:granite_smooth", "mcl_core:granite_smooth"},
		{"mcl_core:granite_smooth", "mcl_core:granite_smooth", "mcl_core:granite_smooth"},
		{"", "mcl_core:stick", ""},
	},
})

mcl_more_signs.register_sign("mcl_more_signs:sign_steel", {
	description = S("Steel Sign"),
	inventory_image = "signs_lib_sign_wall_steel_inv.png",
	tiles = {
		"signs_lib_sign_wall_steel.png", -- 1. Основная поверхность знака
		"signs_lib_sign_wall_steel_edges.png", -- 2. Края знака
		nil, -- not set, so it'll use the standard pole mount texture -- 3. Текстура для крепления к столбу (по умолчанию)
		nil, -- not set, so it'll use the standard hanging chains texture -- 4. Текстура для подвесных цепей (по умолчанию)
		"default_steel_block.png" -- for the yard sign's stick -- 5. Текстура для стойки в виде дворового знака (yard sign)
	},
	groups = mcl_more_signs.standard_steel_groups,
	sounds = mcl_more_signs.standard_steel_sign_sounds,
	locked = true,
	entity_info = "standard",
	allow_hanging = true,
	allow_widefont = true,
	allow_onpole = true,
	allow_yard = true,
	allow_wall = true,
	use_texture_alpha = "clip",
})

minetest.register_craft({
	output = "mcl_more_signs:sign_steel",
	recipe = {
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
		{"", "mcl_core:iron_ingot", ""},
	},
})

--[[
minetest.register_alias("signs:sign_hanging",                   "default:sign_wood_hanging")
minetest.register_alias("basic_signs:hanging_sign",             "default:sign_wood_hanging")
minetest.register_alias("signs:sign_yard",                      "default:sign_wood_yard")
minetest.register_alias("basic_signs:yard_sign",                "default:sign_wood_yard")

minetest.register_alias("default:sign_wall_wood_onpole",        "default:sign_wood_onpole")
minetest.register_alias("default:sign_wall_wood_onpole_horiz",  "default:sign_wood_onpole_horiz")
minetest.register_alias("default:sign_wall_wood_hanging",       "default:sign_wood_hanging")
minetest.register_alias("default:sign_wall_wood_yard",          "default:sign_wood_yard")

minetest.register_alias("default:sign_wall_steel_onpole",       "default:sign_steel_onpole")
minetest.register_alias("default:sign_wall_steel_onpole_horiz", "default:sign_steel_onpole_horiz")
minetest.register_alias("default:sign_wall_steel_hanging",      "default:sign_steel_hanging")
minetest.register_alias("default:sign_wall_steel_yard",         "default:sign_steel_yard")
]]

--[[
table.insert(mcl_more_signs.lbm_restore_nodes, "signs:sign_hanging")
table.insert(mcl_more_signs.lbm_restore_nodes, "basic_signs:hanging_sign")
table.insert(mcl_more_signs.lbm_restore_nodes, "signs:sign_yard")
table.insert(mcl_more_signs.lbm_restore_nodes, "basic_signs:yard_sign")
table.insert(mcl_more_signs.lbm_restore_nodes, "default:sign_wood_yard")
table.insert(mcl_more_signs.lbm_restore_nodes, "default:sign_wall_wood_yard")

-- insert the old wood sign-on-fencepost into mcl_more_signs's conversion LBM

table.insert(mcl_more_signs.old_fenceposts_with_signs, "signs:sign_post")
mcl_more_signs.old_fenceposts["signs:sign_post"] = "default:fence_wood"
mcl_more_signs.old_fenceposts_replacement_signs["signs:sign_post"] = "default:sign_wall_wood_onpole"
]]