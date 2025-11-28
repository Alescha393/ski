-- AI Bot with HTTP for ComputerCraft
local AI_BOT = {
    api_key = "sk-GR3OIGY7wL9HTt7RXJMkQTdez3dflOfK",
    api_url = "https://api.proxyapi.ru/openai/v1/chat/completions",
    conversation_history = {}
}

-- Custom HTTP POST function for ComputerCraft
function AI_BOT.httpPost(url, data, headers)
    local command = "post "
    for k, v in pairs(headers) do
        command = command .. " -H \"" .. k .. ": " .. v .. "\""
    end
    command = command .. " -d \"" .. string.gsub(data, "\"", "\\\"") .. "\" " .. url
    
    local handle = io.popen("curl -s -X POST " .. command)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Simple JSON encoding
function AI_BOT.jsonEncode(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            result = result .. "\"" .. k .. "\":"
        end
        
        if type(v) == "table" then
            result = result .. AI_BOT.jsonEncode(v)
        elseif type(v) == "string" then
            result = result .. "\"" .. string.gsub(v, "\"", "\\\"") .. "\""
        elseif type(v) == "number" then
            result = result .. tostring(v)
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        end
        result = result .. ","
    end
    result = string.sub(result, 1, -2) .. "}"
    return result
end

-- Function to call AI API
function AI_BOT.callAI(message)
    -- Add message to conversation history
    table.insert(AI_BOT.conversation_history, {role = "user", content = message})
    
    -- Limit history to last 5 messages
    if #AI_BOT.conversation_history > 5 then
        table.remove(AI_BOT.conversation_history, 1)
    end
    
    local request_data = {
        model = "gpt-3.5-turbo",
        messages = {
            {role = "system", content = "You are helpful AI assistant. Communicate in Russian with user but keep responses concise."},
        }
    }
    
    -- Add conversation history to messages
    for _, msg in ipairs(AI_BOT.conversation_history) do
        table.insert(request_data.messages, msg)
    end
    
    request_data.max_tokens = 300
    request_data.temperature = 0.7
    
    local headers = {
        ["Authorization"] = "Bearer " .. AI_BOT.api_key,
        ["Content-Type"] = "application/json"
    }
    
    local json_data = AI_BOT.jsonEncode(request_data)
    local response = AI_BOT.httpPost(AI_BOT.api_url, json_data, headers)
    
    if response and response ~= "" then
        -- Simple JSON parsing to extract the response text
        local start_pos = string.find(response, "\"content\":\"")
        if start_pos then
            start_pos = start_pos + 11
            local end_pos = string.find(response, "\"", start_pos)
            if end_pos then
                local ai_response = string.sub(response, start_pos, end_pos - 1)
                -- Unescape newlines and other characters
                ai_response = string.gsub(ai_response, "\\n", "\n")
                ai_response = string.gsub(ai_response, "\\\"", "\"")
                table.insert(AI_BOT.conversation_history, {role = "assistant", content = ai_response})
                return ai_response
            end
        end
    end
    
    return "Oshibka soedineniya. Proverite internet ili API klyuch."
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
        monitor.write("Bot: Privet! Ya AI pomoshnik.")
        monitor.setCursorPos(1, 4)
        monitor.write("Zadavayte voprosy...")
        monitor.setCursorPos(1, 6)
    else
        print("=== AI CHATBOT ===")
        print("Bot: Privet! Ya AI pomoshnik.")
        print("Zadavayte voprosy...")
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
            displayMessage("Bot", "Do svidaniya!")
            break
        elseif input == "clear" then
            AI_BOT.conversation_history = {}
            displayMessage("Bot", "Pamyat ochishchena!")
        else
            displayMessage("Bot", "Dumayu...")
            local response = AI_BOT.callAI(input)
            displayMessage("Bot", response)
        end
    end
end

-- Start the AI bot
AI_BOT.start()
