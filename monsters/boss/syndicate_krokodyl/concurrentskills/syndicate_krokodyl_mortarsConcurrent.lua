syndicate_krokodyl_mortarsConcurrent = {}

function syndicate_krokodyl_mortarsConcurrent.init()
  local skillData = root.assetJson("/monsters/boss/syndicate_krokodyl/concurrentskills/syndicate_krokodyl_mortarsConcurrent.config:syndicate_krokodyl_mortarsConcurrent")
  syndicate_krokodyl_mortarsConcurrent.reset(skillData)

  skillData.projectileGravityMultiplier = root.projectileGravityMultiplier(skillData.projectileType)
  return skillData
end

function syndicate_krokodyl_mortarsConcurrent.enterSkill()
end

function syndicate_krokodyl_mortarsConcurrent.update(dt, skillData)
  if not hasTarget() or isSkillInUse(skillData.pauseDuringSkills) then
    syndicate_krokodyl_mortarsConcurrent.reset(skillData)
    return true
  end

  skillData.fireTimer = math.max(skillData.fireTimer - dt, 0)
  local mag = world.magnitude(self.targetPosition, mcontroller.position())
  if mag > skillData.pauseDistance and skillData.fireTimer == 0 and not skillData.isFiring then
    animator.setAnimationState("mortars", "firing1")
    skillData.isFiring = true
    skillData.burstTimer = 0
  end
  if skillData.isFiring then
    skillData.burstTimer = math.max(skillData.burstTimer - dt, 0)
    if skillData.burstTimer == 0 then
      skillData.currentBurstCount = skillData.currentBurstCount + 1
      animator.burstParticleEmitter("mortarMuzzleFlash")
      playSound("mortarFire")

      fireProjectile(
        skillData,
        syndicate_krokodyl_mortarsConcurrent.firePosition(skillData),
        syndicate_krokodyl_mortarsConcurrent.aimVector(skillData)
      )

      skillData.burstTimer = skillData.burstTime

      if skillData.currentBurstCount == skillData.burstCount then
        skillData.currentBurstCount = 0
        skillData.isFiring = false
        skillData.fireTimer = skillData.fireTime + (skillData.burstCount * skillData.burstTime)
      end
    end
  end
end

function syndicate_krokodyl_mortarsConcurrent.firePosition(skillData)
  local offset = vec2.mul(skillData.offsetInterval, skillData.currentBurstCount)
  offset[1] = offset[1] * mcontroller.facingDirection() 
  return vec2.add(mcontroller.position(), vec2.add(animator.partPoint("mortars", "muzzlePoint"), offset))
end

function syndicate_krokodyl_mortarsConcurrent.aimVector(skillData)
  local targetOffset = world.distance(self.targetPosition, syndicate_krokodyl_mortarsConcurrent.firePosition(skillData))
  local aimVec = util.aimVector(targetOffset, skillData.projectileParameters.speed, skillData.projectileGravityMultiplier, true)
  local aimVector = vec2.rotate(aimVec, sb.nrand(skillData.inaccuracy, 0))
  --aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function syndicate_krokodyl_mortarsConcurrent.reset(skillData)
  animator.setAnimationState("mortars", "idle")
  skillData.fireTimer = 0
  skillData.burstTimer = 0
  skillData.currentBurstCount = 0
  skillData.isFiring = false
end

function syndicate_krokodyl_mortarsConcurrent.uninit(skillData)
end