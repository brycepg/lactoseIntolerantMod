-- file contains core code which doesn't depend on the
-- zomboid API
--
-- for adapter and domain code
--
-- table namespace like they do it in zomboid lua
lactoseIntolerant = {}
lactoseIntolerant.DEBUG = true

-- possible sickness delta is (BASE-MIN to BASE+MAX-1)
lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE = 30
lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA = 0
lactoseIntolerant.NEW_FOOD_SICKNESS_MAX_RAND_EXTRA = 20

lactoseIntolerant.FOODS_WITH_LACTOSE = {"milk", "cream", "yogurt", "kefir", "whey", "cheese", "ice cream", "pizza", "burger", "cake", "chocolate", "icing", "frosted doughnut", "cupcake", "cinnamon roll", "cookie", "smore", "butter", "milkshake"}
-- If the item name matches with the above substrings, except it if it matches any of the below substrings
lactoseIntolerant.NON_LACTOSE_KEYWORDS = {"dairy[ -]free", "almond milk", "oat milk", "rice milk", "soy milk", "hemp milk", "flax milk", "cashew milk", "tiger nut milk", "without cheese", "burger patty", "imitation", "coconut milk"}
-- Chance that a player will not say anything when eating lactose
lactoseIntolerant.NO_PHRASE_CHANCE = 20

-- for testing
if not ZombRand and lactoseIntolerant.DEBUG then
    function setZombRand(value)
        ZombRand = function(min, max)
            return value
        end
    end
    print("ZombRand is not defined.. defining for testing")
    ZombRand = function(min, max)
        math.random(min, max)
    end
end


-- add to the bottom or edit tests
lactoseIntolerant.phrases = {
    "This food is making my tummy all rumbly",
    "Uhh didn't you know i'm lactose intolerant?",
    "...",
    "Fuck not dairy again",
    "Well I'm gonna spend an evening on the toilet again thanks asshole",
    "There's gonna be a war zone in my asshole",
    "${age} years old and to think I'd learn not to eat dairy",
    "I'm gonna be shaking off farts for the next hour",
    "It's not just any cow.. it's a dairy cow",
}

---------------------------------------------------------------
------------------------- functions ---------------------------
---------------------------------------------------------------

function lactoseIntolerant.choosePhrase(randfunc)
    -- choose phrase for player to say
    if randfunc(0, 99) < lactoseIntolerant.NO_PHRASE_CHANCE then
        return ""
    end
    local index = randfunc(0, #lactoseIntolerant.phrases)
    if lactoseIntolerant.DEBUG then
        print("chosen index: " .. tostring(index))
    end
    local chosenPhrase = lactoseIntolerant.phrases[index]
    return chosenPhrase
end


function lactoseIntolerant.choosePhraseWithInterp(info_table)
  local chosenPhrase = lactoseIntolerant.choosePhrase(ZombRand)
  if chosenPhrase then
      return lactoseIntolerant.Interp(chosenPhrase, info_table)
  end
  return ""
end


function lactoseIntolerant.calculateNewFoodSicknessCount(count, oldFoodSicknessLevel, percentage)
    -- calculate new food sickness level for multiple items
    -- count(number): nubmer of items which induce sickenss
    -- percentage(number): percentage of the item eaten
    -- oldFoodSicknessLevel(number): baseline sickness before itemList was eaten
    local curFoodSicknessLevel = oldFoodSicknessLevel
    i = 0
    while i < count do
         curFoodSicknessLevel = lactoseIntolerant.calculateNewFoodSicknessLevel(curFoodSicknessLevel, percentage, ZombRand)
        i = count + 1
    end
    return curFoodSicknessLevel
end


function lactoseIntolerant.calculateNewFoodSicknessLevelList(itemList, percentage, oldFoodSicknessLevel)
    -- calculate new food sickness level for multiple items
    -- itemList(array): an array of InventoryItem objects
    -- percentage(number): percentage of the item eaten
    -- oldFoodSicknessLevel(number): baseline sickness before itemList was eaten
    local curFoodSicknessLevel = oldFoodSicknessLevel

    for _, extraItem in ipairs(itemList) do
        local itemName = extraItem:getName()
        local food_contains_lactose = lactoseIntolerant.foodNameContainsLactose(itemName)
        if food_contains_lactose then
            oldFoodSicknessLevel = curFoodSicknessLevel
            curFoodSicknessLevel = lactoseIntolerant.calculateNewFoodSicknessLevel(curFoodSicknessLevel, percentage, ZombRand)
            if lactoseIntolerant.DEBUG then
                print(tostring(oldFoodSicknessLevel) .. " -> " .. tostring(curFoodSicknessLevel))
            end
         end
       end
       return curFoodSicknessLevel
end


function lactoseIntolerant.calculateNewFoodSicknessLevel(currentFoodSicknessLevel, itemPercentage, randfunc)
    -- Calculate new food sickness item for eating a food with lactose
    -- itemPercentage: percentage of the item used
    -- make the random function an argument to remove zomboid only function
    -- for testing
    -- returns: a float/int with of new sickness level
    local multiplier = 1
    -- Feel effects more immediately for the player, and then back of additive sickness
    if currentFoodSicknessLevel > 50 then
        multiplier = multiplier * 0.5
    end
    local _rand_extra = randfunc(lactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA, lactoseIntolerant.NEW_FOOD_SICKNESS_MAX_RAND_EXTRA)
    local sicknessDeltaBase = lactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + _rand_extra
    local sicknessDelta = (sicknessDeltaBase * itemPercentage) * multiplier
    local newSicknessLevel = currentFoodSicknessLevel + sicknessDelta
    return newSicknessLevel
end


function lactoseIntolerant.Interp(s, tab)
    -- interpolation for characters with variable dollar sign braces interpolation
    -- example: lactoseIntolerant.Interp("a: ${foo}", {foo="bar"}) == "a: bar"
    -- s(string): string with possible interpolates
    -- tab(table): a table of possible interpolation key values
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end


local function _foodContainsNonLactoseKeywords(itemName)
    for i = 1, #lactoseIntolerant.NON_LACTOSE_KEYWORDS do
        match = string.find(itemName, lactoseIntolerant.NON_LACTOSE_KEYWORDS[i])
        if match ~= nil then
            return true
        end
    end
    return false
end


function lactoseIntolerant.foodNameContainsLactose(itemName)
    -- Check whether a food contains lactose based on its name
    -- return bool
    local food_name = string.lower(itemName)
    local food_with_lactose_match = false
    for i = 1, #lactoseIntolerant.FOODS_WITH_LACTOSE do
        match = string.find(food_name, lactoseIntolerant.FOODS_WITH_LACTOSE[i])
        if match ~= nil then
            food_with_lactose_match = true
            break
        end
    end
    if food_with_lactose_match then
        excepting_keyword = _foodContainsNonLactoseKeywords(food_name)
        if excepting_keyword then
            food_with_lactose_match = false
        end
    end
    return food_with_lactose_match
end


function lactoseIntolerant.zombListToLuaArray(zombList)
    -- convert project zomboid java array object to a native lua array
    itemArray = {}
    for j = 0, zombList:size()-1 do
        itemArray[j+1] = zombList:get(j)
    end
    return itemArray
end
---------------------------------------------------------------


---------------------------------------------------------------
----------------- Class FoodSicknessCalculator ----------------
---------------------------------------------------------------
            -- for both single and multiple items items
            -- knows whether to say phrase or not
            -- pro: encapulate food sickness calculations
            -- pro: encapulate sending phrase message state
            -- pro: more testable
            -- con: extra code, have to change working code
            -- con: disposable class creation every single time
            -- local foodSicknessDecider = lactoseIntolerant.FoodSicknessCalculator:new(item)
            -- local newSicknessLevel = lactoseIntolerant.foodSicknessDecider:calculateNewSicknessLevel(oldFoodSicknessLevel, percentage)
            -- foodSicknessDecider:shouldSayPhrase()
FoodSicknessCalculator = {}
FoodSicknessCalculator.__index = FoodSicknessCalculator

function FoodSicknessCalculator:new(food_item_contents_decider)
    -- item: an zomboid InventoryItem
    -- to decide over
    local obj = {}
    setmetatable(obj, FoodSicknessCalculator)
    obj.food_item_contents_decider = food_item_contents_decider
    return obj
end

function FoodSicknessCalculator:from_item(item)
    realized_food_contents = RealizedFoodContents:new(item)
    item_contents_decider = FoodItemContentsDecider:new(realized_food_contents)
    food_sickness_calculator = self:new(item_contents_decider)
    return food_sickness_calculator
end

function FoodSicknessCalculator:doesItemInduceSickness()
    -- boolean: if true the food does induce sickness
    return self.food_item_contents_decider:containsLactose()
end

function FoodSicknessCalculator:calculateNewSicknessLevel(oldFoodSicknessLevel, percentage)
    if not self:doesItemInduceSickness() then
        return oldFoodSicknessLevel
    end
    return lactoseIntolerant.calculateNewFoodSicknessCount(self.food_item_contents_decider:howManyLactoseIngredients(), oldFoodSicknessLevel, percentage)
end
---------------------------------------------------------------


---------------------------------------------------------------
---------------- Class FoodItemContentsDecider ----------------
---------------------------------------------------------------
--
-- 1. decides whether the food item contains lactose
-- 2. can count how many ingredients contain lactose
-- PRO: simplifies calculation code and deduplicates checks
-- CON: harder to customize sickness level based on item name
--
FoodItemContentsDecider = {}
FoodItemContentsDecider.__index = FoodItemContentsDecider
function FoodItemContentsDecider:new(realized_food_contents)
    -- realized_food_contents: object of RealizedFoodContents
    -- intentionally coupling realized_food_contents
    -- in case I want to change how the item is
    -- looked at in the future
    obj = {}
    obj.relevant_item_names = realized_food_contents:getItemNames()
    setmetatable(obj, FoodItemContentsDecider)
    return obj
end
function FoodItemContentsDecider:containsLactose()
    return self:howManyLactoseIngredients() >= 1
end
function FoodItemContentsDecider:howManyLactoseIngredients()
    local count = 0
    for i, food_name in ipairs(self.relevant_item_names) do
        if lactoseIntolerant.foodNameContainsLactose(food_name) then
        count = count + 1
    end
    end
    return count
end


---------------------------------------------------------------
---------------- Class RealizedFoodContents -------------------
---------------------------------------------------------------
--- food contents are the actual items that the player is eating instead of the
--- summarized
--- PRO: allows me to do the unwrapping of inventory items in one place
-- CON: not much, kind of hard to understand what this does

RealizedFoodContents = {}
function RealizedFoodContents:new(item)
    -- inventoryItem: The item from the context menu
    -- menu
    obj = {}
    obj.inventoryItem = item
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function RealizedFoodContents:gatherBaseItems()
    local haveExtraItems = self.inventoryItem:haveExtraItems()
    if haveExtraItems then
        local extraItems = self.inventoryItem:getExtraItems()
        return lactoseIntolerant.zombListToLuaArray(extraItems)
    end
    return {self.inventoryItem}
end

function RealizedFoodContents:getItemNames()
    local names = {}
    for i, item in pairs(self:gatherBaseItems()) do
        names[i] = item:getName()
    end
    return names
end

---------------------------------------------------------------
