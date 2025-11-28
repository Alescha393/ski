-- Бот-статистик для ComputerCraft
-- Advanced Computer required

-- Настройки
local updateInterval = 2 -- секунды
local themeColor = colors.blue
local accentColor = colors.orange
local warningColor = colors.red
local successColor = colors.green

-- Данные о местоположении (можно настроить вручную)
local locationData = {
    name = "База Альфа",
    biome = "Лес",
    dimension = "Overworld",
    x = 0,
    y = 0,
    z = 0,
    fuelLevel = 0
}

-- Инициализация
if not term.isColor() then
    print("Требуется advanced computer!")
    return
end

term.clear()
term.setCursorPos(1,1)

-- Функции получения данных
local function getTimeData()
    local time = os.time()
    local day = os.day()
    
    local hour = math.floor((time / 1000) % 24)
    local minute = math.floor((time % 1000) / 1000 * 60)
    
    local timeString = string.format("%02d:%02d", hour, minute)
    local dayString = "День " .. day
    
    local timeOfDay
    if hour >= 6 and hour < 12 then
        timeOfDay = "🌅 Утро"
    elseif hour >= 12 and hour < 18 then
        timeOfDay = "☀️ День"
    elseif hour >= 18 and hour < 22 then
        timeOfDay = "🌇 Вечер"
    else
        timeOfDay = "🌙 Ночь"
    end
    
    return {
        time = timeString,
        day = dayString,
        period = timeOfDay,
        isNight = hour < 6 or hour >= 22
    }
end

local function getWeatherData()
    -- В Minecraft ComputerCraft нет реальных данных о погоде
    -- Генерируем псевдослучайную погоду на основе времени
    local time = os.time()
    local weatherTypes = {
        {name = "☀️ Ясно", color = colors.yellow},
        {name = "⛅ Облачно", color = colors.white},
        {name = "🌧️ Дождь", color = colors.blue},
        {name = "⛈️ Гроза", color = colors.purple},
        {name = "❄️ Снег", color = colors.cyan}
    }
    
    math.randomseed(time)
    local weather = weatherTypes[math.random(1, #weatherTypes)]
    
    -- Ночью увеличиваем вероятность ясной погоды
    local timeData = getTimeData()
    if timeData.isNight and weather.name ~= "☀️ Ясно" then
        if math.random(1, 3) == 1 then
            weather = weatherTypes[1]
        end
    end
    
    return weather
end

local function getSystemData()
    local freeDisk = 0
    local usedDisk = 0
    
    -- Получаем информацию о диске
    if fs.getFreeSpace and fs.getCapacity then
        freeDisk = fs.getFreeSpace("/")
        usedDisk = fs.getCapacity("/") - freeDisk
    end
    
    local uptime = os.clock()
    local uptimeString = string.format("%.1f сек", uptime)
    
    return {
        diskFree = freeDisk,
        diskUsed = usedDisk,
        uptime = uptimeString
    }
end

local function getLocationData()
    -- Обновляем координаты если это turtle
    if turtle then
        locationData.x, locationData.y, locationData.z = gps.locate() or locationData.x, locationData.y, locationData.z
        locationData.fuelLevel = turtle.getFuelLevel()
    else
        -- Для компьютера используем фиктивные координаты или GPS
        if peripheral.find("modem") then
            local modem = peripheral.find("modem")
            if modem then
                locationData.x, locationData.y, locationData.z = gps.locate() or locationData.x, locationData.y, locationData.z
            end
        end
    end
    
    return locationData
end

-- Функции отрисовки интерфейса
local function drawBox(x, y, width, height, color, title)
    term.setBackgroundColor(color)
    
    -- Верхняя граница
    term.setCursorPos(x, y)
    term.write("╔" .. string.rep("═", width - 2) .. "╗")
    
    -- Заголовок
    if title then
        term.setCursorPos(x + 2, y)
        term.write(" " .. title .. " ")
    end
    
    -- Боковые границы и заполнение
    for i = 1, height - 2 do
        term.setCursorPos(x, y + i)
        term.write("║")
        term.setCursorPos(x + width - 1, y + i)
        term.write("║")
        term.write(string.rep(" ", width - 2))
    end
    
    -- Нижняя граница
    term.setCursorPos(x, y + height - 1)
    term.write("╚" .. string.rep("═", width - 2) .. "╝")
    
    term.setBackgroundColor(colors.black)
end

local function drawProgressBar(x, y, width, value, maxValue, color)
    local fillWidth = math.floor((value / maxValue) * (width - 2))
    
    term.setCursorPos(x, y)
    term.write("[")
    
    term.setBackgroundColor(color)
    term.write(string.rep(" ", fillWidth))
    term.setBackgroundColor(colors.black)
    term.write(string.rep(" ", width - 2 - fillWidth))
    term.write("]")
    
    -- Процент
    local percent = math.floor((value / maxValue) * 100)
    term.setCursorPos(x + width + 2, y)
    term.write(percent .. "%")
end

local function drawInterface()
    local width, height = term.getSize()
    
    -- Очистка экрана
    term.setBackgroundColor(colors.black)
    term.clear()
    
    -- Заголовок
    term.setTextColor(themeColor)
    term.setCursorPos(1, 1)
    term.write("╔══════════════════════════════════════╗")
    term.setCursorPos(1, 2)
    term.write("║          БОТ-СТАТИСТИК v1.0         ║")
    term.setCursorPos(1, 3)
    term.write("╚══════════════════════════════════════╝")
    
    -- Получение данных
    local timeData = getTimeData()
    local weatherData = getWeatherData()
    local systemData = getSystemData()
    local location = getLocationData()
    
    -- Блок времени и даты
    drawBox(2, 5, 36, 6, colors.gray, "⏰ ВРЕМЯ И ДАТА")
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 6)
    term.write("Время: ")
    term.setTextColor(accentColor)
    term.write(timeData.time)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 7)
    term.write("Дата: ")
    term.setTextColor(accentColor)
    term.write(timeData.day)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 8)
    term.write("Период: ")
    term.setTextColor(weatherData.color)
    term.write(timeData.period)
    
    -- Блок погоды
    drawBox(40, 5, 36, 6, colors.gray, weatherData.name)
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 6)
    term.write("Состояние: ")
    term.setTextColor(weatherData.color)
    term.write(weatherData.name)
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 7)
    term.write("Температура: ")
    term.setTextColor(accentColor)
    term.write(math.random(15, 25) .. "°C")
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 8)
    term.write("Влажность: ")
    term.setTextColor(accentColor)
    term.write(math.random(40, 90) .. "%")
    
    -- Блок местоположения
    drawBox(2, 12, 36, 8, colors.gray, "📍 МЕСТОПОЛОЖЕНИЕ")
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 13)
    term.write("Название: ")
    term.setTextColor(accentColor)
    term.write(location.name)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 14)
    term.write("Биом: ")
    term.setTextColor(accentColor)
    term.write(location.biome)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 15)
    term.write("Измерение: ")
    term.setTextColor(accentColor)
    term.write(location.dimension)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 16)
    term.write("Координаты: ")
    term.setTextColor(accentColor)
    term.write(string.format("X:%d Y:%d Z:%d", location.x, location.y, location.z))
    
    if location.fuelLevel > 0 then
        term.setTextColor(colors.white)
        term.setCursorPos(4, 17)
        term.write("Топливо: ")
        drawProgressBar(13, 17, 15, location.fuelLevel, 10000, successColor)
    end
    
    -- Блок системы
    drawBox(40, 12, 36, 8, colors.gray, "💻 СИСТЕМА")
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 13)
    term.write("Аптайм: ")
    term.setTextColor(accentColor)
    term.write(systemData.uptime)
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 14)
    term.write("Память: ")
    if systemData.diskUsed > 0 then
        local total = systemData.diskUsed + systemData.diskFree
        drawProgressBar(50, 14, 20, systemData.diskUsed, total, themeColor)
    else
        term.setTextColor(accentColor)
        term.write("Недоступно")
    end
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 15)
    term.write("Тип: ")
    term.setTextColor(accentColor)
    if turtle then
        term.write("Черепаха")
    else
        term.write("Компьютер")
    end
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 16)
    term.write("ID: ")
    term.setTextColor(accentColor)
    term.write(os.getComputerID())
    
    -- Статус бар внизу
    term.setBackgroundColor(themeColor)
    term.setCursorPos(1, height)
    local statusText = "🔄 Обновление через " .. updateInterval .. " сек | Q - Выход | R - Обновить вручную"
    term.write(statusText .. string.rep(" ", width - #statusText))
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

-- Основной цикл
local function main()
    local lastUpdate = os.clock()
    
    while true do
        local currentTime = os.clock()
        
        -- Автоматическое обновление
        if currentTime - lastUpdate >= updateInterval then
            drawInterface()
            lastUpdate = currentTime
        end
        
        -- Обработка ввода
        local event, key = os.pullEvent(0.5) -- Неблокирующее ожидание
        
        if event == "key" then
            if key == keys.q then
                term.clear()
                term.setCursorPos(1, 1)
                print("Бот-статистик завершил работу")
                return
            elseif key == keys.r then
                drawInterface()
                lastUpdate = currentTime
            end
        end
    end
end

-- Запуск программы
term.clear()
print("Загрузка бота-статистика...")
sleep(1)

-- Проверка GPS
if not peripheral.find("modem") and not turtle then
    print("⚠️  Внимание: GPS недоступен")
    print("Координаты будут статичными")
    sleep(2)
end

main()
