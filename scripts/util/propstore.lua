
---  12/19/2020 10:08 PM

-- TODO docs

---- require "/scripts/util/propstore.lua"

PropStore = {}

function PropStore.new(id, referenceTable)
  if not status then error("PropStore.lua needs to be in a context where the 'status' table is accessible.") end
  if type(id) ~= "string" or id == "" then error("Invalid id passed to PropStore.new, should be a unique string like statuseffect name.") end

  local self = setmetatable({}, { __index = PropStore })
  self.propId = "__propStore_" .. id
  self.defaults = {}
  self.reference = referenceTable
  self.props = status.statusProperty(self.propId, {})
  return self
end

function PropStore:recall(fieldName, defaultOnEmpty)
  self.reference[fieldName] = self.props[fieldName] or defaultOnEmpty
  self.defaults[fieldName] = defaultOnEmpty
end

function PropStore:uninit()
  local newProps = {}
  for fieldName, default in pairs(self.defaults) do
    if self.reference[fieldName] ~= default then
      -- value was changed from original default, save it
      newProps[fieldName] = self.reference[fieldName]
    end
  end

  -- check if newProps is not empty, then save it
  -- if empty, remove the property from the player to not clutter player data
  status.setStatusProperty(self.propId, next(newProps) and newProps)
end
