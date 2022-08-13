
if type(self.speciesFile) == "table" then
	if self.speciesFile.charGenTextLabels[1] == "Eye colour" and self.speciesFile.charGenTextLabels[6] == "Detail colour" then

		self.speciesData = sb.jsonMerge(self.speciesData, root.assetJson("/humanoid/dragon/draconisdragons/sbqAnimOverrideParts.config") )
	end
end
