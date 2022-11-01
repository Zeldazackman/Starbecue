
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

function init()
	activeItem.setHoldingItem(false)
	local hand = activeItem.hand()
	if storage.clickAction == nil then
		storage.clickAction = "unassigned"
		storage.directives = ""
	end
	setIconAndDescription()

	message.setHandler( hand.."ItemData", function(_,_, data)
		storage.directives = data.directives or storage.directives or ""
		if data.assignClickAction ~= nil then
			storage.icon = data.icon
			storage.clickAction = data.assignClickAction
			setIconAndDescription()
		elseif ((not storage.clickAction) or (storage.clickAction == "unassigned")) and data.defaultClickAction ~= nil then
			activeItem.setInventoryIcon((data.defaultIcon or ("/items/active/sbqController/"..data.defaultClickAction..".png"))..(storage.directives or ""))
		else
			setIconAndDescription()
		end
	end)
end

local assignedMenu
local currentData
local occpantsWhenAssigned

function dontDoRadialMenu(arg)
	dontDoMenu = arg
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() then
		currentData = player.getProperty( "sbqCurrentData") or {}
		if occpantsWhenAssigned ~= (currentData.totalOccupants or 0) then
			assignedMenu = nil
		end

		if (storage.seatdata.shift or 0) > 0.2 and controls.up then
			if not assignedMenu then
				if activeItem.hand() == "primary" then activeItem.callOtherHandScript("dontDoRadialMenu", true) end
				if dontDoMenu then return end
				assignedMenu = true


				local sbqSettings = player.getProperty("sbqSettings") or {}
				local settings = sb.jsonMerge(sbqSettings.global or {}, sbqSettings.sbqOccupantHolder or {})

				local options = {
					{
						name = "despawn",
						icon = "/interface/xhover.png"
					},
					{
						name = "oralVore",
						icon = returnVoreIcon("oralVore") or "/items/active/sbqController/oralVore.png"
					},
					{
						name = "analVore",
						icon = returnVoreIcon("analVore") or "/items/active/sbqController/analVore.png"
					}
				}
				occpantsWhenAssigned = currentData.totalOccupants or 0
				if (currentData.totalOccupants or 0) > 0 then
					options[1].icon = "/items/active/sbqController/letout.png"
				end
				if settings.tailMaw then
					table.insert(options, 3, {
						name = "tailVore",
						icon = returnVoreIcon("tailVore") or "/items/active/sbqController/tailVore.png"
					} )
				end
				if settings.navel then
					table.insert(options, {
						name = "navelVore",
						icon = returnVoreIcon("navelVore") or "/items/active/sbqController/navelVore.png"
					} )
				end
				if settings.breasts then
					table.insert(options, {
						name = "breastVore",
						icon = returnVoreIcon("breastVore") or "/items/active/sbqController/breastVore.png"
					} )
				end
				if settings.pussy then
					table.insert(options, {
						name = "unbirth",
						icon = returnVoreIcon("unbirth") or "/items/active/sbqController/unbirth.png"
					} )
				end
				if settings.penis then
					table.insert(options, {
						name = "cockVore",
						icon = returnVoreIcon("cockVore") or "/items/active/sbqController/cockVore.png"
					} )
				end

				world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "controllerActionSelect" }, true )
			else
				if dontDoMenu then return end
				sbq.loopedMessage("radialSelection", player.id(), "sbqGetRadialSelection", {}, function(data)
					if data.selection ~= nil and data.type == "controllerActionSelect" then
						sbq.lastRadialSelection = data.selection
						sbq.radialSelectionType = data.type
						if data.selection == "cancel" then return end
						if data.selection == "despawn" and data.pressed and not sbq.click then
							sbq.click = true
							if type(currentData.id) == "number" and world.entityExists(currentData.id) then
								if (currentData.totalOccupants or 0) > 0 then
									world.sendEntityMessage(currentData.id, "letout")
								else
									world.sendEntityMessage(currentData.id, "despawn")
								end
							end
						elseif data.button == 0 and data.pressed and not sbq.click then
							sbq.click = true
							world.sendEntityMessage(player.id(), "primaryItemData", { assignClickAction = data.selection })
						elseif data.button == 2 and data.pressed and not sbq.click then
							sbq.click = true
							world.sendEntityMessage(player.id(), "altItemData", {assignClickAction = data.selection })
						elseif not data.pressed then
							sbq.click = false
						end
					end
				end)
			end
		elseif assignedMenu then
			world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqClose" )
			if sbq.radialSelectionType == "controllerActionSelect" then
				if sbq.lastRadialSelection == "despawn" then
					if type(currentData.id) == "number" and world.entityExists(currentData.id) then
						if (currentData.totalOccupants or 0) > 0 then
							world.sendEntityMessage(currentData.id, "letout")
						else
							world.sendEntityMessage(currentData.id, "despawn")
						end
					end
				end
			end
			assignedMenu = nil
			activeItem.callOtherHandScript("dontDoRadialMenu")
		else
			if fireMode == "primary" and not clicked then
				clicked = true
				if type(currentData.id) == "number" and world.entityExists(currentData.id) then
					doVoreAction(currentData.id)
				else
					local sbqSettings = player.getProperty("sbqSettings") or {}
					local settings = sb.jsonMerge( sbqSettings.sbqOccupantHolder or {}, sbqSettings.global or {})
					world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { spawner = player.id(), settings = settings } )
				end
			elseif fireMode == "none" then
				clicked = false
			end
		end
	end
end

function doVoreAction(id)
	local entityaimed = world.entityQuery(activeItem.ownerAimPosition(), 2, {
		withoutEntityId = player.id(),
		includedTypes = {"creature"}
	})
	local entityInRange = world.entityQuery(mcontroller.position(), 5, {
		withoutEntityId = player.id(),
		includedTypes = {"creature"}
	})
	local sent
	for i, victimId in ipairs(entityaimed) do
		for j, eid in ipairs(entityInRange) do
			if victimId == eid and entity.entityInSight(victimId) then
				world.sendEntityMessage( id, "requestTransition", storage.clickAction, { id = victimId } )
			end
		end
	end
	world.sendEntityMessage( id, "requestTransition", storage.clickAction, {} )
end


function setIconAndDescription()
	getDirectives()
	activeItem.setInventoryIcon((storage.icon or returnVoreIcon(storage.clickAction) or ("/items/active/sbqController/"..storage.clickAction..".png"))..(storage.directives or ""))
end

function returnVoreIcon(action)
	local icon
	currentData = player.getProperty( "sbqCurrentData") or {}
	if currentData.species == "sbqOccupantHolder" or not currentData.species then
		local species = player.species()
		local success, notEmpty = pcall(root.nonEmptyRegion, ("/humanoid/"..species.."/voreControllerIcons/"..action..".png"))
		if success and notEmpty ~= nil then
			icon = "/humanoid/"..species.."/voreControllerIcons/"..action..".png"
		end
	end
	return icon
end

function getDirectives()
	currentData = player.getProperty( "sbqCurrentData") or {}
	if currentData.species == "sbqOccupantHolder" or not currentData.species then
		local overrideData = status.statusProperty("speciesAnimOverrideData") or {}
		storage.directives = overrideData.directives
	end
end
