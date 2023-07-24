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

PlayerObj = {}
function PlayerObj:new(foodSicknessLevel, age, name)
    obj = {}
    setmetatable(obj, PlayerObj)
    self.__index = PlayerObj
    self.sayOutput = {}
    self.age = age
    self.name = name
    self._bodyDamage = BodyDamage:new(foodSicknessLevel)
    return self
end

function PlayerObj:Say(sayString)
    table.insert(self.sayOutput, sayString)
end

function PlayerObj:getBodyDamage()
    print("fsl", self.foodSicknessLevel)
    return self._bodyDamage
end

function PlayerObj:getAge()
    return self.age
end

function PlayerObj:getForname()
    return self.name
end

BodyDamage = {}
function BodyDamage:new(foodSicknessLevel)
    obj = {}
    setmetatable(obj, self)
    self.__index = self
    self.foodSicknessLevel = foodSicknessLevel
    print("fsl bd", self.foodSicknessLevel)
    return obj
end

function BodyDamage:getFoodSicknessLevel()
    print("get fsl  bd", self.foodSicknessLevel)
    return self.foodSicknessLevel
end

function BodyDamage:setFoodSicknessLevel(foodSicknessLevel)
    print("set fsl  bd", foodSicknessLevel)
    self.foodSicknessLevel = foodSicknessLevel
end
