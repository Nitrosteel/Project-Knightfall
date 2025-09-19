syndicate_krokodyl_smokegrenadesConcurrent = {}

function syndicate_krokodyl_smokegrenadesConcurrent.init()
  local skillData = root.assetJson("/monsters/boss/syndicate_krokodyl/concurrentskills/syndicate_krokodyl_smokegrenadesConcurrent.config:syndicate_krokodyl_smokegrenadesConcurrent")
  skillData.fireTimer = 0
  skillData.interval = 1
  skillData.cooldownTimer = 0
  skillData.firing = false
  skillData.baseParams = skillData.projectileParameters
  return skillData
end

function syndicate_krokodyl_smokegrenadesConcurrent.enterSkill()
end

function syndicate_krokodyl_smokegrenadesConcurrent.update(dt, skillData)
  if not hasTarget() or isSkillInUse(skillData.pauseDuringSkills) then return true end

  local mag = world.magnitude(self.targetPosition, mcontroller.position())
  skillData.cooldownTimer = math.max(skillData.cooldownTimer - dt, 0)
  if skillData.cooldownTimer == 0 and mag < skillData.detectRadius then
    animator.setAnimationState("smoke_grenades", "firing1")
    skillData.firing = true
  end

  if skillData.firing then
    skillData.fireTimer = skillData.fireTimer - dt
    if skillData.fireTimer <= 0 then
      local params = sb.jsonMerge(skillData.baseParams, {})
      params.speed = params.speed + (skillData.interval * params.speed)
      skillData.projectileParameters = params
      fireProjectile(
        skillData,
        syndicate_krokodyl_smokegrenadesConcurrent.firePosition(skillData),
        syndicate_krokodyl_smokegrenadesConcurrent.aimVector(skillData)
      )
      skillData.fireTimer = skillData.fireDelay
      skillData.interval = skillData.interval + 1
      if skillData.interval > skillData.volleyCount then
        skillData.firing = false
        skillData.interval = 1
        skillData.cooldownTimer = skillData.cooldownTime
      end
    end  
  end
end

function syndicate_krokodyl_smokegrenadesConcurrent.firePosition(skillData)
  local offset = vec2.mul(skillData.offsetInterval, skillData.interval)
  offset[1] = offset[1] * mcontroller.facingDirection()
  local pos = vec2.add(mcontroller.position(),  vec2.add(animator.partPoint("smoke_grenades", "firePoint"), offset))
  return pos
end

function syndicate_krokodyl_smokegrenadesConcurrent.aimVector(skillData)
  return vec2.rotate({mcontroller.facingDirection() * skillData.interval, 3}, sb.nrand(skillData.inaccuracy, 0))
end

function syndicate_krokodyl_smokegrenadesConcurrent.uninit(skillData)
end