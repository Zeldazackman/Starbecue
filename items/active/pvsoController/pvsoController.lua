function init()
	activeItem.setArmAngle(config.getParameter("inactiveArmAngle", 0))
	if storage.clickActions == nil then
		storage.clickActions = {}
	end
end

function update()
end
