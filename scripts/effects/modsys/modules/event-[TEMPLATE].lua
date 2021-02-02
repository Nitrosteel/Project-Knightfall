
--- Template for Events


--[[
  EVENT:  type
  CFG:    name  type
--]]

if not Modsys then error("This script isn't supposed to be require'd yourself lol.") end
---@type Modsys, Event
local Modsys, Event = Modsys, Event

---@class EventTemplate : Event
local EventTemplate = Event.new()

function EventTemplate:init()
  -- normal init
end

function EventTemplate:update(dt)
  -- self:emit()
end

function EventTemplate:uninit()
  -- normal uninit
end
