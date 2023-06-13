require 'lactoseIntolerantCore'

-- DONE: Add nasuea for foods with cheese in it such as a stirfry with cheese
    -- What functions describe the contents of an edible item? getExtraItems
-- playtest out stir fry nasua
-- Do I need to specify both on game boot and on game start
-- Test sandbox option for trait points (default: +1)
-- implement allow phrases to be disableable
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
        local bodyDamage = playerObj:getBodyDamage()
        local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
        local haveExtraItems = item:haveExtraItems()
        local sayPhrase = false
        if haveExtraItems then
            local extraItems = item:getExtraItems()
            local itemArray = zombListToLuaArray(extraItems)
            newSicknessLevel = calculateNewFoodSicknessLevelList(itemArray, oldFoodSicknessLevel, percentage)
            bodyDamage:setFoodSicknessLevel(newSicknessLevel);
            sayPhrase = true
        else
        end
        itemName = item:getName()
        food_contains_lactose = foodContainsLactose(itemName)
        playerObj:Say("Eating: " .. itemName)
        if food_contains_lactose then
            -- lets refactor this so I can use it for get extraItems
             local bodyDamage = playerObj:getBodyDamage()
             local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
             local newSicknessLevel = calculateNewFoodSicknessLevel(oldFoodSicknessLevel, percentage, ZombRand)
             bodyDamage:setFoodSicknessLevel(newSicknessLevel);
             sayPhrase = true
         end

         if sayPhrase then
             -- allow disabling of phrase
             local phrase_info_table = {}
             phrase_info_table.age = tostring(playerObj:getAge())
             phrase_info_table.name = playerObj:getName()
             phrase_info_table.item = itemName
             print("phrase_info_table: " .. tostring(phrase_info_table))
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
