function die()
	local offset = config.getParameter("doorOffset") or {0,0}
	local position = object.position()
	local entity = world.objectAt({position[1]-offset[1],position[2]-offset[2]})
	if type(entity) == "number" then
		world.callScriptedEntity(entity, "openDoor")
	end
end
