function onInteraction(args)
	--[[
	if storage.linked then


		return
	end]]
	return { "OpenTeleportDialog", config.getParameter("teleporterConfig", root.assetJson("/interface/warping/remoteteleporter.config")) }
end


function processWireInput()
	if object.isInputNodeConnected(0) then
		storage.state = object.getInputNodeLevel(0)
		setLightState(storage.state)
		object.setInteractive(storage.state)
	end
	--[[
	if object.isInputNodeConnected(1) or object.isOutputNodeConnected(0) then
		storage.linked = true
		storage.destinations = {}

		table.insert(storage.destinations, {
			canBookmark = false,
			includePlayerBookmarks = false,
			destinations = {
				{
					name = "Somewhere else...",
					planetName = "???",
					warpAction = "OwnShip",
					icon = "beamup"
				}
			}
		})

	else
		storage.linked = false
	end
	]]
end

function setLightState(newState)
	if newState then
		animator.setAnimationState("light", "on")
		object.setSoundEffectEnabled(true)
		if animator.hasSound("on") then
			animator.playSound("on")
		end
		--TODO: support lightColors configuration
		object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
	else
		animator.setAnimationState("light", "off")
		object.setSoundEffectEnabled(false)
		if animator.hasSound("off") then
			animator.playSound("off")
		end
		object.setLightColor(config.getParameter("lightColorOff", {0, 0, 0}))
	end
end
