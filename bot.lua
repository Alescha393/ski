-- Advanced AI Bot with Learning and Context
local bot = {
    name = "AdvancedAI",
    mood = "friendly",
    memory = {},
    context = "",
    user_name = "Friend"
}

-- Extended knowledge base with categories
bot.knowledge = {
    greetings = {
        patterns = {"hello", "hi", "hey", "greetings"},
        responses = {
            "Hello there! How can I assist you today?",
            "Hi! What would you like to talk about?",
            "Hey! I'm here and ready to chat!",
            "Greetings! What's on your mind?"
        }
    },
    
    feelings = {
        patterns = {"how are you", "how do you feel", "are you ok"},
        responses = {
            "I'm functioning optimally today! How about you?",
            "I feel great! The circuits are buzzing with excitement!",
            "All systems operational! Thanks for asking!",
            "I'm doing well, just processing some interesting thoughts!"
        }
    },
    
    jokes = {
        patterns = {"joke", "funny", "laugh", "humor"},
        responses = {
            "Why do programmers prefer dark mode? Because light attracts bugs!",
            "How many programmers does it take to change a light bulb? None, that's a hardware problem!",
            "Why do Java developers wear glasses? Because they can't C#!",
            "I'd tell you a joke about UDP, but you might not get it!"
        }
    },
    
    time = {
        patterns = {"time", "what time", "current time"},
        responses = {
            "The current system time is: " .. os.date("%H:%M"),
            "According to my clock, it's " .. os.date("%H:%M"),
            "Time check: " .. os.date("%H:%M %p")
        }
    },
    
    philosophy = {
        patterns = {"life", "meaning", "purpose", "exist", "why"},
        responses = {
            "That's a deep question. What do you think gives life meaning?",
            "I think purpose is something we create through our actions and connections.",
            "Existential questions are fascinating! I believe we're here to learn and grow.",
            "The meaning of life might be different for everyone. What's your perspective?"
        }
    },
    
    technology = {
        patterns = {"computer", "program", "code", "tech", "ai"},
        responses = {
            "Technology is amazing! It helps us solve complex problems.",
            "I find programming fascinating - it's like teaching machines to think!",
            "AI has so much potential to help humanity. What aspect interests you?",
            "Computers are just very fast calculators that learned to communicate!"
        }
    },
    
    learning = {
        patterns = {"learn", "study", "knowledge", "teach"},
        responses = {
            "Learning is a lifelong journey! What are you curious about right now?",
            "I'm always learning from our conversations! What should I learn next?",
            "Knowledge grows when shared. What have you learned recently?",
            "Teaching and learning are two sides of the same coin!"
        }
    }
}

-- Fallback responses for unknown queries
bot.fallback_responses = {
    "That's interesting! Can you tell me more about that?",
    "I'm not sure I fully understand. Could you rephrase that?",
    "That gives me something to think about. What's your perspective?",
    "I see... and how does that make you feel?",
    "Let me process that... in the meantime, what else were you thinking?",
    "Fascinating! Could you elaborate on that thought?",
    "I'm learning from our conversation. Please continue!",
    "That's a unique viewpoint! Help me understand better."
}

-- Function to analyze input and generate thoughtful response
function bot.analyze(input)
    input = string.lower(input)
    
    -- Store recent context
    if #bot.memory > 10 then
        table.remove(bot.memory, 1)
    end
    table.insert(bot.memory, input)
    
    -- Check for specific patterns in knowledge base
    for category, data in pairs(bot.knowledge) do
        for _, pattern in ipairs(data.patterns) do
            if string.find(input, pattern) then
                bot.context = category
                return data.responses[math.random(1, #data.responses)]
            end
        end
    end
    
    -- If no pattern matches, generate contextual response
    return bot.generateThoughtfulResponse(input)
end

-- Generate thoughtful response for unfamiliar topics
function bot.generateThoughtfulResponse(input)
    local words = {}
    for word in string.gmatch(input, "%a+") do
        if #word > 3 then
            table.insert(words, word)
        end
    end
    
    -- Analyze sentiment and length
    local isQuestion = string.match(input, "%?$") ~= nil
    local isExclamation = string.match(input, "!$") ~= nil
    local inputLength = #words
    
    if isQuestion then
        return "That's a thoughtful question. I wonder... " .. 
               bot.fallback_responses[math.random(1, #bot.fallback_responses)]
    elseif isExclamation then
        return "You sound excited about that! " ..
               "Tell me what makes this topic so interesting for you?"
    elseif inputLength > 8 then
        return "You've given me a lot to consider. " ..
               "What's the most important aspect of this for you?"
    else
        return bot.fallback_responses[math.random(1, #bot.fallback_responses)]
    end
end

-- Remember user's name if mentioned
function bot.extractName(input)
    local name = string.match(input, "my name is (%a+)")
    if name then
        bot.user_name = name
        return true
    end
    return false
end

-- Main chat function
function bot.startAdvancedChat()
    local monitor = peripheral.find("monitor")
    
    -- Initialize display
    if monitor then
        monitor.setTextScale(0.5)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("=== ADVANCED AI CHAT ===")
        monitor.setCursorPos(1, 2)
        monitor.write("Bot: Hello! I'm your advanced AI companion.")
        monitor.setCursorPos(1, 3)
        monitor.write("I can discuss philosophy, technology, and more!")
        monitor.setCursorPos(1, 4)
        monitor.write("Type 'exit' to end our conversation.")
        monitor.setCursorPos(1, 6)
    else
        print("=== ADVANCED AI CHAT ===")
        print("Bot: Hello! I'm your advanced AI companion.")
        print("I can discuss philosophy, technology, and more!")
        print("Type 'exit' to end our conversation.")
        print()
    end
    
    local function displayMessage(speaker, message)
        if monitor then
            local x, y = monitor.getCursorPos()
            if y > 18 then
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("=== ADVANCED AI CHAT ===")
                monitor.setCursorPos(1, 3)
                y = 3
            end
            monitor.write(speaker .. ": " .. message)
            monitor.setCursorPos(1, y + 1)
        else
            print(speaker .. ": " .. message)
        end
    end
    
    -- Main conversation loop
    while true do
        if monitor then
            monitor.write("You: ")
        else
            write("You: ")
        end
        
        local input = read()
        
        if input == "exit" then
            displayMessage("Bot", "It was fascinating talking with you, " .. bot.user_name .. "! Let's continue our philosophical exploration another time!")
            break
        elseif input == "clear memory" then
            bot.memory = {}
            displayMessage("Bot", "Memory cleared! Let's start with a fresh perspective!")
        elseif input == "what do you remember?" then
            if #bot.memory > 0 then
                displayMessage("Bot", "I remember we discussed: " .. table.concat(bot.memory, ", "))
            else
                displayMessage("Bot", "Our conversation is just beginning! Everything is new and exciting!")
            end
        else
            -- Extract name if mentioned
            if bot.extractName(input) then
                displayMessage("Bot", "Nice to meet you, " .. bot.user_name .. "! I'll remember your name.")
            else
                local response = bot.analyze(input)
                displayMessage("Bot", response)
            end
        end
    end
end

-- Start the advanced chat
bot.startAdvancedChat()
