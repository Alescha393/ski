-- Bot Statistic for ComputerCraft
-- Advanced Computer required

local updateInterval = 2
local themeColor = colors.blue
local accentColor = colors.orange

local locationData = {
    name = "Base Alpha",
    biome = "Forest", 
    dimension = "Overworld",
    x = 0,
    y = 0,
    z = 0,
    fuelLevel = 0
}

if not term.isColor() then
    print("Need advanced computer!")
    return
end

term.clear()
term.setCursorPos(1,1)

local function getTimeData()
    local time = os.time()
    local day = os.day()
    local hour = math.floor((time / 1000) % 24)
    local minute = math.floor((time % 1000) / 1000 * 60)
    local timeString = string.format("%02d:%02d", hour, minute)
    local dayString = "Day " .. day
    
    local timeOfDay
    if hour >= 6 and hour < 12 then
        timeOfDay = "Morning"
    elseif hour >= 12 and hour < 18 then
        timeOfDay = "Day"
    elseif hour >= 18 and hour < 22 then
        timeOfDay = "Evening"
    else
        timeOfDay = "Night"
    end
    
    return {
        time = timeString,
        day = dayString,
        period = timeOfDay,
        isNight = hour < 6 or hour >= 22
    }
end

local function getWeatherData()
    local time = os.time()
    local weatherTypes = {
        {name = "Clear", color = colors.yellow},
        {name = "Cloudy", color = colors.white},
        {name = "Rain", color = colors.blue},
        {name = "Storm", color = colors.purple},
        {name = "Snow", color = colors.cyan}
    }
    
    math.randomseed(time)
    local weather = weatherTypes[math.random(1, #weatherTypes)]
    
    local timeData = getTimeData()
    if timeData.isNight and weather.name ~= "Clear" then
        if math.random(1, 3) == 1 then
            weather = weatherTypes[1]
        end
    end
    
    return weather
end

local function getSystemData()
    local freeDisk = 0
    local usedDisk = 0
    
    if fs.getFreeSpace and fs.getCapacity then
        freeDisk = fs.getFreeSpace("/")
        usedDisk = fs.getCapacity("/") - freeDisk
    end
    
    local uptime = os.clock()
    local uptimeString = string.format("%.1f sec", uptime)
    
    return {
        diskFree = freeDisk,
        diskUsed = usedDisk,
        uptime = uptimeString
    }
end

local function getLocationData()
    if turtle then
        locationData.x, locationData.y, locationData.z = gps.locate() or locationData.x, locationData.y, locationData.z
        locationData.fuelLevel = turtle.getFuelLevel()
    else
        if peripheral.find("modem") then
            local modem = peripheral.find("modem")
            if modem then
                locationData.x, locationData.y, locationData.z = gps.locate() or locationData.x, locationData.y, locationData.z
            end
        end
    end
    
    return locationData
end

local function drawBox(x, y, width, height, color, title)
    term.setBackgroundColor(color)
    
    term.setCursorPos(x, y)
    term.write("+" .. string.rep("-", width - 2) .. "+")
    
    if title then
        term.setCursorPos(x + 2, y)
        term.write(" " .. title .. " ")
    end
    
    for i = 1, height - 2 do
        term.setCursorPos(x, y + i)
        term.write("|")
        term.setCursorPos(x + width - 1, y + i)
        term.write("|")
        term.write(string.rep(" ", width - 2))
    end
    
    term.setCursorPos(x, y + height - 1)
    term.write("+" .. string.rep("-", width - 2) .. "+")
    
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
    
    local percent = math.floor((value / maxValue) * 100)
    term.setCursorPos(x + width + 2, y)
    term.write(percent .. "%")
end

local function drawInterface()
    local width, height = term.getSize()
    
    term.setBackgroundColor(colors.black)
    term.clear()
    
    term.setTextColor(themeColor)
    term.setCursorPos(1, 1)
    term.write("====================================")
    term.setCursorPos(1, 2)
    term.write("      BOT STATISTIC v1.0           ")
    term.setCursorPos(1, 3)
    term.write("====================================")
    
    local timeData = getTimeData()
    local weatherData = getWeatherData()
    local systemData = getSystemData()
    local location = getLocationData()
    
    drawBox(2, 5, 36, 6, colors.gray, "TIME AND DATE")
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 6)
    term.write("Time: ")
    term.setTextColor(accentColor)
    term.write(timeData.time)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 7)
    term.write("Date: ")
    term.setTextColor(accentColor)
    term.write(timeData.day)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 8)
    term.write("Period: ")
    term.setTextColor(weatherData.color)
    term.write(timeData.period)
    
    drawBox(40, 5, 36, 6, colors.gray, weatherData.name)
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 6)
    term.write("Weather: ")
    term.setTextColor(weatherData.color)
    term.write(weatherData.name)
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 7)
    term.write("Temp: ")
    term.setTextColor(accentColor)
    term.write(math.random(15, 25) .. "C")
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 8)
    term.write("Humidity: ")
    term.setTextColor(accentColor)
    term.write(math.random(40, 90) .. "%")
    
    drawBox(2, 12, 36, 8, colors.gray, "LOCATION")
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 13)
    term.write("Name: ")
    term.setTextColor(accentColor)
    term.write(location.name)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 14)
    term.write("Biome: ")
    term.setTextColor(accentColor)
    term.write(location.biome)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 15)
    term.write("Dimension: ")
    term.setTextColor(accentColor)
    term.write(location.dimension)
    
    term.setTextColor(colors.white)
    term.setCursorPos(4, 16)
    term.write("Coords: ")
    term.setTextColor(accentColor)
    term.write(string.format("X:%d Y:%d Z:%d", location.x, location.y, location.z))
    
    if location.fuelLevel > 0 then
        term.setTextColor(colors.white)
        term.setCursorPos(4, 17)
        term.write("Fuel: ")
        drawProgressBar(10, 17, 15, location.fuelLevel, 10000, colors.green)
    end
    
    drawBox(40, 12, 36, 8, colors.gray, "SYSTEM")
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 13)
    term.write("Uptime: ")
    term.setTextColor(accentColor)
    term.write(systemData.uptime)
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 14)
    term.write("Memory: ")
    if systemData.diskUsed > 0 then
        local total = systemData.diskUsed + systemData.diskFree
        drawProgressBar(50, 14, 20, systemData.diskUsed, total, themeColor)
    else
        term.setTextColor(accentColor)
        term.write("Not available")
    end
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 15)
    term.write("Type: ")
    term.setTextColor(accentColor)
    if turtle then
        term.write("Turtle")
    else
        term.write("Computer")
    end
    
    term.setTextColor(colors.white)
    term.setCursorPos(42, 16)
    term.write("ID: ")
    term.setTextColor(accentColor)
    term.write(os.getComputerID())
    
    term.setBackgroundColor(themeColor)
    term.setCursorPos(1, height)
    local statusText = "Update in " .. updateInterval .. " sec | Q - Exit | R - Refresh"
    term.write(statusText .. string.rep(" ", width - #statusText))
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

local function main()
    local lastUpdate = os.clock()
    
    while true do
        local currentTime = os.clock()
        
        if currentTime - lastUpdate >= updateInterval then
            drawInterface()
            lastUpdate = currentTime
        end
        
        local event, key = os.pullEvent(0.5)
        
        if event == "key" then
            if key == keys.q then
                term.clear()
                term.setCursorPos(1, 1)
                print("Bot stopped")
                return
            elseif key == keys.r then
                drawInterface()
                lastUpdate = currentTime
            end
        end
    end
end

term.clear()
print("Loading bot statistic...")
sleep(1)

if not peripheral.find("modem") and not turtle then
    print("Warning: GPS not available")
    print("Coordinates will be static")
    sleep(2)
end

main()
