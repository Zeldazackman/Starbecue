---@diagnostic disable: undefined-global

local _update = update
local _init = init

local isOC
function init()
	_init()

	if target_ID and world.entityExists(target_ID) then
		isOC = world.callScriptedEntity(target_ID, "config.getParameter", "isOC")
	end

end


function update(dt)
	if isOC then
		if owner_ID and world.entityExists(owner_ID) then
			world.sendEntityMessage(owner_ID, "sbqResetCamera")
		end
		stagehand.die()
	else
		_update(dt)
	end
end
