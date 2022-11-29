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

local function parse_line(modname, line)
	if line:match("^#") or line:match("^%s*$") then
		return
	end
	line = line:trim()
	local full_name, rest = unpack(line:split("%s+", false, 1, true))
	if not (full_name and rest) then
		return
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
}

return function(modname, modpath)
	local settingtypes_lines = get_lines_from_file(modpath .. DIR_DELIM .. "settingtypes.txt")

	if not settingtypes_lines then
		return
	end

	local settings = {
		_listeners = {},

		_subscribe_for_modification = function(self, name, func)
			local listeners = self._listeners[name] or {}
			table.insert(listeners, func)
			self._listeners[name] = listeners
		end,

		modify_setting = function(self, name, value)
			value = tonumber(value)
			self[name] = value
			for _, func in ipairs(self._listeners[name] or {}) do
				func(value)
			end
		end,
	}
	for _, line in ipairs(settingtypes_lines) do
		local full_name, short_name, datatype, default = parse_line(modname, line)
		if full_name then
			local getter = getters[datatype]
			if getter then
				settings[short_name] = getter(full_name, default)
			else
				error("TODO: implement parsing settings of type " .. datatype)
			end
		end
	end

	return settings
end
