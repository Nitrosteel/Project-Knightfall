

--[[
  CFG:
  INPUT:  data.*
--]]

if not Modsys then error("This script isn't supposed to be require'd yourself lol.") end
---@type Modsys, Action
local Modsys, Action = Modsys, Action

---@class Debug : Action
local DebugAction = Action.new()

function DebugAction:init()
  -- normal init
end

function DebugAction:update(dt)
  -- persistence etc
end

function DebugAction:uninit()
  -- normal uninit
end

function DebugAction:run(data)
  Modsys.log("Debug action ran! Name: %s, Data: %s", self._name, sb.print(data))
end
