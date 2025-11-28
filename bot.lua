-- Advanced Turtle AI with Mod Support
-- Use: wget https://raw.githubusercontent.com/Alescha393/ski/main/turtle_miner.lua miner.lua

local TURTLE_AI = {
    name = "SmartMiner",
    version = "3.0",
    current_turtle = nil,
    target_blocks = {},
    mining_mode = "auto",
    fuel_check = true
}

-- Initialize turtle
function TURTLE_AI:init()
    if turtle then
        self.current_turtle = turtle
        print("Turtle connected successfully!")
        self:update_status()
        return true
    else
        print("Error: No turtle found!")
        return false
    end
end

-- Update turtle status
function TURTLE_AI:update_status()
    self.fuel_level = turtle.getFuelLevel()
    self.inventory = {}
    
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            self.inventory[i] = {
                name = item.name,
                count = item.count
            }
        end
    end
end

-- Basic movement
function TURTLE_AI:move_forward()
    if turtle.forward() then return true end
    return false
end

function TURTLE_AI:move_back()
    if turtle.back() then return true end
    return false
end

function TURTLE_AI:turn_left()
    turtle.turnLeft()
    return true
end

function TURTLE_AI:turn_right()
    turtle.turnRight()
    return true
end

function TURTLE_AI:move_up()
    if turtle.up() then return true end
    return false
end

function TURTLE_AI:move_down()
    if turtle.down() then return true end
    return false
end

-- Mining functions
function TURTLE_AI:dig_forward()
    return turtle.dig()
end

function TURTLE_AI:dig_up()
    return turtle.digUp()
end

function TURTLE_AI:dig_down()
    return turtle.digDown()
end

-- Block detection with mod support
function TURTLE_AI:inspect_forward()
    return turtle.inspect()
end

function TURTLE_AI:inspect_up()
    return turtle.inspectUp()
end

function TURTLE_AI:inspect_down()
    return turtle.inspectDown()
end

-- Learn new block ID
function TURTLE_AI:learn_block(block_name)
    if not self.target_blocks[block_name] then
        self.target_blocks[block_name] = true
        print("Learned new block: " .. block_name)
        return true
    end
    return false
end

-- Remove block from learning
function TURTLE_AI:forget_block(block_name)
    if self.target_blocks[block_name] then
        self.target_blocks[block_name] = nil
        print("Forgot block: " .. block_name)
        return true
    end
    return false
end

-- Smart mining algorithm
function TURTLE_AI:smart_mine(max_time)
    local start_time = os.time()
    local mined_blocks = {}
    local search_patterns = {"forward", "up", "down", "left", "right"}
    
    print("Starting smart mining...")
    print("Looking for: " .. self:get_target_list())
    
    while true do
        if max_time and os.time() - start_time > max_time then
            print("Time limit reached!")
            break
        end
        
        -- Check fuel
        if self.fuel_check and turtle.getFuelLevel() < 50 then
            print("Low fuel! Current: " .. turtle.getFuelLevel())
            break
        end
        
        local found_block = false
        
        -- Check all directions for target blocks
        for _, direction in ipairs(search_patterns) do
            local success, data = false, nil
            
            if direction == "forward" then
                success, data = self:inspect_forward()
            elseif direction == "up" then
                success, data = self:inspect_up()
            elseif direction == "down" then
                success, data = self:inspect_down()
            elseif direction == "left" then
                self:turn_left()
                success, data = self:inspect_forward()
                self:turn_right()
            elseif direction == "right" then
                self:turn_right()
                success, data = self:inspect_forward()
                self:turn_left()
            end
            
            if success and data and self.target_blocks[data.name] then
                print("Found target block: " .. data.name)
                
                -- Dig the block
                if direction == "forward" then
                    if self:dig_forward() then
                        mined_blocks[data.name] = (mined_blocks[data.name] or 0) + 1
                        found_block = true
                    end
                elseif direction == "up" then
                    if self:dig_up() then
                        mined_blocks[data.name] = (mined_blocks[data.name] or 0) + 1
                        found_block = true
                    end
                elseif direction == "down" then
                    if self:dig_down() then
                        mined_blocks[data.name] = (mined_blocks[data.name] or 0) + 1
                        found_block = true
                    end
                elseif direction == "left" then
                    self:turn_left()
                    if self:dig_forward() then
                        mined_blocks[data.name] = (mined_blocks[data.name] or 0) + 1
                        found_block = true
                    end
                    self:turn_right()
                elseif direction == "right" then
                    self:turn_right()
                    if self:dig_forward() then
                        mined_blocks[data.name] = (mined_blocks[data.name] or 0) + 1
                        found_block = true
                    end
                    self:turn_left()
                end
                
                if found_block then
                    break
                end
            end
        end
        
        if not found_block then
            -- Explore new area
            if not self:explore_new_area() then
                print("Cannot find more blocks in this area.")
                break
            end
        end
        
        self:update_status()
        
        -- Check inventory space
        local empty_slots = 0
        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                empty_slots = empty_slots + 1
            end
        end
        
        if empty_slots <= 2 then
            print("Inventory almost full! Empty slots: " .. empty_slots)
            break
        end
    end
    
    print("Mining completed!")
    return mined_blocks
end

-- Explore new areas when no blocks found
function TURTLE_AI:explore_new_area()
    local moves = {
        function() return self:move_forward() end,
        function() 
            self:turn_left()
            local result = self:move_forward()
            self:turn_right()
            return result
        end,
        function()
            self:turn_right()
            local result = self:move_forward()
            self:turn_left()
            return result
        end,
        function() return self:move_up() end,
        function() return self:move_down() end
    }
    
    for _, move_func in ipairs(moves) do
        if move_func() then
            return true
        end
    end
    
    return false
end

-- Get list of target blocks
function TURTLE_AI:get_target_list()
    local blocks = {}
    for block_name, _ in pairs(self.target_blocks) do
        table.insert(blocks, block_name)
    end
    return table.concat(blocks, ", ")
end

-- Auto-learn blocks from environment
function TURTLE_AI:auto_learn_blocks()
    print("Scanning environment for blocks...")
    local directions = {"forward", "up", "down", "left", "right"}
    local learned = 0
    
    for _, dir in ipairs(directions) do
        local success, data = false, nil
        
        if dir == "forward" then
            success, data = self:inspect_forward()
        elseif dir == "up" then
            success, data = self:inspect_up()
        elseif dir == "down" then
            success, data = self:inspect_down()
        elseif dir == "left" then
            self:turn_left()
            success, data = self:inspect_forward()
            self:turn_right()
        elseif dir == "right" then
            self:turn_right()
            success, data = self:inspect_forward()
            self:turn_left()
        end
        
        if success and data then
            if self:learn_block(data.name) then
                learned = learned + 1
            end
        end
    end
    
    print("Auto-learned " .. learned .. " new blocks")
    return learned
end

-- Mine specific quantity of blocks
function TURTLE_AI:mine_quantity(block_name, quantity)
    local mined = 0
    local target_quantity = quantity or 64
    
    print("Mining " .. target_quantity .. " of " .. block_name)
    
    -- Temporarily set only this block as target
    local original_targets = self.target_blocks
    self.target_blocks = {[block_name] = true}
    
    while mined < target_quantity do
        local results = self:smart_mine(30) -- 30 second chunks
        
        if results[block_name] then
            mined = mined + results[block_name]
            print("Progress: " .. mined .. "/" .. target_quantity)
        else
            print("No more " .. block_name .. " found nearby")
            break
        end
        
        if mined >= target_quantity then
            break
        end
    end
    
    -- Restore original targets
    self.target_blocks = original_targets
    
    print("Mined " .. mined .. " " .. block_name)
    return mined
end

-- Command parser
function TURTLE_AI:parse_command(command)
    local cmd = string.lower(command)
    
    if cmd == "help" or cmd == "помощь" then
        return self:show_help()
    
    elseif cmd == "status" or cmd == "статус" then
        self:update_status()
        return "Fuel: " .. self.fuel_level .. " | Targets: " .. self:get_target_list()
    
    elseif string.find(cmd, "learn") or string.find(cmd, "изучить") then
        local block_name = string.match(cmd, "[^%s]+$")
        if block_name then
            return self:learn_block(block_name) and "Block learned: " .. block_name or "Already known: " .. block_name
        else
            return "Usage: learn <block_id>"
        end
    
    elseif string.find(cmd, "forget") or string.find(cmd, "забыть") then
        local block_name = string.match(cmd, "[^%s]+$")
        if block_name then
            return self:forget_block(block_name) and "Forgot: " .. block_name or "Not in list: " .. block_name
        else
            return "Usage: forget <block_id>"
        end
    
    elseif string.find(cmd, "mine all") or string.find(cmd, "копать все") then
        local results = self:smart_mine(300) -- 5 minutes
        local report = "Mining results:\n"
        for block, count in pairs(results) do
            report = report .. "  " .. block .. ": " .. count .. "\n"
        end
        return report
    
    elseif string.find(cmd, "mine") then
        local block_name, quantity = string.match(cmd, "mine%s+(%S+)%s*(%d*)")
        if not block_name then
            block_name = string.match(cmd, "копать%s+(%S+)%s*(%d*)")
        end
        
        if block_name then
            quantity = tonumber(quantity) or 64
            local mined = self:mine_quantity(block_name, quantity)
            return "Mined " .. mined .. " " .. block_name
        else
            return "Usage: mine <block_id> [quantity]"
        end
    
    elseif string.find(cmd, "auto learn") or string.find(cmd, "авто изучение") then
        local learned = self:auto_learn_blocks()
        return "Auto-learned " .. learned .. " blocks from environment"
    
    elseif string.find(cmd, "list") or string.find(cmd, "список") then
        return "Target blocks: " .. self:get_target_list()
    
    elseif string.find(cmd, "scan") or string.find(cmd, "сканировать") then
        local directions = {"forward", "up", "down"}
        local found = {}
        
        for _, dir in ipairs(directions) do
            local success, data = false, nil
            if dir == "forward" then success, data = self:inspect_forward()
            elseif dir == "up" then success, data = self:inspect_up()
            elseif dir == "down" then success, data = self:inspect_down() end
            
            if success and data then
                table.insert(found, dir .. ": " .. data.name)
            else
                table.insert(found, dir .. ": air")
            end
        end
        
        return "Scan results: " .. table.concat(found, ", ")
    
    else
        return "Unknown command. Type 'help' for available commands."
    end
end

-- Show help
function TURTLE_AI:show_help()
    return [[
=== Turtle Mining AI Commands ===

Basic:
  help - show this help
  status - show fuel and target blocks
  scan - scan nearby blocks

Learning:
  learn <block_id> - learn new block type
  forget <block_id> - remove block from targets
  auto learn - learn blocks from environment
  list - show target blocks

Mining:
  mine all - mine all known blocks
  mine <block_id> [quantity] - mine specific block
  mine coal 64 - mine 64 coal

Examples:
  learn minecraft:diamond_ore
  mine minecraft:iron_ore 32
  mine all
]]
end

-- Main control interface
function TURTLE_AI:start_control()
    if not self:init() then
        return
    end
    
    print("=== Smart Turtle Miner ===")
    print("Version: " .. self.version)
    print("Fuel: " .. self.fuel_level)
    print()
    print("Type 'help' for commands")
    print("First, learn some blocks with 'learn <block_id>'")
    print("or 'auto learn' to scan environment")
    print()
    
    -- Pre-learn common blocks
    local common_blocks = {
        "minecraft:coal_ore",
        "minecraft:iron_ore", 
        "minecraft:gold_ore",
        "minecraft:diamond_ore",
        "minecraft:redstone_ore",
        "minecraft:lapis_ore"
    }
    
    for _, block in ipairs(common_blocks) do
        self:learn_block(block)
    end
    
    print("Pre-loaded common blocks: " .. self:get_target_list())
    print()
    
    while true do
        write("Miner> ")
        local command = read()
        
        if command == "exit" or command == "quit" or command == "выход" then
            print("Shutting down miner...")
            break
        end
        
        local result = self:parse_command(command)
        print(result)
        print()
    end
end

-- Auto-start
local function main()
    TURTLE_AI:start_control()
end

main()
