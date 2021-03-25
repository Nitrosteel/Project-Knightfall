require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

NebCometStrike = WeaponAbility:new()

function NebCometStrike:init()
  self.cooldownTimer = self.cooldownTime
  self.windupTimer = 0
end

function NebCometStrike:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.weapon.currentAbility == nil
      and self.fireMode == "alt"
      and self.cooldownTimer == 0
      and not status.statPositive("activeMovementAbilities")
      and not status.resourceLocked("energy") then

    self:setState(self.windup)
  end
end

function NebCometStrike:windup()
  self.weapon:setStance(self.stances.windup)

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  animator.setParticleEmitterActive("dashCharge", true)
  animator.playSound("dashCharge")

  self.windupTimer = 0
  local windupProgress = 0
  while self.windupTimer < self.windupTime and self.fireMode == "alt" do
    mcontroller.controlModifiers({jumpingSuppressed = true})

    self.windupTimer = self.windupTimer + self.dt

    local from = self.stances.windup.weaponOffset or {0,0}
    local to = self.stances.windup.endWeaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(windupProgress, from[1], to[1]), interp.linear(windupProgress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(windupProgress, self.stances.windup.weaponRotation, self.stances.windup.endWeaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(windupProgress, self.stances.windup.armRotation, self.stances.windup.endArmRotation))

    windupProgress = math.min(1.0, self.windupTimer/self.windupTime)

    coroutine.yield()
  end

  self:setState(self.dash, windupProgress)
end

function NebCometStrike:dash(windupProgress)
  self.weapon:setStance(self.stances.dash)
  status.overConsumeResource("energy", self.energyUsage)

  local dashDuration = windupProgress * (self.dashTime[2] - self.dashTime[1]) + self.dashTime[1]

  animator.playSound("dashFire")

  local wasInvulnerable = status.stat("invulnerable") > 0
  status.addEphemeralEffect("invulnerable", dashDuration)

  local position = mcontroller.position()
  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.power = params.power * config.getParameter("damageLevelMultiplier")
  local finalParams = copy(self.finalProjectileParameters)
  finalParams.powerMultiplier = activeItem.ownerPowerMultiplier()
  finalParams.power = params.power * config.getParameter("damageLevelMultiplier")

  util.wait(dashDuration, function(dt)
    local ownerAim = activeItem.ownerAimPosition()
    local mpos = mcontroller.position()

    local dashAim = vec2.norm(world.distance(ownerAim,mpos))
    mcontroller.setVelocity(vec2.mul(dashAim, self.dashSpeed))
    mcontroller.controlMove(self.weapon.aimDirection)

    local direction = vec2.norm(world.distance(mcontroller.position(), position))
    while world.magnitude(mcontroller.position(), position) >= self.trailInterval do
      position = vec2.add(position, vec2.mul(direction, self.trailInterval))
      world.spawnProjectile(self.projectileType, vec2.add(position, self.projectileOffset), activeItem.ownerEntityId(), world.distance(activeItem.ownerAimPosition(), mcontroller.position()), false, params)
    end

    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)
  if dashDuration == self.dashTime[2] then
    world.spawnProjectile(self.finalProjectileType, vec2.add(position, self.projectileOffset), activeItem.ownerEntityId(), world.distance(activeItem.ownerAimPosition(), mcontroller.position()), false, finalParams)
  end
  animator.setParticleEmitterActive("dashCharge", false)

  mcontroller.setVelocity({0,0})
  self.cooldownTimer = self.cooldownTime
end

function NebCometStrike:uninit()
  status.clearPersistentEffects("weaponMovementAbility")

  animator.setParticleEmitterActive("dashCharge", false)

  if self.weapon.currentState == self.dash then
    mcontroller.setVelocity({0,0})
  end
end