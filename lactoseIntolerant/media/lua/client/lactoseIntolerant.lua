-- code which does IO with project zomboid
require 'lactoseIntolerantCore'

-- How do I get the code to run ONLY if the eating action is completed?
-- | Is partial eating a thing?
-- | Modify event or action?


-- DONE: Add nasuea for foods with cheese in it such as a stirfry with cheese
-- playtest out stir fry nasua
-- Do I need to specify both on game boot and on game start
-- Test sandbox option for trait points (default: +1)
-- implement allow phrases to be disableable
local old_eatmenu = ISInventoryPaneContextMenu.eatItem
local lactoseIntolerantOverrideSet = false


function lactoseIntolerant.eatItemWithLactoseIntoleranceTrait(item, percentage, player)
        print("Testing out the print function wubba lubba dub dub")
        old_eatmenu(item, percentage, player)
        local playerObj = getPlayer(player)
        if not playerObj:HasTrait("lactoseIntolerant") then
            playerObj:Say("I do not have lactose intolerance")
            -- remove this check from chain, I think I can do this
            -- even with multiplayer since it is client sided code
            ISInventoryPaneContextMenu.eatItem = old_eatmenu
            return
        end

        local bodyDamage = playerObj:getBodyDamage()
        local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
        food_sickness_calculator = FoodSicknessCalculator:from_item(item)
        newSicknessLevel = food_sickness_calculator:calculateNewFoodSicknessLevel(oldFoodSicknessLevel, percentage)
        if newSicknessLevel ~= oldFoodSicknessLevel then
            bodyDamage:setFoodSicknessLevel(newSicknessLevel)
        end
        if newSicknessLevel > oldFoodSicknessLevel then
             -- XXX: allow disabling of phrase
             local phrase_info_table = {}
             phrase_info_table.age = tostring(playerObj:getAge())
             phrase_info_table.name = playerObj:getName()
             phrase_info_table.item = itemName

             playerObj:Say("phrase_info_table: " .. tostring(phrase_info_table))
             local phrase = lactoseIntolerant.choosePhraseWithInterp(phrase_info_table)
             playerObj:Say("say phrases: " .. tostring(SandboxVars.lactoseIntolerant.SayPhrasesOnDairyConsumption))
             if phrase then
                playerObj:Say(phrase)
            end
        end
end


function lactoseIntolerant.overrideEatItem()
    ISInventoryPaneContextMenu.eatItem = lactoseIntolerant.eatItemWithLactoseIntoleranceTrait
end


function lactoseIntolerant.registerLactoseIntoleranceTrait()
    local lactose_intolerant_trait_point_cost = SandboxVars.lactoseIntolerant.PointCost
    TraitFactory.addTrait("lactoseIntolerant", getText("UI_trait_lactoseIntolerant"), lactose_intolerant_trait_point_cost, getText("UI_trait_lactoseIntolerantdesc"), false)
end

if not lactoseIntolerantOverrideSet then
    -- Is only boot needed?
    Events.OnGameBoot.Add(lactoseIntolerant.overrideEatItem)
    Events.OnGameStart.Add(lactoseIntolerant.overrideEatItem)
    Events.OnGameBoot.Add(lactoseIntolerant.registerLactoseIntoleranceTrait)
    Events.OnGameStart.Add(lactoseIntolerant.registerLactoseIntoleranceTrait)
    -- allow override
    -- XXX: uncomment before release
    -- lactoseIntolerantOverrideSet = true
end
