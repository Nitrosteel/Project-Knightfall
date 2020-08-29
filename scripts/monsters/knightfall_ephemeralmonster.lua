require "/monsters/monster.lua"


--[[-- 
  * ephemeralmonster.lua
  *
  * Monster script (replaces monster.lua) that times a monster, and makes it die when time runs out.
  *
  * Created by Lyrthras#7199 on 06/28/20
--]]--

--[[--
  === Additional JSON fields ===
  - timeToLive          - float: [def -1] time from spawning until the moment the monster should die. -1 disables this behavior
  - dropItemsOnTimeout  - boolean: [def true] if the monster should drop items when time to live runs out. (Any other value than false evaluates to true)
--]]--


local _init = init
local _update = update

function init()
  _init()

  self.lifeTimer = config.getParameter("timeToLive", -1)
end

function update(dt)
  _update(dt)

  if self.lifeTimer > 0 then    -- don't try to update if not set/depleted
    self.lifeTimer = math.max(self.lifeTimer - dt, 0) 
  end

  if self.lifeTimer == 0 then
    if not config.getParameter("dropItemsOnTimeout", true) then 
      monster.setDropPool(nil) 
    end
    status.setResource("health",0)
  end
end