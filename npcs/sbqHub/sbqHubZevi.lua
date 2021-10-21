local oldinit = init
local oldupdate = update
local olduninit = uninit

function init()
	status.setStatusProperty("speciesOverride", "sbqZevi")
	status.addPersistentEffect("speciesAnimOverride", "speciesAnimOverride")
	oldinit()
end

function update(dt)
	oldupdate(dt)
end

function uninit()
	olduninit()
end
