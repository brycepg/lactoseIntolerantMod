require 'lactoseIntolerantCore'

-- How do I get the code to run ONLY if the eating action is completed?
-- | Is partial eating a thing?
-- | Modify event or action?


--
-- DONE: Add nasuea for foods with cheese in it such as a stirfry with cheese
    -- What functions describe the contents of an edible item? getExtraItems
-- playtest out stir fry nasua
-- Do I need to specify both on game boot and on game start
-- Test sandbox option for trait points (default: +1)
-- implement allow phrases to be disableable
local old_eatmenu = ISInventoryPaneContextMenu.eatItem
local lactoseIntolerantOverrideSet = false


function eatItemWithLactoseIntoleranceTrait(item, percentage, player)
        print("Testing out the print function wubba lubba dub dub")
        old_eatmenu(item, percentage, player)
        local playerObj = getPlayer(player)
        if not playerObj:HasTrait("lactoseIntolerant") then
            playerObj:Say("I do not have lactose intolerance")
            ISInventoryPaneContextMenu.eatItem = old_eatmenu
            return
        end
        local sayPhrase = false

        local bodyDamage = playerObj:getBodyDamage()
        local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()

        local haveExtraItems = item:haveExtraItems()

        if haveExtraItems then

            local extraItems = item:getExtraItems()
            local itemArray = zombListToLuaArray(extraItems)
            newSicknessLevel = calculateNewFoodSicknessLevelList(itemArray, oldFoodSicknessLevel, percentage)
            bodyDamage:setFoodSicknessLevel(newSicknessLevel);
            sayPhrase = true
        else

            itemName = item:getName()
            playerObj:Say("Eating: " .. itemName)

            if foodContainsLactose(itemName) then
                -- lets refactor this so I can use it for get extraItems
                 local newSicknessLevel = calculateNewFoodSicknessLevel(oldFoodSicknessLevel, percentage, ZombRand)
                 bodyDamage:setFoodSicknessLevel(newSicknessLevel);
                 sayPhrase = true
             end
        end

         if sayPhrase then

             -- allow disabling of phrase
             local phrase_info_table = {}
             phrase_info_table.age = tostring(playerObj:getAge())
             phrase_info_table.name = playerObj:getName()
             phrase_info_table.item = itemName

             playerObj:Say("phrase_info_table: " .. tostring(phrase_info_table))
             local phrase = choosePhraseWithInterp(phrase_info_table)
             playerObj:Say("say phrases: " .. tostring(SandboxVars.lactoseIntolerant.SayPhrasesOnDairyConsumption))

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
