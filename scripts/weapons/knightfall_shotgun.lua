-- Original script by Patman.
-- Modified by Nitrosteel, using Claude Sonnet 4.6.
--
-- Adds randomised projectile speed variation for shotguns.
-- Patches whichever gunfire class is available: KFGunFire, GunFire, or both.

local function shotgunFireProjectile(self, projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  if not self._altSpeedFixed then
    if self.projectileParameters.speed and self.abilitySlot == "alt" then
      local a = config.getParameter("altAbility")
      if not a or not a.projectileParameters or not a.projectileParameters.speed then
        self.projectileParameters.speed = nil
      end
    end
    self._altSpeedFixed = true
  end

  local speed = (projectileParams and projectileParams.speed) or self.projectileParameters.speed

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    params.speed = util.randomInRange(speed)

    projectileId = world.spawnProjectile(
      projectileType,
      firePosition or self:firePosition(),
      activeItem.ownerEntityId(),
      self:aimVector(inaccuracy or self.inaccuracy),
      false,
      params
    )
  end
  return projectileId
end

-- Patch whichever class(es) are loaded. This script is class-agnostic.
if KFGunFire then
  KFGunFire.fireProjectile = shotgunFireProjectile
end
if GunFire then
  GunFire.fireProjectile = shotgunFireProjectile
end