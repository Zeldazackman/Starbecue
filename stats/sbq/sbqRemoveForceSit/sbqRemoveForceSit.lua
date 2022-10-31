function init()
	status.removeEphemeralEffect("sbqForceSit")
	mcontroller.resetAnchorState()
	mcontroller.setRotation(0)
end

function update(dt)
	mcontroller.setRotation(0)
	effect.expire()
end

function uninit()
	mcontroller.setRotation(0)
end
