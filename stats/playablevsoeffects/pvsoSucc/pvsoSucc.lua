
function init()
end

function update(dt)
	local data = status.statusProperty("pvsoSuccData")
	if data == nil then return end
	local position = mcontroller.position()

	local dx = 0
	if (data.destination[1] - position[1]) > 0 then
		dx = 1
	else
		dx = -1
	end
	local dy = 0
	if (data.destination[2] - position[2]) > 0 then
		dy = 1
	else
		dy = -1
	end
	mcontroller.addMomentum({dx * data.force, dy * data.force})
end

function uninit()
end
