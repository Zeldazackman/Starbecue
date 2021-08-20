function init()
	--get seat inext from our little hack
	self.seat_index = effect.duration() -1
end

function update(dt)
	if world.entityExists(effect.sourceEntity()) and (effect.sourceEntity() ~= -65536) then
		effect.modifyDuration(1)

		mcontroller.setVelocity({0, 0})
		mcontroller.controlModifiers({movementSuppressed = true, facingSuppressed = true, runningSuppressed = true, jumpingSuppressed = true})

		local anchorEntity, seatindex = mcontroller.anchorState()
		--sb.logInfo("Seat Index:"..seatindex)

		if (anchorEntity ~= effect.sourceEntity()) and (seatindex ~= self.seat_index) then
			mcontroller.resetAnchorState()
			mcontroller.setAnchorState( effect.sourceEntity(), self.seat_index )
		end
	else
		effect.expire()
	end
end

function uninit()
end
