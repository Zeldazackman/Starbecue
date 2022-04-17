
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

local assignedMenu
local currentData

function dontDoRadialMenu(arg)
	dontDoMenu = arg
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() then
		currentData = player.getProperty( "sbqCurrentData") or {}

		if (storage.seatdata.shift or 0) > 0.2 then
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
						icon = "/items/active/sbqController/oralVore.png"
					},
					{
						name = "analVore",
						icon = "/items/active/sbqController/analVore.png"
					}
				}
				if settings.tailMaw then
					table.insert(options, 3, {
						name = "tailVore",
						icon = "/items/active/sbqController/tailVore.png"
					} )
				end
				if settings.breasts then
					table.insert(options, {
						name = "breastVore",
						icon = "/items/active/sbqController/breastVore.png"
					} )
				end
				if settings.pussy then
					table.insert(options, {
						name = "unbirth",
						icon = "/items/active/sbqController/unbirth.png"
					} )
				end
				if settings.penis then
					table.insert(options, {
						name = "cockVore",
						icon = "/items/active/sbqController/cockVore.png"
					} )
				end

				world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "controllerActionSelect" }, true )
			else
				if dontDoMenu then return end
				sbq.loopedMessage("radialSelection", player.id(), "sbqGetRadialSelection", {}, function(data)

					if data.selection ~= nil and data.type == "controllerActionSelect" then
						sbq.lastRadialSelection = data.selection
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
			if sbq.lastRadialSelection == "despawn" then
				if type(currentData.id) == "number" and world.entityExists(currentData.id) then
					if (currentData.totalOccupants or 0) > 0 then
						world.sendEntityMessage(currentData.id, "letout")
					else
						world.sendEntityMessage(currentData.id, "despawn")
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
					local settings = sb.jsonMerge(sbqSettings.global or {}, sbqSettings.sbqOccupantHolder or {})
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
	world.sendEntityMessage( id, "requestTransition", storage.clickAction, { id = entityaimed[1] } )
end


function setIconAndDescription()
	activeItem.setInventoryIcon((storage.icon or ("/items/active/sbqController/"..storage.clickAction..".png"))..(storage.directives or ""))
end
