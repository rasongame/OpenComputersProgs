local component = require("component")
local event = require("event")

local pim = component.pim
local stacksToInsert = 2
local CHEST_SIDE = "west"
local FILLED_CHEST_SIDE = "north"
[[
    Для работы требуется OpenPeripheral
    В FILLED_CHEST сторону загружаете питательные баночки
    В CHEST сторону выкидываются использованные баночки

]] 
local chestCounter = 1
local function replaceCans(slot, i)
    pim.pushItemIntoSlot(CHEST_SIDE, i)
    pim.pullItemIntoSlot(FILLED_CHEST_SIDE, chestCounter, 64, i)
    chestCounter = chestCounter + 1

end
local function scanPlayer()
    while true do
        e, nick, uuid, addr = event.pull("player_on")
        print(nick)
        for i = 1, 40 do
            local slot = pim.getStackInSlot(i)
            if slot then
                if slot.display_name == "Tin Can" then
                    replaceCans(slot, i)
                end
            end
        end
    end
end
scanPlayer()