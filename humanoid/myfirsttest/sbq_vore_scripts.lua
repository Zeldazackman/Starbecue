
function sbq.otherLocationEffects(i, eid, health, bellyEffect, location, powerMultiplier )

	if (sbq.occupant[i].progressBar <= 0) then
		if (sbq.settings.penisCumTF and location == "shaft") or (sbq.settings.ballsCumTF and ( location == "balls" or location == "ballsR" or location == "ballsL" )) then
			sbq.loopedMessage("CumTF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
				if not immune then
					transformMessageHandler( eid , 3, sbq.config.victimTransformPresets.cumBlob )
				end
			end)
		elseif sbq.settings.wombEggify and location == "womb" then
			local bellyEffect = "sbqHeal"
			if sbq.settings.displayDigest then
				if sbq.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
					bellyEffect = sbq.config.bellyDisplayStatusEffects[bellyEffect]
				end
			end
			eggify(eid, bellyEffect)
		elseif sbq.settings.wombTF and location == "womb" then
			sbq.loopedMessage("Transform"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
				if not immune then
					playerTransformMessageHandler( eid, 3 )
				end
			end)
		end
	end
end

function sbq.extraBellyEffects(i, eid, health, bellyEffect)

	if (sbq.occupant[i].progressBar <= 0) then

		if sbq.settings.bellyEggify and sbq.occupant[i].species ~= "sbqEgg" then
			local bellyEffect = "sbqHeal"
			if sbq.settings.displayDigest then
				if sbq.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
					bellyEffect = sbq.config.bellyDisplayStatusEffects[bellyEffect]
				end
			end
			eggify(eid, bellyEffect)
		elseif sbq.settings.bellyTF then
			sbq.loopedMessage("Transform"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
				if not immune then
					playerTransformMessageHandler( eid, 3 )
				end
			end)
		end
	end
end

function eggify(eid, bellyEffect)
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
				layerDigest = true,
				settings = {
					cracks = 0,
					bellyEffect = bellyEffect,
					escapeDifficulty = sbq.settings.escapeDifficulty,
					replaceColorTable = replaceColorTable,
					skinNames = { head = "plastic" },
					firstLoadDone = true
				}
			})
		end
	end)
end
