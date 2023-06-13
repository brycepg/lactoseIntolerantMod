function getName(self)
    return self.name
end

testItem = {}
testItem.__index = testItem
function testItem:create(name)
   local item = {}             -- our new object
   setmetatable(item,testItem)  -- make testItem handle lookup
   item.name = name      -- initialize our object
   return item
end

function testItem:haveExtraItems()
    return false
end
function testItem:getName()
   return self.name
end


TestItemWithExtraItems = {}
TestItemWithExtraItems.__index = TestItemWithExtraItems
function TestItemWithExtraItems:create(name, extraItems)
   local item = {}             -- our new object
   setmetatable(item,TestItemWithExtraItems)  -- make TestItemWithExtraItems handle lookup
   item.name = name      -- initialize our object
   return item
end

function TestItemWithExtraItems:haveExtraItems()
    return extraItems.size() > 0
end

function TestItemWithExtraItems:getName = testItem.getName
