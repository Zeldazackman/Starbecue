local x, y, distance

function init()
	local destination = effect.sourceEntity()
	x = (destination % 1000) - 500
	y = math.floor(destination / 1000)
	distance = math.sqrt(x^2 + y^2)

	effect.expire()
end

function update(dt)
	if not distance then effect.expire() return end
	if distance > 1 then
		mcontroller.controlApproachVelocity({50 * x/distance, 50 * y/distance}, 650/(distance^0.5))
	else
		mcontroller.setVelocity({10 * x, 10 * y})
	end
	effect.expire()
end

function uninit()
end
