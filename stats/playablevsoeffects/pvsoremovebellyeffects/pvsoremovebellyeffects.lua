function init()
	status.removeEphemeralEffect("damagedigest")
	status.removeEphemeralEffect("damagesoftdigest")
	status.removeEphemeralEffect("displaydamagesoftdigest")
	status.removeEphemeralEffect("displaydamagedigest")
	status.removeEphemeralEffect("pvsovoreheal")
	effect.expire()
end

function update(dt)
	effect.expire()
end

function uninit()
end
