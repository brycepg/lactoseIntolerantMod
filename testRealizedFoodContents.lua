require "lactoseIntolerantCore"
require 'testUtils'

NAME1 = "foo"
item = TestItem:new(NAME1)
print(item.name)
rfc = RealizedFoodContents:new(item)
assert(item.name == NAME1)
ii = rfc["inventoryItem"]
for key, _ in pairs(ii) do
    print("key " .. tostring(key))
end
print("ii" .. tostring(ii))
assert(ii.name == NAME1, "what")
assert(item:getName() == NAME1)
assert(rfc.inventoryItem:getName() == item:getName())
item_gathered = rfc:gatherBaseItems()[1]
print(item_gathered.name)
assert(item_gathered == item)
names = rfc:getItemNames()
assert(names[1] == NAME1)

-- Test with extra items
NAME2 = "bar"
extraItems1 = TestItem:new("baz")
extraItems2 = TestItem:new("bam")
exi = ExtraItems:new{extraItems1, extraItems2}
iNAME2 = TestItemWithExtraItems:new(NAME2, exi)
print("hve extra items", iNAME2:haveExtraItems())
rfc2 = RealizedFoodContents:new(iNAME2)
base_items = rfc2:gatherBaseItems()
print("base items" .. tostring(base_items))
-- base items empty only when have extra items is true
print("base items size" .. tostring(#base_items))
print("have extra items " .. tostring(rfc2.inventoryItem:haveExtraItems()))
print("extra items " .. tostring(rfc2.inventoryItem:getExtraItems()))
print("extra items[0] " .. tostring(rfc2.inventoryItem:getExtraItems():get(0)))
print("#extra items " .. tostring(#(rfc2.inventoryItem:getExtraItems())))
function str_array(arr)
    local result = ""
    for i, item in ipairs(arr) do
        result = result .. (tostring(i) .. ": " .. tostring(item) .. "\n")
    end
    return result
end
print("b" .. str_array( rfc2:getItemNames()))

