local oldinit = init
local oldupdate = update
local olduninit = uninit

function init()
	status.setStatusProperty("overrideData", {
		species = "sbqZevi",
		directives = "?replace;418093=418093fb?replace;57a3b9=57a3b9fb?replace;70b9cf=70b9cffb"
	})
	status.setPersistentEffects("speciesAnimOverride", {"speciesAnimOverride"})
	oldinit()
end

function update(dt)
	oldupdate(dt)
end

function uninit()
	olduninit()
end
