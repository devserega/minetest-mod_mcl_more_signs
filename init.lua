-- This mod provides the visible text on signs library used by Home Decor
-- and perhaps other mods at some point in the future.  Forked from thexyz's/
-- PilzAdam's original text-on-signs mod and rewritten by Vanessa Ezekowitz
-- and Diego Martinez

mcl_more_signs = {}

mcl_more_signs.path = minetest.get_modpath(minetest.get_current_modname())

mcl_more_signs.S = minetest.get_translator(minetest.get_current_modname())

mcl_more_signs.edit_priv = minetest.settings:get("mcl_more_signs.edit_priv") or "signslib_edit"

dofile(mcl_more_signs.path.."/encoding.lua")
dofile(mcl_more_signs.path.."/api.lua")
dofile(mcl_more_signs.path.."/signs.lua")
dofile(mcl_more_signs.path.."/compat.lua")
