require "/items/active/weapons/ranged/gun.lua"

local baseInit = init
local baseUpdate = update
local id

local colors, altColors = {"#344495", "#5588D4"}, {"#932625", "#D93A3A"}
local barBg, altBarBg = "/scripts/knightfall_reloadbar.png", "/scripts/knightfall_reloadbar.png"

function init()
  baseInit()
	id = activeItem.ownerEntityId()
  
  local cursor = config.getParameter("cursor", "/cursors/reticle0.cursor")
  activeItem.setCursor(cursor)
	
	for _,ability in pairs(self.weapon.abilities) do
		if ability.cooldownBar ~= false then
			local alt = activeItem.hand() == "alt" or ability.abilitySlot == "alt"
			
			local maxTime = ability.fireTime
			if ability.fireType == "burst" then 
				maxTime = (ability.fireTime - ability.burstTime) * ability.burstCount
			end
			ability._cooldownBarTime = maxTime
			
			ability.cooldownBarOffset = ability.cooldownBarOffset or (alt and 2.5 or 3)
			ability.cooldownBarColors = ability.cooldownBarColors or (alt and altColors or colors)
			ability.cooldownBarImage = ability.cooldownBarImage or (alt and altBarBg or barBg)
		end
	end
end

function update(...)
	baseUpdate(...)

	for _,ability in pairs(self.weapon.abilities) do
		if ability._cooldownBarTime and ability.cooldownBar ~= false and (ability.cooldownBar == true or ability._cooldownBarTime >= 0.75) then
			local timer = (ability.cooldownTimer or 0) / ability._cooldownBarTime
			if self.weapon.currentAbility == ability and self.weapon.currentState == ability.burst then timer = 1 end
			
			world.sendEntityMessage(id, "kf_bars", timer, ability.cooldownBarOffset, ability.cooldownBarColors, ability.cooldownBarImage)
		end
	end
end

--[[    cooldown bar funny json stuff
         all parameters are optional

  "ability" : {
		// by default only displays if fireTime is 0.75 or higher
	  "cooldownBar" : false,
		
		// Y offset
		"cooldownBarOffset" : 3,
		
		// bar color and filled bar color
	  "cooldownBarColors" : ["#FFFFFF", "#FFFFFF"],

		// bar background
		"cooldownBarImage" : "/among/us/cock.png"
  }

]]