-- encoding borrowed from signs_lib fork at https://github.com/lord-server/lord

-- The "ANSI" encoding here actually refers to "windows-1251", which shows up as
-- "ANSI" on Russian version of MS Windows

local ansi_decode = {
	[128] = "\208\130",
	[129] = "\208\131",
	[130] = "\226\128\154",
	[131] = "\209\147",
	[132] = "\226\128\158",
	[133] = "\226\128\166",
	[134] = "\226\128\160",
	[135] = "\226\128\161",
	[136] = "\226\130\172",
	[137] = "\226\128\176",
	[138] = "\208\137",
	[139] = "\226\128\185",
	[140] = "\208\138",
	[141] = "\208\140",
	[142] = "\208\139",
	[143] = "\208\143",
	[144] = "\209\146",
	[145] = "\226\128\152",
	[146] = "\226\128\153",
	[147] = "\226\128\156",
	[148] = "\226\128\157",
	[149] = "\226\128\162",
	[150] = "\226\128\147",
	[151] = "\226\128\148",
	[152] = "\194\152",
	[153] = "\226\132\162",
	[154] = "\209\153",
	[155] = "\226\128\186",
	[156] = "\209\154",
	[157] = "\209\156",
	[158] = "\209\155",
	[159] = "\209\159",
	[160] = "\194\160",
	[161] = "\209\142",
	[162] = "\209\158",
	[163] = "\208\136",
	[164] = "\194\164",
	[165] = "\210\144",
	[166] = "\194\166",
	[167] = "\194\167",
	[168] = "\208\129",
	[169] = "\194\169",
	[170] = "\208\132",
	[171] = "\194\171",
	[172] = "\194\172",
	[173] = "\194\173",
	[174] = "\194\174",
	[175] = "\208\135",
	[176] = "\194\176",
	[177] = "\194\177",
	[178] = "\208\134",
	[179] = "\209\150",
	[180] = "\210\145",
	[181] = "\194\181",
	[182] = "\194\182",
	[183] = "\194\183",
	[184] = "\209\145",
	[185] = "\226\132\150",
	[186] = "\209\148",
	[187] = "\194\187",
	[188] = "\209\152",
	[189] = "\208\133",
	[190] = "\209\149",
	[191] = "\209\151"
}
local utf8_decode = {
	[128] = {
		[147] = "\150",
		[148] = "\151",
		[152] = "\145",
		[153] = "\146",
		[154] = "\130",
		[156] = "\147",
		[157] = "\148",
		[158] = "\132",
		[160] = "\134",
		[161] = "\135",
		[162] = "\149",
		[166] = "\133",
		[176] = "\137",
		[185] = "\139",
		[186] = "\155"
	},
	[130] = {[172] = "\136"},
	[132] = {[150] = "\185", [162] = "\153"},
	[194] = {
		[152] = "\152",
		[160] = "\160",
		[164] = "\164",
		[166] = "\166",
		[167] = "\167",
		[169] = "\169",
		[171] = "\171",
		[172] = "\172",
		[173] = "\173",
		[174] = "\174",
		[176] = "\176",
		[177] = "\177",
		[181] = "\181",
		[182] = "\182",
		[183] = "\183",
		[187] = "\187"
	},
	[208] = {
		[129] = "\168",
		[130] = "\128",
		[131] = "\129",
		[132] = "\170",
		[133] = "\189",
		[134] = "\178",
		[135] = "\175",
		[136] = "\163",
		[137] = "\138",
		[138] = "\140",
		[139] = "\142",
		[140] = "\141",
		[143] = "\143",
		[144] = "\192",
		[145] = "\193",
		[146] = "\194",
		[147] = "\195",
		[148] = "\196",
		[149] = "\197",
		[150] = "\198",
		[151] = "\199",
		[152] = "\200",
		[153] = "\201",
		[154] = "\202",
		[155] = "\203",
		[156] = "\204",
		[157] = "\205",
		[158] = "\206",
		[159] = "\207",
		[160] = "\208",
		[161] = "\209",
		[162] = "\210",
		[163] = "\211",
		[164] = "\212",
		[165] = "\213",
		[166] = "\214",
		[167] = "\215",
		[168] = "\216",
		[169] = "\217",
		[170] = "\218",
		[171] = "\219",
		[172] = "\220",
		[173] = "\221",
		[174] = "\222",
		[175] = "\223",
		[176] = "\224",
		[177] = "\225",
		[178] = "\226",
		[179] = "\227",
		[180] = "\228",
		[181] = "\229",
		[182] = "\230",
		[183] = "\231",
		[184] = "\232",
		[185] = "\233",
		[186] = "\234",
		[187] = "\235",
		[188] = "\236",
		[189] = "\237",
		[190] = "\238",
		[191] = "\239"
	},
	[209] = {
		[128] = "\240",
		[129] = "\241",
		[130] = "\242",
		[131] = "\243",
		[132] = "\244",
		[133] = "\245",
		[134] = "\246",
		[135] = "\247",
		[136] = "\248",
		[137] = "\249",
		[138] = "\250",
		[139] = "\251",
		[140] = "\252",
		[141] = "\253",
		[142] = "\254",
		[143] = "\255",
		[144] = "\161",
		[145] = "\184",
		[146] = "\144",
		[147] = "\131",
		[148] = "\186",
		[149] = "\190",
		[150] = "\179",
		[151] = "\191",
		[152] = "\188",
		[153] = "\154",
		[154] = "\156",
		[155] = "\158",
		[156] = "\157",
		[158] = "\162",
		[159] = "\159"
	},
	[210] = {[144] = "\165", [145] = "\180"}
}

local wide_character_codes = {
}

mcl_more_signs.unicode_install = function(
	numbers
)
	local scope = utf8_decode
	for i = 1,#numbers-2 do
		if not scope[numbers[i]] then
			scope[numbers[i]] = {}
		end
		scope = scope[numbers[i]]
	end
	scope[numbers[#numbers-1]] = "&#x" .. numbers[#numbers] .. ";"
	table.insert(
		wide_character_codes,
		numbers[#numbers]
	)
end

mcl_more_signs.unicode_install({38,"26"})

dofile(mcl_more_signs.path.."/nonascii-de.lua")
dofile(mcl_more_signs.path.."/nonascii-fr.lua")
dofile(mcl_more_signs.path.."/nonascii-pl.lua")
dofile(mcl_more_signs.path.."/nonascii-ua.lua")

local nmdc = {
	[36] = "$",
	[124] = "|"
}

function mcl_more_signs.AnsiToUtf8(s)
	local r, b = ""
	for i = 1, s and s:len() or 0 do
		b = s:byte(i)
		if b < 128 then
			r = r .. string.char(b)
		else
			if b > 239 then
				r = r .. "\209" .. string.char(b - 112)
			elseif b > 191 then
				r = r .. "\208" .. string.char(b - 48)
			elseif ansi_decode[b] then
				r = r .. ansi_decode[b]
			else
				r = r .. "_"
			end
		end
	end
	return r
end

function mcl_more_signs.Utf8ToAnsi(s)
	local r, b = ""
	local scope
	local j, l, u
	for i = 1, s and s:len() or 0 do
		b = s:byte(i)

		-- legacy parser
		if b == 0x26 then
			r = r .. "&#x26;"
		elseif b < 128 then
			if nmdc[b] then
				r = r .. nmdc[b]
			else
				r = r .. string.char(b)
			end
		elseif scope then
			if scope[b] then
				scope = scope[b]
				if "string" == type(scope) then
					r, scope = r .. scope, nil
					j = -1 -- supress general UTF-8 parser
				end
			else
				scope = nil
			end
		elseif utf8_decode[b] then
			scope = utf8_decode[b]
		end

		-- general UTF-8 parser
		if j == -1 then -- supressed by legacy parser
			j = nil
		elseif b < 0x80 then
			if j then
				r = r .. "&#ufffd;"
				j = nil
			end
			-- ASCII handled by legacy parser
		elseif b >= 0xc0 then
			if j then
				r = r .. "&#ufffd;"
			end
			j = i
			if b >= 0xf8 then
				r = r .. "&#ufffd;"
				j = nil
			elseif b >= 0xf0 then
				l, u = 4, b % (2 ^ 3)
			elseif b >= 0xe0 then
				l, u = 3, b % (2 ^ 4)
			else
				l, u = 2, b % (2 ^ 5)
			end
		else
			if j then
				u = u * (2 ^ 6) + b % (2 ^ 6)
				if i == j + l - 1 then
					r = r .. string.format("&#u%x;", u)
					j = nil
				end
			else
				r = r .. "&#ufffd;"
			end
		end
	end
	if j then
		r = r .. "&#ufffd;"
	end
	return r
end

mcl_more_signs.wide_character_codes = wide_character_codes
mcl_more_signs.unifont_halfwidth = dofile(mcl_more_signs.path.."/unifont-halfwidth.lua")
