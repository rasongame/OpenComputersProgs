json, web, comp = require("json"), require("web"), require("component")
computer, serialization = require("computer"), require("serialization")
true_keyboard, filesystem, event = require("keyboard"), require("filesystem"), require("event")
botToken = "1865498062:AXASDasdadasda234542345"

allowedIds = {
    559723688
}
url = "https://api.telegram.org/bot" .. botToken .. "/"
--
-- wget https://raw.githubusercontent.com/IgorTimofeev/MineOS/04b3ed60e770c724c4304610fddb1f36d4452bfc/lib/web.lua /lib/web.lua
-- wget https://raw.githubusercontent.com/rxi/json.lua/master/json.lua /lib/web.lua
-- wget 
--
messages = {
    ru: {
        invalidPatternNameOrElse: "Случилась ошибка: не найден шаблон для крафта или поданы неправильные аргументы",
        nothingIsCrafting: "Ничего не крафтится (показывает только что заказано через телегу",
        stringA: "Сейчас крафтится\n",
        stringB: "Заказан ", 
        stringC: "в количестве ", 
        stringD: "\nСлотов использовано:",
        stringE: "Название | Кол-во | Доступен для крафта | ID | DMG\n", 
        stringF: "Добавлено", 
        stringG: "Удалено",
        statSlotsUsed: "Слотов использовано: ",
        statPatternsHave: "Из них имеет шаблон для воспроизводства: ",
        updateCache: "Обновить кэш предметов",
        updatedCache: "Кэш обновлен",
        stringCraftedOk: {"Заказ «" , "» готов"},
        stringCraftedErr: {"Случилась ошибка при заказе «" , "»: "},
        binds: "Бинды",
    },
    current: nil
}
messages.current = messages.ru
-- messages.current = messages.ru

craftingNow, tableToFile = {}, {}
table.split = (inputstr, sep) -> 
    if sep == nil then
        sep = "%s"
    t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
 
    return t
 
tableToFile.load = (location) ->
  --returns a table stored in a file.
  tableFile = assert(io.open(location))
  return serialization.unserialize(tableFile\read("*all"))
 
tableToFile.save = (table, location) ->
  --saves a table to a file
  tableFile = assert(io.open(location, "w"))
  tableFile\write(serialization.serialize(table))
  tableFile\close()
wrap_to_code = (msg) -> "<code> #{msg} </code>"
isAllowed = (_id) ->
    for _, id in ipairs allowedIds
        if id == _id
            return true
    return false
 
InlineKeyboardButton = (text, url, callback_data) ->
    x = {}
    if text then x.text = text else return nil
    x.url = url
    x.callback_data = callback_data
    return x
InlineKeyboardMarkup = (kbd) ->
    json.encode {
        inline_keyboard: kbd
    }
api_call = (methodName, args) ->
    pizda = web.serialize(args)
    xyu = url..methodName.."?"
    return web.request(xyu..pizda)
generateCallbackData = (...) ->
    data = {...}
    x = data[1] .. ';'
    for i=2, #data
        x = x .. data[i]
 
    return x
answerCallbackQuery = (callback_query_id, text, show_alert, url, cache_time) ->
    if not callback_query_id then return nil, "callback_query_id == nil"
    return api_call("answerCallbackQuery", {
        callback_query_id: callback_query_id,
        text: text,
        show_alert: show_alert,
        url: url,
        cache_time: cache_time,
    })
 
reply = (_update, _text, _reply_markup) ->
    return api_call("sendMessage", {chat_id:_update.message.chat.id, text:_text, parse_mode:"HTML", reply_markup:_reply_markup})
 
craftItem = (update, args) ->
    _damage = tonumber(args[4])
    item = comp.me_controller.getCraftables({name:args[2], damage: _damage})[1]
    count = tonumber(args[3])
    if item and count then
        craftable = item.request(count)
        item_label = item.getItemStack().label
        reply(update, messages.current.stringB .. "«"..item_label.."»"..messages.current.stringC.. count)
        table.insert(craftingNow, {
            item:craftable,
            chat_id: update.message.chat.id,
            name: item_label,
            count: count
        }
        )
    else
        reply(update, wrap_to_code messages.current.invalidPatternOrElse )

sendCurrentCraftingItems = (update) ->
    if #craftingNow == 0 return reply(update, wrap_to_code messages.current.nothingIsCrafting)
    msg = messages.current.stringA
    for i, v in ipairs(craftingNow) do
        msg = msg .. v.count .. " " .. v.name
    reply(update, msg)
cacheTimeout = 1000
cacheItems = {
    c:comp.me_controller.getCraftables(),
    i:comp.me_controller.getItemsInNetwork(),
lastUpdate: os.time()}
updateCache =-> 
    print("updateCache()")
    cacheItems.c = comp.me_controller.getCraftables()
    cacheItems.i = comp.me_controller.getItemsInNetwork()
    cacheItems.lastUpdate = os.time()
 
 
offset, offsetY = 1, 30
craftOffset, craftOffsetY = 1, 30
keyboard, ckeyboard = nil, nil
updateCraftableItems = (update, to_next) ->
    if not ckeyboard then return
    if cacheItems.lastUpdate+cacheTimeout <= os.time() then updateCache()
    items_count = cacheItems.c.n
    if to_next then craftOffset = craftOffset + craftOffsetY else craftOffset = craftOffset - craftOffsetY
    msg = "Название | ID\n"
    for i=craftOffset, craftOffset+craftOffsetY do
        item = cacheItems.c[i]
        if item then
            stack = item.getItemStack()
            computer.pullSignal(0)
            msg = msg..stack.label .. " " .. stack.name .. " " .. stack.damage .. '\n'
 
    msg = wrap_to_code(msg)
    api_call("editMessageText", {
        chat_id:update.callback_query.message.chat.id,
        message_id:update.callback_query.message.message_id,
        text:msg,
        parse_mode:"HTML",
    reply_markup:ckeyboard}
    )
 
sendCraftableItems = (update) ->
    if cacheItems.lastUpdate+cacheTimeout <= os.time() then updateCache()
    msg = "Название | ID\n"
    if to_next then craftOffset = craftOffset + craftOffsetY else craftOffset = craftOffset - craftOffsetY
    craftOffset = 1
    for i=craftOffset, craftOffset+craftOffsetY do
        item = cacheItems.c[i]
        if item then
            stack = item.getItemStack()
            computer.pullSignal(0)
            msg = msg..stack.label .. " " .. stack.name .. " " .. stack.damage .. '\n'
    msg = wrap_to_code(msg .. messages.current.stringD .. cacheItems.c.n)
    ckeyboard = InlineKeyboardMarkup({{
        InlineKeyboardButton("<", nil, "sendCraftableItems;left;"..update.message.message_id),
    InlineKeyboardButton(">", nil, "sendCraftableItems;right;"..update.message.message_id)}})
 
    reply(update, msg, ckeyboard)
updateItems = (update, to_next) -> 
    if not keyboard then return
    if cacheItems.lastUpdate+cacheTimeout <= os.time() then updateCache()
    items_count = cacheItems.i.n
    msg = messages.current.stringE
    if to_next then offset = offset + offsetY else offset = offset - offsetY
    for i=offset, offset+offsetY do
        item = cacheItems.i[i]
        if item then
            msg = msg.. i .. ": "  .. item.label .. ' ' .. item.size ..' ' .. (item.isCraftable and "✅" or "💀")
            msg = msg.." "..item.name.." "..item.damage..'\n'
            computer.pullSignal(0)
    msg = wrap_to_code(msg..messages.current.stringD.. items_count)
    api_call("editMessageText", {
        chat_id:update.callback_query.message.chat.id,
        message_id:update.callback_query.message.message_id,
        text:msg,
        parse_mode:"HTML",
        reply_markup:keyboard}
    )
 
sendItems = (update, args) ->
    startTime = os.time()
    if cacheItems.lastUpdate+cacheTimeout <= os.time() then updateCache()
    items_count = cacheItems.i.n
    msg = messages.current.stringE
    splitNumber = tonumber(args[2]) or 0
    offset = 1
    for i=offset, offset+offsetY do
        item = cacheItems.i[i]
        if item then
            msg = "#{msg} #{i}: #{item.label} #{item.size}" .. (item.isCraftable and "✅" or "💀")
            msg = "#{msg} {item.name} #{item.damage}\n"
            computer.pullSignal(0)
 
    msg = wrap_to_code(msg..messages.current.stringD .. items_count)
    keyboard = InlineKeyboardMarkup({{
        InlineKeyboardButton("<", nil, "sendItems;left;"..update.message.message_id),
    InlineKeyboardButton(">", nil, "sendItems;right;"..update.message.message_id)}})
 
    reply(update, msg, keyboard)
binds = {
    "chest": "minecraft:chest"
}
 
addBind = (update, args) ->
    binds[args[2]] = args[3]
    tableToFile.save(binds, "/binds.config")
    reply(update, wrap_to_code('Добавлено'))
removeBind = (update, args) ->
    if args[2] and binds[args[2]] then
        binds[args[2]] = nil
    tableToFile.save(binds, "/binds.config")
    reply(update, wrap_to_code("Удалено"))
 
getBindList = (update) ->
    msg = "Бинды\n"
    for k, v in pairs(binds) do 
        msg = msg .. k .. ' = ' .. v .. '\n'
    msg = wrap_to_code(msg)
    reply(update, msg)
getStat = (update) ->
    msg = ""
    ramFree, ramTotal = computer.freeMemory(), computer.totalMemory()
    ramFormatted = string.format("%.0f", ((ramTotal-ramFree)/ramTotal) * 100)
 
    msg = msg .. "[" .. ramFormatted .. "%" .. ']' .. math.floor((ramTotal-ramFree) / 1024) .. "KiB" .. '/' .. ramTotal / 1024 .. "KiB" .. '\n'
    msg = msg .. messages.current.statSlotsUsed  .. cacheItems.i.n .. '\n'
    msg = msg .. messages.current.statPatternsHave .. cacheItems.c.n .. '\n'
 
    kbd = InlineKeyboardMarkup({
        {
            InlineKeyboardButton(messages.current.updateCache, nil, "updateCache" ), 
        },
        {
            InlineKeyboardButton("2", nil, "2;2" ), 
            InlineKeyboardButton("3", nil, "3;3" ), 
        }, {
            InlineKeyboardButton("STOP", nil, "STOP")
        }
        })
        -- kbd = json.encode(kbd)
 
    reply(update, msg, kbd)
 
commands = {
    ["/start"]: (update) -> reply(update, "hehe") ,
    ["/stop"]: (update) -> reply(update, "closing...") os.exit() ,
    ["/uptime"]: (update) -> reply(reply, computer.getArchitecture()),
    ['/get_bind_list']:getBindList,
    ['/add_bind']:addBind,
    ['/rm_bind']:removeBind,
    ["/craftable"]:sendCraftableItems,
    ["/items"]: sendItems,
    ["/craft"]: craftItem,
    ["/queue"]: sendCurrentCraftingItems,
    ["/update_cache"]: updateCache,
    ["/stat"]: getStat, 
}
tg_update_id = 0
print(api_call("getUpdates", {offset:-1}))
 
logic = ->
    e, addr, x, keyCode, plyName = event.pull(0, "key_up")
    if keyCode == true_keyboard.keys.q then
        print("if keyCode == true_keyboard.keys.q then os.exit()")
        os.exit()

    for i, item in ipairs(craftingNow)
        success, reason = item.item.isDone()
        if success then
            msg = messages.current.stringCraftedOk[1] .. item.name .. messages.current.stringCraftedOk[2]
            api_call("sendMessage", {chat_id:item.chat_id, text: msg})
            craftingNow[i]=nil
 
        if not success and reason then
            msg = messages.current.stringCraftErr[1] .. item.name .. messages.current.stringCraftedErr[2] .. reason
            api_call("sendMessage", {chat_id:item.chat_id, text:msg})
            craftingNow[i]=nil
 
processMessage = (update) ->
    if update.message.text and isAllowed(update.message.from.id) then
        words = {}
        for substring in update.message.text\gmatch "%S+" table.insert(words, substring)
        if commands[words[1]] then
            commands[words[1]](update, words)
 
processCallbackQuery = (update) ->
    callback_data = update.callback_query.data
    x = table.split(callback_data, ';')
    if x[1] == "STOP" then 
        answerCallbackQuery(update.callback_query.id)
        os.exit() 
    if x[1] == "sendItems" then
        updateItems(update, x[2] == "right" and true or false)
        answerCallbackQuery(update.callback_query.id) 
    if x[1] == "sendCraftableItems" then
        updateCraftableItems(update, x[2] == "right" and true or false)
        answerCallbackQuery(update.callback_query.id)
    if x[1] == "updateCache" then
        updateCache()
        answerCallbackQuery(update.callback_query.id, messages.current.updatedCache) 
 
updates = ->
    res_raw = api_call("getUpdates", {offset: tg_update_id+1, limit: 5})
    res = json.decode(res_raw)
 
    for _, update in ipairs(res.result) do
        tg_update_id = update.update_id
        if update.message then
            processMessage(update)
        if update.callback_query then
            processCallbackQuery(update)
 
print("Загружаем бинды... ")
 
if filesystem.exists("/binds.config") then
    binds = tableToFile.load("/binds.config")
 
for k, v in pairs(binds) do print(k, "", v)
while true do
    updates()
    logic()