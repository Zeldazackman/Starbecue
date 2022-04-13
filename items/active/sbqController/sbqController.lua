function init()
	activeItem.setHoldingItem(false)
	local hand = activeItem.hand()
	if storage.clickAction == nil then
		storage.clickAction = "unassigned"
		storage.directives = ""
	end
	setIconAndDescription()

	message.setHandler( hand.."ItemData", function(_,_, data)
		storage.directives = data.directives or ""
		if data.assignClickAction ~= nil then
			storage.clickAction = data.assignClickAction
			storage.icon = data.icon
			setIconAndDescription()
		elseif ((not storage.clickAction) or (storage.clickAction == "unassigned")) and data.defaultClickAction ~= nil then
			activeItem.setInventoryIcon((data.defaultIcon or ("/items/active/sbqController/"..data.defaultClickAction..".png"))..(storage.directives or ""))
		else
			setIconAndDescription()
		end
	end)
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() then
		local currentData = player.getProperty( "sbqCurrentData") or {}

		if shiftHeld and fireMode == "primary" and not clicked then
			if type(currentData.id) == "number" and world.entityExists(currentData.id) then
				world.sendEntityMessage(currentData.id, "despawn")
			end
		elseif fireMode == "primary" and not clicked then
			clicked = true
			if type(currentData.id) == "number" and world.entityExists(currentData.id) then
				doVoreAction(currentData.id)
			else
				local sbqSettings = player.getProperty("sbqSettings") or {}
				local settings = sb.jsonMerge(sbqSettings.global or {}, sbqSettings.sbqOccupantHolder or {})
				world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { spawner = player.id(), settings = settings } )
			end
		elseif fireMode == "none" then
			clicked = false
		end
	end
end

function doVoreAction(id)
	local entityaimed = world.entityQuery(activeItem.ownerAimPosition(), 2, {
		withoutEntityId = player.id(),
		includedTypes = {"creature"}
	})
	if type(entityaimed[1]) == "number" and entity.entityInSight(entityaimed[1]) then
		world.sendEntityMessage( id, "requestTransition", storage.clickAction, { id = entityaimed[1] } )
	end
end


function setIconAndDescription()
	activeItem.setInventoryIcon((storage.icon or ("/items/active/sbqController/"..storage.clickAction..".png"))..(storage.directives or ""))
end
