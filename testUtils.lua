-- Class ExtraItems --
ExtraItems = {}
function ExtraItems:new(table)
    obj = {}
    obj._table = table
    setmetatable(obj, ExtraItems)
    ExtraItems.__index = ExtraItems
    return obj
end

function ExtraItems:size()
    return #(self._table)
end

function ExtraItems:get(index)
    local lua_index = index+1
    return self._table[lua_index]
end

function getName(self)
    return self.name
end

TestItem = {}
-- XXX rename create to new
function TestItem:new(name)
   item = {}             -- our new object
   item.name = name      -- initialize our object
   setmetatable(item,self)  -- make TestItem handle lookup
   self.__index = self
   return item
end

function TestItem:haveExtraItems()
    return false
end
function TestItem:getName()
   return self.name
end


TestItemWithExtraItems = {}
-- How does inheritance
function TestItemWithExtraItems:new(name, extraItems)
   obj = {}             -- our new object
   obj.name = name      -- initialize our object
   obj.extraItems = extraItems
   setmetatable(obj,self)  -- make TestItemWithExtraItems handle lookup
   self.__index = self
   return obj
end

function TestItemWithExtraItems:haveExtraItems()
    local ei = self.extraItems
    return ei:size() > 0
end

function TestItemWithExtraItems:getExtraItems()
    return self.extraItems
end

TestItemWithExtraItems.getName = TestItem.getName
