
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

function init()
	activeItem.setTwoHandedGrip(true)
	activeItem.setArmAngle(-45)
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() and fireMode == "primary" and not clicked then
		clicked = true

		local predators = world.entityQuery( activeItem.ownerAimPosition(), 2, {
			withoutEntityId = entity.id(), includedTypes = { "vehicle" }
		} )

		if predators[1] ~= nil then
			sbq.addRPC(world.sendEntityMessage( predators[1], "objectPredCheck" ), function (isObject)
				if isObject then
					player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:nominomicon" }, predators[1])
				end
			end)
		end
	elseif fireMode == "none" then
		clicked = false
	end
	sbq.checkRPCsFinished(dt)
end
