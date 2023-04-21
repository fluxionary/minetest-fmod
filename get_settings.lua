local f = string.format

local function get_lines_from_file(filename)
	local fh = io.open(filename, "r")
	if not fh then
		return
	end
	local lines = fh:read("*all"):split("\n")
	fh:close()
	return lines
end

local function strip_readable_name(text)
	if text:sub(1, 1) ~= "(" then
		error(f("%q %s", text, text))
	end
	local depth = 1
	local i = 2
	while depth > 0 do
		if text:sub(i, i) == ")" then
			depth = depth - 1
		elseif text:sub(i, i) == "(" then
			depth = depth + 1
		end
		i = i + 1
	end
	return text:sub(i):trim()
end

local function starts_with(s, start)
	return s:sub(1, #start) == start
end

local function parse_line(modname, line)
	if line:match("^%s*#") or line:match("^%s*%[") or line:match("^%s*$") then
		return
	end
	line = line:trim()
	local full_name, rest = unpack(line:split("%s+", false, 1, true))
	if not (full_name and rest) then
		return
	end
	if starts_with(full_name, "secure.") then
		full_name = full_name:sub(#"secure." + 1)
	end
	local mn, short_name = unpack(full_name:split("[:%.]", false, 1, true))
	assert(mn == modname, f("invalid setting name %s", full_name))
	rest = strip_readable_name(rest)
	local datatype, default, params = unpack(rest:split("%s+", false, 2, true))

	return full_name, short_name, datatype, default, params
end

local getters = {
	int = function(full_name, default)
		return tonumber(minetest.settings:get(full_name)) or tonumber(default)
	end,
	float = function(full_name, default)
		return tonumber(minetest.settings:get(full_name)) or tonumber(default)
	end,
	bool = function(full_name, default)
		return minetest.settings:get_bool(full_name, minetest.is_yes(default))
	end,
	string = function(full_name, default)
		return minetest.settings:get(full_name) or default
	end,
	enum = function(full_name, default)
		return minetest.settings:get(full_name) or default
	end,
	flags = function(full_name, default)
		return (minetest.settings:get(full_name) or default):split()
	end,
}

return function(modname, modpath)
	local settingtypes_lines = get_lines_from_file(modpath .. DIR_DELIM .. "settingtypes.txt")

	if not settingtypes_lines then
		return
	end

	local settings = {}
	for _, line in ipairs(settingtypes_lines) do
		local full_name, short_name, datatype, default, params = parse_line(modname, line)
		if full_name then
			local getter = getters[datatype]
			if getter then
				settings[short_name] = getter(full_name, default, params)
			else
				error("TODO: implement parsing settings of type " .. datatype)
			end
		end
	end

	local listeners_by_key = {}

	return setmetatable({
		_subscribe_for_modification = function(self, key, func)
			local listeners = listeners_by_key[key] or {}
			table.insert(listeners, func)
			listeners_by_key[key] = listeners
		end,
	}, {
		__index = function(self, key)
			return settings[key]
		end,
		__newindex = function(self, key, value)
			settings[key] = value
			for _, func in ipairs(listeners_by_key[key] or {}) do
				func(value)
			end
		end,
	})
end
