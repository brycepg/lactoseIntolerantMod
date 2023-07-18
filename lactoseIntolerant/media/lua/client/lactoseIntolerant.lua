-- This file contains code which does IO with project zomboid

--------------------------------------------------------------
require 'lactoseIntolerantCore'

-- playtest out stir fry nasua
--
-- Q: How do I get the code to run ONLY if the eating action is completed?
-- | Is partial eating a thing?
-- | Modify event or action?

-- Q: Do I need to specify both on game boot and on game start?
-- Q: Does it work in multiplayer?

-- DONE: Add nasuea for foods with cheese in it such as a stirfry with cheese
-- DONE: playtest allow phrases to be disableable


--------------------------------------------------------------
-------------------- Function override -----------------------
--------------------------------------------------------------

local old_eatmenu = ISInventoryPaneContextMenu.eatItem
local lactoseIntolerantOverrideSet = false


function lactoseIntolerant.eatItemWithLactoseIntoleranceTrait(item, percentage, player)
        old_eatmenu(item, percentage, player)
        local playerObj = getPlayer(player)
        if not playerObj:HasTrait("lactoseIntolerant") then
            playerObj:Say("I do not have lactose intolerance")
            -- remove this check from chain, I think I can do this
            -- even with multiplayer since it is client sided code
            ISInventoryPaneContextMenu.eatItem = old_eatmenu
            return
        end

        ------------------ Sickness calculation ---------------
        local bodyDamage = playerObj:getBodyDamage()
        local oldFoodSicknessLevel = bodyDamage:getFoodSicknessLevel()
        local fsc = foodSicknessCalculatorForLactose(item)
        local newSicknessLevel = fsc:calculateNewSicknessLevel(
            oldFoodSicknessLevel, percentage
        )
        if newSicknessLevel ~= oldFoodSicknessLevel then
            bodyDamage:setFoodSicknessLevel(newSicknessLevel)
        end

        ------------------- Phrase code -----------------------
        shouldSayPhrase = (
            SandboxVars.lactoseIntolerant.SayPhrasesOnDairyConsumption and
            newSicknessLevel > oldFoodSicknessLevel and
            lactoseIntolerant.skipPhraseChance(ZombRand)
        )
        if lactoseIntolerant.DEBUG then
            shouldSayPhrase = true
        end
        if shouldSayPhrase then
             phrase_info =  lactoseIntolerant.populatePhraseInfo(
                 playerObj, itemName
             )
             print("lactoseMod: AGE -> ", tostring(phrase_info.age))
             print("lactoseMod: NAME -> ", tostring(phrase_info.name))
             local phraseString = lactoseIntolerant.choosePhraseWithInterp(
                 phrase_info_table
             )
             if phrase then
                playerObj:Say(phrase)
            end
        end
end

function lactoseIntolerant.overrideEatItem()
    ISInventoryPaneContextMenu.eatItem = lactoseIntolerant.eatItemWithLactoseIntoleranceTrait
end


--------------------------------------------------------------
----------------------- Trait registration  ------------------
--------------------------------------------------------------

function lactoseIntolerant.registerLactoseIntoleranceTrait()
    local lactose_intolerant_trait_point_cost = -1
    -- not sure how to make point cost configurable, not worth it
    -- local lactose_intolerant_trait_point_cost = SandboxVars.lactoseIntolerant.PointCost
    TraitFactory.addTrait("lactoseIntolerant", getText("UI_trait_lactoseIntolerant"), lactose_intolerant_trait_point_cost, getText("UI_trait_lactoseIntolerantdesc"), false)
end


---------------------------------------------------------------
------------------------- Main --------------------------------
--------------------------------------------------------------
-- These are the entry points for this mod

-- 1. override function.
-- this over ride function calls the old function to preserve
-- functionality and the ability of other mods to add to this
-- chain
-- 2. trait registration
-- This allows the trait to show up during character selection

if not lactoseIntolerantOverrideSet then
    -- Is only boot needed?
    Events.OnGameBoot.Add(lactoseIntolerant.overrideEatItem)
    Events.OnGameBoot.Add(lactoseIntolerant.registerLactoseIntoleranceTrait)
    -- allow override
    -- XXX: uncomment before release
    -- lactoseIntolerantOverrideSet = true
end
