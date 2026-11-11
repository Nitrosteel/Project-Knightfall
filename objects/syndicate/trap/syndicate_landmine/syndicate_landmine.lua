require "/scripts/vec2.lua"

function init()
  object.setInteractive(true)
  object.setAllOutputNodes(false)
  animator.setAnimationState("switchState", "off")

  self.triggered = false
  self.triggerTimer = 0
  self.triggerDelay = config.getParameter("triggerDelay", 0)
  self.explosionProjectile = config.getParameter("explosionProjectile", "explosivebarrel")
  self.explosionDamage = config.getParameter("explosionDamage", 50)

  local detectArea = config.getParameter("detectArea")
  local pos = entity.position()
  self.detectArea = {
    vec2.add(pos, detectArea[1]),
    vec2.add(pos, detectArea[2])
  }
end

function explode()
  world.spawnProjectile(
    self.explosionProjectile,
    object.toAbsolutePosition({0.0, 0.2}),
    entity.id(),
    {0, 0},
    false,
    {power = self.explosionDamage}
  )
end

function trigger()
  if self.triggered then return end
  self.triggered = true
  self.triggerTimer = self.triggerDelay

  object.setAllOutputNodes(true)
  animator.setAnimationState("switchState", "on")
  animator.playSound("on")
end

function onInteraction(args)
  trigger()
end

function die(smash)
  if smash then
    explode()
  end
end

function update(dt)
  if self.triggered then
    self.triggerTimer = math.max(0, self.triggerTimer - dt)
    if self.triggerTimer == 0 then
      object.smash(true)
    end
    return
  end

  local entityIds = world.entityQuery(self.detectArea[1], self.detectArea[2], {
    includedTypes = {"creature"},
    boundMode = "CollisionArea"
  })
  if #entityIds > 0 then
    trigger()
  end
end