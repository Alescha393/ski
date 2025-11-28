-- AI Bot with GUI
local function startGUIChat()
    local monitor = peripheral.find("monitor")
    
    if monitor then
        -- Use monitor
        monitor.setTextScale(0.5)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("=== AI CHAT ===")
        monitor.setCursorPos(1, 3)
        monitor.write("Bot: Hello! I'm ready to chat!")
    else
        -- Use console
        print("=== AI CHAT ===")
        print("Bot: Hello! I'm ready to chat!")
    end
    
    local function displayMessage(speaker, message)
        if monitor then
            local x, y = monitor.getCursorPos()
            if y > 18 then
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("=== AI CHAT ===")
                monitor.setCursorPos(1, 3)
            end
            monitor.write(speaker .. ": " .. message)
            monitor.setCursorPos(1, y + 1)
        else
            print(speaker .. ": " .. message)
        end
    end
    
    -- Simple response logic
    local function getAIResponse(input)
        input = string.lower(input)
        
        if string.find(input, "hello") then return "Hello! How are you?" end
        if string.find(input, "how are you") then return "Great! I'm programming a bit here!" end
        if string.find(input, "joke") then return "Why is a programmer always wet? Because he's always in the pool!" end
        if string.find(input, "time") then return "Current time: " .. os.date("%H:%M") end
        if string.find(input, "love") then return "I enjoy talking with you!" end
        
        local responses = {
            "Interesting... continue!",
            "Tell me more about it!",
            "I'm listening...",
            "What do you think about this?",
            "Let's talk about something else!"
        }
        return responses[math.random(1, #responses)]
    end
    
    -- Main chat loop
    while true do
        if monitor then
            monitor.write("You: ")
        else
            write("You: ")
        end
        
        local input = read()
        
        if input == "exit" then
            displayMessage("Bot", "Goodbye! Come back again!")
            break
        end
        
        local response = getAIResponse(input)
        displayMessage("Bot", response)
    end
end

-- Start GUI chat
startGUIChat()
