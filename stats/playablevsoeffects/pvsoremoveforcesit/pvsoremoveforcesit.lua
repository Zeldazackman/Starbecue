function init()
	status.removeEphemeralEffect("pvsoforcesit")
	effect.expire()
end

function update(dt)
	effect.expire()
end

function uninit()
end
