---@diagnostic disable: undefined-global

message.setHandler("setBoobMask", function (_,_,booba)
	if booba then
		local part = replaceSpeciesGenderTags(self.speciesData.sbqBreastCover or "/humanoid/<species><reskin>/breasts/femaleBreastsCover.png")
		local success, notEmpty = pcall(root.nonEmptyRegion, (part))
		if success and notEmpty ~= nil then
			animator.setPartTag("breastsCover", "partImage", part)
			self.parts["breastsCover"] = part
		end
		local part = replaceSpeciesGenderTags(self.speciesData.sbqBreastCoverMask or "/humanoid/<species><reskin>/breasts/mask/femalebody.png")
		local success, notEmpty = pcall(root.nonEmptyRegion, (part))
		if success and notEmpty ~= nil then
			animator.setGlobalTag("bodyMask1", part)
		end
	else
		animator.setPartTag("breastsCover", "partImage", "")
		self.parts["breastsCover"] = ""
		animator.setGlobalTag("bodyMask1", "/humanoid/animOverrideMasks/malebody.png")
	end
end)
