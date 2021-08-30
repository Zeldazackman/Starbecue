s = {}

function init()
	if object.uniqueId() ~= nil then
		object.setUniqueId(sb.makeUuid())
	end
	s.defaultValues = root.assetJson(config.getParameter("path"))
	s.vehicle = s.defaultValues.spov.types[math.random(#s.defaultValues.spov.types)]
	s.position = object.position()
	s.spawnPosition = localToGlobal(s.defaultValues.spov.position)

	message.setHandler( "saveVSOsettings", function(_,_, settings )
		storage.settings = settings
	end)

	if storage.settings == nil and s.defaultValues.spov.settings ~= nil then
		storage.settings = s.defaultValues.spov.settings
	end
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
		s.vsoEid = world.spawnVehicle( s.vehicle, s.spawnPosition, { spawner = entity.id(), settings = storage.settings, direction = object.direction() } )
	end

end

function die()
	if s.vsoEid ~= nil then
		world.sendEntityMessage(s.vsoEid, "despawn")
	end

end
