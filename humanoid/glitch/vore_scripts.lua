function sbq.otherLocationEffects(i, eid, health, bellyEffect, location, powerMultiplier )
	if location == "womb" then
		local bellyEffect = "sbqHeal"
		if sbq.settings.displayDigest then
			if sbq.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
				bellyEffect = sbq.config.bellyDisplayStatusEffects[bellyEffect]
			end
		end
		world.sendEntityMessage( eid, "applyStatusEffect", bellyEffect, powerMultiplier, entity.id())
	end

	if (sbq.occupant[i].progressBar <= 0) then
		if (sbq.settings.penisCumTF and location == "shaft") or (sbq.settings.ballsCumTF and ( location == "balls" or location == "ballsR" or location == "ballsL" )) then
			sbq.loopedMessage("CumTF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
				if not immune then
					transformMessageHandler( eid , 3, sbq.config.victimTransformPresets.cumBlob )
				end
			end)
		elseif sbq.settings.wombEggify and location == "womb" then
			sbq.loopedMessage("Eggify"..eid, eid, "sbqIsPreyEnabled", {"eggImmunity"}, function (immune)
				if not immune then
					local eggData = root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle")
					local replaceColorTable = {
						eggData.sbqData.plasticReplaceColors[1][math.random(1, #eggData.sbqData.plasticReplaceColors[1])],
						eggData.sbqData.plasticReplaceColors[2][math.random(1, #eggData.sbqData.plasticReplaceColors[2])]
					}
					transformMessageHandler( eid, 3, {
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
	end
end
