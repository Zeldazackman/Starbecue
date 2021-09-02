function init()
	status.removeEphemeralEffect("pvsoForceSit")
	mcontroller.resetAnchorState()
end

function update(dt)
	effect.expire()
end

function uninit()
end
