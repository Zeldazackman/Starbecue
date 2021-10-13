function init()
	activeItem.setHoldingItem(false)
	local hand = activeItem.hand()
	if storage.clickAction == nil then
		storage.clickAction = "unassigned"
	end
	setIconAndDescription()

	message.setHandler( hand.."ItemData", function(_,_, data)
		if data.assignClickAction ~= nil then
			storage.clickAction = data.assignClickAction
			setIconAndDescription()
		elseif ((not storage.clickAction) or (storage.clickAction == "unassigned")) and data.defaultClickAction ~= nil then
			activeItem.setInventoryIcon("/items/active/sbqController/"..data.defaultClickAction..".png")
		end
	end)
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() and fireMode == "primary" and not clicked then
		clicked = true
		getNextAction()
		setIconAndDescription()
	elseif fireMode == "none" then
		if not player.isLounging() then
			setIconAndDescription()
		end
		clicked = false
	end
end

function getNextAction()
	local actions = config.getParameter("actions")
	for i, action in ipairs(actions) do
		if storage.clickAction == action then
			storage.clickAction = actions[i+1] or "unassigned"
			return
		end
	end
end

function setIconAndDescription()
	activeItem.setInventoryIcon("/items/active/sbqController/"..storage.clickAction..".png")
end
