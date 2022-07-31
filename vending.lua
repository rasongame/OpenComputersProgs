local component = require("component")
local event = require("event")

local pim = component.pim
local CHEST_SIDE = "south"
local FILLED_CHEST_SIDE = "west"
local itemToReplaceDisplayName = "Tin Can"
local usingME = false
-- [[
--  Для работы требуется OpenPeripheral
--  В FILLED_CHEST сторону загружаете питательные баночки
--  В CHEST сторону выкидываются использованные баночки 
-- ]
local chestSlot = 1
local chestSlotLimit = 27
local function replaceCans(slot, i) -- return boolean success
    local pushRes = pim.pushItemIntoSlot(CHEST_SIDE, i)
    if pushRes == 0 then return false end -- Если ничё не получилось спихнуть в сундук - сундук полный, а сами не можем положить туда же
    pim.pullItemIntoSlot(FILLED_CHEST_SIDE, chestSlot, slot.qty, i)
    if not usingME then 
        if chestSlot < chestSlotLimit then
            chestSlot = chestSlot + 1 
        else
            print("chestSlot = " .. chestSlot .. " :: Возврат на первую позицию")
            chestSlot = 1
        end
    end
    return true
end
local function scanPlayer()
    while true do
        e, nick, uuid, addr = event.pull("player_on")
        local replacedCansCount = 0
        print(nick)
        for i = 1, 40 do
            local slot = pim.getStackInSlot(i)
            if slot then
                if slot.display_name == itemToReplaceDisplayName then
                    if replaceCans(slot, i) then 
                        replacedCansCount = replacedCansCount + slot.qty 
                    end

                end
            end
        end
        print("Затрачено " .. replacedCansCount .. " банок")
    end
end
scanPlayer()
