---@diagnostic disable:undefined-global

local oldInitAfterInit = initAfterInit
local oldDoUpdate = doUpdate

message.setHandler("sbqUpdateAnimTags", function (_,_, animTags)
	for tag, value in pairs(animTags) do
		animator.setGlobalTag(tag, value)
	end
end)

message.setHandler("sbqUpdateAnimPartTag", function (_,_, part, animTags)
	for tag, value in pairs(animTags) do
		animator.setPartTag(part, tag, value)
	end
end)

message.setHandler("sbqDoAnimsName", function (_,_, animsName, force)
	doAnims(self.speciesData.animations[animsName], force)
end)

message.setHandler("sbqDoAnims", function (_,_, anims, force)
	doAnims(anims, force)
end)

message.setHandler("sbqDoAnimName", function (_,_, state, animName, force)
	doAnim(state, self.speciesData.animations[animName], force)
end)

message.setHandler("sbqDoAnim", function (_,_, state, anim, force)
	doAnim(state, anim, force)
end)

message.setHandler("sbqGetAnimData", function (_,_, partTags)
	for tag, value in pairs(partTags.global) do
		animator.setGlobalTag(tag, value)
	end
	return self.animStateData
end)


-- this function need to be replaced/modified because of stuff that would be in the chest area for say, breast vore
function setCosmetic.chest(cosmetic)
	if cosmetic ~= nil then
		local item = root.itemConfig(cosmetic)
		local images = item.config[self.gender.."Frames"]

		local chest = fixFilepath(images.body, item)
		local breasts = fixFilepath(images.breasts, item)

		local backSleeve = fixFilepath(images.backSleeve, item)
		local frontSleeve = fixFilepath(images.frontSleeve, item)

		local frontMask = fixFilepath(images.frontMask, item)
		local backMask = fixFilepath(images.backMask, item)

		local directives = getCosmeticDirectives(item)

		animator.setPartTag("chest_cosmetic", "cosmeticDirectives", directives )
		animator.setPartTag("breasts_cosmetic", "cosmeticDirectives", directives )

		animator.setPartTag("backarms_cosmetic", "cosmeticDirectives", directives )
		animator.setPartTag("frontarms_cosmetic", "cosmeticDirectives", directives )
		animator.setPartTag("backarms_rotation_cosmetic", "cosmeticDirectives", directives )
		animator.setPartTag("frontarms_rotation_cosmetic", "cosmeticDirectives", directives )

		animator.setPartTag("chest_cosmetic", "partImage", chest )
		animator.setPartTag("breasts_cosmetic", "partImage", breasts )

		animator.setPartTag("backarms_cosmetic", "partImage", backSleeve )
		animator.setPartTag("frontarms_cosmetic", "partImage", frontSleeve )
		animator.setPartTag("backarms_rotation_cosmetic", "partImage", backSleeve )
		animator.setPartTag("frontarms_rotation_cosmetic", "partImage", frontSleeve )

		if frontMask ~= nil and frontMask ~= "" then
			animator.setGlobalTag( "frontarmsMask", "?addmask="..frontMask )
		end
		if backMask ~= nil and backMask ~= "" then
			animator.setGlobalTag( "backarmsMask", "?addmask="..backMask )
		end
	else
		animator.setPartTag("chest_cosmetic", "partImage", "" )
		animator.setPartTag("breasts_cosmetic", "partImage", "" )

		animator.setPartTag("backarms_cosmetic", "partImage", "" )
		animator.setPartTag("frontarms_cosmetic", "partImage", "" )
		animator.setPartTag("backarms_rotation_cosmetic", "partImage", "" )
		animator.setPartTag("frontarms_rotation_cosmetic", "partImage", "" )

		animator.setGlobalTag( "frontarmsMask", "" )
		animator.setGlobalTag( "backarmsMask", "" )
	end
end

-- this function needs to be replaced to make sure the belly is handeled for normal vore, and the dick for cock vore
function setCosmetic.legs(cosmetic)
	if cosmetic ~= nil then
		local item = root.itemConfig(cosmetic)
		local mask = fixFilepath(item.config.mask, item)
		local tailMask = fixFilepath(item.config.tailMask, item)

		local cosmeticDirectives = getCosmeticDirectives(item)

		animator.setPartTag("body_cosmetic", "cosmeticDirectives", cosmeticDirectives )
		animator.setPartTag("body_cosmetic", "partImage", fixFilepath(item.config[self.gender.."Frames"], item) )

		animator.setPartTag("tail_cosmetic", "cosmeticDirectives", cosmeticDirectives )
		animator.setPartTag("tail_cosmetic", "partImage", fixFilepath(item.config[self.gender.."TailFrames"], item) )

		animator.setPartTag("belly_cosmetic", "cosmeticDirectives", cosmeticDirectives )
		animator.setPartTag("belly_cosmetic", "partImage", fixFilepath(item.config[self.gender.."BellyFrames"], item) )

		animator.setPartTag("cock_cosmetic", "cosmeticDirectives", cosmeticDirectives )
		animator.setPartTag("cock_cosmetic", "partImage", fixFilepath(item.config[self.gender.."CockFrames"], item) )

		if mask ~= nil and mask ~= "" then
			animator.setGlobalTag( "bodyMask", "?addmask="..mask )
		end
		if tailMask ~= nil and mask ~= "" then
			animator.setGlobalTag( "tailMask", "?addmask="..tailMask )
		end
	else
		animator.setPartTag("body_cosmetic", "partImage", "" )
		animator.setPartTag("tail_cosmetic", "partImage", "" )

		animator.setPartTag("belly_cosmetic", "partImage", "" )
		animator.setPartTag("cock_cosmetic", "partImage", "" )

		animator.setGlobalTag( "bodyMask", "" )
		animator.setGlobalTag( "tailMask", "" )
	end
end
