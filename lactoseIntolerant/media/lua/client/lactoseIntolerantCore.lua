--  TODO: create table for all these functions
--  named: "LactoseIntolerant" table?

LactoseIntolerant = {}
LactoseIntolerant.DEBUG = true

-- possible sickness delta is (BASE-MIN to BASE+MAX-1)
LactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE = 30
LactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA = 0
LactoseIntolerant.NEW_FOOD_SICKNESS_MAX_RAND_EXTRA = 20

-- testable code without references to zomboid API
LactoseIntolerant.FOODS_WITH_LACTOSE = {"milk", "cream", "yogurt", "kefir", "whey", "cheese", "ice cream", "pizza", "burger", "cake", "chocolate", "icing", "frosted doughnut", "cupcake", "cinnamon roll", "cookie", "smore", "butter", "milkshake"}
-- If the item name matches with the above substrings, except it if it matches any of the below substrings
local NON_LACTOSE_KEYWORDS = {"dairy[ -]free", "almond milk", "oat milk", "rice milk", "soy milk", "hemp milk", "flax milk", "cashew milk", "tiger nut milk", "without cheese"}
-- Chance that a player will not say anything when eating lactose
local NO_PHRASE_CHANCE = 20

-- for testing
if not ZombRand and LactoseIntolerant.DEBUG then
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
lactoseIntolerantPhrases = {
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


function choosePhraseWithInterp(info_table)
  local chosenPhrase = choosePhrase(ZombRand)
  if chosenPhrase then
      return lactoseIntolerantInterp(chosenPhrase, info_table)
  end
  return ""
end


function choosePhrase(randfunc)
    -- choose phrase for player to say
    if randfunc(0, 99) < NO_PHRASE_CHANCE then
        return ""
    end
    local index = randfunc(0, #lactoseIntolerantPhrases)
    if LactoseIntolerant.DEBUG then
        print("chosen index: " .. tostring(index))
    end
    local chosenPhrase = lactoseIntolerantPhrases[index]
    return chosenPhrase
end


function calculateNewFoodSicknessLevelList(itemList, percentage, oldFoodSicknessLevel)
    -- itemList is an array
    -- percentage is a float from 0 to 1 noting the
    -- percentage of the food eaten
    local curFoodSicknessLevel = oldFoodSicknessLevel

    -- zero indexed list because of java?
    for _, extraItem in ipairs(itemList) do
        local itemName = extraItem:getName()
        local food_contains_lactose = foodContainsLactose(itemName)
        if food_contains_lactose then
            oldFoodSicknessLevel = curFoodSicknessLevel
            curFoodSicknessLevel = calculateNewFoodSicknessLevel(curFoodSicknessLevel, percentage, ZombRand)
            if LactoseIntolerant.DEBUG then
                print(tostring(oldFoodSicknessLevel) .. " -> " .. tostring(curFoodSicknessLevel))
            end
         end
       end
       return curFoodSicknessLevel
end


function calculateNewFoodSicknessLevel(currentFoodSicknessLevel, itemPercentage, randfunc)
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
    local _rand_extra = randfunc(LactoseIntolerant.NEW_FOOD_SICKNESS_MIN_RAND_EXTRA, LactoseIntolerant.NEW_FOOD_SICKNESS_MAX_RAND_EXTRA)
    local sicknessDeltaBase = LactoseIntolerant.LACTOSE_ITEM_SICKNESS_BASE + _rand_extra
    local sicknessDelta = (sicknessDeltaBase * itemPercentage) * multiplier
    local newSicknessLevel = currentFoodSicknessLevel + sicknessDelta
    return newSicknessLevel
end


function lactoseIntolerantInterp(s, tab)
    -- interpolation for characters with variable dollar sign braces interpolation
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end


local function _foodContainsNonLactoseKeywords(itemName)
    for i = 1, #NON_LACTOSE_KEYWORDS do
        match = string.find(itemName, NON_LACTOSE_KEYWORDS[i])
        if match ~= nil then
            return true
        end
    end
    return false
end


function foodContainsLactose(itemName)
    -- Check whether a food contains lactose based on its name
    -- return bool
    local food_name = string.lower(itemName)
    local food_with_lactose_match = false
    for i = 1, #LactoseIntolerant.FOODS_WITH_LACTOSE do
        match = string.find(food_name, LactoseIntolerant.FOODS_WITH_LACTOSE[i])
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


function zombListToLuaArray(zombList)
    -- convert project zomboid java array object to a native lua array
    itemArray = {}
    for j = 0, zombList:size()-1 do
        itemArray = zombList:get(j)
    end
    return itemArray
end
