local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc

local translations = {}
local current

translations.enUS = {
    ["Сейчас"] = "Now",
    ["Цена"] = "Price",
    ["Среднее"] = "Average",
    ["Лотов"] = "Listings",
    ["Скан"] = "Scan",
    ["нет данных"] = "no data",
    ["не было в продаже"] = "not listed",
    ["только что"] = "just now",
    ["%d мин назад"] = "%d min ago",
    ["%d ч назад"] = "%d h ago",
    ["%d дн назад"] = "%d d ago",
    ["дороже среднего на %d%%"] = "%d%% above average",
    ["дешевле среднего на %d%%"] = "%d%% below average",
    ["на уровне среднего"] = "at average",
    ["в среднем %d"] = "%d on average",
    ["Откройте окно аукциона"] = "Open the auction house first",
    ["Скан начат, не закрывайте окно аукциона"] = "Scan started, keep the auction window open",
    ["Скан уже идёт"] = "A scan is already running",
    ["Собрано лотов: %d"] = "Collected %d listings",
    ["Скан завершён:"] = "Scan complete:",
    ["Частичный просмотр учтён:"] = "Partial browse recorded:",
    ["сканов: %d, предметов: %d, последний скан: %s"] = "scans: %d, items: %d, last scan: %s",
    ["в списке: %d"] = "listed: %d",
    ["Предмет"] = "Item",
    ["Среднее"] = "Average",
    ["Лотов"] = "Qty",
    ["Сканировать"] = "Scan",
    ["Настройки"] = "Settings",
    ["Список"] = "List",
    ["Поиск"] = "Search",
    ["выберите предмет"] = "select an item",
    ["День"] = "Day",
    ["Неделя"] = "Week",
    ["Месяц"] = "Month",
    ["нет данных за этот период"] = "no data for this period",
    ["дней с данными: %d"] = "days with data: %d",
    ["сканов не было"] = "no scans",
    ["цена последнего скана дня, всего сканов:"] = "last scan of the day, scans:",
    ["Показывать историю в подсказках"] = "Show history in tooltips",
    ["Сканировать автоматически"] = "Scan automatically",
    ["Показывать количество лотов"] = "Show listing counts",
    ["Учитывать данные Auctionator"] = "Use Auctionator data",
    ["Хранить сканов: %d"] = "Keep %d scans",
    ["Забывать предмет через %d дн"] = "Forget an item after %d d",
    ["Автоскан не чаще раза в %d мин"] = "Auto scan at most every %d min",
    ["Стереть историю"] = "Wipe history",
    ["модуль истории не загрузился, проверьте ошибки Lua"] = "the history module failed to load, check for Lua errors",
    ["Окно включено"] = "Window enabled",
    ["Окно выключено"] = "Window disabled",
    ["/auc window — окно у аукциона вкл/выкл"] = "/auc window - toggle the auction window",
    ["никогда"] = "never",
    ["История очищена"] = "History cleared",
    ["Глубина истории: %d сканов"] = "History depth: %d scans",
    ["Укажите число от 2 до 30"] = "Enter a number from 2 to 30",
    ["Удалено предметов: %d"] = "Items removed: %d",
    ["Срок хранения: %d дней"] = "Retention: %d days",
    ["Укажите число от 1 до 365"] = "Enter a number from 1 to 365",
    ["Подсказки включены"] = "Tooltips enabled",
    ["Подсказки выключены"] = "Tooltips disabled",
    ["Автоскан включён"] = "Auto scan enabled",
    ["Автоскан выключен"] = "Auto scan disabled",
    ["Команды:"] = "Commands:",
    ["/auc — состояние"] = "/auc - status",
    ["/auc scan — полный скан аукциона"] = "/auc scan - full auction scan",
    ["/auc keep <n> — сколько сканов хранить"] = "/auc keep <n> - how many scans to keep",
    ["/auc days <n> — через сколько дней забывать предмет"] = "/auc days <n> - forget an item after n days",
    ["/auc tooltip — подсказки вкл/выкл"] = "/auc tooltip - toggle tooltips",
    ["/auc auto — автоскан вкл/выкл"] = "/auc auto - toggle auto scan",
    ["/auc clear — стереть историю"] = "/auc clear - wipe history",
    ["за %d дн (Auctionator)"] = "over %d d (Auctionator)",
}

NS.L = setmetatable({}, {
    __index = function(_, key)
        if current then
            local text = current[key]
            if text then return text end
        end
        return key
    end,
    __newindex = function()
        error("NS.L — таблица только для чтения")
    end,
})

function NS.ResolveLocale(key)
    if key == "ruRU" or key == "enUS" then
        return key
    end
    local client = GetLocale and GetLocale() or "enUS"
    return client == "ruRU" and "ruRU" or "enUS"
end

function NS.ApplyLocale(key)
    local resolved = NS.ResolveLocale(key)
    NS.localeKey = resolved
    current = resolved ~= "ruRU" and translations.enUS or nil
end
