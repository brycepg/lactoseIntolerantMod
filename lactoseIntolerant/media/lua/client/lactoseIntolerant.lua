require 'lactoseIntolerantCore'

-- DONE: Add nasuea for foods with cheese in it such as a stirfry with cheese
    -- What functions describe the contents of an edible item?
-- Do I need to specify both on game boot and on game start
-- Test sandbox option for trait points (default: +1)
-- Test allow phrases to be disableable
local old_eatmenu = ISInventoryPaneContextMenu.eatItem
local lactoseIntolerantOverrideSet = false


function choosePhraseWithInterp(info_table)
  local chosenPhrase = choosePhrase(ZombRand)
  if chosenPhrase then
      return lactoseIntolerantInterp(chosenPhrase, info_table)
  end
  return ""
end


function eatItemWithLactoseIntoleranceTrait(item, percentage, player)
        old_eatmenu(item, percentage, player)
        local playerObj = getPlayer(player)
        if not playerObj:HasTrait("lactoseIntolerant") then
            playerObj:Say("I do not have lactose intolerance")
            ISInventoryPaneContextMenu.eatItem = old_eatmenu
            return
        end
        -- Test Out ExtraItems with stir fry
        -- I'm going to check each item in a meal to see if it contains a cheese item
        -- Count the amount of foods with cheese in them
        local haveExtraItems = item:haveExtraItems(); if haveExtraItems then
        local bodyDamage = playerObj:getBodyDamage()
        local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
        local extraItems = item:getExtraItems()
        for j = 0, extraItems:size()-1 do
            local extraItem = extraItems:get(j)
            playerObj:Say("ISInventoryPage extra item "..j.." = "..tostring(extraItem or "nil"))
            food_contains_lactose = foodContainsLactose(extraItem:getName())
            if foodContainsLactose then
             end
           end
        end
        itemArray = {}
        for j = 0, itemList:size()-1 do
            itemArray = itemList:get(j)
        end
        newSicknessLevel = calculateNewFoodSicknessLevelList(itemArray, oldFoodSicknessLevel, percentage)
        bodyDamage:setFoodSicknessLevel(newSicknessLevel);
        itemName = item:getName()
        food_contains_lactose = foodContainsLactose(itemName)
        playerObj:Say("Eating: " .. itemName)
        if food_contains_lactose then
            -- lets refactor this so I can use it for get extraItems
             local bodyDamage = playerObj:getBodyDamage()
             local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
             local newSicknessLevel = calculateNewFoodSicknessLevel(oldFoodSicknessLevel, percentage, ZombRand)
             bodyDamage:setFoodSicknessLevel(newSicknessLevel);
             -- allow disabling of phrase
             local phrase_info_table = {}
             phrase_info_table.age = tostring(playerObj:getAge())
             phrase_info_table.name = playerObj:getName()
             phrase_info_table.item = itemName
             local phrase = choosePhraseWithInterp(phrase_info_table)
             print("say phrases: " .. tostring(SandboxVars.lactoseIntolerant.SayPhrasesOnDairyConsumption))
             if phrase then
                playerObj:Say(phrase)
            end
        end
end


function overrideEatItem()
    ISInventoryPaneContextMenu.eatItem = eatItemWithLactoseIntoleranceTrait
end


function registerLactoseIntoleranceTrait()
    local lactose_intolerant_trait_point_cost = SandboxVars.lactoseIntolerant.PointCost
    TraitFactory.addTrait("lactoseIntolerant", getText("UI_trait_lactoseIntolerant"), lactose_intolerant_trait_point_cost, getText("UI_trait_lactoseIntolerantdesc"), false)
end

if not lactoseIntolerantOverrideSet then
    Events.OnGameBoot.Add(overrideEatItem)
    Events.OnGameStart.Add(overrideEatItem)
    Events.OnGameBoot.Add(registerLactoseIntoleranceTrait)
    Events.OnGameStart.Add(registerLactoseIntoleranceTrait)
    -- allow override
    -- lactoseIntolerantOverrideSet = true
end
ISInventoryPaneContextMenu.eatItem = eatItemWithLactoseIntoleranceTrait
