
---  12/19/2020 10:08 PM

-- TODO docs

---- require "/scripts/util/propstore.lua"

PropStore = {}

function PropStore.new(id, referenceTable)
  if not status then error("PropStore.lua needs to be in a context where the 'status' table is accessible.") end
  if type(id) ~= "string" or id == "" then error("Invalid id passed to PropStore.new, should be a unique string like statuseffect name.") end

  local self = setmetatable({}, { __index = PropStore })
  self.propId = "kf.propStore." .. id
  self.defaults = {}
  self.reference = referenceTable
  self.props = status.statusProperty(self.propId) or {}
  return self
end

function PropStore:recall(fieldName, defaultOnEmpty)
  self.reference[fieldName] = self.props[fieldName] or defaultOnEmpty
  self.defaults[fieldName] = defaultOnEmpty or false  -- prevent nil value
end

function PropStore:uninit()
  local newProps = {}
  for fieldName, default in pairs(self.defaults) do
    if type(default) == "table" or self.reference[fieldName] ~= default then
      -- value was changed from original default, save it
      -- if it's a table, always save it (we won't want to compare contents tho)
      newProps[fieldName] = self.reference[fieldName]
    end
  end

  -- check if newProps is not empty, then save it
  -- if empty, remove the property from the player to not clutter player data
  -- edit : okay heccin, nil doesn't remove the key from the player, dammit
  status.setStatusProperty(self.propId, next(newProps) and newProps)
end
