local inited
local updated
local thingDid

function init()
	inited = true
	updated = false
end

function update(dt)
	if inited and updated and dt and (world.regionActive(object.boundBox())) and not thingDid then
		thingDid = doTheThing()
	end
	if inited and updated and dt and (world.regionActive(object.boundBox())) and thingDid then
		thingDone()
	end
	if inited then
		updated = true
	end
end

function uninit()
	inited = false
	updated = false
end

function doTheThing()
end
function thingDone()
end
