local json, web, comp = require("json"), require("web"), require("component")
local computer, serialization = require("computer"), require("serialization")
local true_keyboard, filesystem, event = require("keyboard"), require("filesystem"), require("event")
local botToken = "1865498062:AXASDasdadasda234542345"
local allowedIds = {
  559723688
}
local url = "https://api.telegram.org/bot" .. botToken .. "/"
local messages = {
  ru = {
    invalidPatternNameOrElse = "Случилась ошибка: не найден шаблон для крафта или поданы неправильные аргументы",
    nothingIsCrafting = "Ничего не крафтится (показывает только что заказано через телегу",
    stringA = "Сейчас крафтится\n",
    stringB = "Заказан ",
    stringC = "в количестве ",
    stringD = "\nСлотов использовано:",
    stringE = "Название | Кол-во | Доступен для крафта | ID | DMG\n",
    stringF = "Добавлено",
    stringG = "Удалено",
    statSlotsUsed = "Слотов использовано: ",
    statPatternsHave = "Из них имеет шаблон для воспроизводства: ",
    updateCache = "Обновить кэш предметов",
    updatedCache = "Кэш обновлен",
    stringCraftedOk = {
      "Заказ «",
      "» готов"
    },
    stringCraftedErr = {
      "Случилась ошибка при заказе «",
      "»: "
    },
    binds = "Бинды"
  },
  current = nil
}
messages.current = messages.ru
local craftingNow, tableToFile = { }, { }
table.split = function(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = { }
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end
tableToFile.load = function(location)
  local tableFile = assert(io.open(location))
  return serialization.unserialize(tableFile:read("*all"))
end
tableToFile.save = function(table, location)
  local tableFile = assert(io.open(location, "w"))
  tableFile:write(serialization.serialize(table))
  return tableFile:close()
end
local wrap_to_code
wrap_to_code = function(msg)
  return "<code> " .. tostring(msg) .. " </code>"
end
local isAllowed
isAllowed = function(_id)
  for _, id in ipairs(allowedIds) do
    if id == _id then
      return true
    end
  end
  return false
end
local InlineKeyboardButton
InlineKeyboardButton = function(text, url, callback_data)
  local x = { }
  if text then
    x.text = text
  else
    return nil
  end
  x.url = url
  x.callback_data = callback_data
  return x
end
local InlineKeyboardMarkup
InlineKeyboardMarkup = function(kbd)
  return json.encode({
    inline_keyboard = kbd
  })
end
local api_call
api_call = function(methodName, args)
  local pizda = web.serialize(args)
  local xyu = url .. methodName .. "?"
  return web.request(xyu .. pizda)
end
local generateCallbackData
generateCallbackData = function(...)
  local data = {
    ...
  }
  local x = data[1] .. ';'
  for i = 2, #data do
    x = x .. data[i]
  end
  return x
end
local answerCallbackQuery
answerCallbackQuery = function(callback_query_id, text, show_alert, url, cache_time)
  if not callback_query_id then
    return nil, "callback_query_id == nil"
  end
  return api_call("answerCallbackQuery", {
    callback_query_id = callback_query_id,
    text = text,
    show_alert = show_alert,
    url = url,
    cache_time = cache_time
  })
end
local reply
reply = function(_update, _text, _reply_markup)
  return api_call("sendMessage", {
    chat_id = _update.message.chat.id,
    text = _text,
    parse_mode = "HTML",
    reply_markup = _reply_markup
  })
end
local craftItem
craftItem = function(update, args)
  local _damage = tonumber(args[4])
  local item = comp.me_controller.getCraftables({
    name = args[2],
    damage = _damage
  })[1]
  local count = tonumber(args[3])
  if item and count then
    local craftable = item.request(count)
    local item_label = item.getItemStack().label
    reply(update, messages.current.stringB .. "«" .. item_label .. "»" .. messages.current.stringC .. count)
    return table.insert(craftingNow, {
      item = craftable,
      chat_id = update.message.chat.id,
      name = item_label,
      count = count
    })
  else
    return reply(update, wrap_to_code(messages.current.invalidPatternOrElse))
  end
end
local sendCurrentCraftingItems
sendCurrentCraftingItems = function(update)
  if #craftingNow == 0 then
    return reply(update, wrap_to_code(messages.current.nothingIsCrafting))
  end
  local msg = messages.current.stringA
  for i, v in ipairs(craftingNow) do
    msg = msg .. v.count .. " " .. v.name
  end
  return reply(update, msg)
end
local cacheTimeout = 1000
local cacheItems = {
  c = comp.me_controller.getCraftables(),
  i = comp.me_controller.getItemsInNetwork(),
  lastUpdate = os.time()
}
local updateCache
updateCache = function()
  print("updateCache()")
  cacheItems.c = comp.me_controller.getCraftables()
  cacheItems.i = comp.me_controller.getItemsInNetwork()
  cacheItems.lastUpdate = os.time()
end
local offset, offsetY = 1, 30
local craftOffset, craftOffsetY = 1, 30
local keyboard, ckeyboard = nil, nil
local updateCraftableItems
updateCraftableItems = function(update, to_next)
  if not ckeyboard then
    return 
  end
  if cacheItems.lastUpdate + cacheTimeout <= os.time() then
    updateCache()
  end
  local items_count = cacheItems.c.n
  if to_next then
    craftOffset = craftOffset + craftOffsetY
  else
    craftOffset = craftOffset - craftOffsetY
  end
  local msg = "Название | ID\n"
  for i = craftOffset, craftOffset + craftOffsetY do
    local item = cacheItems.c[i]
    if item then
      local stack = item.getItemStack()
      computer.pullSignal(0)
      msg = msg .. stack.label .. " " .. stack.name .. " " .. stack.damage .. '\n'
    end
  end
  msg = wrap_to_code(msg)
  return api_call("editMessageText", {
    chat_id = update.callback_query.message.chat.id,
    message_id = update.callback_query.message.message_id,
    text = msg,
    parse_mode = "HTML",
    reply_markup = ckeyboard
  })
end
local sendCraftableItems
sendCraftableItems = function(update)
  if cacheItems.lastUpdate + cacheTimeout <= os.time() then
    updateCache()
  end
  local msg = "Название | ID\n"
  if to_next then
    craftOffset = craftOffset + craftOffsetY
  else
    craftOffset = craftOffset - craftOffsetY
  end
  craftOffset = 1
  for i = craftOffset, craftOffset + craftOffsetY do
    local item = cacheItems.c[i]
    if item then
      local stack = item.getItemStack()
      computer.pullSignal(0)
      msg = msg .. stack.label .. " " .. stack.name .. " " .. stack.damage .. '\n'
    end
  end
  msg = wrap_to_code(msg .. messages.current.stringD .. cacheItems.c.n)
  ckeyboard = InlineKeyboardMarkup({
    {
      InlineKeyboardButton("<", nil, "sendCraftableItems;left;" .. update.message.message_id),
      InlineKeyboardButton(">", nil, "sendCraftableItems;right;" .. update.message.message_id)
    }
  })
  return reply(update, msg, ckeyboard)
end
local updateItems
updateItems = function(update, to_next)
  if not keyboard then
    return 
  end
  if cacheItems.lastUpdate + cacheTimeout <= os.time() then
    updateCache()
  end
  local items_count = cacheItems.i.n
  local msg = messages.current.stringE
  if to_next then
    offset = offset + offsetY
  else
    offset = offset - offsetY
  end
  for i = offset, offset + offsetY do
    local item = cacheItems.i[i]
    if item then
      msg = msg .. i .. ": " .. item.label .. ' ' .. item.size .. ' ' .. (item.isCraftable and "✅" or "💀")
      msg = msg .. " " .. item.name .. " " .. item.damage .. '\n'
      computer.pullSignal(0)
    end
  end
  msg = wrap_to_code(msg .. messages.current.stringD .. items_count)
  return api_call("editMessageText", {
    chat_id = update.callback_query.message.chat.id,
    message_id = update.callback_query.message.message_id,
    text = msg,
    parse_mode = "HTML",
    reply_markup = keyboard
  })
end
local sendItems
sendItems = function(update, args)
  local startTime = os.time()
  if cacheItems.lastUpdate + cacheTimeout <= os.time() then
    updateCache()
  end
  local items_count = cacheItems.i.n
  local msg = messages.current.stringE
  local splitNumber = tonumber(args[2]) or 0
  offset = 1
  for i = offset, offset + offsetY do
    local item = cacheItems.i[i]
    if item then
      msg = tostring(msg) .. " " .. tostring(i) .. ": " .. tostring(item.label) .. " " .. tostring(item.size) .. (item.isCraftable and "✅" or "💀")
      msg = tostring(msg) .. " {item.name} " .. tostring(item.damage) .. "\n"
      computer.pullSignal(0)
    end
  end
  msg = wrap_to_code(msg .. messages.current.stringD .. items_count)
  keyboard = InlineKeyboardMarkup({
    {
      InlineKeyboardButton("<", nil, "sendItems;left;" .. update.message.message_id),
      InlineKeyboardButton(">", nil, "sendItems;right;" .. update.message.message_id)
    }
  })
  return reply(update, msg, keyboard)
end
local binds = {
  ["chest"] = "minecraft:chest"
}
local addBind
addBind = function(update, args)
  binds[args[2]] = args[3]
  tableToFile.save(binds, "/binds.config")
  return reply(update, wrap_to_code('Добавлено'))
end
local removeBind
removeBind = function(update, args)
  if args[2] and binds[args[2]] then
    binds[args[2]] = nil
  end
  tableToFile.save(binds, "/binds.config")
  return reply(update, wrap_to_code("Удалено"))
end
local getBindList
getBindList = function(update)
  local msg = "Бинды\n"
  for k, v in pairs(binds) do
    msg = msg .. k .. ' = ' .. v .. '\n'
  end
  msg = wrap_to_code(msg)
  return reply(update, msg)
end
local getStat
getStat = function(update)
  local msg = ""
  local ramFree, ramTotal = computer.freeMemory(), computer.totalMemory()
  local ramFormatted = string.format("%.0f", ((ramTotal - ramFree) / ramTotal) * 100)
  msg = msg .. "[" .. ramFormatted .. "%" .. ']' .. math.floor((ramTotal - ramFree) / 1024) .. "KiB" .. '/' .. ramTotal / 1024 .. "KiB" .. '\n'
  msg = msg .. messages.current.statSlotsUsed .. cacheItems.i.n .. '\n'
  msg = msg .. messages.current.statPatternsHave .. cacheItems.c.n .. '\n'
  local kbd = InlineKeyboardMarkup({
    {
      InlineKeyboardButton(messages.current.updateCache, nil, "updateCache")
    },
    {
      InlineKeyboardButton("2", nil, "2;2"),
      InlineKeyboardButton("3", nil, "3;3")
    },
    {
      InlineKeyboardButton("STOP", nil, "STOP")
    }
  })
  return reply(update, msg, kbd)
end
local commands = {
  ["/start"] = function(update)
    return reply(update, "hehe")
  end,
  ["/stop"] = function(update)
    return reply(update, "closing...")(os.exit())
  end,
  ["/uptime"] = function(update)
    return reply(reply, computer.getArchitecture())
  end,
  ['/get_bind_list'] = getBindList,
  ['/add_bind'] = addBind,
  ['/rm_bind'] = removeBind,
  ["/craftable"] = sendCraftableItems,
  ["/items"] = sendItems,
  ["/craft"] = craftItem,
  ["/queue"] = sendCurrentCraftingItems,
  ["/update_cache"] = updateCache,
  ["/stat"] = getStat
}
local tg_update_id = 0
print(api_call("getUpdates", {
  offset = -1
}))
local logic
logic = function()
  local e, addr, x, keyCode, plyName = event.pull(0, "key_up")
  if keyCode == true_keyboard.keys.q then
    print("if keyCode == true_keyboard.keys.q then os.exit()")
    os.exit()
  end
  for i, item in ipairs(craftingNow) do
    local success, reason = item.item.isDone()
    if success then
      local msg = messages.current.stringCraftedOk[1] .. item.name .. messages.current.stringCraftedOk[2]
      api_call("sendMessage", {
        chat_id = item.chat_id,
        text = msg
      })
      craftingNow[i] = nil
    end
    if not success and reason then
      local msg = messages.current.stringCraftErr[1] .. item.name .. messages.current.stringCraftedErr[2] .. reason
      api_call("sendMessage", {
        chat_id = item.chat_id,
        text = msg
      })
      craftingNow[i] = nil
    end
  end
end
local processMessage
processMessage = function(update)
  if update.message.text and isAllowed(update.message.from.id) then
    local words = { }
    for substring in update.message.text:gmatch("%S+") do
      table.insert(words, substring)
    end
    if commands[words[1]] then
      return commands[words[1]](update, words)
    end
  end
end
local processCallbackQuery
processCallbackQuery = function(update)
  local callback_data = update.callback_query.data
  local x = table.split(callback_data, ';')
  if x[1] == "STOP" then
    answerCallbackQuery(update.callback_query.id)
    os.exit()
  end
  if x[1] == "sendItems" then
    updateItems(update, x[2] == "right" and true or false)
    answerCallbackQuery(update.callback_query.id)
  end
  if x[1] == "sendCraftableItems" then
    updateCraftableItems(update, x[2] == "right" and true or false)
    answerCallbackQuery(update.callback_query.id)
  end
  if x[1] == "updateCache" then
    updateCache()
    return answerCallbackQuery(update.callback_query.id, messages.current.updatedCache)
  end
end
local updates
updates = function()
  local res_raw = api_call("getUpdates", {
    offset = tg_update_id + 1,
    limit = 5
  })
  local res = json.decode(res_raw)
  for _, update in ipairs(res.result) do
    tg_update_id = update.update_id
    if update.message then
      processMessage(update)
    end
    if update.callback_query then
      processCallbackQuery(update)
    end
  end
end
print("Загружаем бинды... ")
if filesystem.exists("/binds.config") then
  binds = tableToFile.load("/binds.config")
end
for k, v in pairs(binds) do
  print(k, "", v)
end
while true do
  updates()
  logic()
end
