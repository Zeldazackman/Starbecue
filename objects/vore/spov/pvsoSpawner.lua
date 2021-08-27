s = {}
function init()
	if object.uniqueId() ~= nil then
		object.setUniqueId(sb.makeUuid())
	end
	s.defaultValues = root.assetJson(config.getParameter("path"))
	s.vehicle = s.defaultValues.spov.types[math.random(#s.defaultValues.spov.types)]
	s.position = object.position()
	s.spawnPosition = localToGlobal(s.defaultValues.spov.position)
end

function localToGlobal(position)
	local lpos = { position[1], position[2] }
	if object.direction() == -1 then lpos[1] = -lpos[1] end
	local mpos = s.position
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end

s.vsoEid = nil

function update(dt)

	if (s.vsoEid == nil) or (not world.entityExists(s.vsoEid)) then
		s.vsoEid = world.spawnVehicle( s.vehicle, s.spawnPosition, { settings = storage.settings } )
	end


end

function die()

end
