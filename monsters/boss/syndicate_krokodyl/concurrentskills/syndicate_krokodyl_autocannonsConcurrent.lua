syndicate_krokodyl_autocannonsConcurrent = {}

function syndicate_krokodyl_autocannonsConcurrent.init()
  local skillData = root.assetJson("/monsters/boss/syndicate_krokodyl/concurrentskills/syndicate_krokodyl_autocannonsConcurrent.config:syndicate_krokodyl_autocannonsConcurrent")
  skillData.fireTimer = 0
  skillData.aimAngle = 0
  skillData.burstTimer = 0
  skillData.currentBurstCount = 0
  return skillData
end

function syndicate_krokodyl_autocannonsConcurrent.enterSkill()
end

function syndicate_krokodyl_autocannonsConcurrent.update(dt, skillData)
  if not hasTarget() or isSkillInUse(skillData.pauseDuringSkills) then return true end

  local angleVec = world.distance(self.targetPosition, mcontroller.position())
  self.targetAutocannonAngle = math.atan(angleVec[2], math.abs(angleVec[1]))
  local inFront = (angleVec[1] * mcontroller.facingDirection()) > 0
  local canFire = inFront

  if skillData.aimAngleMinMax then
    local baseAngle = self.targetAutocannonAngle
    self.targetAutocannonAngle = util.clamp(self.targetAutocannonAngle or 0, math.rad(skillData.aimAngleMinMax[1]), math.rad(skillData.aimAngleMinMax[2]))
    
    if self.targetAutocannonAngle ~= baseAngle then
      canFire = false
    end
  end

  self.currentAutocannonAngle = syndicate_krokodyl_utlities.rotateAngle(self.currentAutocannonAngle or 0, self.targetAutocannonAngle, dt, skillData.rotateSpeed or 1)
  
  animator.resetTransformationGroup("autocannons")
  local rotCentre = animator.partPoint("autocannons", "rotationCentre")
  rotCentre[1] = rotCentre[1] * mcontroller.facingDirection()
  animator.rotateTransformationGroup("autocannons", self.currentAutocannonAngle, rotCentre)

  skillData.fireTimer = math.max(skillData.fireTimer - dt, 0)
  if canFire and skillData.fireTimer == 0 then
    skillData.burstTimer = math.max(skillData.burstTimer - dt, 0)
    if skillData.burstTimer == 0 then
      skillData.currentBurstCount = skillData.currentBurstCount + 1
      animator.setAnimationState("autocannons", "firing")
      animator.burstParticleEmitter("autocannonMuzzleFlash")
      playSound("autocannonFire")

      fireProjectile(
        skillData,
        syndicate_krokodyl_autocannonsConcurrent.firePosition(),
        syndicate_krokodyl_autocannonsConcurrent.aimVector(skillData)
      )

      skillData.burstTimer = skillData.burstTime

      if skillData.currentBurstCount == skillData.burstCount then
        skillData.currentBurstCount = 0
        skillData.fireTimer = skillData.fireTime + (skillData.burstCount * skillData.burstTime)
      end
    end
  end
end

function syndicate_krokodyl_autocannonsConcurrent.firePosition()
  return vec2.add(mcontroller.position(), animator.partPoint("autocannons", "muzzlePoint"))
end

function syndicate_krokodyl_autocannonsConcurrent.aimVector(skillData)
  local aimVector = vec2.rotate({1, 0}, self.currentAutocannonAngle + sb.nrand(skillData.inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function syndicate_krokodyl_autocannonsConcurrent.uninit(skillData)
end