local f = string.format

local get_current_modname = minetest.get_current_modname
local get_modpath = minetest.get_modpath

local our_modname = get_current_modname()
local our_modpath = get_modpath(our_modname)

local build_has = dofile(our_modpath .. DIR_DELIM .. "build_has.lua")
local get_settings = dofile(our_modpath .. DIR_DELIM .. "get_settings.lua")
local parse_version = dofile(our_modpath .. DIR_DELIM .. "parse_version.lua")

local function create(fork, extra_private_state)
	local modname = get_current_modname()
	local modpath = get_modpath(modname)
	local S = minetest.get_translator(modname)
	local F = minetest.formspec_escape

	local mod_conf = Settings(modpath .. DIR_DELIM .. "mod.conf")
	assert(modname == mod_conf:get("name"), "mod name mismatch")

	local version = parse_version(mod_conf:get("version"))

	local private_state = {
		mod_storage = minetest.get_mod_storage(),
	}

	if extra_private_state then
		for k, v in pairs(extra_private_state) do
			private_state[k] = v
		end
	end

	return {
		modname = modname,
		modpath = modpath,

		title = mod_conf:get("title") or modname,
		description = mod_conf:get("description"),
		author = mod_conf:get("author"),
		license = mod_conf:get("license"),
		media_license = mod_conf:get("media_license"),
		website = mod_conf:get("website") or mod_conf:get("url"),
		version = version,
		fork = fork or "flux",

		S = S,
		FS = function(...)
			return F(S(...))
		end,

		has = build_has(mod_conf),
		settings = get_settings(modname, modpath),

		check_version = function(required)
			if type(required) == "table" then
				required = os.time(required)
			end
			local calling_modname = minetest.get_current_modname() or "UNKNOWN"
			assert(
				version >= required,
				f("%s requires a newer version of %s; please update it", calling_modname, modname)
			)
		end,

		log = function(level, messagefmt, ...)
			return minetest.log(level, f("[%s] %s", modname, f(messagefmt, ...)))
		end,

		chat_send_player = function(player, messagefmt, ...)
			if type(player) ~= "string" then
				player = player:get_player_name()
			end

			minetest.chat_send_player(player, f("[%s] %s", modname, S(messagefmt, ...)))
		end,

		chat_send_all = function(message, ...)
			minetest.chat_send_all(f("[%s] %s", modname, S(message, ...)))
		end,

		dofile = function(...)
			assert(modname == get_current_modname(), "attempt to call dofile from external mod")
			local filename = table.concat({ modpath, ... }, DIR_DELIM) .. ".lua"
			local loader = assert(loadfile(filename))
			return loader(private_state)
		end,
	}
end

fmod = create()
fmod.create = create
