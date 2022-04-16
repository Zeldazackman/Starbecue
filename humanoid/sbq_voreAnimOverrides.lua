---@diagnostic disable:undefined-global

--local oldInitAfterInit = initAfterInit
--local oldDoUpdate = doUpdate

sbq = {}

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
	for part, tags in pairs(partTags) do
		if part == "global" then
			for tag, value in pairs(tags) do
				animator.setGlobalTag(tag, value)
			end
		else
			for tag, value in pairs(tags) do
				animator.setPartTag(part, tag, value)
			end
		end
	end
	return {self.animStateData, mcontroller.facingDirection()}
end)

function sbq.getSettings(callback, failcallback)
	addRPC(world.sendEntityMessage(entity.id(), "sbqLoadSettings", "sbqOccupantHolder"), callback, failcallback)
end

-- this function need to be replaced/modified because of stuff that would be in the chest area for say, breast vore
local _chest_addon = setCosmetic.chest_addon
function setCosmetic.chest_addon(cosmetic, item, images, directives)
	local breasts = fixFilepath(images.breasts, item)

	animator.setPartTag("breasts_cosmetic", "cosmeticDirectives", directives or "" )
	animator.setPartTag("breasts_cosmetic", "partImage", breasts or "" )

	_chest_addon(cosmetic, item, images, directives)
end

local _chest_clear = setCosmetic.chest_clear
function setCosmetic.chest_clear(cosmetic)
	animator.setPartTag("breasts_cosmetic", "partImage", "" )
	_chest_clear(cosmetic)
end

-- this function needs to be replaced to make sure the belly is handeled for normal vore, and the dick for cock vore
local _legs_addon = setCosmetic.legs_addon
function setCosmetic.legs_addon(cosmetic, item, directives)
	local belly = fixFilepath(item.config[self.gender.."BellyFrames"], item)

	animator.setPartTag("belly_cosmetic", "cosmeticDirectives", directives or "" )
	animator.setPartTag("belly_cosmetic", "partImage", belly or "" )

	sbq.getSettings(function (settings)
		if settings.penis then
			local cock = fixFilepath(item.config[self.gender.."CockFrames"], item)
			animator.setPartTag("cock_cosmetic", "cosmeticDirectives", directives or "" )
			animator.setPartTag("cock_cosmetic", "partImage", cock or "" )
		else
			sbq.clearPenis()
		end

		if settings.balls then
			local ballsFront = fixFilepath(item.config[self.gender.."ballsFrontFrames"], item)
			local ballsBack = fixFilepath(item.config[self.gender.."ballsBackFrames"], item)
			animator.setPartTag("ballsFront_cosmetic", "cosmeticDirectives", directives or "" )
			animator.setPartTag("ballsFront_cosmetic", "partImage", ballsFront or "" )
			animator.setPartTag("ballsBack_cosmetic", "cosmeticDirectives", directives or "" )
			animator.setPartTag("ballsBack_cosmetic", "partImage", ballsBack or "" )
		else
			sbq.clearBalls()
		end

		if settings.pussy then
			local pussy = fixFilepath(item.config[self.gender.."pussyFrames"], item)
			animator.setPartTag("pussy_cosmetic", "cosmeticDirectives", directives or "" )
			animator.setPartTag("pussy_cosmetic", "partImage", pussy or "" )
		else
			sbq.clearPussy()
		end
	end)

	_legs_addon(cosmetic, item, directives)
end

function sbq.clearPenis()
	animator.setPartTag("cock_cosmetic", "partImage", "" )
end
function sbq.clearBalls()
	animator.setPartTag("ballsFront_cosmetic", "partImage", "" )
	animator.setPartTag("ballsBack_cosmetic", "partImage", "" )
end
function sbq.clearPussy()
	animator.setPartTag("pussy_cosmetic", "partImage", "" )
end

local _legs_clear = setCosmetic.legs_clear
function setCosmetic.legs_clear(cosmetic)

	animator.setPartTag("belly_cosmetic", "partImage", "" )
	sbq.clearPenis()
	sbq.clearBalls()
	sbq.clearPussy()

	_legs_clear(cosmetic)
end
