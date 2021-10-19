
function sbq.letout(id)
	world.sendEntityMessage( player.loungingIn(), "letout", id )
end

function sbq.turboDigest(id)
	world.sendEntityMessage( id, "sbqTurboDigest" )
end

function sbq.transform(id)
	world.sendEntityMessage( player.loungingIn(), "transform", id, 3 )
end

function sbq.xeroEggify(id)
	world.sendEntityMessage( player.loungingIn(), "transform", id, 3, {
		barColor = {"aa720a", "e4a126", "ffb62e", "ffca69"},
		forceSettings = true,
		layer = true,
		state = "smol",
		species = "sbqEgg",
		layerLocation = "egg",
		settings = {
			cracks = 0,
			bellyEffect = "sbqHeal",
			escapeModifier = sbq.sbqSettings.global.escapeModifier,
			skinNames = {
				head = "xeronious",
				body = "xeronious"
			}
		}
	})
end
