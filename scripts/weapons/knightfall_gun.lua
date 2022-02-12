require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

local id
local colors, altColors = {"#344495", "#5588D4"}, {"#932625", "#D93A3A"}

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()
  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end
	
	self.weapon.kfcfg = {}
	if player then
		local cursor = config.getParameter("cursor", "/cursors/reticle0.cursor")
		activeItem.setCursor(cursor)
		
		self.weapon.kfcfg = player.getProperty("knightfall_config", {})
	end

	self.weapon.cooldownBars = {}
  self.weapon:init()
	
	id = activeItem.ownerEntityId()
	
	if player then
		local cfg = self.weapon.kfcfg
		self.weapon.barTimeMin = cfg.cooldownBar_minTime or 0.75
		
		for _,ability in pairs(self.weapon.abilities) do
			--restore cooldown timer
			if ability.storeCooldown ~= false then
				if storage["cooldown_"..ability.abilitySlot] then
					local t = 0
					if storage.lastClock and ability.unheldRecharge ~= false then
						t = math.max(0, os.clock() - storage.lastClock)
					end
					ability.cooldownTimer = math.max(0, storage["cooldown_"..ability.abilitySlot] - t)
					
					storage["cooldown_"..ability.abilitySlot] = nil
				else
					ability.cooldownTimer = 0
				end
			end
			
			--setup cooldown bars
			if not ability.fireTime or cfg["cooldownBar_"..ability.abilitySlot] == false then
				ability.cooldownBar = false
			end
			
			if ability.cooldownBar ~= false then
				local alt = activeItem.hand() == "alt" or ability.abilitySlot == "alt"
				ability.cooldownBarColors = ability.cooldownBarColors or (alt and altColors or colors)
			end
			
			if ability.fireType == "burst" then 
				ability._cooldownTime = (ability.fireTime - ability.burstTime) * ability.burstCount
			else
				ability._cooldownTime = ability.fireTime
			end
		end
	end
end

function update(dt, fireMode, shiftHeld)
	local bars = self.weapon.cooldownBars
	
	--bars
	if player then
		for _,ability in pairs(self.weapon.abilities) do
			if ability.cooldownBar ~= false and (ability.cooldownBar == true or ability._cooldownTime >= self.weapon.barTimeMin) then
				local timer = (ability.cooldownTimer or 0) / ability._cooldownTime
				if self.weapon.currentAbility == ability and (self.weapon.currentState == ability.auto or self.weapon.currentState == ability.burst) then
					timer = 1
				end
				timer = 1 - math.min(math.max(timer or 0, 0), 1)
				
				local color = ability.cooldownBarColors[timer == 1 and 2 or 1]
				
				bars[#bars+1] = {timer, color}
			end
		end
	end
	
  self.weapon:update(dt, fireMode, shiftHeld)
	
	if #bars > 0 then world.sendEntityMessage(id, "kf_bars", bars) end
	self.weapon.cooldownBars = {}
end

function uninit()
	--store cooldown timer
	for _,ability in pairs(self.weapon.abilities) do
		if ability.cooldownTimer and ability.storeCooldown ~= false then
			if self.weapon.currentAbility then
				ability.cooldownTimer = ability._cooldownTime
			end
			storage["cooldown_"..ability.abilitySlot] = ability.cooldownTimer
		end
	end
	storage.lastClock = os.clock()
	
  self.weapon:uninit()
end

--[[    cooldown bar funny json stuff
         all parameters are optional

	"ability" : {
		// if excluded the bar will display if fireTime >= 0.75
		"cooldownBar" : false,
		
		// bar color and filled bar color
		"cooldownBarColors" : ["#FFFFFF", "#FFFFFF"],
		
		// if false cooldownTimer will not be stored
		"storeCooldown" : true,
		
		//if false the stored cooldownTimer will not recharge while weapon isnt being used
		"unheldRecharge" : true
	}
]]