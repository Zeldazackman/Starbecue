function init()
	status.removeEphemeralEffect("pvsoDigest")
	status.removeEphemeralEffect("pvsoSoftDigest")
	status.removeEphemeralEffect("pvsoDisplaySoftDigest")
	status.removeEphemeralEffect("pvsoDisplayDigest")
	status.removeEphemeralEffect("pvsoVoreHeal")
	effect.expire()
end

function update(dt)
	effect.expire()
end

function uninit()
end
