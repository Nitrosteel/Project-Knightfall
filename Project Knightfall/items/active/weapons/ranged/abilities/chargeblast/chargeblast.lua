require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
--this is princess's lua, not mine, i just editted it a tad :P - Nebulox
ChargeBlast = WeaponAbility:new()

function ChargeBlast:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.chargeLevels[1].cooldown
  self.chargeTimer = 0
  
  self.chargeLevel = {}
  self.chargeLevelPrev = {}
  
  self.impactSoundTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("chains", {})
    animator.setParticleEmitterActive("beamCollision", false)
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
  end
end

function ChargeBlast:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.impactSoundTimer = math.max(self.impactSoundTimer - self.dt, 0)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    self:setState(self.charge)
  end
end

function ChargeBlast:charge()
  self.weapon:setStance(self.stances.charge)
  
  animator.playSound("charge")
  
  self.chargeTimer = 0
  self.chargeLevelPrev = self:currentChargeLevel()
  
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    self.chargeTimer = self.chargeTimer + self.dt

    if self.chargeLevelPrev ~= self:currentChargeLevel() then
      self.chargeLevelPrev = self:currentChargeLevel()
      chargeLevelses = self.chargeLevels
      animator.playSound(self.chargeLevelPrev.chargedSound or "charged")
      if self.chargeLevelPrev == chargeLevelses[#chargeLevelses] then
        animator.stopAllSounds("charge")
      end
    end
    
    coroutine.yield()
  end
  animator.stopAllSounds("charge")
  
  self.chargeLevel = self:currentChargeLevel()
  local energyCost = self:levelStat(self.chargeLevels[1].energyCost,self.chargeLevels[#self.chargeLevels].energyCost) or 0
  if self.chargeLevel and (energyCost == 0 or status.overConsumeResource("energy", energyCost)) then
    self:setState(self.fire)
  end
end

function ChargeBlast:fire()
  self.weapon:setStance(self.stances.fire)
  
  if self.stances.fire.charge then
    animator.playSound("firecharge")
    util.wait(self.stances.fire.charge)
  end
  
  animator.stopAllSounds("firecharge")
  animator.playSound(self.chargeLevel.fireSound or "fire")

  local wasColliding = false
  self.damageConfig.baseDamage = self:levelStat(self.chargeLevels[1].baseDamage,self.chargeLevels[#self.chargeLevels].baseDamage)
  local beamLength = self:levelStat(self.chargeLevels[1].beamLength, self.chargeLevels[#self.chargeLevels].beamLength)
  
  util.wait(self.stances.fire.duration, function()
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), beamLength))
    local collidePoint = world.lineCollision(beamStart, beamEnd)
    if collidePoint then
      beamEnd = collidePoint
  
      beamLength = world.magnitude(beamStart, beamEnd)
  
      animator.setParticleEmitterActive("beamCollision", true)
      animator.resetTransformationGroup("beamEnd")
      animator.translateTransformationGroup("beamEnd", {beamLength, 0})
  
      if self.impactSoundTimer == 0 then
        animator.setSoundPosition("beamImpact", {beamLength, 0})
        animator.playSound("beamImpact")
        self.impactSoundTimer = self.chargeLevel.cooldown
      end
    else
      animator.setParticleEmitterActive("beamCollision", false)
    end
  
    self.weapon:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}}, self.chargeLevel.cooldown)
  
    self:drawBeam(beamEnd, collidePoint)
  end)
  
  self:reset()

  util.wait(self.stances.fire.cooldown, function()
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), beamLength))
    local collidePoint = world.lineCollision(beamStart, beamEnd)
    if collidePoint then beamEnd = collidePoint end
    
    self:drawWeakBeam(beamEnd, collidePoint)
  end)
  
  self:reset()
  
  self.cooldownTimer = self.chargeLevel.cooldown or 0

  self:setState(self.cooldown, self.cooldownTimer)
end

function ChargeBlast:drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function ChargeBlast:drawWeakBeam(endPos, didCollide)
  local newChain = copy(self.chainWeak)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function ChargeBlast:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function ChargeBlast:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function ChargeBlast:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function ChargeBlast:currentChargeLevel()
  local bestChargeTime = 0
  local bestChargeLevel
  for _, chargeLevel in pairs(self.chargeLevels) do
    if self.chargeTimer >= chargeLevel.time and self.chargeTimer >= bestChargeTime then
      bestChargeTime = chargeLevel.time
      bestChargeLevel = chargeLevel
    end
  end
  return bestChargeLevel
end

function ChargeBlast:levelStat(minstat, maxstat)
  local chargeTime = math.min(self.chargeTimer, self.chargeLevels[#self.chargeLevels].time)
  if minstat < maxstat then return ((maxstat - minstat) * (chargeTime / self.chargeLevels[#self.chargeLevels].time) + minstat)
  elseif minstat > maxstat then return ((minstat - maxstat) * (1 - (chargeTime / self.chargeLevels[#self.chargeLevels].time)) + maxstat)
  else return minstat end -- you nigga what  
end

function ChargeBlast:uninit()
  self:reset()
end

function ChargeBlast:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
  animator.setParticleEmitterActive("beamCollision", false)
end
