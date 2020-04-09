CallableProperties = {}

local function setup(object)
    local meta = getmetatable(object)

    -- Handles situations where the metatabale's __index was already set
    local originalIndex
    if meta then
        originalIndex = meta.__index
    end

    setmetatable(object, {
        __callableProperties = {},
        __originalIndex = originalIndex,
        __index = function (self, index)
            local meta = getmetatable(self)

            local storedValue = meta.__callableProperties[index]
            if storedValue then
                if storedValue == nil then return end
                if type(storedValue) ~= "function" then return storedValue end

                return storedValue(object)
            end

            -- Super gross way to stop infinite recursion
            local copyobj = table.Copy(object)
            local copyMeta = table.Copy(getmetatable(copyobj))

            -- Will either be what the index lookup was before we wrapped it or nil which results in default lookup
            copyMeta.__index = copyMeta.__originalIndex

            setmetatable(copyobj, copyMeta)

            return copyobj[index]
        end
    })
end

local function teardown(object)
    local meta = getmetatable(object)
    meta.__index = meta.__originalIndex
    meta.__originalIndex = nil
    meta.__callableProperties = nil

    setmetatable(object, meta)
end

function CallableProperties.register(object, key)
    if key == "__index" then error("Cannot register __index") end

    local meta = getmetatable(object)

    if not meta then setup(object) end

    meta = getmetatable(object)
    meta.__callableProperties[key] = object[key]
    setmetatable( object, meta )

    object[key] = nil
end

function CallableProperties.deregister(object, key)
    local meta = getmetatable(object)
    if not meta.__callableProperties then return end

    object[key] = meta.__callableProperties[key]
    meta.__callableProperties[key] = nil

    if table.Count(meta.__callableProperties) == 0 then return teardown(object) end

    setmetatable(object, meta)
end
