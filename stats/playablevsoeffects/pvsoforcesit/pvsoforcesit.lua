function init()
end

function update(dt)
	local data = status.statusProperty("pvsoForceSitData")

	if data ~= nil and world.entityExists(data.source) and (data.source ~= entity.id()) and (world.entityType(data.source) == "vehicle") then
		mcontroller.setVelocity({0, 0})
		mcontroller.controlModifiers({movementSuppressed = true, facingSuppressed = true, runningSuppressed = true, jumpingSuppressed = true})

		local anchorEntity, seatindex = mcontroller.anchorState()

		if (anchorEntity ~= data.source) and (seatindex ~= data.index) then
			if not pcall(mcontroller.setAnchorState, data.source, data.index ) then
				sb.logInfo("didn't anchor to "..data.source.." "..data.index)
			end
		end
	else
		effect.expire()
	end
end

function uninit()
	status.setStatusProperty("pvsoDontTouchDoors", false)
	world.sendEntityMessage(entity.id(), "pvsoRestoreDamageTeam")
end
