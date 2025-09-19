syndicate_krokodyl_missilesConcurrent = {}

function syndicate_krokodyl_missilesConcurrent.init()
  local skillData = root.assetJson("/monsters/boss/syndicate_krokodyl/concurrentskills/syndicate_krokodyl_missilesConcurrent.config:syndicate_krokodyl_missilesConcurrent")
  syndicate_krokodyl_missilesConcurrent.reset(skillData)
  return skillData
end

function syndicate_krokodyl_missilesConcurrent.enterSkill()
end

function syndicate_krokodyl_missilesConcurrent.update(dt, skillData)
  if not hasTarget() or isSkillInUse(skillData.pauseDuringSkills) then
    syndicate_krokodyl_missilesConcurrent.reset(skillData)
    return true
  end

  skillData.fireTimer = math.max(skillData.fireTimer - dt, 0)
  local mag = world.magnitude(self.targetPosition, mcontroller.position())
  if mag > skillData.pauseDistance and skillData.fireTimer == 0 and not skillData.isFiring then
    animator.setAnimationState("missiles", "launch1")
    skillData.isFiring = true
    skillData.burstTimer = 0
  end
  if skillData.isFiring then
    skillData.burstTimer = math.max(skillData.burstTimer - dt, 0)
    if skillData.burstTimer == 0 then
      skillData.currentProjectileIndex = skillData.currentProjectileIndex + 1
      animator.burstParticleEmitter("missileMuzzleFlash")
      playSound("missileFire")

      --front
      fireProjectile(
        skillData,
        syndicate_krokodyl_missilesConcurrent.firePosition(skillData),
        syndicate_krokodyl_missilesConcurrent.aimVector(skillData)
      )
      --back
      fireProjectile(
        skillData,
        syndicate_krokodyl_missilesConcurrent.firePosition(skillData, true),
        syndicate_krokodyl_missilesConcurrent.aimVector(skillData)
      )

      skillData.burstTimer = (skillData.currentProjectileIndex % skillData.burstInterval == 0) and skillData.burstIntervalTime or skillData.burstTime

      if skillData.currentProjectileIndex == skillData.burstCount then
        skillData.currentProjectileIndex = 0
        skillData.isFiring = false
        skillData.fireTimer = skillData.fireTime + (skillData.burstCount * skillData.burstTime * skillData.burstInterval * skillData.burstIntervalTime)
      end
    end
  end
end

function syndicate_krokodyl_missilesConcurrent.firePosition(skillData, useBack)
  local offset = skillData.firePositions[skillData.currentProjectileIndex]
  offset[1] = offset[1] * mcontroller.facingDirection() 
  return vec2.add(mcontroller.position(), vec2.add(animator.partPoint(useBack and "missiles-back" or "missiles-front", "muzzlePoint") or {0, 0}, offset))
end

function syndicate_krokodyl_missilesConcurrent.aimVector(skillData)
  local aimVector = vec2.rotate(skillData.aimVector, sb.nrand(skillData.inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function syndicate_krokodyl_missilesConcurrent.reset(skillData)
  animator.setAnimationState("missiles", "idle")
  skillData.fireTimer = 0
  skillData.burstTimer = 0
  skillData.currentProjectileIndex = 0
  skillData.isFiring = false
end

function syndicate_krokodyl_missilesConcurrent.uninit(skillData)
end