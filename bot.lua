-- AI Bot with ProxyAPI Integration
local http = require("http")
local json = require("json")

local AI_BOT = {
    api_key = "sk-GR3OIGY7wL9HTt7RXJMkQTdez3dflOfK",
    api_url = "https://api.proxyapi.ru/openai/v1/chat/completions",
    conversation_history = {}
}

-- Function to call AI API
function AI_BOT.callAI(message)
    local headers = {
        ["Authorization"] = "Bearer " .. AI_BOT.api_key,
        ["Content-Type"] = "application/json"
    }
    
    -- Add message to conversation history
    table.insert(AI_BOT.conversation_history, {role = "user", content = message})
    
    -- Limit history to last 10 messages to avoid token limits
    if #AI_BOT.conversation_history > 10 then
        table.remove(AI_BOT.conversation_history, 1)
    end
    
    local request_data = {
        model = "gpt-3.5-turbo",
        messages = {
            {role = "system", content = "You are a helpful AI assistant. Communicate in Russian language with user."},
            unpack(AI_BOT.conversation_history)
        },
        max_tokens = 500,
        temperature = 0.7
    }
    
    local response = http.post(AI_BOT.api_url, json.encode(request_data), headers)
    
    if response and response.getResponseCode() == 200 then
        local data = json.decode(response.readAll())
        if data.choices and data.choices[1] then
            local ai_response = data.choices[1].message.content
            table.insert(AI_BOT.conversation_history, {role = "assistant", content = ai_response})
            return ai_response
        end
    end
    
    return "Sorry, I cannot connect to AI service right now."
end

-- Initialize bot
function AI_BOT.start()
    local monitor = peripheral.find("monitor")
    
    -- Setup display
    if monitor then
        monitor.setTextScale(0.5)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("=== AI CHATBOT ===")
        monitor.setCursorPos(1, 3)
        monitor.write("Bot: Privet! Ya tvoy AI pomoshnik.")
        monitor.setCursorPos(1, 4)
        monitor.write("Mogu obsuzhdat lyubye temy!")
        monitor.setCursorPos(1, 6)
    else
        print("=== AI CHATBOT ===")
        print("Bot: Privet! Ya tvoy AI pomoshnik.")
        print("Mogu obsuzhdat lyubye temy!")
        print()
    end
    
    local function displayMessage(speaker, message)
        if monitor then
            local x, y = monitor.getCursorPos()
            if y > 18 then
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("=== AI CHATBOT ===")
                monitor.setCursorPos(1, 3)
                y = 3
            end
            monitor.write(speaker .. ": " .. message)
            monitor.setCursorPos(1, y + 1)
        else
            print(speaker .. ": " .. message)
        end
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
            displayMessage("Bot", "Do svidaniya! Rad byl poobshchatsya!")
            break
        elseif input == "clear" then
            AI_BOT.conversation_history = {}
            displayMessage("Bot", "Pamyat ochishchena! Nachinaem s chistogo lista!")
        else
            displayMessage("Bot", "Dumayu...")
            local response = AI_BOT.callAI(input)
            displayMessage("Bot", response)
        end
    end
end

-- Start the AI bot
AI_BOT.start()
