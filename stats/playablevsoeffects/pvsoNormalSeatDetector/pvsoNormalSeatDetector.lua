function init()
	--[[
		if this status ever triggers, we know we somehow entered normal vehicle seat behavior, so we better tell the
		vehicle to kick us out for a moment so the weird anchoring behavior can be restored
	]]
	local data = status.statusProperty("pvsoForceSitData")
	if world.entityExists(data.source) then
		world.sendEntityMessage(data.source, "pvsoFixWeirdSeatBehavior", entity.id())
	end
end

function update(dt)
	effect.expire()
end

function uninit()
end
