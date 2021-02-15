
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/ranged/gunfire.lua"

--[[--
  * knightfall_gunfire_multimuzzle.lua
  * Ability script (class: MultiMuzzle)
  *
  * Allows to define multiple muzzles per gun, each muzzle with its own projectile and configuration.
  * If the "muzzles" parameter doesn't exist, script just works as gunfire.lua.
  *
  * Note: for each muzzle in muzzles, add a corresponding muzzleFlash anim part prefixed with the muzzle name.
  * (You need to specify it even if there would be no visible muzzleFlash for it.)
  * For example: given:
  *   "muzzles": { "mainMuzzle": {...}, "muzzle3": {...} }
  * You would need the following parts ( "<muzzleName>Flash" ):
  *   "parts": { ..., "mainMuzzleFlash": {/* muzzleFlash parameters here */}, "muzzle3Flash": {...} }
  * Lastly, each part also have a part image. (Use "" to specify no image)
  *
  *
  * Created by Lyrthras#7199 on 02/05/21
  * v1.1 [02/15/21] - fixed m.projectileParameters being m.projectileParams
  *                   redone so the script works as normal gunfire.lua if not supplied muzzles
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  - muzzles   - Muzzles:  [def {}] table of custom muzzles with the following structure:
      "muzzleName" : {
        - offset  - Vec2F: [def (0,0)]  Offset of this muzzle from the default muzzle (from weapon's muzzleOffset)
        - baseDamage,
          baseDps,
          inaccuracy,
          projectileType,
          projectileCount,
          projectileParameters  - overrides the ability config's parameters for this specific muzzle.
                                  projectileParameters are instead merged to the base one.
                                  All are optional, would inherit from base config if it doesn't exist here.
      }
--]]--


MultiMuzzle = GunFire:new()

function MultiMuzzle:init()
  GunFire.init(self)
  self.projectileParameters = self.projectileParameters or {}   -- might be missing?
  self.projectileCount = self.projectileCount or 1    -- might be missing?

  self.default = {
    baseDamage = self.baseDamage,
    baseDps = self.baseDps,
    projectileCount = self.projectileCount,
  }
end


function MultiMuzzle:muzzleFlash()
  if self.muzzles and next(self.muzzles) then  -- Multi-muzzle behavior --
    for name in pairs(self.muzzles) do
      animator.setPartTag(name .. "Flash", "variant", math.random(1, self.muzzleFlashVariants or 3))
    end
    animator.setAnimationState("firing", "altFire")
    animator.playSound(animator.hasSound("multiMuzzleFire") and "multiMuzzleFire" or "fire")
  else                        -- Normal gunfire behavior --
    animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
    animator.setAnimationState("firing", "fire")
    animator.playSound("fire")
  end

  animator.burstParticleEmitter("muzzleFlash")
  animator.setLightActive("muzzleFlash", true)
end


function MultiMuzzle:fireProjectile()
  if self.muzzles and next(self.muzzles) then  -- Multi-muzzle behavior --
    for _, m in pairs(self.muzzles) do
      -- intercept damagePerShot call
      self.baseDamage = m.baseDamage or self.default.baseDamage
      self.baseDps = m.baseDps or self.default.baseDps
      self.projectileCount = m.projectileCount or self.default.projectileCount

      GunFire.fireProjectile(self,
          m.projectileType,
          m.projectileParameters,
          m.inaccuracy,
          self:firePosition(vec2.add(self.weapon.muzzleOffset, m.offset or 0)),
          m.projectileCount
      )

      -- revert interception
      self.baseDamage = self.default.baseDamage
      self.baseDps = self.default.baseDps
      self.projectileCount = self.default.projectileCount
    end
  else                        -- Normal gunfire behavior --
    GunFire.fireProjectile(self)
  end
end


function MultiMuzzle:firePosition(offset)
  return vec2.add(mcontroller.position(), activeItem.handPosition(offset or self.weapon.muzzleOffset))
end
