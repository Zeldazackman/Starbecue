---@diagnostic disable:undefined-global

--local oldInitAfterInit = initAfterInit


local _scaleUpdated = scaleUpdated
function scaleUpdated(dt)
	_scaleUpdated(dt)
	local occupantHolder = (status.statusProperty("sbqCurrentData") or {}).id
	if occupantHolder then
		world.sendEntityMessage(occupantHolder, "sbqOccupantHolderScale", self.currentScale or 1, (self.controlParameters or {}).yOffset or 0)
	end
end

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

message.setHandler("sbqSetPartTag", function (_,_, part, tag, value)
	animator.setPartTag(part, tag, value)
end)

message.setHandler("sbqSetGlobalTag", function (_,_, tag, value)
	animator.setGlobalTag(tag, value)
end)

message.setHandler("sbqSetStatusValue", function (_,_, name, value)
	self[name] = value
	refreshCosmetics = true
end)


message.setHandler("sbqEnableUnderwear", function (_,_, enable)
	if self.speciesFile.hasUnderwear and not enable then
		for partname, string in pairs(self.speciesData.nudePartImages or {}) do
			local part = replaceSpeciesGenderTags(string)
			local success, notEmpty = pcall(root.nonEmptyRegion, (part))
			if success and notEmpty ~= nil then
				animator.setPartTag(partname, "partImage", part)
				self.parts[partname] = part
			end
		end
	end

	for partname, string in pairs(self.speciesData.underwearPartImages or {}) do
		if enable then
			local part = replaceSpeciesGenderTags(string)
			local success, notEmpty = pcall(root.nonEmptyRegion, (part))
			if success and notEmpty ~= nil then
				animator.setPartTag(partname, "partImage", part)
				self.parts[partname] = part
			end
		else
			local part = ""
			animator.setPartTag(partname, "partImage", part)
			self.parts[partname] = part
		end
	end
end)

message.setHandler("sbqEnableBra", function (_,_, enable)
	if self.speciesFile.hasBra and not enable then
		for partname, string in pairs(self.speciesData.nudeChestPartImages or {}) do
			local part = replaceSpeciesGenderTags(string)
			local success, notEmpty = pcall(root.nonEmptyRegion, (part))
			if success and notEmpty ~= nil then
				animator.setPartTag(partname, "partImage", part)
				self.parts[partname] = part
			end
		end
	end

	for partname, string in pairs(self.speciesData.braPartImages or {}) do
		if enable then
			local part = replaceSpeciesGenderTags(string)
			local success, notEmpty = pcall(root.nonEmptyRegion, (part))
			if success and notEmpty ~= nil then
				animator.setPartTag(partname, "partImage", part)
				self.parts[partname] = part
			end
		else
			local part = ""
			animator.setPartTag(partname, "partImage", part)
			self.parts[partname] = part
		end
	end
end)

message.setHandler("sbqUpdateAnimPartImage", function (_,_, partname, string)
	local part = replaceSpeciesGenderTags(string)
	local success, notEmpty = pcall(root.nonEmptyRegion, (part))
	if success and notEmpty ~= nil then
		animator.setPartTag(partname, "partImage", part)
		self.parts[partname] = part
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

message.setHandler("sbqGetAnimData", function (_,_)
	return mcontroller.facingDirection()
end)

function sbq.getSettings(callback, failcallback)
	addRPC(world.sendEntityMessage(entity.id(), "sbqLoadSettings", "sbqOccupantHolder"), callback, failcallback)
end

-- this function need to be replaced/modified because of stuff that would be in the chest area for say, breast vore
local _chest_addon = setCosmetic.chest_addon
function setCosmetic.chest_addon(cosmetic, item, images, directives)

	local whitelisted = root.assetJson("/sbqGeneral.config").chestVoreWhitelist[cosmetic.name]

	local belly = fixFilepath(images.belly, item)
	animator.setPartTag("belly_cosmetic", "cosmeticDirectives", directives or "" )
	animator.setPartTag("belly_cosmetic", "partImage", belly or "" )

	if whitelisted then
		sbq.getSettings(function (settings)
			if settings.breasts then
				local breasts = fixFilepath(images.breasts, item)
				animator.setPartTag("breasts_cosmetic", "cosmeticDirectives", directives or "" )
				animator.setPartTag("breasts_cosmetic", "partImage", breasts or "" )
			else
				sbq.clearBreasts()
			end
		end)
	end
	sbq.hideBreasts(not whitelisted)

	_chest_addon(cosmetic, item, images, directives)
end

function sbq.clearBreasts()
	animator.setPartTag("breasts_cosmetic", "partImage", "" )
end

function sbq.hideBreasts(bool)
	if not bool then
		animator.setGlobalTag( "breastsVisible", self.breastsVisible or "?crop;0;0;0;0" )
	else
		animator.setGlobalTag( "breastsVisible", "?crop;0;0;0;0" )
	end
end

local _chest_clear = setCosmetic.chest_clear
function setCosmetic.chest_clear(cosmetic)
	animator.setPartTag("breasts_cosmetic", "partImage", "")
	animator.setPartTag("belly_cosmetic", "partImage", "" )
	sbq.hideBreasts(false)
	_chest_clear(cosmetic)
end

-- this function needs to be replaced to make sure the belly is handeled for normal vore, and the dick for cock vore
local _legs_addon = setCosmetic.legs_addon
function setCosmetic.legs_addon(cosmetic, item, directives)

	local whitelisted = root.assetJson("/sbqGeneral.config").legsVoreWhitelist[cosmetic.name]

	if whitelisted then
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
		end)
	else
		sbq.clearPenis()
		sbq.clearBalls()
	end

	sbq.hidePenis(not whitelisted)
	sbq.hideBalls(not whitelisted)
	sbq.hidePussy(not whitelisted)

	_legs_addon(cosmetic, item, directives)
end

function sbq.clearPenis()
	animator.setPartTag("cock_cosmetic", "partImage", "" )
end
function sbq.clearBalls()
	animator.setPartTag("ballsFront_cosmetic", "partImage", "" )
	animator.setPartTag("ballsBack_cosmetic", "partImage", "" )
end

function sbq.hidePenis(bool)
	if not bool then
		animator.setGlobalTag( "cockVisible", self.cockVisible or "?crop;0;0;0;0" )
	else
		animator.setGlobalTag( "cockVisible", "?crop;0;0;0;0" )
	end
end

function sbq.hidePussy(bool)
	if not bool then
		animator.setGlobalTag( "pussyVisible", self.pussyVisible or "?crop;0;0;0;0" )
	else
		animator.setGlobalTag( "pussyVisible", "?crop;0;0;0;0" )
	end
end

function sbq.hideBalls(bool)
	if not bool then
		animator.setGlobalTag( "ballsVisible", self.ballsVisible or "?crop;0;0;0;0" )
	else
		animator.setGlobalTag( "ballsVisible", "?crop;0;0;0;0" )
	end
end

local _legs_clear = setCosmetic.legs_clear
function setCosmetic.legs_clear(cosmetic)

	sbq.clearPenis()
	sbq.clearBalls()

	sbq.hidePenis(false)
	sbq.hideBalls(false)

	_legs_clear(cosmetic)
end
