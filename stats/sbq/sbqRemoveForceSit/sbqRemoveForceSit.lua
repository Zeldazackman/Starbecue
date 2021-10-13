function init()
	status.removeEphemeralEffect("sbqForceSit")
	mcontroller.resetAnchorState()
end

function update(dt)
	effect.expire()
end

function uninit()
end
