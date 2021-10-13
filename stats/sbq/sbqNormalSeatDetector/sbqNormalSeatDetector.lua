function init()
	--[[
		if this status ever triggers, we know we somehow entered normal vehicle seat behavior, so we better tell the
		vehicle to kick us out for a moment so the weird anchoring behavior can be restored

		we don't care about if NPCs have the normal seat behavior, in fact we probably prefer it for them, so we don't
		do anything if this gets on an NPC
	]]
end

function update(dt)
	if world.entityType(entity.id()) == "player" then
		local data = status.statusProperty("sbqForceSitData")
		if data and data.source and world.entityExists(data.source) then
			world.sendEntityMessage(data.source, "fixWeirdSeatBehavior", entity.id())
		end
	end
end

function uninit()
end
