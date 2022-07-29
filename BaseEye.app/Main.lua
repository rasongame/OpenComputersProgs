
-- Import libraries
local GUI = require("GUI")
local system = require("System")
local event = require("Event")
local filesystem = require("Filesystem")
local bridge = component.proxy(component.list("openperipheral_bridge")())
local me_controller = component.proxy(component.list("me_controller")())
local localization = system.getCurrentScriptLocalization()
local configPath = "/Glasses.cfg"
---------------------------------------------------------------------------------

-- Add a new window to MineOS workspace
local workspace, window, menu = system.addWindow(GUI.tabbedWindow(1, 1, 60, 20, 0xE1E1E1))

local layout, layout2 = nil, nil

local glassUpdateHandler = nil
local items, fluids = nil, nil
local updateDelay = 1
local useMESystem, useMEPowerSystem, useMECPUSystem = true, true, true
local useMEItemsSystem, useMEFluidsSystem, useShowRAMUsage = true, true, true

local function setDefaultParams()
    items = {
        {"IC2:itemOreIridium", 0},
        {"minecraft:diamond", 0}
    }
    fluids = {
        "creosote",
        "water",
        "bioethanol"
    }
end

if filesystem.exists(configPath) then
    local res, reason = filesystem.readTable(configPath)
    if res ~= nil then
        updateDelay = res["updateDelay"]
        items = res["items"]
        fluids = res["fluids"]
        useMESystem, useMEPowerSystem, useMECPUSystem = res["useMESystem"], res["useMEPowerSystem"], res["useMECPUSystem"]
        useMEItemsSystem, useMEFluidsSystem, useShowRAMUsage = res["useMEItemsSystem"], res["useMEFluidsSystem"], res["useShowRAMUsage"]
    else
        GUI.alert(localization.cantRestoreSettings) 
        setDefaultParams() 
    end

else setDefaultParams() end
local function getFluidAmount(fluidName) 
    for _, fluid in ipairs(me_controller.getFluidsInNetwork()) do
        if fluid.name == fluidName then
            return fluid.label, fluid.amount
        end
    end
    return nil, nil
end


local switches = {

    ["me_switch"]       = {
        GUI.switchAndLabel(1, 3, 45, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, localization.useMESystem, true),
        useMESystem
    },
    ["me_power_switch"] = {
        GUI.switchAndLabel(1, 5, 45, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, localization.useMEPowerSystem, true),
        useMEPowerSystem
    },
    ["me_cpu_switch"]   = {
        GUI.switchAndLabel(1, 7, 45, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, localization.useMECPUSystem, true),
        useMECPUSystem
    },
    ["me_items_switch"] = {
        GUI.switchAndLabel(1, 9, 45, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, localization.useMEItemsSystem, true),
        useMEItemsSystem
    },
    ["me_fluids_switch"] = {
        GUI.switchAndLabel(1, 11, 45, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, localization.useMEFluidsSystem, true),
        useMEFluidsSystem
    }
    
}
local function initShit2()

    layout2 = window:addChild(GUI.layout(1,3, window.width , window.height, 2, 1))
    local updateDelayInput = GUI.input(1, 1, 15, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", localization.inSeconds)
    local addFluidInput    = GUI.input(1, 1, 15, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", localization.FluidName)
    local addItemInput     = GUI.input(1, 1, 15, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", localization.ItemName)
    layout2:addChild(GUI.text(1, 1, 0x000000, localization.updateDelay))
    layout2:addChild(updateDelayInput)
    local btn = layout2:addChild(GUI.button(1,1, 10, 1, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.Change))
    btn.onTouch = function()
        updateDelay = tonumber(updateDelayInput.text)
        updateDelayInput.text = ""
    end
    layout2:addChild(GUI.text(1, 1, 0x000000, localization.FluidName))
    layout2:addChild(addFluidInput)
    local btn2 = layout2:addChild(GUI.button(1,1, 10, 1, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.Change))
    btn2.onTouch = function()
        local fluidLabel, _ = getFluidAmount(addFluidInput.text)
        if fluidLabel then
            table.insert(fluids, addFluidInput.text)
            
        else
            GUI.alert(localization.cantFindFluid)
        end
        addFluidInput.text = ""
    end
    layout2:addChild(GUI.text(1, 1, 0x000000, localization.ItemName))
    layout2:addChild(addItemInput)
    local btn3 = layout2:addChild(GUI.button(1,1, 10, 1, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.Change))
    btn3.onTouch = function()
        table.insert(items, {addItemInput.text, 0})
        addItemInput.text = ""
    end
    local save_btn = layout2:addChild(GUI.button(1,1, 10, 1, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.SaveToFile))
    save_btn.onTouch = function()
        local success, reason = filesystem.writeTable(configPath, {
            ["items"]=items,
            ["fluids"]=fluids,
            ["updateDelay"] = updateDelay,
            ["useMESystem"] = useMESystem,
            ["useMEPowerSystem"] = useMEPowerSystem,
            ["useMECPUSystem"] = useMECPUSystem,
            ["useMEItemsSystem"] = useMEItemsSystem,
            ["useMEFluidsSystem"] = useMEFluidsSystem,
            ["useShowRAMUsage"] = useShowRAMUsage
        })
        if not success then
            GUI.alert(success, reason)
        end

        
    end

    layout2:setPosition(2, 1, btn)
    layout2:setPosition(2, 1, btn2)
    layout2:setPosition(2, 1, btn3)
    layout2:update()
end 

local function initShit()
    layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))

    for k, v in pairs(switches) do
        layout:addChild(v[1])
        v[1].switch.onStateChanged = function(state)
            v[2] = not v[2]
        end
    end
end

initShit()
initShit2()

layout.hidden = false
layout2.hidden = true


local contextMenu = menu:addContextMenuItem("App")
contextMenu:addItem("Close").onTouch = function()
    event.removeHandler(glassUpdateHandler)
    bridge.clear()
    bridge.sync()
    window:remove()
end

-- Create callback function with resizing rules when window changes its' size
window.onResize = function(newWidth, newHeight)
    window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
    layout.width, layout.height = newWidth, newHeight
end

function addBox(x, y, w, h, color, tran)
    bridge.addBox(x, y, w, h, color, tran)
end

function addText(x, y, text, color)
    bridge.addText(x, y, text, color)
end

function addIcon(x, y, name, meta)
    bridge.addIcon(x, y, name, meta)
end
function addAllIcons(xStartPos, yStartPos)
    local indexY = 25
    for i = 1, #items do
        addIcon(0, yStartPos + indexY, items[i][1], items[i][2])
        indexY = indexY + 15
    end
end
function getSize(name,dmg)
    for _, item in ipairs(me_controller.getAvailableItems()) do
        if item.fingerprint.id == name and item.fingerprint.dmg == dmg then
            return item.size
        end
    end
    return 0
end

local function mePowerUsage()
    return {
        ["PowerInjection"]=me_controller.getAvgPowerInjection(),
        ["AvgPowerUsage"]=me_controller.getAvgPowerUsage(),
        ["IdlePowerUsage"]=me_controller.getIdlePowerUsage()
    }
end
local function meStoredPower()
    return {
        ["StoredPower"]=me_controller.getStoredPower(),
        ["MaxStoredPower"]=me_controller.getMaxStoredPower()
    }
end
local cpus = me_controller.getCpus()
local count_of_cpu = cpus["n"]
local function drawMECPUSystem(xStartPos, yStartPos)
    local indexY = 1
    for i=1, count_of_cpu do
        addText(xStartPos, yStartPos + indexY, "CPU NAME: " .. cpus[i]["name"], 0xFFFFFF)
        addText(xStartPos, yStartPos + indexY + 15, "BUSY: " .. tostring(cpus[i]["busy"]), 0xFFFFFF)
        indexY = indexY + 30
    end
end
local function drawMEPowerSystem(xStartPos, yStartPos)
    local i = yStartPos        
    local powerUsage = mePowerUsage()
    local powerStored = meStoredPower()
    for k, v in pairs(powerUsage) do
        addText(xStartPos, i, k .. ": " .. math.floor(v), 0xFFFFFF)
        i = i + 10
    end
    for k, v in pairs(powerStored) do
        addText(xStartPos, i, k .. ": " .. math.floor(v), 0x454341)
        i = i + 10
    end
end
local function drawMEItemsSystem(xStartPos, yStartPos)
    addAllIcons(xStartPos, yStartPos)
    local indexY = 30
    for i = 1, #items do
        addText(xStartPos + 15, yStartPos + indexY, getSize(items[i][1], items[i][2]), 0xFFFFFF)
        indexY = indexY + 15
    end
end

local function drawMEFluidsSystem(xStartPos, yStartPos)
    local indexY = 30
    for i = 1, #fluids do
        local fluidLabel, fluidAmount = getFluidAmount(fluids[i])
        if fluidLabel ~= nil then
            addText(xStartPos + 15, yStartPos + indexY, fluidLabel .. ": " .. fluidAmount / 1000 .. "B", 0xFFFFFF)
            indexY = indexY + 15
        end
    end
end

local function drawMESystem()
    if switches["me_power_switch"][2] then
        drawMEPowerSystem(1, 20)
    end
    if switches["me_cpu_switch"][2] then
        drawMECPUSystem(135, 10)
    end
    if switches["me_items_switch"][2] then
        drawMEItemsSystem(1, 70)
    end
    if switches["me_fluids_switch"][2] then
        drawMEFluidsSystem(50, 70)
    end
end

local function updateGlasses()
    bridge.clear()
    addText(1,1, "TI PIDOR", 0xFF0000)
    addText(1,10, "ME module activated: " .. tostring(useMESystem), 0xFFFFFF)
    if switches["me_switch"][2] then
        drawMESystem()
    end
    bridge.sync()
end
window.tabBar:addItem("Раз").onTouch = function()
    glassUpdateHandler = event.addHandler(updateGlasses, updateDelay)
    layout2.hidden = true
    layout.hidden = false
end
window.tabBar:addItem("Два").onTouch = function()
    event.removeHandler(glassUpdateHandler)
    layout2.hidden = false
    layout.hidden = true
end
glassUpdateHandler = event.addHandler(updateGlasses, updateDelay)

---------------------------------------------------------------------------------

-- Draw changes on screen after customizing your window
workspace:draw()
