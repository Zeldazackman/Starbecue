
function sbq.letout(id, i)
	world.sendEntityMessage( sbq.sbqCurrentData.id, "letout", id )
end

function sbq.npcInteract(id, i)
	world.sendEntityMessage(id, "sbqInteract", player.id(), sbq.occupant[i].location)
end

function sbq.turboDigest(id, i)
	world.sendEntityMessage( id, "sbqTurboDigest" )
end

function sbq.transform(id, i)
	sbq.addRPC(world.sendEntityMessage(id, "sbqIsPreyEnabled", "transformImmunity"), function (immune)
		if not immune then
			world.sendEntityMessage( sbq.sbqCurrentData.id, "transform", id, 3 )
		end
	end)
end

function sbq.eggify(id, i)
	sbq.addRPC(world.sendEntityMessage(id, "sbqIsPreyEnabled", "eggImmunity"), function (immune)
		if not immune then
			local eggData = root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle")
			local replaceColors = {
				math.random(1, #eggData.sbqData.replaceColors[1] - 1),
				math.random(1, #eggData.sbqData.replaceColors[2] - 1)
			}

			world.sendEntityMessage( sbq.sbqCurrentData.id, "transform", id, 3, {
				barColor = eggData.sbqData.replaceColors[2][replaceColors[2]+1],
				forceSettings = true,
				layer = true,
				state = "smol",
				species = "sbqEgg",
				layerLocation = "egg",
				settings = {
					cracks = 0,
					bellyEffect = "sbqHeal",
					escapeDifficulty = sbq.sbqSettings.global.escapeDifficulty,
					replaceColors = replaceColors
				}
			})
		end
	end)
end

function sbq.xeroEggify(id, i)
	sbq.addRPC(world.sendEntityMessage(id, "sbqIsPreyEnabled", "eggImmunity"), function (immune)
		if not immune then
			world.sendEntityMessage( sbq.sbqCurrentData.id, "transform", id, 3, {
				barColor = {"aa720a", "e4a126", "ffb62e", "ffca69"},
				forceSettings = true,
				layer = true,
				state = "smol",
				species = "sbqEgg",
				layerLocation = "egg",
				settings = {
					cracks = 0,
					bellyEffect = "sbqHeal",
					escapeDifficulty = sbq.sbqSettings.global.escapeDifficulty,
					replaceColorTable = {
						{"aa720a", "e4a126", "ffb62e", "ffca69"},
						{"aa720a", "e4a126", "ffb62e", "ffca69"}
					},
				}
			})
		end
	end)
end

function sbq.cumTF(id, i)
	sbq.addRPC(world.sendEntityMessage(id, "sbqIsPreyEnabled", "transformImmunity"), function (immune)
		if not immune then
			world.sendEntityMessage( sbq.sbqCurrentData.id, "transform", id, 3, sbq.config.victimTransformPresets.cumBlob)
		end
	end)
end

function sbq.plasticEggify(id, i)
	sbq.addRPC(world.sendEntityMessage(id, "sbqIsPreyEnabled", "eggImmunity"), function (immune)
		if not immune then
			local eggData = root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle")
			local replaceColorTable = {
				eggData.sbqData.plasticReplaceColors[1][math.random(1, #eggData.sbqData.plasticReplaceColors[1])],
				eggData.sbqData.plasticReplaceColors[2][math.random(1, #eggData.sbqData.plasticReplaceColors[2])]
			}
			world.sendEntityMessage( sbq.sbqCurrentData.id, "transform", id, 3, {
				barColor = replaceColorTable[2],
				forceSettings = true,
				layer = true,
				state = "smol",
				species = "sbqEgg",
				layerLocation = "egg",
				settings = {
					cracks = 0,
					bellyEffect = "sbqHeal",
					escapeDifficulty = sbq.sbqSettings.global.escapeDifficulty,
					replaceColorTable = replaceColorTable,
					skinNames = { head = "plastic" },
					firstLoadDone = true
				}
			})
		end
	end)
end

function sbq.glassEggify(id, i)
	sbq.addRPC(world.sendEntityMessage(id, "sbqIsPreyEnabled", "eggImmunity"), function (immune)
		if not immune then
			local eggData = root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle")
			local replaceColorTable = {
				eggData.sbqData.glassReplaceColors[1][math.random(1, #eggData.sbqData.glassReplaceColors[1])],
				eggData.sbqData.glassReplaceColors[2][math.random(1, #eggData.sbqData.glassReplaceColors[2])]
			}
			world.sendEntityMessage( sbq.sbqCurrentData.id, "transform", id, 3, {
				barColor = replaceColorTable[2],
				forceSettings = true,
				layer = true,
				state = "smol",
				species = "sbqEgg",
				layerLocation = "egg",
				settings = {
					cracks = 0,
					bellyEffect = "sbqHeal",
					escapeDifficulty = sbq.sbqSettings.global.escapeDifficulty,
					replaceColorTable = replaceColorTable
				}
			})
		end
	end)
end
