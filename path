-- ИИ бот с графическим интерфейсом
local function startGUIChat()
    local monitor = peripheral.find("monitor")
    
    if monitor then
        -- Используем монитор
        monitor.setTextScale(0.5)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("=== ИИ ЧАТ ===")
        monitor.setCursorPos(1, 3)
        monitor.write("Бот: Привет! Я готов к общению!")
    else
        -- Используем консоль
        print("=== ИИ ЧАТ ===")
        print("Бот: Привет! Я готов к общению!")
    end
    
    local function displayMessage(speaker, message)
        if monitor then
            local x, y = monitor.getCursorPos()
            if y > 18 then
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("=== ИИ ЧАТ ===")
                monitor.setCursorPos(1, 3)
            end
            monitor.write(speaker .. ": " .. message)
            monitor.setCursorPos(1, y + 1)
        else
            print(speaker .. ": " .. message)
        end
    end
    
    -- Простая логика ответов
    local function getAIResponse(input)
        input = string.lower(input)
        
        if string.find(input, "привет") then return "Привет! Как твои дела?" end
        if string.find(input, "как дела") then return "Отлично! Программирую тут немного!" end
        if string.find(input, "шутка") then return "Почему программист всегда мокрый? Потому что он постоянно в бассейне (pool)!" end
        if string.find(input, "время") then return "Сейчас: " .. os.date("%H:%M") end
        if string.find(input, "любим") then return "Мне нравится общаться с тобой!" end
        
        local responses = {
            "Интересно... продолжай!",
            "Расскажи мне больше об этом!",
            "Я слушаю...",
            "Что ты думаешь об этом?",
            "Давай поговорим о чем-то еще!"
        }
        return responses[math.random(1, #responses)]
    end
    
    -- Основной цикл чата
    while true do
        if monitor then
            monitor.write("Ты: ")
        else
            write("Ты: ")
        end
        
        local input = read()
        
        if input == "выход" then
            displayMessage("Бот", "До свидания! Заходи еще!")
            break
        end
        
        local response = getAIResponse(input)
        displayMessage("Бот", response)
    end
end

-- Запуск GUI чата
startGUIChat()
