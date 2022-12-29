
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")
require("/scripts/SBQ_species_config.lua")
require("/interface/scripted/sbq/sbqIndicatorHud/hudActions.lua")

function init()
	sbq.config = root.assetJson("/sbqGeneral.config")
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

require("/scripts/speciesAnimOverride_player_species.lua")

local assignedMenu
local occpantsWhenAssigned
local selectedPrey
local selectedPreyIndex

function dontDoRadialMenu(arg)
	dontDoMenu = arg
end

function update(dt, fireMode, shiftHeld, controls)
	sbq.checkRPCsFinished(dt)
	if not player.isLounging() then
		sbq.sbqCurrentData = player.getProperty( "sbqCurrentData") or {}
		if occpantsWhenAssigned ~= (sbq.sbqCurrentData.totalOccupants or 0) then
			assignedMenu = nil
		end

		if (storage.seatdata.shift or 0) > 0.2 then
			if not assignedMenu and controls.up then
				if activeItem.hand() == "primary" then activeItem.callOtherHandScript("dontDoRadialMenu", true) end
				if dontDoMenu then return end
				assignedMenu = true
				selectedPrey = nil
				assignSelectMenu()

			elseif assignedMenu then
				if dontDoMenu then return end
				sbq.loopedMessage("radialSelection", player.id(), "sbqGetRadialSelection", {}, function(data)
					if data.selection ~= nil then
						sbq.lastRadialSelection = data.selection
						sbq.radialSelectionType = data.type
						if data.selection == "cancel" then return end
						if data.selection == "despawn" and data.pressed and not sbq.click then
							sbq.click = true
							letout(selectedPrey)
							return
						end

						if data.type == "controllerActionSelect" then
							if data.button == 0 and data.pressed and not sbq.click then
								sbq.click = true
								world.sendEntityMessage(player.id(), "primaryItemData", { assignClickAction = data.selection })
							elseif data.button == 2 and data.pressed and not sbq.click then
								sbq.click = true
								world.sendEntityMessage(player.id(), "altItemData", {assignClickAction = data.selection })
							end
						elseif data.type == "controllerSelectMenu" then
							if data.pressed and not sbq.click then
								sbq.click = true
								if data.selection == "assignAction" then
									assignAssignActionMenu()
								elseif data.selection == "rpAction" then
									assignRPActionMenu()
								elseif data.selection == "preyAction" then
									assignPreyActionMenu()
								end
							end
						elseif data.type == "controllerPreySelect" then
							if data.pressed and not sbq.click then
								sbq.click = true
								assignPreyActionsLocation(data.selection)
							end
						elseif data.type == "controllerPreyAction" then
							if data.pressed and not sbq.click then
								sbq.click = true
								if type(sbq[data.selection]) == "function" then
									sbq[data.selection](selectedPrey, selectedPreyIndex)
								end
							end
						end
						if not data.pressed then
							sbq.click = false
						end
					end
				end)
			end
		elseif assignedMenu then
			world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqClose" )
			if sbq.lastRadialSelection == "despawn" then
				letout(selectedPrey)
			end
			assignedMenu = nil
			activeItem.callOtherHandScript("dontDoRadialMenu")
		else
			if fireMode == "primary" and not clicked then
				clicked = true
				if type(sbq.sbqCurrentData.id) == "number" and world.entityExists(sbq.sbqCurrentData.id) then
					doVoreAction(sbq.sbqCurrentData.id)
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

function letout(i)
	if type(sbq.sbqCurrentData.id) == "number" and world.entityExists(sbq.sbqCurrentData.id) then
		if (sbq.sbqCurrentData.totalOccupants or 0) > 0 then
			world.sendEntityMessage(sbq.sbqCurrentData.id, "letout",i)
		else
			world.sendEntityMessage(sbq.sbqCurrentData.id, "despawn",i)
		end
	end
end

function assignAssignActionMenu()
	local sbqSettings = player.getProperty("sbqSettings") or {}
	local settings = sb.jsonMerge(sbqSettings.sbqOccupantHolder or {}, sbqSettings.global or {})

	local options = {
		{
			name = "despawn",
			icon = "/interface/xhover.png",
			title = "Let Out"
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
	occpantsWhenAssigned = sbq.sbqCurrentData.totalOccupants or 0
	if (sbq.sbqCurrentData.totalOccupants or 0) > 0 then
		options[1].icon = nil
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
end

function assignSelectMenu()
	local options = {
		{
			name = "despawn",
			icon = "/interface/xhover.png",
			title = "Let Out"
		},
		--[[{
			name = "rpAction",
			title = "Roleplay\nActions"
		},]]
		{
			name = "assignAction",
			title = "Assign\nClick"
		}
	}
	occpantsWhenAssigned = sbq.sbqCurrentData.totalOccupants or 0
	if (sbq.sbqCurrentData.totalOccupants or 0) > 0 then
		options[1].icon = nil
		table.insert(options, {
			name = "preyAction",
			title = "Prey\nActions"
		})
	end
	world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "controllerSelectMenu" }, true )
end

function assignRPActionMenu()

end

function assignPreyActionMenu()
	local options = {
		{
			name = "all",
			title = "By Location"
		}
	}
	if sbq.sbqCurrentData.id and world.entityExists(sbq.sbqCurrentData.id) then
		sbq.addRPC(world.sendEntityMessage(sbq.sbqCurrentData.id, "getOccupancyData"), function (data)
			for i = 0, 7 do
				local number = i
				local i = tostring(i)
				if data.occupant and data.occupant[i].id ~= nil and world.entityExists(data.occupant[i].id) then
					table.insert(options, {
						name = data.occupant[i].id,
						title = (number+1)..": "..(world.entityName(data.occupant[i].id) or "")
					})
				end
			end
			world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "controllerPreySelect" }, true )
		end)
	end
end

function assignLocationActionSelect()
	local sbqSettings = player.getProperty("sbqSettings") or {}
	local settings = sb.jsonMerge(sbqSettings.sbqOccupantHolder or {}, sbqSettings.global or {})


end

function assignPreyActionsLocation(id)
	selectedPrey = id
	local sbqSettings = player.getProperty("sbqSettings") or {}
	local settings = sb.jsonMerge(sbqSettings.sbqOccupantHolder or {}, sbqSettings.global or {})
	sbq.getSpeciesConfig(player.species(), settings)
	local sbqData = sbq.speciesConfig.sbqData

	local options = {
		{
			name = "despawn",
			title = "Let Out"
		},
		{
			name = "npcInteract",
			title = "Interact"
		}
	}
	if sbq.sbqCurrentData.id and world.entityExists(sbq.sbqCurrentData.id) then
		sbq.addRPC(world.sendEntityMessage(sbq.sbqCurrentData.id, "getOccupancyData"), function(data)
			sbq.occupant = data.occupant
			for i = 0, 7 do
				local number = i
				local i = tostring(i)
				selectedPreyIndex = i
				if data.occupant and data.occupant[i].id ~= nil and world.entityExists(data.occupant[i].id) and data.occupant[i].id == id then
					local locationData = sbqData.locations[data.occupant[i].location]
					for j, action in ipairs(locationData.preyActions or {}) do
						if (not action.checkSettings) or sbq.checkSettings(action.checkSettings, settings) then
							table.insert(options, {
								name = action.script,
								title = action.name
							})
						end
					end
					world.sendEntityMessage( player.id(), "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "controllerPreyAction" }, true )
					break
				end
			end
		end)
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
	sbq.sbqCurrentData = player.getProperty( "sbqCurrentData") or {}
	if sbq.sbqCurrentData.species == "sbqOccupantHolder" or not sbq.sbqCurrentData.species then
		local species = player.species()
		local success, notEmpty = pcall(root.nonEmptyRegion, ("/humanoid/"..species.."/voreControllerIcons/"..action..".png"))
		if success and notEmpty ~= nil then
			icon = "/humanoid/"..species.."/voreControllerIcons/"..action..".png"
		end
	end
	return icon
end

function getDirectives()
	sbq.sbqCurrentData = player.getProperty( "sbqCurrentData") or {}
	if sbq.sbqCurrentData.species == "sbqOccupantHolder" or not sbq.sbqCurrentData.species then
		local overrideData = status.statusProperty("speciesAnimOverrideData") or {}
		storage.directives = overrideData.directives
	end
end

function sbq.checkSettings(checkSettings, settings)
	for setting, value in pairs(checkSettings or {}) do
		if (type(settings[setting]) == "table") and settings[setting].name ~= nil then
			if not value then return false
			elseif type(value) == "table" then
				if not sbq.checkTable(value, settings[setting]) then return false end
			end
		elseif type(value) == "table" then
			local match = false
			for i, value in ipairs(value) do if (settings[setting] or false) == value then
				match = true
				break
			end end
			if not match then return false end
		elseif (settings[setting] or false) ~= value then return false
		end
	end
	return true
end

function sbq.checkTable(check, checked)
	for k, v in pairs(check) do
		if type(v) == "table" then
			if not sbq.checkTable(v, (checked or {})[k]) then return false end
		elseif v == true and type((checked or {})[k]) ~= "boolean" and ((checked or {})[k]) ~= nil then
		elseif not (v == (checked or {})[k] or false) then return false
		end
	end
	return true
end
