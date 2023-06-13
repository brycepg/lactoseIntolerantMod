-- luarocks is not working on my system so no luatest
require "lactoseIntolerant/media/lua/client/lactoseIntolerantCore"
require "testUtils"
assert( lactoseIntolerant.foodNameContainsLactose("cheese") == true )
assert( lactoseIntolerant.foodNameContainsLactose("cheese pizza") == true )
assert( lactoseIntolerant.foodNameContainsLactose("beer") == false )
assert( lactoseIntolerant.foodNameContainsLactose("cat piss") == false )
assert( lactoseIntolerant.foodNameContainsLactose("milk") == true )
assert( lactoseIntolerant.foodNameContainsLactose("almond milk") == false )
assert( lactoseIntolerant.foodNameContainsLactose("oat milk") == false )
assert( lactoseIntolerant.foodNameContainsLactose("dairy free milk") == false )
assert( lactoseIntolerant.foodNameContainsLactose("dairy-free milk") == false )

assert( lactoseIntolerant.Interp("hi ${name}", {name="bob"})  == "hi bob" )
assert( lactoseIntolerant.Interp("hi", {name="bob"})  == "hi" )

assert (type(math.random(1, 5)) == type(5))
math.randomseed(os.time())
assert(lactoseIntolerant.choosePhrase(math.random) ~= nil)
function noRandomMin(min, max)
    return min
end
assert(lactoseIntolerant.calculateNewFoodSicknessLevel(0, 1, noRandomMin) == lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)

itemWithoutCheese = testItem:create("foo")
item2 = testItem:create("cheese figurine")
item2 = testItem:create("milk without cow")

testItemList = {
    itemWithoutCheese,
    item2,
}

ZombRand = function(min, max)
    return min
end
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemList, 1, 0)
assert(newValue == lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)

item3 = testItem:create("cheese2")

testItemListTwoIngredients = {
    itemWithoutCheese,
    item2,
    item3,
}
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemListTwoIngredients, 1, 0)
assert(newValue == (lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)*2)

-- todo test interpolated phrases
--

itemWithoutCheeseContentsDecider = FoodItemContentsDecider:new(itemWithoutCheese)
assert (itemWithoutCheeseContentsDecider:howManyLactoseIngredients() == 0)
