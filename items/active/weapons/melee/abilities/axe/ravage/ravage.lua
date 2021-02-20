require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

BladeCharge = WeaponAbility:new()

function BladeCharge:init()
  self.cooldownTimer = self.cooldownTime
  BladeCharge:reset()
end

function BladeCharge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.cooldownTimer == 0 and not self.weapon.currentAbility and not status.resourceLocked("energy") and self.fireMode == "alt" then
    self:setState(self.windup)
  end
end

function BladeCharge:windup()
  self.weapon:setStance(self.stances.windup)

  animator.setAnimationState("bladeCharge", "charge")
  animator.setParticleEmitterActive("bladeCharge", true)

  local chargeTimer = self.chargeTime
  while self.fireMode == "alt" do

    if not animator.animationState("blade"):find("empowered-") then
      animator.setAnimationState("blade", "empowered-extend")  -- dirtyfix.jayson.mp4
    end

    chargeTimer = math.max(0, chargeTimer - self.dt)
	if chargeTimer == 0 then
		animator.setGlobalTag("bladeDirectives", "border=1;"..self.chargeBorder..";00000000")
		self:setState(self.slash)
	end

    -- stop it from rotating around endlessly
    if self.stances.windup.maxArmRotation then
      self.weapon.relativeArmRotation = math.min(self.weapon.relativeArmRotation, math.rad(self.stances.windup.maxArmRotation))
    end
    coroutine.yield()
  end
  
  if chargeTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.slash)
  end
end

function BladeCharge:slash()
  local slash = coroutine.create(self.slashAction)
  coroutine.resume(slash, self)

  local movement = function()
    mcontroller.controlModifiers({runningSuppressed = true})

    if self.hover then
      mcontroller.controlApproachYVelocity(self.hoverYSpeed, self.hoverForce)
    end
  end

  while util.parallel(slash, movement) do
    coroutine.yield()
  end
end

function BladeCharge:slashAction()
  local armRotationOffset = math.random(1, #self.armRotationOffsets)
  if not status.overConsumeResource("energy", self.energyUsage * (self.stances.windup.duration + self.stances.slash.duration)) then return end

  self.weapon:setStance(self.stances.windup)
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation - util.toRadians(self.armRotationOffsets[armRotationOffset])
  self.weapon:updateAim()

  util.wait(self.stances.windup.duration, function()
    return status.resourceLocked("energy")
  end)

  self.weapon.aimDirection = -self.weapon.aimDirection
  mcontroller.controlFace(self.weapon.aimDirection)

  self.weapon:setStance(self.stances.slash)
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(self.armRotationOffsets[armRotationOffset])
  self.weapon:updateAim()

  armRotationOffset = armRotationOffset + 1
  if armRotationOffset > #self.armRotationOffsets then armRotationOffset = 1 end

  animator.setAnimationState("bladeCharge", "idle")
  animator.setParticleEmitterActive("bladeCharge", false)
  animator.setAnimationState("swoosh", "slash")
  animator.playSound("swing")

  util.wait(self.stances.slash.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  self.cooldownTimer = self.cooldownTime
end

function BladeCharge:reset()
  animator.setGlobalTag("bladeDirectives", "")
  animator.setParticleEmitterActive("bladeCharge", false)
  animator.setAnimationState("bladeCharge", "idle")
end

function BladeCharge:uninit()
  self:reset()
end