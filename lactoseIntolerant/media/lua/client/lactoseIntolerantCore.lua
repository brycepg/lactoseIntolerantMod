require "genericFoodIntolerance"

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

lactoseIntolerant.DEBUG = false

------------------ Sickness calculation config ----------------
-- possible sickness delta is (BASE-MIN to BASE+MAX-1)
lactoseIntolerant.SICKNESS_BASE = 40
lactoseIntolerant.NEW_SICKNESS_MIN_RAND_EXTRA = -5
lactoseIntolerant.NEW_SICKNESS_MAX_RAND_EXTRA = 10
lactoseIntolerant.SICKNESS_REDUCTION_THRESHOLD = 50
lactoseIntolerant.REDUCTION_THRESHOLD_MULTIPLIER = 0.5

function lactoseIntolerant.getMultiplier(
        currentFoodSicknessLevel)
    -- Feel effects more immediately for the player, and then back off additive sickness
    if (currentFoodSicknessLevel >=
        lactoseIntolerant.SICKNESS_REDUCTION_THRESHOLD
            ) then
        return (lactoseIntolerant.REDUCTION_THRESHOLD_MULTIPLIER)
    end
    return 1
end

----------------- Food identification config ------------------
-- note these are all subset comparisons that ingore case of the original word and support string.find regex
-- only use lower case characters here
lactoseIntolerant.FOODS_WITH_LACTOSE = {"milk", "cream", "yogurt", "kefir", "whey", "cheese", "ice cream", "pizza", "burger", "cake", "chocolate", "icing", "frosted doughnut", "cupcake", "cinnamon roll", "cookie", "smore", "butter", "milkshake", "nutella", "queso", "protein shake", "lasagna"}

-- If the item name matches with the above substrings, except it if it matches any of the below substrings
lactoseIntolerant.NON_LACTOSE_KEYWORDS = {"dairy[ -]free", "almond milk", "oat milk", "rice milk", "soy milk", "hemp milk", "flax milk", "cashew milk", "tiger nut milk", "without cheese", "burger patty", "imitation", "coconut milk", "dark[ -]chocolate", "peanut"}
-- Chance that a player will not say anything when eating lactose

lactoseIntolerant.FOODS_WITH_GLUTEN = {"baguette", "biscuit", "cake", "cereal", "bread", "pão", "burrito", "sandwich", "nuggets", "cornbread", "corndog", "croissant", "cupcake", "doughnut", "muffin", "dumpling", "noodle soup", "pancakes", "perogies", "pie", "pizza", "bagel", "taco", "tortilla", "waffles", "cinnamon roll", "cone", "crackers", "ramen", "flour", "gravy", "pasta", "pretzel", "beer"}
lactoseIntolerant.NON_GLUENT_KEYWORDS = {"gluent[ -]free", "potato pancakes"}


------------------- Phrase configuration ----------------------
lactoseIntolerant.NO_PHRASE_CHANCE = 30

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
    "Goddamnit {name}",
    "No more {item} PLEASE",
}

------------------------- Testing -----------------------------
if not ZombRand then
    lactoseIntolerant.DEBUG = true
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

function lactoseIntolerant.eatItemWithLactoseIntoleranceTrait(item, percentage, playerObj, shouldSayPhrase)
    ------------------ Sickness calculation ---------------
    local bodyDamage = playerObj:getBodyDamage()
    local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
    local fsc = lactoseIntolerant.foodSicknessCalculatorForLactose(item)
    local newSicknessLevel = fsc:calculateNewSicknessLevel(
        oldFoodSicknessLevel, percentage
    )
    if lactoseIntolerant.DEBUG then
        print("---")
        print("old food sickness level: " .. oldFoodSicknessLevel)
        print("new food sickness level: " .. newSicknessLevel)
    end
    if newSicknessLevel ~= oldFoodSicknessLevel then
        bodyDamage:setFoodSicknessLevel(newSicknessLevel)
    end

    ------------------- Phrase code -----------------------
    shouldSayPhrase = (
        shouldSayPhrase and
        newSicknessLevel > oldFoodSicknessLevel
    )
    local phrase_info =  lactoseIntolerant.populatePhraseInfo(
        playerObj, item:getName()
    )
    if lactoseIntolerant.DEBUG then
        print("should say phrase: ", shouldSayPhrase)
        print("lactoseMod: AGE -> ", tostring(phrase_info.age))
        print("lactoseMod: NAME -> ", tostring(phrase_info.name))
    end
    if shouldSayPhrase then
         local phraseString = lactoseIntolerant.choosePhraseWithInterp(
             phrase_info
         )
         if phraseString then
            playerObj:Say(phraseString)
        else
            if lactoseIntolerant.DEBUG then
                playerObj:Say("No phrase string")
            end
        end
    end
end


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
    -- Read from bottom to top

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
     phrase_info_table.name = playerObj:getForname()
     phrase_info_table.item = itemName
     return phrase_info_table
end


function lactoseIntolerant.sayPhraseChance(randfunc)
    if randfunc(0, 99) < lactoseIntolerant.NO_PHRASE_CHANCE then
        return false
    end
    return true
end


function lactoseIntolerant.choosePhrase(randfunc)
    --- Randomly choose a phrase using `randfunc`
    --- args(func): Random func -- Zombrand for game
    --- return(str): a phrase
    local index = randfunc(1, #lactoseIntolerant.phrases+1)
    if lactoseIntolerant.DEBUG then
        print("chosen index: " .. tostring(index))
    end
    local chosenPhrase = lactoseIntolerant.phrases[index]
    return chosenPhrase
end


function lactoseIntolerant.choosePhraseWithInterp(info_table)
    local chosenPhrase = lactoseIntolerant.choosePhrase(ZombRand)
    return  lactoseIntolerant.interpolateInfoTable(chosenPhrase, info_table)
end


function lactoseIntolerant.interpolateInfoTable(chosenPhraseTemplate, info_table)
    local chosenPhrase = chosenPhraseTemplate
    for key, value in pairs(info_table) do
        if lactoseIntolerant.DEBUG then
            print("key: " .. key .. " value: " .. value)
        end
        local keymarker = string.format("{%s}", key)
        chosenPhrase = string.gsub(chosenPhrase, keymarker, value)
    end
    return chosenPhrase
end


function lactoseIntolerant.foodSicknessCalculatorForLactose(item)
    --- What would be a good way to simplify class layout?
    --- RealizedFoodContents work very well
    local realized_food_contents = genericFoodIntolerance.RealizedFoodContents:new(item)
    local item_contents_decider = genericFoodIntolerance.FoodItemContentsDecider:new(realized_food_contents, lactoseIntolerant.foodNameContainsLactose)
    local food_sickness_calculator = LactoseFoodSicknessCalculator:new(item_contents_decider)
    return food_sickness_calculator
end

LactoseFoodSicknessCalculator = genericFoodIntolerance.FoodSicknessCalculator:factory(lactoseIntolerant.calculateNewFoodSicknessCount)
