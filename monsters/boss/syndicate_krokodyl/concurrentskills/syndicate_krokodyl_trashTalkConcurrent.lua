syndicate_krokodyl_trashTalkConcurrent = {}

function syndicate_krokodyl_trashTalkConcurrent.init()
  local skillData = root.assetJson("/monsters/boss/syndicate_krokodyl/concurrentskills/syndicate_krokodyl_trashTalkConcurrent.config:syndicate_krokodyl_trashTalkConcurrent")
  skillData.cooldownTimer = 0
  return skillData
end

function syndicate_krokodyl_trashTalkConcurrent.enterSkill()
end

function syndicate_krokodyl_trashTalkConcurrent.update(dt, skillData)
  if not hasTarget() or isSkillInUse(skillData.pauseDuringSkills) then return true end

  skillData.cooldownTimer = math.max(skillData.cooldownTimer - dt, 0)
  if skillData.cooldownTimer == 0 then
    monster.say(util.randomChoice(skillData.trashTalk))

    skillData.cooldownTimer = (math.random() * (skillData.talkInterval[2] - skillData.talkInterval[1])) + skillData.talkInterval[1]
  end
end

function syndicate_krokodyl_trashTalkConcurrent.uninit(skillData)
end