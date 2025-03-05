require "/items/active/shields/shield.lua"

local nilFunction = function() end

local oldInit = init or nilFunction
local oldUpdate = update or nilFunction
local oldUninit = uninit or nilFunction
local oldRaiseShield = raiseShield or nilFunction
local oldLowerShield = lowerShield or nilFunction

function init()
	oldInit()
	
	randomShieldOffset = config.getParameter("randomShieldOffset")
	loopPitchRange = config.getParameter("loopPitchRange")
end

function update(...)
	oldUpdate(...)
	
	animator.setLightActive("shield", self.active)
	
	local s = status.resourcePercentage("shieldStamina")
	
	if randomShieldOffset then
		animator.resetTransformationGroup("random")
		local n = type(randomShieldOffset) == "table" and util.lerp(s, randomShieldOffset) or randomShieldOffset
		local offset = { util.randomInRange{-n, n}, util.randomInRange{-n, n} }
		animator.translateTransformationGroup("random", offset)
	end
	
	if loopPitchRange then
		animator.setSoundPitch("loop", util.lerp(s, loopPitchRange))
	end
end

function raiseShield()
	oldRaiseShield()
	
	animator.playSound("loop", -1)
end

function lowerShield()
	oldLowerShield()
	
	self.aimAngle = 0
	animator.stopAllSounds("loop")
	animator.resetTransformationGroup("random")
end

function uninit()
	oldUninit()
	
	animator.stopAllSounds("loop")
	animator.resetTransformationGroup("random")
end