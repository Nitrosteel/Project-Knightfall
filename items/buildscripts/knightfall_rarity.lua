function knightfallRarity(cfg)
	if cfg.tooltipFields and cfg.tooltipFields.rarityLabel then
		return
	end
	
	local rarityCfg = root.assetJson("/items/buildscripts/knightfall_rarity.config")
	local labels = rarityCfg[cfg.rarityLabelKind or "default"]
	
	if labels then
		local rarity = cfg.rarity
		rarity = rarity:lower()
		
		if labels[rarity] then
			cfg.tooltipFields = cfg.tooltipFields or {}
			cfg.tooltipFields.rarityLabel = labels[rarity]
		end
	end
end