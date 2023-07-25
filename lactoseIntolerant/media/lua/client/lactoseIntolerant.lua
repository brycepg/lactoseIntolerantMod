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
        local shouldSayPhrase = (SandboxVars.lactoseIntolerant.SayPhrasesOnDairyConsumption
            and lactoseIntolerant.sayPhraseChance(ZombRand))
        lactoseIntolerant.eatItemWithLactoseIntoleranceTrait(item, percentage, playerObj, shouldSayPhrase)

end


function lactoseIntolerant.overrideEatItem()
    lactoseIntolerant.DEBUG = isDebug()
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
