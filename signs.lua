-- Definitions for additional VoxeLibre signs

local S = mcl_more_signs.S

local signs = {
	{
		name = "granite",
		description = S("Granite Sign"),
		inventory_image = "signs_lib_sign_granite_inv.png",
		tiles = {
			"signs_lib_sign_wall_granite.png",
			"signs_lib_sign_wall_granite_edges.png",
			"default_wood.png"
		},
		groups = mcl_more_signs.standard_stone_groups,
		sounds = mcl_more_signs.standard_stone_sign_sounds,
		recipe = {
			{"mcl_core:granite", "mcl_core:granite", "mcl_core:granite"},
			{"mcl_core:granite", "mcl_core:granite", "mcl_core:granite"},
			{"", "mcl_core:stick", ""}
		}
	},
	{
		name = "diorite",
		description = S("Diorite Sign"),
		inventory_image = "signs_lib_sign_diorite_inv.png",
		tiles = {
			"signs_lib_sign_wall_diorite.png",
			"signs_lib_sign_wall_diorite_edges.png",
			"default_wood.png"
		},
		groups = mcl_more_signs.standard_stone_groups,
		sounds = mcl_more_signs.standard_stone_sign_sounds,
		recipe = {
			{"mcl_core:diorite", "mcl_core:diorite", "mcl_core:diorite"},
			{"mcl_core:diorite", "mcl_core:diorite", "mcl_core:diorite"},
			{"", "mcl_core:stick", ""}
		}
	},
	{
		name = "cobbled_deepslate",
		description = S("Cobbled Deepslate Sign"),
		inventory_image = "signs_lib_sign_cobbled_deepslate_inv.png",
		tiles = {
			"signs_lib_sign_wall_cobbled_deepslate.png",
			"signs_lib_sign_wall_cobbled_deepslate_edges.png",
			"default_wood.png"
		},
		groups = mcl_more_signs.standard_stone_groups,
		sounds = mcl_more_signs.standard_stone_sign_sounds,
		recipe = {
			{"mcl_deepslate:deepslate_cobbled", "mcl_deepslate:deepslate_cobbled", "mcl_deepslate:deepslate_cobbled"},
			{"mcl_deepslate:deepslate_cobbled", "mcl_deepslate:deepslate_cobbled", "mcl_deepslate:deepslate_cobbled"},
			{"", "mcl_core:stick", ""}
		},
		default_color = "mcl_dye:white"
	},
	{
		name = "andesite",
		description = S("Andesite Sign"),
		inventory_image = "signs_lib_sign_andesite_inv.png",
		tiles = {
			"signs_lib_sign_wall_andesite.png",
			"signs_lib_sign_wall_andesite_edges.png",
			"default_wood.png"
		},
		groups = mcl_more_signs.standard_stone_groups,
		sounds = mcl_more_signs.standard_stone_sign_sounds,
		recipe = {
			{"mcl_core:andesite", "mcl_core:andesite", "mcl_core:andesite"},
			{"mcl_core:andesite", "mcl_core:andesite", "mcl_core:andesite"},
			{"", "mcl_core:stick", ""}
		},
	},
	{
		name = "steel",
		description = S("Steel Sign"),
		inventory_image = "signs_lib_sign_steel_inv.png",
		tiles = {
			"signs_lib_sign_wall_steel.png",
			"signs_lib_sign_wall_steel_edges.png",
			nil,
			nil,
			"default_steel_block.png"
		},
		groups = mcl_more_signs.standard_steel_groups,
		sounds = mcl_more_signs.standard_steel_sign_sounds,
		recipe = {
			{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
			{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
			{"", "mcl_core:iron_ingot", ""}
		},
		default_color = "mcl_dye:black",
		locked = true
	}
}

for _, sign in ipairs(signs) do
	mcl_more_signs.register_sign("mcl_more_signs:sign_" .. sign.name, {
		description = sign.description,
		_tt_help = S("Can be written"),
		inventory_image = sign.inventory_image,
		tiles = sign.tiles,
		groups = sign.groups,
		sounds = sign.sounds,
		entity_info = "standard",
		allow_hanging = true,
		allow_widefont = true,
		allow_onpole = true,
		allow_yard = true,
		allow_wall = true,
		use_texture_alpha = "clip",
		default_color = sign.default_color,
		locked = sign.locked
	})

	minetest.register_craft({
		output = "mcl_more_signs:sign_" .. sign.name,
		recipe = sign.recipe
	})
end

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