function init()
	local statuses = config.getParameter("cauldronStatusEffects")
	storage.status = statuses[math.random(#statuses)]
	storage.occupant = {}
	animator.setGlobalTag("directives", config.getParameter("cauldronStatusDirectives")[storage.status])
	storage.hue = 0
end

function update(dt)
	if storage.status == "partytime" then
		storage.hue = storage.hue + 1
		animator.setGlobalTag("directives", "?hueshift="..storage.hue)
	end
	for i, occupantId in ipairs(storage.occupant) do
		if checkClose(occupantId) then
			world.sendEntityMessage(occupantId, "applyStatusEffect", storage.status, 10)
		else
			table.remove(storage.occupant, i)
		end
	end
end

function checkClose(occupantId)
	local box = object.boundBox()
	local players = world.playerQuery({box[1], box[2]}, {box[3], box[4]})
	for _, player in ipairs(players) do
		if player == occupantId then
			return true
		end
	end
end


function onInteraction(args)
	table.insert(storage.occupant, args.sourceId)
	world.sendEntityMessage(args.sourceId, "applyStatusEffect", storage.status)
end

function die()
end
