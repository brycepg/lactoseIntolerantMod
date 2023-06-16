-- luarocks is not working on my system so no luatest
require "lactoseIntolerantCore"
require "testUtils"

lactoseIntolerant.DEBUG = true
FULLPERCENTAGE = 1

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

itemWithoutCheese = TestItem:new("foo")
item2 = TestItem:new("cheese figurine")
item2 = TestItem:new("milk without cow")

testItemList = {
    itemWithoutCheese,
    item2,
}

ZombRand = function(min, max)
    return min
end
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemList, 1, 0)
assert(newValue == lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)

item3 = TestItem:new("cheese2")

testItemListTwoIngredients = {
    itemWithoutCheese,
    item2,
    item3,
}
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemListTwoIngredients, 1, 0)
assert(newValue == (lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA)*2)

-- todo test interpolated phrases
--

rfcwocheese = RealizedFoodContents:new(itemWithoutCheese)
itemWithoutCheeseContentsDecider = FoodItemContentsDecider:new(rfcwocheese)
assert (itemWithoutCheeseContentsDecider:howManyLactoseIngredients() == 0)


_assert = assert
function assert(val, val2)
    print(tostring(val))
    _assert(val)
end
-- Test food sickness calculator from item
function test_food_sickness_calculator_no_lactose()
    -- should be the same value given
    local original_sickness = 69
    local item3 = TestItem:new("butt sauce")
    local food_sickness_calculator = FoodSicknessCalculator:from_item(item)
    local new_sickness_level = food_sickness_calculator:calculateNewSicknessLevel(original_sickness, FULLPERCENTAGE)
    print("osl: " .. tostring(original_sickness))
    print("nsl: " .. tostring(new_sickness_level))
    print("count: " .. tostring(food_sickness_calculator.food_item_contents_decider:howManyLactoseIngredients()))
    assert(new_sickness_level == original_sickness)
end

test_food_sickness_calculator_no_lactose()

function test_food_sickness_calculator_with_lactose()
    -- should be the same value given
    local original_sickness = 0
    local item3 = TestItem:new("cheese cat")
    local food_sickness_calculator = FoodSicknessCalculator:from_item(item)
    local new_sickness_level = food_sickness_calculator:calculateNewSicknessLevel(original_sickness, FULLPERCENTAGE)
    local should_be_new = lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA
    print("new_sickness_level: " .. tostring(new_sickness_level))
    assert(new_sickness_level == should_be_new)
end

test_food_sickness_calculator_with_lactose()
