# fmod

flux's mod boilerplate

## public API

* `modname = fmod.create(fork)`

  creates the boilerplate i use in all my mods, so i don't have to worry about keeping them all up-to-date when
  i tweak things.

  `fork` is an optional parameter for other people to use if they fork a mod.

the api which is created looks like

```lua
modname = {
		modname = modname,
		modpath = modpath,
		title = mod_conf:get("title") or modname,
		description = mod_conf:get("description"),
		author = mod_conf:get("author"),
		license = mod_conf:get("license"),
		version = mod_conf:get("version"),
		fork = fork or "flux",

		S = S,

		has = build_has(mod_conf),

		check_version = function(required)
			assert(mod_conf:get("version") >= required, f("%s requires a newer version of %s; please update it", minetest.get_current_modname(), modname))
		end,

		log = function(level, messagefmt, ...)
			return minetest.log(level, f("[%s] %s", modname, f(messagefmt, ...)))
		end,

		dofile = function(...)
			return dofile(table.concat({modpath, ...}, DIR_DELIM) .. ".lua")
		end,
}
```
