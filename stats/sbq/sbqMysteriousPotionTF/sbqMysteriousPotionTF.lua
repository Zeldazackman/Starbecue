local inited

function init()
	doInit()
end

function doInit()
	if world.pointTileCollision(entity.position(), {"Null"}) then return end

	self = status.statusProperty("sbqMysteriousPotionTF") or {}
	status.setStatusProperty("sbqMysteriousPotionTFDuration", effect.duration() )
	if not self.species then
		local speciesList = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
		self.species = speciesList[math.random(#speciesList)]
	end
	local genders = {"male", "female"}
	if not self.gender then
		self.gender = genders[math.random(2)]
	end
	if self.gender == "noChange" then
		self.gender = world.entityGender(entity.id())
	end

	local success, speciesFile = pcall(root.assetJson, ("/species/"..self.species..".species"))
	if success and not self.identity then
		self.identity = {}
		for i, data in ipairs(speciesFile.genders or {}) do
			if data.name == self.gender then
				self.identity.hairGroup = data.hairGroup or "hair"
				self.identity.facialHairGroup = data.facialHairGroup or "facialHair"
				self.identity.facialMaskGroup = data.facialMaskGroup or "facialMask"

				if data.hair[1] ~= nil then
					self.identity.hairType = data.hair[math.random(#data.hair)]
				end
				if data.facialHair[1] ~= nil then
					self.identity.facialHairType = data.facialHair[math.random(#data.facialHair)]
				end
				if data.facialMask[1] ~= nil then
					self.identity.facialMaskType = data.facialMask[math.random(#data.facialMask)]
				end
			end
		end
	end
	local undyColor
	if success and not self.directives then
		local directives = ""
		local colorTable = (speciesFile.bodyColor or {})[math.random(#speciesFile.bodyColor)]
		if type(colorTable) == "table" then
			directives = "?replace"
			for color, replace in pairs(colorTable) do
				directives = directives..";"..color.."="..replace
			end
		end
		local directives2 = ""
		colorTable = (speciesFile.undyColor or {})[math.random(#speciesFile.undyColor)]
		if type(colorTable) == "table" then
			directives2 = "?replace"
			for color, replace in pairs(colorTable) do
				directives2 = directives2..";"..color.."="..replace
			end
		end
		undyColor = directives2
		self.directives = directives..directives2
	end
	if success and not self.hairDirectives then
		local directives = ""
		local colorTable = (speciesFile.hairColor or {})[math.random(#speciesFile.hairColor)]

		if type(colorTable) == "table" then
			directives = "?replace"
			for color, replace in pairs(colorTable) do
				directives = directives..";"..color.."="..replace
			end
		end

		if speciesFile.headOptionAsHairColor then
			self.hairDirectives = directives
		else
			self.hairDirectives = self.directives
		end
		if speciesFile.hairColorAsBodySubColor then
			self.directives = self.directives..self.hairDirectives
			self.hairDirectives = self.directives
		end
		if speciesFile.altOptionAsHairColor then
			self.hairDirectives = self.hairDirectives..(undyColor or "")
		end
	end

	local specialStatus
	if success then
		specialStatus = speciesFile.customAnimStatus
	end

	self.mysteriousPotion = true
	self.permanent = true

	local statusProperty = status.statusProperty("speciesAnimOverrideData") or {}
	if not statusProperty.mysteriousPotion then
		status.setStatusProperty("oldSpeciesAnimOverrideData", statusProperty)
		status.setStatusProperty("oldSpeciesAnimOverrideCategory", status.getPersistentEffects("speciesAnimOverride"))
	end

	status.setStatusProperty("sbqMysteriousPotionTF", self)
	status.clearPersistentEffects("speciesAnimOverride")
	status.setStatusProperty("speciesAnimOverrideData", self)
	status.setPersistentEffects("speciesAnimOverride", {specialStatus or "speciesAnimOverride"})
	refreshOccupantHolder()

	inited = true
end

function update(dt)
	if not inited then doInit() end
	status.setStatusProperty("sbqMysteriousPotionTFDuration", effect.duration() )
end

function uninit()
	status.setStatusProperty("sbqMysteriousPotionTFDuration", effect.duration() )
	if effect.duration() == 0 then
		status.setStatusProperty("sbqMysteriousPotionTF", nil)
		status.clearPersistentEffects("speciesAnimOverride")
		status.setStatusProperty("speciesAnimOverrideData", status.statusProperty("oldSpeciesAnimOverrideData"))
		status.setPersistentEffects("speciesAnimOverride", status.statusProperty("oldSpeciesAnimOverrideCategory"))
		refreshOccupantHolder()
	end
end

function refreshOccupantHolder()
	local currentData = status.statusProperty("sbqCurrentData") or {}
	if currentData.species == "sbqOccupantHolder" and world.entityExists(currentData.id) then
		world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { driver = entity.id(), settings = currentData.settings, retrievePrey = currentData.id, direction = mcontroller.facingDirection() } )
	end
end
