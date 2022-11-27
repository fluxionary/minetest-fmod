local function parse_version(version)
	local y, m, d, h, mi, s
	y, m, d = version:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
	if y and m and d then
		return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
	end

	y, m, d, s = version:match("^(%d%d%d%d)-(%d%d)-(%d%d)[%.%s](%d+)$")
	if y and m and d and s then
		return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), sec = tonumber(s) })
	end

	y, m, d, h, mi, s = version:match("^(%d%d%d%d)-(%d%d)-(%d%d)[T ](%d%d):(%d%d):(%d%d)$")
	if y and m and d and h and mi and s then
		return os.time({
			year = tonumber(y),
			month = tonumber(m),
			day = tonumber(d),
			hour = tonumber(h),
			min = tonumber(mi),
			sec = tonumber(s),
		})
	end

	error(string.format("can't parse version %q", version))
end

local function build_has(mod_conf)
	local optional_depends = mod_conf:get("optional_depends")
	if not optional_depends then
		return {}
	end
	local has = {}
	for _, mod in ipairs(optional_depends:split()) do
		mod = mod:trim()
		has[mod] = minetest.get_modpath(mod) and true or false
	end
	return has
end

local function create(fork)
	local f = string.format

	local modname = minetest.get_current_modname()
	local modpath = minetest.get_modpath(modname)
	local S = minetest.get_translator(modname)

	local mod_conf = Settings(modpath .. DIR_DELIM .. "mod.conf")
	assert(modname == mod_conf:get("name"), "mod name mismatch")

	local version = parse_version(mod_conf:get("version"))

	return {
		modname = modname,
		modpath = modpath,
		title = mod_conf:get("title") or modname,
		description = mod_conf:get("description"),
		author = mod_conf:get("author"),
		license = mod_conf:get("license"),
		version = version,
		fork = fork or "flux",

		S = S,

		has = build_has(mod_conf),

		check_version = function(required)
			assert(
				version >= required,
				f("%s requires a newer version of %s; please update it", minetest.get_current_modname(), modname)
			)
		end,

		log = function(level, messagefmt, ...)
			return minetest.log(level, f("[%s] %s", modname, f(messagefmt, ...)))
		end,

		dofile = function(...)
			return dofile(table.concat({ modpath, ... }, DIR_DELIM) .. ".lua")
		end,
	}
end

fmod = create()
fmod.create = create
