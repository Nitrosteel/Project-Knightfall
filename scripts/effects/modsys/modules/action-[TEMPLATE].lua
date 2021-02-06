
--- Template for Actions


--[[
  INPUT:  type/field  type/*
  CFG:    name  type
--]]

if not Modsys then error("This script isn't supposed to be require'd yourself lol.") end
---@type Modsys, Action
local Modsys, Action = Modsys, Action

---@class ActionTemplate : Action
local ActionTemplate = Action.new()

function ActionTemplate:init()
  -- normal init
end

function ActionTemplate:update(dt)
  -- persistence etc
end

function ActionTemplate:uninit()
  -- normal uninit
end

function ActionTemplate:run(data)

end
