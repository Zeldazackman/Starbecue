function init()
	if storage.state == nil then storage.state = config.getParameter("defaultLightState", true) end
	if storage.interactive == nil then storage.interactive = true end

	object.setInteractive(storage.interactive)
	setLightState(storage.state)
end

function onInteraction(args)
	if storage.linked then
		if storage.destinations ~= nil and storage.destinations[1] ~= nil then
			return { "OpenTeleportDialog", {
				canBookmark = false,
				includePlayerBookmarks = false,
				destinations = storage.destinations
			}}
		end
		return
	end
	return { "OpenTeleportDialog", config.getParameter("teleporterConfig", root.assetJson("/interface/warping/remoteteleporter.config")) }
end

function processWireInput()
	if object.isInputNodeConnected(1) or object.isOutputNodeConnected(0) then
		storage.linked = true
		if object.isOutputNodeConnected(0) then
			storage.destinations = {}
			local connectedDestinations = object.getOutputNodeIds(0)
			for id, index in pairs(connectedDestinations) do
				addDestination(id)
			end
		end
	else
		storage.linked = false
	end

	if object.isInputNodeConnected(0) then
		storage.state = object.getInputNodeLevel(0)
	else
		storage.state = config.getParameter("defaultLightState", true)
	end

	if (not storage.linked) or (object.isOutputNodeConnected(0) and storage.destinations ~= nil and storage.destinations[1] ~= nil) then
		storage.interactive = storage.state
	else
		storage.interactive = false
	end

	object.setInteractive(storage.interactive)
	setLightState(storage.state)
	object.setOutputNodeLevel(0, storage.state)
end

function addDestination(id)
	local continue = true
	if object.getInputNodeIds(1)[id] ~= nil and not object.getInputNodeLevel(1) then
		continue = false
	end
	if continue then
		local coords = world.entityPosition(id)
		table.insert(storage.destinations, {
			name = "Somewhere else...",
			planetName = "???",
			warpAction = "nowhere="..math.floor(coords[1]).."."..math.floor(coords[2]),
			icon = "default"
		})
	end
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
