---@diagnostic disable-next-line: undefined-global
genericFoodIntolerance = genericFoodIntolerance or {}


function genericFoodIntolerance.zombListToLuaArray(zombList)
    -- convert project zomboid java array object to a native lua array
    itemArray = {}
    for j = 0, zombList:size()-1 do
        itemArray[j+1] = zombList:get(j)
    end
    return itemArray
end



function genericFoodIntolerance.containsExceptingKeyword(foodName, exceptingTable)
    -- negate the positive match if it contains an excepting keyword
    for i = 1, #exceptingTable do
        match = string.find(foodName, exceptingTable[i])
        if match ~= nil then
            return true
        end
    end
    return false
end


function genericFoodIntolerance.foodNameMatches(foodName, inclusiveTable, exclusiveTable)
    -- Check whether a food contains lactose based on its name
    -- inclusiveTable is a table of lua expressions which can be matched against food name
    -- exclusiveTable is a table of lua expressions which can negate an inclusive match
    -- return bool
    local food_name = string.lower(foodName)
    food_with_match = false
    for i = 1, #inclusiveTable do
        match = string.find(food_name, inclusiveTable[i])
        if match ~= nil then
            -- print("match", food_name, " to ", inclusiveTable[i])
            food_with_match = true
            break
        end
    end
    if food_with_match then
        excepting_keyword = genericFoodIntolerance.containsExceptingKeyword(foodName, exclusiveTable)
        if excepting_keyword then
            food_with_match = false
        end
    end
    return food_with_match
end

function genericFoodIntolerance.printTable(tbl, indent)
    indent = indent or 0

    for key, value in pairs(tbl) do
        local formattedKey = tostring(key)
        if type(value) == "table" then
                print(string.rep("  ", indent) .. formattedKey .. " = {")
            printTable(value, indent + 1)
            print(string.rep("  ", indent) .. "}")
        else
            local formattedValue = tostring(value)
            print(string.rep("  ", indent) .. formattedKey .. " = " .. formattedValue)
        end
    end
end

---------------------------------------------------------------
--------------------Sickness aggregation classes---------------
---------------------------------------------------------------
-- These classes streamline the checking of food items
-- for dairy and subsequent sickness calculations

--- XXX if I make this class local can I still test it?
--- otherwise I need to namespace or rename it
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
            -- implement shouldSayPhrase() ?
FoodSicknessCalculator = {}
FoodSicknessCalculator.__index = FoodSicknessCalculator

function FoodSicknessCalculator:factory(calculationFunction)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    self.calculationFunction = calculationFunction
    return obj
end

function FoodSicknessCalculator:new(food_item_contents_decider)
    -- item: an zomboid InventoryItem
    -- to decide over
    local obj = {}
    setmetatable(obj, FoodSicknessCalculator)
    obj.food_item_contents_decider = food_item_contents_decider
    return obj
end


function FoodSicknessCalculator:doesItemInduceSickness()
    -- boolean: if true the food does induce sickness
    return self.food_item_contents_decider:containsFoodNameMatch()
end

function FoodSicknessCalculator:calculateNewSicknessLevel(oldFoodSicknessLevel, percentage)
    if not self:doesItemInduceSickness() then
        return oldFoodSicknessLevel
    end
    return self.calculationFunction(self.food_item_contents_decider:howManyMatchingIngredients(), oldFoodSicknessLevel, percentage)
end


---------------------------------------------------------------
---------------- Class FoodItemContentsDecider ----------------
---------------------------------------------------------------
--
-- 1. decides whether the food item contains match
-- 2. can count how many ingredients contain match
-- PRO: simplifies calculation code and deduplicates checks
-- CON: harder to customize sickness level based on item name
--
FoodItemContentsDecider = {}
FoodItemContentsDecider.__index = FoodItemContentsDecider
--- FoodNameMatcher takes a matching function and then allows you to give it a list of item names
--- and then returns the count
--- Makes the code easier to understand
function FoodItemContentsDecider:new(realized_food_contents, foodNameMatcher)
    -- realized_food_contents: object of RealizedFoodContents
    -- intentionally coupling realized_food_contents
    -- in case I want to change how the item is
    -- looked at in the future
    obj = {}
    obj.foodNameMatcher = foodNameMatcher
    obj.relevant_item_names = realized_food_contents:getItemNames()
    setmetatable(obj, FoodItemContentsDecider)
    return obj
end
--- XXX rewrite to
function FoodItemContentsDecider:containsFoodNameMatch()
    return self:howManyMatchingIngredients() >= 1
end
function FoodItemContentsDecider:howManyMatchingIngredients()
    local count = 0
    for i, food_name in ipairs(self.relevant_item_names) do
        -- XXX rewrite class to give this function as an argument, foodNameMatcher
        if self.foodNameMatcher(food_name) then
        count = count + 1
    end
    end
    return count
end


---------------------------------------------------------------
---------------- Class RealizedFoodContents -------------------
---------------------------------------------------------------
--- food contents are the actual items that the player is
--  eating instead of the summarized representation
--  For example, for a stiry fry made of cheese and meat
--  it will simply list the items
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
        return genericFoodIntolerance.zombListToLuaArray(extraItems)
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
