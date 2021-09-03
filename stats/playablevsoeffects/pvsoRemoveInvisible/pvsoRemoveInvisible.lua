function init()
	status.removeEphemeralEffect("pvsoInvisible")
	effect.setParentDirectives("multiply=FFFFFFFF")
end

function update(dt)
	effect.expire()
end

function uninit()
end
