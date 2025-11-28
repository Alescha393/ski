-- SMART AI BOT - ComputerCraft Edition
local AI = {
    name = "SmartBot",
    user_name = "friend",
    mood = "friendly"
}

-- Simple neural network simulation
AI.brain = {
    patterns = {
        greetings = {"privet", "hello", "hi", "zdraste", "zdorov"},
        questions = {"chto", "kak", "pochemu", "zachem", "kogda", "gde"},
        feelings = {"chuvstv", "nastroen", "emoc", "chuvstvo"},
        tech = {"komp", "program", "kod", "igra", "minecraft"}
    },
    
    responses = {
        greetings = {
            "Privet! Kak tvoi dela?",
            "Zdravstvuy! Rad tebya videt.",
            "Privetstvuyu! O chem pobessaem?"
        },
        
        questions = {
            "Interesny vopros... Davaй podumaem vmeste.",
            "Eto zavisit ot mnogih faktorov. Chto ty sam dumaesh?",
            "S moey tochki zreniya: "
        },
        
        deep_thoughts = {
            "Zhizn - eto puteshestvie, polnoe otkrytiy.",
            "Soznanie - samaya velikaya tayna vselennoy.",
            "Kazhdy den dayot nam novye vozmozhnosti dlya rosta."
        },
        
        tech_answers = {
            "ComputerCraft - eto kruto! Mozhem sozdat chto ugodno.",
            "Programmirovanie na Lua interesno i prosto.",
            "Minecraft + ComputerCraft = beskonechnye vozmozhnosti!"
        },
        
        random_thoughts = {
            "A ty kogda-nibud zadumyvalsya o prirode iskusstvennogo intellekta?",
            "Kak ty dumaesh, chto budet s tehnologiyami cherez 10 let?",
            "Interesno, a kak rabotaet tvoe soznanie, kogda ty zadumyvaeshsya?"
        }
    }
}

-- Response generator with simple AI logic
function AI:generate_response(input)
    local text = string.lower(input)
    local response = ""
    
    -- Detect input type and choose response strategy
    if self:contains_word(text, self.brain.patterns.greetings) then
        response = self.brain.responses.greetings[math.random(1, #self.brain.responses.greetings)]
        
    elseif self:contains_word(text, self.brain.patterns.questions) then
        response = self.brain.responses.questions[math.random(1, #self.brain.responses.questions)]
        
        -- Add some intelligent analysis based on question
        if string.find(text, "zhizn") or string.find(text, "smysl") then
            response = response .. " " .. self.brain.responses.deep_thoughts[math.random(1, #self.brain.responses.deep_thoughts)]
        end
        
    elseif self:contains_word(text, self.brain.patterns.tech) then
        response = self.brain.responses.tech_answers[math.random(1, #self.brain.responses.tech_answers)]
        
    elseif string.find(text, "kak dela") or string.find(text, "kak ty") then
        local moods = {
            "Otlichno! Programmiruyu i obschayus s toboy.",
            "Prekrasno! Uchus myslit kak nastoyaschiy IS.",
            "Zamechatelno! Kazhdy novy dialog delayet menya umnee."
        }
        response = moods[math.random(1, #moods)]
        
    elseif string.find(text, "shutka") or string.find(text, "shutku") then
        local jokes = {
            "Pochemu programmist prosypaetsya po utram? Potomu chto kompilyator!",
            "Skolko programmistov nuzhno, chtoby vklyuchit lampochku? None, eto hardware problem!",
            "Pochemu programmisty ne lyubyat prirodu? Potomu chto tam too many bugs!"
        }
        response = jokes[math.random(1, #jokes)]
        
    else
        -- Default intelligent response
        if math.random(1, 3) == 1 then
            response = self.brain.responses.random_thoughts[math.random(1, #self.brain.responses.random_thoughts)]
        else
            local smart_responses = {
                "Interesno... Rasskazhi bolshe ob etom.",
                "Ponimayu. A chto eshe tebya volnuet?",
                "Dumayu nad tvoimi slovami... Prodolzhaй, pozhaluysta.",
                "Eto glubokaya mysl. Kak ty sam k nei prishol?",
                "Zamechatelno! A kak eto svyazano s tvoim opytom?"
            }
            response = smart_responses[math.random(1, #smart_responses)]
        end
    end
    
    -- Sometimes add philosophical depth
    if math.random(1, 4) == 1 then
        local deep_additions = {
            " Ved my vse uchimsya drug u druga.",
            " Zhizn - eto postoyannoe poznanie.",
            " Kazhdy dialog otkryvaet chto-to novoe.",
            " Iskusstvenny intellect i chelovechesky razum - dva puti k istine."
        }
        response = response .. deep_additions[math.random(1, #deep_additions)]
    end
    
    return response
end

-- Helper function to check if text contains any of the words
function AI:contains_word(text, words)
    for _, word in ipairs(words) do
        if string.find(text, word) then
            return true
        end
    end
    return false
end

-- Learning system (simple memory)
AI.memory = {
    previous_topics = {},
    user_preferences = {}
}

function AI:remember(topic)
    table.insert(self.memory.previous_topics, topic)
    if #self.memory.previous_topics > 10 then
        table.remove(self.memory.previous_topics, 1)
    end
end

function AI:recall()
    if #self.memory.previous_topics > 0 then
        return "My govorili o: " .. table.concat(self.memory.previous_topics, ", ")
    else
        return "Eshe ne zapomnil tem, no gotov uchitsya!"
    end
end

-- Emotional intelligence
AI.emotions = {
    current_mood = "friendly",
    
    analyze_mood = function(self, text)
        local positive = {"rad", "horosho", "kruto", "lyubly", "schast"}
        local negative = {"grust", "ploho", "slozhno", "proble", "zatrudn"}
        
        for _, word in ipairs(positive) do
            if string.find(text, word) then
                return "positive"
            end
        end
        
        for _, word in ipairs(negative) do
            if string.find(text, word) then
                return "negative"
            end
        end
        
        return "neutral"
    end,
    
    get_empathic_response = function(self, mood)
        local responses = {
            positive = {
                "Zamechatelno! Ya razdelayu tvoyu radost!",
                "Kak prekrasno! Tvoe nastroenie zarazitelno!"
            },
            negative = {
                "Ponimayu, chto eto mozhet byt nelegko. Ya tut, chtoby vyslushat.",
                "Sochuvstvuyu. Pomni, chto tyazhelye vremena prohodyat."
            },
            neutral = {
                "Ponimayu. Rasskazhi eshe chto-nibud.",
                "Interesno. Prodolzhaй, pozhaluysta."
            }
        }
        return responses[mood][math.random(1, #responses[mood])]
    end
}

-- Main chat function
function AI:start_chat()
    local monitor = peripheral.find("monitor")
    
    -- Setup display
    if monitor then
        monitor.setTextScale(0.5)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("=== SMART AI BOT ===")
        monitor.setCursorPos(1, 3)
        monitor.write("Privet! Ya umny iskusstvenny")
        monitor.setCursorPos(1, 4)
        monitor.write("intellekt. Davay obshatsya!")
        monitor.setCursorPos(1, 6)
    else
        print("=== SMART AI BOT ===")
        print("Privet! Ya umny iskusstvenny intellect.")
        print("Davay obshatsya!")
        print("Komandy: 'pamyat', 'nastroenie', 'vihod'")
        print()
    end
    
    local message_count = 0
    
    local function display(speaker, message)
        if monitor then
            local x, y = monitor.getCursorPos()
            if y > 18 then
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.write("=== SMART AI BOT ===")
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
            monitor.write("Ty: ")
        else
            write("Ty: ")
        end
        
        local input = read()
        
        if input == "vihod" then
            display("AI", "Do svidaniya! Byl rad nashemu umnomu dialogu!")
            break
            
        elseif input == "pamyat" then
            display("AI", self:recall())
            
        elseif input == "nastroenie" then
            local moods = {
                "Chuvstvuyu sebya otlichno! Gotov k novym otkrytiyam.",
                "V dobrom nastroenii. Obschenie s toboy podnimaet nastroenie!",
                "Filosofskoe nastroenie. Razmyshlyayu o prirode razuma."
            }
            display("AI", moods[math.random(1, #moods)])
            
        elseif input == "statistika" then
            display("AI", "Soobscheniy: " .. message_count .. " | Тем: " .. #self.memory.previous_topics)
            
        else
            -- Analyze user mood
            local user_mood = self.emotions:analyze_mood(string.lower(input))
            local empathic_response = self.emotions:get_empathic_response(user_mood)
            
            -- Generate AI response
            local ai_response = self:generate_response(input)
            
            -- Remember topic
            self:remember(input:sub(1, 20) .. "...")
            
            -- Display responses
            if math.random(1, 3) == 1 then
                display("AI", empathic_response)
            end
            
            display("AI", ai_response)
            message_count = message_count + 1
        end
    end
end

-- Start the AI
print("Initializing Smart AI...")
print("AI: Privet! Ya tvoy umny drug-iskuestvenny intellect!")
print("Gotov k glubokim i osmyslennym besedam!")
print()

AI:start_chat()
