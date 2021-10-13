function init()
end

function update(dt)
	local data = status.statusProperty("sbqForceSitData")

	if data ~= nil and world.entityExists(data.source) and (data.source ~= entity.id()) and (world.entityType(data.source) == "vehicle") then
		mcontroller.setVelocity({0, 0})
		mcontroller.controlModifiers({movementSuppressed = true, facingSuppressed = true, runningSuppressed = true, jumpingSuppressed = true})

		local anchorEntity, seatindex = mcontroller.anchorState()

		if (anchorEntity ~= data.source) and (seatindex ~= data.index) then
			mcontroller.resetAnchorState()
			if not pcall(mcontroller.setAnchorState, data.source, data.index ) then
			end
		end
	else
		effect.expire()
	end
end

function uninit()
	status.setStatusProperty("sbqDontTouchDoors", false)
	world.sendEntityMessage(entity.id(), "sbqRestoreDamageTeam")
end
