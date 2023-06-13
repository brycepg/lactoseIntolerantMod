-- luarocks is not working on my system so no luatest
require "lactoseIntolerant/media/lua/client/lactoseIntolerantCore"
assert( lactoseIntolerant.foodContainsLactose("cheese") == true )
assert( lactoseIntolerant.foodContainsLactose("cheese pizza") == true )
assert( lactoseIntolerant.foodContainsLactose("beer") == false )
assert( lactoseIntolerant.foodContainsLactose("cat piss") == false )
assert( lactoseIntolerant.foodContainsLactose("milk") == true )
assert( lactoseIntolerant.foodContainsLactose("almond milk") == false )
assert( lactoseIntolerant.foodContainsLactose("oat milk") == false )
assert( lactoseIntolerant.foodContainsLactose("dairy free milk") == false )
assert( lactoseIntolerant.foodContainsLactose("dairy-free milk") == false )

assert( lactoseIntolerant.Interp("hi ${name}", {name="bob"})  == "hi bob" )
assert( lactoseIntolerant.Interp("hi", {name="bob"})  == "hi" )

assert (type(math.random(1, 5)) == type(5))
math.randomseed(os.time())
assert(lactoseIntolerant.choosePhrase(math.random) ~= nil)
function noRandomMin(min, max)
    return min
end
assert(lactoseIntolerant.calculateNewFoodSicknessLevel(0, 1, noRandomMin) == lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)

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

function testItem:getName()
   return self.name
end

item1 = testItem:create("foo")
item2 = testItem:create("cheese figurine")
item2 = testItem:create("milk without cow")

testItemList = {
    item1,
    item2,
}

ZombRand = function(min, max)
    return min
end
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemList, 1, 0)
assert(newValue == lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)

item3 = testItem:create("cheese2")

testItemListTwoIngredients = {
    item1,
    item2,
    item3,
}
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemListTwoIngredients, 1, 0)
assert(newValue == (lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)*2)

-- todo test interpolated phrases
