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


--- XXX look into replacing this hook with a more robust one
local old_eatmenu = ISInventoryPaneContextMenu.eatItem


function lactoseIntolerant.eatItemHook(item, percentage, player)
        old_eatmenu(item, percentage, player)
        local playerObj = getPlayer(player)
        if not playerObj:HasTrait("lactoseIntolerant") then
            if lactoseIntolerant.DEBUG then
                playerObj:Say("I do not have lactose intolerance")
            end
            -- remove this check from chain, I think I can do this
            -- even with multiplayer since it is client sided code
            ISInventoryPaneContextMenu.eatItem = old_eatmenu
            return
        end
        local shouldSayPhrase = SandboxVars.lactoseIntolerant.SayPhrasesOnDairyConsumption
        eatItemWithLactoseIntoleranceTrait(item, percentage, playerObj, shouldSayPhrase)

end


function eatItemWithLactoseIntoleranceTrait(item, percentage, playerObj, shouldSayPhrase)
    ------------------ Sickness calculation ---------------
    --- mock playerObj
        --- haveExtraItems() -> bool
        --- getExtraItems -> JavaList
            --- size() -> number
            --- get() number -> TestItem
        --- getBodyDamage() -> BodyDamage
            --- getFoodSicknessLevel() -> number
            --- setFoodSicknessLevel() number ->
    --- add to TestItem
        --- getName() -> str
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
        shouldSayPhrase and
        newSicknessLevel > oldFoodSicknessLevel and
        lactoseIntolerant.skipPhraseChance(ZombRand)
    )
    if lactoseIntolerant.DEBUG then
        print("lactoseMod: AGE -> ", tostring(phrase_info.age))
        print("lactoseMod: NAME -> ", tostring(phrase_info.name))
        shouldSayPhrase = true
    end
    if shouldSayPhrase then
         phrase_info =  lactoseIntolerant.populatePhraseInfo(
             playerObj, item:getName()
         )
         local phraseString = lactoseIntolerant.choosePhraseWithInterp(
             phrase_info
         )
         if phraseString then
            playerObj:Say(phraseString)
        end
    end
end


function lactoseIntolerant.overrideEatItem()
    ISInventoryPaneContextMenu.eatItem = lactoseIntolerant.eatItemHook
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

Events.OnGameBoot.Add(lactoseIntolerant.overrideEatItem)
Events.OnGameBoot.Add(lactoseIntolerant.registerLactoseIntoleranceTrait)
