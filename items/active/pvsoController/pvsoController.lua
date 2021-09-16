function init()
	activeItem.setHoldingItem(false)
	local hand = activeItem.hand()

	message.setHandler( hand.."ItemData", function(_,_, data)
		if data.assignClickAction ~= nil then
			storage.clickAction = data.assignClickAction
			activeItem.setInventoryIcon("/items/active/pvsoController/"..data.assignClickAction..".png")
		end
		if not storage.clickAction and data.defaultClickAction ~= nil then
			activeItem.setInventoryIcon("/items/active/pvsoController/"..data.defaultClickAction..".png")
		end
	end)
	if storage.clickAction ~= nil then
		activeItem.setInventoryIcon("/items/active/pvsoController/"..storage.clickAction..".png")
	end
end

local voreActionList = {
	"vore",
	"oralVore",
	"analVore",
	"tailVore",
	"cockVore",
	"breastVore",
	"physicalAttack",
	"specialAttack",
	"grab",
	"succ"
}

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() and fireMode == "primary" and not clicked then
		sb.logInfo("clicky")
		clicked = true
		if storage.clickAction == nil then
			storage.clickAction = "vore"
		else
			getNextAction()
		end
		if storage.clickAction ~= nil then
			activeItem.setInventoryIcon("/items/active/pvsoController/"..storage.clickAction..".png")
		else
			activeItem.setInventoryIcon("/items/active/pvsoController/unassigned.png")
		end
	elseif fireMode ~= "primary" then
		clicked = false
	end
end

function getNextAction()
	for i, action in ipairs(voreActionList) do
		if storage.clickAction == action then
			storage.clickAction = voreActionList[i+1]
			return
		end
	end
end
