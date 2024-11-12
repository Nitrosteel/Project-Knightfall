require "/items/active/weapons/melee/meleeslash.lua"

-- Modified spear stab attack that adds energy cost and a spin motion.

KFSpearStab = MeleeSlash:new()

function KFSpearStab:init()
  MeleeSlash.init(self)

  self.energyUsage = self.energyUsage or 0

  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
end

function KFSpearStab:fire()
  MeleeSlash.fire(self)

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.fireMode == "primary" and self.allowHold ~= false then
    self:setState(self.hold)
  else
	if self.stances.comboSpin then
		self:setState(self.comboSpin)
	end
  end
end

function KFSpearStab:hold()
  self.weapon:setStance(self.stances.hold)
  self.weapon:updateAim()

  while self.fireMode == "primary" do
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    coroutine.yield()
  end

  self:setState(self.comboSpin)
end

function KFSpearStab:comboSpin()
  self.weapon:setStance(self.stances.comboSpin)
  animator.setGlobalTag("stanceDirectives", self.stances.comboSpin.stanceDirectives or "")
  self.weapon:updateAim()
  
  local progress = 0
  util.wait(self.stances.comboSpin.duration, function()

	self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.comboSpin.weaponRotation, self.stances.comboSpin.endWeaponRotation))
	self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.comboSpin.armRotation, self.stances.comboSpin.endArmRotation))

	progress = math.min(1.0, progress + (self.dt / self.stances.comboSpin.duration))
  end)
  
  animator.setGlobalTag("comboDirectives", "")
  self.cooldownTimer = self:cooldownTime()
  self.weapon:setStance(self.stances.idle)
end
