require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Melee combo edit to include motion restrictions and swoosh rotations.
-- Made for non-energy melee weapons.
-- 'Ph' stands for 'Physical'.

KFMeleeComboPh = WeaponAbility:new()

function KFMeleeComboPh:init()
  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0

  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns[1]

  self.animKeyPrefix = self.animKeyPrefix or ""

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function KFMeleeComboPh:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      self:readyFlash()
    end
  end

  if self.flashTimer > 0 then
    self.flashTimer = math.max(0, self.flashTimer - self.dt)
    if self.flashTimer == 0 then
      animator.setGlobalTag("bladeDirectives", "")
    end
  end

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode

  if not self.weapon.currentAbility and self:shouldActivate() then
    self:setState(self.windup)
  end
end

-- State: windup
function KFMeleeComboPh:windup()
  local stance = self.stances["windup"..self.comboStep]

  self.weapon:setStance(stance)

  animator.resetTransformationGroup("rotatedSwoosh")
  animator.rotateTransformationGroup("rotatedSwoosh", 0)

  self.edgeTriggerTimer = 0

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
	util.wait(stance.duration, function()
		mcontroller.controlModifiers(
			{
				movementSuppressed = stance.allowMovement == false,
				walkingSuppressed = stance.allowWalking == false,
				runningSuppressed = stance.allowRunning == false,
				jumpingSuppressed = stance.allowJumping == false
			}
		)
	end)
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances["preslash"..self.comboStep] then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: wait
-- waiting for next combo input
function KFMeleeComboPh:wait()
  local stance = self.stances["wait"..(self.comboStep - 1)]

  self.weapon:setStance(stance)

  animator.resetTransformationGroup("rotatedSwoosh")
  animator.rotateTransformationGroup("rotatedSwoosh", 0)

  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup)
      return
    end

	mcontroller.controlModifiers(
		{
            movementSuppressed = stance.allowMovement == false,
            walkingSuppressed = stance.allowWalking == false,
            runningSuppressed = stance.allowRunning == false,
            jumpingSuppressed = stance.allowJumping == false
		}
	)
  end)

  self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
  self.comboStep = 1
end

-- State: preslash
-- brief frame in between windup and fire
function KFMeleeComboPh:preslash()
  local stance = self.stances["preslash"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration, function()
	mcontroller.controlModifiers(
		{
            movementSuppressed = stance.allowMovement == false,
            walkingSuppressed = stance.allowWalking == false,
            runningSuppressed = stance.allowRunning == false,
            jumpingSuppressed = stance.allowJumping == false
		}
	)
  end)

  self:setState(self.fire)
end

-- State: fire
function KFMeleeComboPh:fire()
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  animator.rotateTransformationGroup("rotatedSwoosh", stance.swooshRotation or 0)

  util.wait(stance.duration, function()
	mcontroller.controlModifiers(
		{
            movementSuppressed = stance.allowMovement == false,
            walkingSuppressed = stance.allowWalking == false,
            runningSuppressed = stance.allowRunning == false,
            jumpingSuppressed = stance.allowJumping == false
		}
	)

    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
  end)

  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  else
	if self.stances.comboSpin then
		self:setState(self.comboSpin)
	end
  end
end

function KFMeleeComboPh:comboSpin()
  self.weapon:setStance(self.stances.comboSpin)
  animator.setGlobalTag("stanceDirectives", self.stances.comboSpin.stanceDirectives or "")
  self.weapon:updateAim()

  animator.playSound("comboSpin")
  
  local progress = 0
  util.wait(self.stances.comboSpin.duration, function()

	self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.comboSpin.weaponRotation, self.stances.comboSpin.endWeaponRotation))
	self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.comboSpin.armRotation, self.stances.comboSpin.endArmRotation))

	progress = math.min(1.0, progress + (self.dt / self.stances.comboSpin.duration))
  end)
  
  animator.setGlobalTag("comboDirectives", "")
  self.cooldownTimer = self.cooldowns[self.comboStep]
  self.comboStep = 1
  self.weapon:setStance(self.stances.idle)
end

function KFMeleeComboPh:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    if self.comboStep > 1 then
      return self.edgeTriggerTimer > 0
    else
      return self.fireMode == (self.activatingFireMode or self.abilitySlot)
    end
  end
end

function KFMeleeComboPh:readyFlash()
  animator.setGlobalTag("bladeDirectives", self.flashDirectives)
  self.flashTimer = self.flashTime
end

function KFMeleeComboPh:computeDamageAndCooldowns()
  local attackTimes = {}
  for i = 1, self.comboSteps do
    local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
    if self.stances["preslash"..i] then
      attackTime = attackTime + self.stances["preslash"..i].duration
    end
    table.insert(attackTimes, attackTime)
  end

  self.cooldowns = {}
  local totalAttackTime = 0
  local totalDamageFactor = 0
  for i, attackTime in ipairs(attackTimes) do
    self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
    self.stepDamageConfig[i].timeoutGroup = "primary"..i

    local damageFactor = self.stepDamageConfig[i].baseDamageFactor
    self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

    totalAttackTime = totalAttackTime + attackTime
    totalDamageFactor = totalDamageFactor + damageFactor

    local targetTime = totalDamageFactor * self.fireTime
    local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
    table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
  end
end

function KFMeleeComboPh:uninit()
  self.weapon:setDamage()
end
