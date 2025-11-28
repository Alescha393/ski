-- Advanced Turtle AI with Return Home Function
-- Use: wget https://raw.githubusercontent.com/Alescha393/ski/main/smart_miner.lua miner.lua

local TURTLE_AI = {
    name = "SmartMiner",
    version = "4.0",
    current_turtle = nil,
    target_blocks = {},
    mining_mode = "auto",
    fuel_check = true,
    home_position = {x = 0, y = 0, z = 0, facing = 0},
    current_position = {x = 0, y = 0, z = 0, facing = 0},
    path_history = {}
}

-- Initialize turtle
function TURTLE_AI:init()
    if turtle then
        self.current_turtle = turtle
        print("Turtle connected successfully!")
        
        -- Set home position
        self:set_home()
        self:update_status()
        return true
    else
        print("Error: No turtle found!")
        return false
    end
end

-- Set current position as home
function TURTLE_AI:set_home()
    self.home_position = {
        x = self.current_position.x,
        y = self.current_position.y, 
        z = self.current_position.z,
        facing = self.current_position.facing
    }
    print("Home position set!")
    return true
end

-- Update turtle status and position tracking
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

-- Movement with position tracking
function TURTLE_AI:move_forward()
    if turtle.forward() then
        self:update_position("forward")
        table.insert(self.path_history, "forward")
        return true
    end
    return false
end

function TURTLE_AI:move_back()
    if turtle.back() then
        self:update_position("back")
        table.insert(self.path_history, "back")
        return true
    end
    return false
end

function TURTLE_AI:turn_left()
    turtle.turnLeft()
    self.current_position.facing = (self.current_position.facing - 1) % 4
    table.insert(self.path_history, "turn_left")
    return true
end

function TURTLE_AI:turn_right()
    turtle.turnRight()
    self.current_position.facing = (self.current_position.facing + 1) % 4
    table.insert(self.path_history, "turn_right")
    return true
end

function TURTLE_AI:move_up()
    if turtle.up() then
        self.current_position.y = self.current_position.y + 1
        table.insert(self.path_history, "up")
        return true
    end
    return false
end

function TURTLE_AI:move_down()
    if turtle.down() then
        self.current_position.y = self.current_position.y - 1
        table.insert(self.path_history, "down")
        return true
    end
    return false
end

-- Update position based on movement and facing direction
function TURTLE_AI:update_position(direction)
    local facing = self.current_position.facing
    
    if direction == "forward" then
        if facing == 0 then self.current_position.z = self.current_position.z - 1
        elseif facing == 1 then self.current_position.x = self.current_position.x + 1
        elseif facing == 2 then self.current_position.z = self.current_position.z + 1
        elseif facing == 3 then self.current_position.x = self.current_position.x - 1 end
    elseif direction == "back" then
        if facing == 0 then self.current_position.z = self.current_position.z + 1
        elseif facing == 1 then self.current_position.x = self.current_position.x - 1
        elseif facing == 2 then self.current_position.z = self.current_position.z - 1
        elseif facing == 3 then self.current_position.x = self.current_position.x + 1 end
    end
end

-- Calculate distance to home
function TURTLE_AI:get_distance_to_home()
    local dx = math.abs(self.current_position.x - self.home_position.x)
    local dy = math.abs(self.current_position.y - self.home_position.y)
    local dz = math.abs(self.current_position.z - self.home_position.z)
    return dx + dy + dz
end

-- Return to home position
function TURTLE_AI:return_home()
    print("Returning to home position...")
    print("Distance: " .. self:get_distance_to_home())
    
    -- First, return to home Y level
    while self.current_position.y ~= self.home_position.y do
        if self.current_position.y > self.home_position.y then
            if not self:move_down() then
                if not self:dig_down() then
                    print("Cannot move down! Trying alternative path...")
                    break
                end
            end
        else
            if not self:move_up() then
                if not self:dig_up() then
                    print("Cannot move up! Trying alternative path...")
                    break
                end
            end
        end
    end
    
    -- Return to home X position
    while self.current_position.x ~= self.home_position.x do
        self:face_direction(self.current_position.x > self.home_position.x and 3 or 1)
        if not self:move_forward() then
            if not self:dig_forward() then
                print("Cannot move horizontally! Trying alternative path...")
                break
            end
        end
    end
    
    -- Return to home Z position
    while self.current_position.z ~= self.home_position.z do
        self:face_direction(self.current_position.z > self.home_position.z and 2 or 0)
        if not self:move_forward() then
            if not self:dig_forward() then
                print("Cannot move horizontally! Trying alternative path...")
                break
            end
        end
    end
    
    -- Face home direction
    self:face_direction(self.home_position.facing)
    
    if self.current_position.x == self.home_position.x and
       self.current_position.y == self.home_position.y and
       self.current_position.z == self.home_position.z then
        print("Successfully returned home!")
        return true
    else
        print("Returned close to home. Final position:")
        self:show_position()
        return false
    end
end

-- Face specific direction (0=north, 1=east, 2=south, 3=west)
function TURTLE_AI:face_direction(target_facing)
    while self.current_position.facing ~= target_facing do
        local diff = (target_facing - self.current_position.facing) % 4
        if diff <= 2 then
            self:turn_right()
        else
            self:turn_left()
        end
    end
end

-- Follow path history in reverse to return home
function TURTLE_AI:follow_path_home()
    print("Retracing path back home...")
    local reverse_path = {}
    
    -- Create reverse path
    for i = #self.path_history, 1, -1 do
        local action = self.path_history[i]
        if action == "forward" then table.insert(reverse_path, "back")
        elseif action == "back" then table.insert(reverse_path, "forward")
        elseif action == "up" then table.insert(reverse_path, "down")
        elseif action == "down" then table.insert(reverse_path, "up")
        elseif action == "turn_left" then table.insert(reverse_path, "turn_right")
        elseif action == "turn_right" then table.insert(reverse_path, "turn_left")
        end
    end
    
    -- Execute reverse path
    for _, action in ipairs(reverse_path) do
        if action == "forward" then self:move_forward()
        elseif action == "back" then self:move_back()
        elseif action == "up" then self:move_up()
        elseif action == "down" then self:move_down()
        elseif action == "turn_left" then self:turn_left()
        elseif action == "turn_right" then self:turn_right()
        end
    end
    
    print("Path following completed!")
    self:show_position()
end

-- Show current position
function TURTLE_AI:show_position()
    local directions = {"north", "east", "south", "west"}
    print(string.format("Position: X=%d, Y=%d, Z=%d, Facing=%s",
        self.current_position.x, self.current_position.y, self.current_position.z,
        directions[self.current_position.facing + 1]))
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

-- Block detection
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

-- Smart mining with return capability
function TURTLE_AI:smart_mine_with_return(max_time, return_when_done)
    local start_time = os.time()
    local mined_blocks = {}
    
    print("Starting smart mining with return home feature...")
    print("Will return automatically when done: " .. tostring(return_when_done))
    
    while true do
        if max_time and os.time() - start_time > max_time then
            print("Time limit reached!")
            break
        end
        
        -- Check fuel for return trip
        local distance_home = self:get_distance_to_home()
        if self.fuel_check and turtle.getFuelLevel() < distance_home + 10 then
            print("Low fuel! Need " .. (distance_home + 10) .. ", have " .. turtle.getFuelLevel())
            break
        end
        
        local found_block = false
        
        -- Check for target blocks in all directions
        local directions = {"forward", "up", "down", "left", "right"}
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
            
            if success and data and self.target_blocks[data.name] then
                print("Found target block: " .. data.name)
                
                -- Dig the block
                local dug = false
                if dir == "forward" then
                    dug = self:dig_forward()
                elseif dir == "up" then
                    dug = self:dig_up()
                elseif dir == "down" then
                    dug = self:dig_down()
                elseif dir == "left" then
                    self:turn_left()
                    dug = self:dig_forward()
                    self:turn_right()
                elseif dir == "right" then
                    self:turn_right()
                    dug = self:dig_forward()
                    self:turn_left()
                end
                
                if dug then
                    mined_blocks[data.name] = (mined_blocks[data.name] or 0) + 1
                    found_block = true
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
        
        -- Check inventory space (leave 4 slots for return trip)
        local empty_slots = 0
        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                empty_slots = empty_slots + 1
            end
        end
        
        if empty_slots <= 4 then
            print("Inventory almost full! Empty slots: " .. empty_slots)
            break
        end
    end
    
    print("Mining completed!")
    
    -- Return home if requested
    if return_when_done then
        print("Auto-returning to home...")
        self:return_home()
    end
    
    return mined_blocks
end

-- Explore new areas
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

-- Command parser with new return functions
function TURTLE_AI:parse_command(command)
    local cmd = string.lower(command)
    
    if cmd == "help" or cmd == "помощь" then
        return self:show_help()
    
    elseif cmd == "status" or cmd == "статус" then
        self:update_status()
        return "Fuel: " .. self.fuel_level .. " | Position: " .. 
               self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z ..
               " | Targets: " .. self:get_target_list()
    
    elseif cmd == "position" or cmd == "позиция" then
        self:show_position()
        return "Distance to home: " .. self:get_distance_to_home()
    
    elseif cmd == "home" or cmd == "домой" then
        return self:return_home() and "Successfully returned home!" or "Failed to return completely"
    
    elseif cmd == "set home" or cmd == "установить дом" then
        return self:set_home() and "Home position set!" or "Failed to set home"
    
    elseif cmd == "retrace" or cmd == "вернуться по пути" then
        self:follow_path_home()
        return "Path retracing completed"
    
    elseif string.find(cmd, "mine return") or string.find(cmd, "копать вернуться") then
        local time_limit = tonumber(string.match(cmd, "%d+")) or 300
        local results = self:smart_mine_with_return(time_limit, true)
        return "Mining with return completed: " .. self:format_results(results)
    
    elseif string.find(cmd, "learn") or string.find(cmd, "изучить") then
        local block_name = string.match(cmd, "[^%s]+$")
        if block_name then
            return self:learn_block(block_name) and "Block learned: " .. block_name or "Already known: " .. block_name
        else
            return "Usage: learn <block_id>"
        end
    
    elseif string.find(cmd, "mine") then
        local return_home = string.find(cmd, "return") ~= nil
        local block_name, quantity = string.match(cmd, "mine%s+(%S+)%s*(%d*)")
        
        if not block_name then
            block_name = string.match(cmd, "копать%s+(%S+)%s*(%d*)")
        end
        
        if block_name then
            quantity = tonumber(quantity) or 64
            local mined = self:mine_quantity(block_name, quantity, return_home)
            return "Mined " .. mined .. " " .. block_name .. (return_home and " and returned home" or "")
        else
            return "Usage: mine <block_id> [quantity] [return]"
        end
    
    else
        return "Unknown command. Type 'help' for available commands."
    end
end

-- Mine specific quantity with optional return
function TURTLE_AI:mine_quantity(block_name, quantity, return_home)
    local mined = 0
    local target_quantity = quantity or 64
    
    print("Mining " .. target_quantity .. " of " .. block_name)
    if return_home then
        print("Will return home when done")
    end
    
    -- Temporarily set only this block as target
    local original_targets = self.target_blocks
    self.target_blocks = {[block_name] = true}
    
    while mined < target_quantity do
        local results = self:smart_mine_with_return(30, false) -- 30 second chunks
        
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
    
    -- Return home if requested
    if return_home then
        self:return_home()
    end
    
    -- Restore original targets
    self.target_blocks = original_targets
    
    print("Mined " .. mined .. " " .. block_name)
    return mined
end

-- Format mining results
function TURTLE_AI:format_results(results)
    local formatted = ""
    for block, count in pairs(results) do
        formatted = formatted .. block .. ": " .. count .. ", "
    end
    return formatted:sub(1, -3)
end

-- Get list of target blocks
function TURTLE_AI:get_target_list()
    local blocks = {}
    for block_name, _ in pairs(self.target_blocks) do
        table.insert(blocks, block_name)
    end
    return table.concat(blocks, ", ")
end

-- Show help
function TURTLE_AI:show_help()
    return [[
=== Turtle Mining AI Commands ===

Position & Return:
  position - show current position
  set home - set current position as home
  home - return to home position
  retrace - return home by retracing path

Mining with Return:
  mine return - mine with auto-return (5 min)
  mine <block> <n> return - mine specific block and return
  mine <block> return - mine 64 blocks and return

Examples:
  mine minecraft:diamond_ore 16 return
  mine thermal:tin_ore return
  mine return (mine all known blocks with return)

Basic:
  help - show this help
  status - show status
  learn <block_id> - learn new block
]]
end

-- Main control interface
function TURTLE_AI:start_control()
    if not self:init() then
        return
    end
    
    print("=== Smart Turtle Miner with Return ===")
    print("Version: " .. self.version)
    print("Fuel: " .. self.fuel_level)
    print("Home position set at: 0,0,0")
    print()
    print("NEW: Automatic return home feature!")
    print("Use 'mine return' to automatically return when done")
    print("Use 'home' to return manually at any time")
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
    print("Type 'help' for commands")
    print()
    
    while true do
        write("Miner> ")
        local command = read()
        
        if command == "exit" or command == "quit" or command == "выход" then
            print("Shutting down miner...")
            -- Optional: return home before exit
            write("Return home before exit? (y/n): ")
            local answer = read()
            if string.lower(answer) == "y" then
                self:return_home()
            end
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
