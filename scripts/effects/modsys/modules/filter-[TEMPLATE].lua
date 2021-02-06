
--- Template for Filters


--[[
  INPUT:  type/field  type/*
  CFG:    name  type
--]]

if not Modsys then error("This script isn't supposed to be require'd yourself lol.") end
---@type Modsys, Filter
local Modsys, Filter = Modsys, Filter

---@class FilterTemplate : Filter
local FilterTemplate = Filter.new()

function FilterTemplate:init()
  -- normal init
end

function FilterTemplate:update(dt)
  -- cooldowns etc
end

function FilterTemplate:uninit()
  -- normal uninit
end

function FilterTemplate:process(data)
  return data   -- returning the data means the filter passed.
end
