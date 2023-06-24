require "/items/active/weapons/ranged/gunfire.lua"

MultiLauncher = GunFire:new()

function MultiLauncher:init()
  GunFire.init(self)
end

function MultiLauncher:update(dt, fireMode, shiftHeld)
  --GunFire.update(self, dt, fireMode, shiftHeld)
  
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
	and not self:loadedBarrel() == false
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
  end
end

function MultiLauncher:loadedBarrel(mode)
  for count = 1, self.maxBarrels do
	if animator.animationState(self.animationPrefix .. count) == self.loadedState then
		if mode then
			return count
		else
			return "" .. self.animationPrefix .. count
		end
	end
  end
  
  return false
end

function MultiLauncher:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  
  -- different muzzle flash depending on which tube fired; only matters on the visual y-axis, since z-axis is not visible to player (starbound is 2d game)
  animator.burstParticleEmitter(self.particleEmitters[self:loadedBarrel(true)])
  
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function MultiLauncher:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()
  
  -- selects animations depending on loaded rocket
  animator.setAnimationState(self:loadedBarrel(), self.fireState)

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function MultiLauncher:burst()
  self.weapon:setStance(self.stances.fire)
  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1
        
        -- selects animations depending on loaded rocket
        animator.setAnimationState(self:loadedBarrel(), self.fireState)
    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    if self:loadedBarrel() == false then shots = 0 end

    util.wait(self.burstTime)
  end
  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function MultiLauncher:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end
  
  -- different projectile position depending on which tube is fired
  local firePos = firePosition or self:firePosition()

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePos,
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.add(self.weapon.muzzleOffset,self.barrelOffsets[self:loadedBarrel(true)])))
end

function MultiLauncher:uninit()
	GunFire.uninit(self)
end