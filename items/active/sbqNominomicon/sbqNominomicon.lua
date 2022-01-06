
sbq = {}

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

function sbq.checkRPCsFinished(dt)
	for i, list in pairs(sbq.rpcList) do
		list.dt = list.dt + dt -- I think this is good to have, incase the time passed since the RPC was put into play is important
		if list.rpc:finished() then
			if list.rpc:succeeded() and list.callback ~= nil then
				list.callback(list.rpc:result(), list.dt)
			elseif list.failCallback ~= nil then
				list.failCallback(list.dt)
			end
			table.remove(sbq.rpcList, i)
		end
	end
end

sbq.rpcList = {}
function sbq.addRPC(rpc, callback, failCallback)
	if callback ~= nil or failCallback ~= nil  then
		table.insert(sbq.rpcList, {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0})
	end
end
