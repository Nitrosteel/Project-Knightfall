require "/scripts/weapons/knightfall_gunfire.lua"
AltProjectileGunfire = GunFire:new()

function AltProjectileGunfire:init()
  GunFire.init(self)
  self.altProjectile._shots = 0
end

function AltProjectileGunfire:shoot()
  local alt = self.altProjectile
  alt._shots = (alt._shots + 1) % alt.interval
  
  if alt._shots == 0 then
    if alt.fireBoth then self:fireProjectile() end
    self:fireProjectile(alt.projectileType, alt.projectileParameters, alt.inaccuracy, nil, alt.projectileCount)
    self:muzzleFlash(alt.animation)
    return alt
  else
    self:fireProjectile()
    GunFire.muzzleFlash(self)
  end
end

function AltProjectileGunfire:auto()
  local alt = self:shoot()
  
  local fireStance = alt and alt.fireStance or self.stances.fire
  self.weapon:setStance(fireStance)
  if fireStance.duration then
    util.wait(fireStance.duration)
  end
  
  self.cooldownTimer = alt and alt.fireTime or self.fireTime
  self:setState(self.cooldown, alt and alt.cooldownStance or nil)
end

function AltProjectileGunfire:burst()
  local altShot
  local stance = self.stances.fire
  self.weapon:setStance(stance)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    local alt = self:shoot()
    if alt then
      altShot = alt
      stance = alt.fireStance or stance
    end
    
    shots = shots - 1
    
    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, stance.armRotation))
    util.wait(self.burstTime)
  end
  
  local t = altShot and altShot.fireTime or self.fireTime
  self.cooldownTimer = (t - self.burstTime) * self.burstCount
  self:setState(self.cooldown, altShot and altShot.cooldownStance)
end

function AltProjectileGunfire:muzzleFlash(anim)
  if not anim then
    return GunFire.muzzleFlash(self)
  end
  
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setLightActive("muzzleFlash", true)
  animator.burstParticleEmitter(anim.burstParticle or "muzzleFlash")
  animator.playSound(anim.sound or "fire")
  
  if not anim.states then
    animator.setAnimationState("firing", "fire")
    return
  end
  for k,v in pairs(anim.states) do
    animator.setAnimationState(k, v)
  end
end

function AltProjectileGunfire:cooldown(stance)
  if stance then
    local old = self.stances.cooldown
    self.stances.cooldown = stance
    GunFire.cooldown(self)
    self.stances.cooldown = old
  else
    GunFire.cooldown(self)
  end
end