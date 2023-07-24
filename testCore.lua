-- luarocks is not working on my system so no luatest
require "lactoseIntolerantCore"
require "testUtils"
F = require("F")

num = 1
assert(F("{num}a") == "1a")
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
print( lactoseIntolerant.Interp("my age is ${age}", {age=1}))
assert( lactoseIntolerant.Interp("my age is ${age}", {age=1})  == "my age is 1" )

assert (type(math.random(1, 5)) == type(5))
math.randomseed(os.time())
assert(lactoseIntolerant.choosePhrase(math.random) ~= nil)
function noRandomMin(min, max)
    return min
end
assert(lactoseIntolerant.calculateNewFoodSicknessLevel(0, 1, noRandomMin) == lactoseIntolerant.SICKNESS_BASE + lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA)

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
assert(newValue == lactoseIntolerant.SICKNESS_BASE + lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA)

item3 = TestItem:new("cheese2")

testItemListTwoIngredients = {
    itemWithoutCheese,
    item2,
    item3,
}
newValue = lactoseIntolerant.calculateNewFoodSicknessLevelList(testItemListTwoIngredients, 1, 0)
assert(newValue == (lactoseIntolerant.SICKNESS_BASE + lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA)*2)

-- todo test interpolated phrases
--

rfcwocheese = RealizedFoodContents:new(itemWithoutCheese)
itemWithoutCheeseContentsDecider = FoodItemContentsDecider:new(rfcwocheese, lactoseIntolerant.foodNameContainsLactose)
assert(itemWithoutCheeseContentsDecider:howManyMatchingIngredients() == 0)


-- Test food sickness calculator from item
function test_food_sickness_calculator_no_lactose()
    -- should be the same value given
    local original_sickness = 69
    local item3 = TestItem:new("butt sauce")
    local food_sickness_calculator = foodSicknessCalculatorForLactose(item)
    local new_sickness_level = food_sickness_calculator:calculateNewSicknessLevel(original_sickness, FULLPERCENTAGE)
    print("osl: " .. tostring(original_sickness))
    print("nsl: " .. tostring(new_sickness_level))
    print("count: " .. tostring(food_sickness_calculator.food_item_contents_decider:howManyMatchingIngredients()))
    assert(new_sickness_level == original_sickness)
end

test_food_sickness_calculator_no_lactose()


function test_food_sickness_calculator_with_lactose()
    -- should be the same value given
    local original_sickness = 0
    local item3 = TestItem:new("cheese cat")
    local food_sickness_calculator = foodSicknessCalculatorForLactose(item)
    local new_sickness_level = food_sickness_calculator:calculateNewSicknessLevel(original_sickness, FULLPERCENTAGE)
    local should_be_new = lactoseIntolerant.SICKNESS_BASE + lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA
    print("new should", new_sickness_level, should_be_new)
    assert(new_sickness_level == should_be_new)
end

test_food_sickness_calculator_with_lactose()


function test_food_sickness_calculator_with_extra_items()
    local original_sickness = 0
    local extraItems1 = TestItem:new("cheese")
    local extraItems2 = TestItem:new("dogs breath")
    local extraItems3 = TestItem:new("butter")
    local exi = ExtraItems:new{extraItems1, extraItems2, extraItems3}
    local item = TestItemWithExtraItems:new("stiry fry rymdreglage", exi)
    local food_sickness_calculator = foodSicknessCalculatorForLactose(item)
    local new_sickness_level = food_sickness_calculator:calculateNewSicknessLevel(
        original_sickness, FULLPERCENTAGE
    )
    local expected = (lactoseIntolerant.SICKNESS_BASE + lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA) * 2
    print("lactose count: " .. tostring(food_sickness_calculator.food_item_contents_decider:howManyMatchingIngredients()))
    print("new: " .. tostring(new_sickness_level))
    assert(new_sickness_level == expected)

    local fsc = foodSicknessCalculatorForLactose(item)
    oldFoodSicknessLevel = original_sickness
    percentage = FULLPERCENTAGE
    newSicknessLevel = fsc:calculateNewSicknessLevel(
        oldFoodSicknessLevel, percentage
    )
end

test_food_sickness_calculator_with_extra_items()

function testEatItemWithLactoseIntolerantTraitExtraItems()
    local initfoodSicknessLevel = 0
    local playerObj = PlayerObj:new(initfoodSicknessLevel, 27, "hairy")
    local item = TestItemWithExtraItems:new("stiry fry rymdreglage", ExtraItems:new{TestItem:new("cheese"), TestItem:new("butter")})
    local shouldSayPhrase = true
    eatItemWithLactoseIntoleranceTrait(item, 1, PlayerObj, shouldSayPhrase)
    print("new food sickness level", playerObj:getBodyDamage():getFoodSicknessLevel())
    assert(playerObj:getBodyDamage():getFoodSicknessLevel() > initfoodSicknessLevel)
end

testEatItemWithLactoseIntolerantTraitExtraItems()
