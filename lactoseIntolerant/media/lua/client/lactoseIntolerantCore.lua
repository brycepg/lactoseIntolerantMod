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


-- new class lactoseIntolerant.FoodItemContentsDecider
-- 1. decides whether the food item contains lactose
-- 2. can count how many ingredients contain lactose
-- PRO: simplifies calculation code and deduplicates checks
-- CON: harder to customize sickness level based on item name
-- XXX: Add lactoseIntolerant after testing
FoodItemContentsDecider = {}
FoodItemContentsDecider.__index = FoodItemContentsDecider
function FoodItemContentsDecider:new(item)
    -- item: zomboid inventoryItem to decide upon
    obj = {}
    setmetatable(obj, FoodItemContentsDecider)
    obj.item = item
    obj.itemName = item:getName()
    return obj
end
function FoodItemContentsDecider:containsLactose()
    return self.howManyLactoseIngredients() >= 1
end
function FoodItemContentsDecider:howManyLactoseIngredients()
    local haveExtraItems = self.item:haveExtraItems()
    local count = 0
    if haveExtraItems then
        local extraItems = self.item:getExtraItems()
        newSicknessLevel = lactoseIntolerant.calculateNewFoodSicknessLevelList(itemArray, oldFoodSicknessLevel, percentage)
        for j = 0, extraItems:size()-1 do
            local extraItem = extraItems:get(j)
            if lactoseIntolerant.foodNamecontainsLactose(extraItem:getName()) then
                count = count + 1
            end
            --print ("ISInventoryPage extra item "..j.." = "..tostring(extraItem or "nil"))
        end
    end
    if (not haveExtraItems and
        lactoseIntolerant.foodNameContainsLactose(self.itemName)) then
            count = 1
    end
    return count
end


-- function lactoseIntolerant.foodItemContainsLactose(item)
--     local haveExtraItems = item:haveExtraItems()
--     if haveExtraItems then
--         local extraItems = item:getExtraItems()
--         local itemArray = lactoseIntolerant.zombListToLuaArray(extraItems)
--     for _, extraItem in ipairs(itemList) do
-- end

function lactoseIntolerant.calculateNewFoodSicknessLevelList(itemList, percentage, oldFoodSicknessLevel)
    -- calculate new food sickness level for multiple items
    -- itemList(array): an array of InventoryItem objects
    -- percentage(int/float): percentage of the item eaten
    -- oldFoodSicknessLevel(int/float): baseline sickness before itemList was eaten
    local curFoodSicknessLevel = oldFoodSicknessLevel

    -- zero indexed list because of java?
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
        itemArray = zombList:get(j)
    end
    return itemArray
end

            -- TODO: foodSicknessDecider class
            -- for both single and multiple items items
            -- knows whether to say phrase or not
            -- pro: encapulate food sickness calculations
            -- pro: encapulate sending phrase message state
            -- pro: more testable
            -- con: extra code, have to change working code
            -- con: disposable class creation every single time
            -- local foodSicknessDecider = lactoseIntolerant.FoodSicknessDecider:new(item)
            -- local newSicknessLevel = lactoseIntolerant.foodSicknessDecider:calculateNewSicknessLevel(oldFoodSicknessLevel, percentage)
            -- foodSicknessDecider:shouldSayPhrase()
FoodSicknessDecider = {}
FoodSicknessDecider.__index = FoodSicknessDecider
function FoodSicknessDecider:new(item)
    -- item: an zomboid InventoryItem
    -- to decide over
    local obj = {}
    setmetatable(obj, FoodSicknessDecider)
    obj.item = item
    obj.itemName = item:getName()
    obj.inducesSicknessFromName = lactoseIntolerant.foodNameContainsLactose(obj.itemName)
    return obj
end

function FoodSicknessDecider:doesItemInduceSickness()
    -- boolean: if true the food does induce sickness
    return self.inducesSickness
end

function FoodSicknessDecider:calculateNewSicknessLevel(oldFoodSicknessLevel, percentage)
    if not self.inducesSickness then
        return oldFoodSicknessLevel
    end
    local haveExtraItems = item:haveExtraItems()
    if haveExtraItems then
        local extraItems = item:getExtraItems()
        local itemArray = lactoseIntolerant.zombListToLuaArray(extraItems)
        newSicknessLevel = lactoseIntolerant.calculateNewFoodSicknessLevelList(itemArray, oldFoodSicknessLevel, percentage)
    else
    end
    return newSicknessLevel
end
