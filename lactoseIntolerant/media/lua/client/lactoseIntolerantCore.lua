require "genericFoodIntolerance"
F = require("F")

-- file contains core code which doesn't depend on the
-- zomboid API
--
-- for adapter and domain code
--
-- table namespace like they do it in zomboid lua
lactoseIntolerant = {}

---------------------------------------------------------------
-------------------- Static Configuration ---------------------
---------------------------------------------------------------
-- Tweakable variables as configuration

lactoseIntolerant.DEBUG = true

------------------ Sickness calculation config ----------------
-- possible sickness delta is (BASE-MIN to BASE+MAX-1)
lactoseIntolerant.SICKNESS_BASE = 50
lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA = 0
lactoseIntolerant.NEW_SICKNESS_MAX_RAND_EXTRA = 20
lactoseIntolerant.SICKNESS_REDUCTION_THRESHOLD = 70
lactoseIntolerant.REDUCTION_THRESHOLD_MULTIPLIER = 0.5

function lactoseIntolerant.getMultiplier(
        currentFoodSicknessLevel)
    -- Feel effects more immediately for the player, and then back off additive sickness
    if (currentFoodSicknessLevel >
        lactoseIntolerant.SICKNESS_REDUCTION_THRESHOLD
            ) then
        return (lactoseIntolerant.REDUCTION_THRESHOLD_MULTIPLIER)
    end
    return 1
end

----------------- Food identification config ------------------
-- note these are all subset comparisons that ingore case of the original word and support string.find regex
-- only use lower case characters here
lactoseIntolerant.FOODS_WITH_LACTOSE = {"milk", "cream", "yogurt", "kefir", "whey", "cheese", "ice cream", "pizza", "burger", "cake", "chocolate", "icing", "frosted doughnut", "cupcake", "cinnamon roll", "cookie", "smore", "butter", "milkshake", "nutella"}

-- If the item name matches with the above substrings, except it if it matches any of the below substrings
lactoseIntolerant.NON_LACTOSE_KEYWORDS = {"dairy[ -]free", "almond milk", "oat milk", "rice milk", "soy milk", "hemp milk", "flax milk", "cashew milk", "tiger nut milk", "without cheese", "burger patty", "imitation", "coconut milk", "dark[ -]chocolate"}
-- Chance that a player will not say anything when eating lactose

lactoseIntolerant.FOODS_WITH_GLUTEN = {"baguette", "biscuit", "cake", "cereal", "bread", "pão", "burrito", "sandwich", "nuggets", "cornbread", "corndog", "croissant", "cupcake", "doughnut", "muffin", "dumpling", "noodle soup", "pancakes", "perogies", "pie", "pizza", "bagel", "taco", "tortilla", "waffles", "cinnamon roll", "cone", "crackers", "ramen", "flour", "gravy", "pasta", "pretzel", "beer"}
lactoseIntolerant.NON_GLUENT_KEYWORDS = {"gluent[ -]free", "potato pancakes"}


------------------- Phrase configuration ----------------------
lactoseIntolerant.NO_PHRASE_CHANCE = 20

-- add to the bottom or edit tests
lactoseIntolerant.phrases = {
    "{age} years old and to think I'd learn not to eat dairy",
    "This food is making my tummy all rumbly",
    "Uhh didn't you know i'm lactose intolerant?",
    "...",
    "Fuck not dairy again",
    "Well I'm gonna spend an evening on the toilet again thanks asshole",
    "There's gonna be a war zone in my asshole",
    "I'm gonna be shaking off farts for the next hour",
    "It's not just any cow.. it's a dairy cow",
    -- Interp tests pass but I have an error during execution.. WHY?
}

------------------------- Testing -----------------------------
if not ZombRand and lactoseIntolerant.DEBUG then
    function setZombRand(value)
        ---@diagnostic disable-next-line: unused-local
        ZombRand = function(min, max)
            return value
        end
    end
    print("ZombRand is not defined.. defining for testing")
    ZombRand = function(min, max)
        return math.random(min, max)
    end
end



---------------------------------------------------------------
------------------------- functions ---------------------------
---------------------------------------------------------------

--------------------Food identification -----------------------
-- For identifying food as dairy as not
-- I decided to go with fuzzy matching to provide more support
-- for mods (no classes)

function lactoseIntolerant.foodNameContainsLactose(itemName)
    return genericFoodIntolerance.foodNameMatches(
        itemName,
        lactoseIntolerant.FOODS_WITH_LACTOSE,
        lactoseIntolerant.NON_LACTOSE_KEYWORDS)
end


-------------------------sickness calculation------------------

function lactoseIntolerant.calculateNewFoodSicknessCount(count, oldFoodSicknessLevel, percentage)
    -- calculate new food sickness level for multiple items
    -- count(number): number of items which induce sickenss
    -- percentage(number): percentage of the item eaten
    -- oldFoodSicknessLevel(number): baseline sickness before itemList was eaten
    local curFoodSicknessLevel = oldFoodSicknessLevel
    i = 0
    -- print("count: " .. tostring(count))
    while i < count do
        -- print("i: " .. tostring(i))
        curFoodSicknessLevel = lactoseIntolerant.calculateNewFoodSicknessLevel(curFoodSicknessLevel, percentage, ZombRand)
        i = i + 1
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

    -- NOTE: Read from bottom to top

    local multiplier = lactoseIntolerant.getMultiplier(
        currentFoodSicknessLevel
    )
    local _rand_extra = randfunc(
        lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA,
        lactoseIntolerant.NEW_SICKNESS_MAX_RAND_EXTRA
    )
    local sicknessDelta = (
        ((lactoseIntolerant.SICKNESS_BASE + _rand_extra) *
        itemPercentage) *
        multiplier
    )
    local newSicknessLevel = (
        currentFoodSicknessLevel + sicknessDelta
    )
    return newSicknessLevel
end


--------------------------phrases------------------------------
-- For saying phrases after eating dairy (no classes)

function lactoseIntolerant.populatePhraseInfo(playerObj, itemName)
     local phrase_info_table = {}
     phrase_info_table.age = tostring(playerObj:getAge())
     phrase_info_table.name = playerObj:getName()
     phrase_info_table.item = itemName
     return phrase_info_table
end


function lactoseIntolerant.skipPhraseChance(randfunc)
    if randfunc(0, 99) < lactoseIntolerant.NO_PHRASE_CHANCE then
        return true
    end
    return false
end


function lactoseIntolerant.choosePhrase(randfunc)
    local index = randfunc(0, #lactoseIntolerant.phrases)
    if lactoseIntolerant.DEBUG then
        print("chosen index: " .. tostring(index))
    end
    local chosenPhrase = lactoseIntolerant.phrases[index]
    return chosenPhrase
end


function lactoseIntolerant._choosePhraseWithInterp(info_table)
  local chosenPhrase = lactoseIntolerant.choosePhrase(ZombRand)
  if chosenPhrase then
      return lactoseIntolerant.Interp(chosenPhrase, info_table)
  end
  return ""
end

function lactoseIntolerant.choosePhraseWithInterp(info_table)
  local chosenPhrase = lactoseIntolerant.choosePhrase(ZombRand)
  if chosenPhrase then
      local age = info_table.age
      local name = info_table.name
      local item = info_table.item
      return F(chosenPhrase)
  end
  return ""
end

-- had some issues with this function
function lactoseIntolerant.Interp(s, tab)
    -- interpolation for characters with variable dollar sign braces interpolation
    -- example: lactoseIntolerant.Interp("a: ${foo}", {foo="bar"}) == "a: bar"
    -- s(string): string with possible interpolates
    -- tab(table): a table of possible interpolation key values
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

function foodSicknessCalculatorForLactose(item)
    --- What would be a good way to simplify class layout?
    --- RealizedFoodContents work very well
    realized_food_contents = RealizedFoodContents:new(item)
    item_contents_decider = FoodItemContentsDecider:new(realized_food_contents, lactoseIntolerant.foodNameContainsLactose)
    food_sickness_calculator = LactoseFoodSicknessCalculator:new(item_contents_decider)
    return food_sickness_calculator
end

LactoseFoodSicknessCalculator = FoodSicknessCalculator:factory(lactoseIntolerant.calculateNewFoodSicknessCount)
