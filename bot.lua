-- Fixed Turtle AI - Complete Version
-- Use: wget https://raw.githubusercontent.com/Alescha393/ski/main/fixed_miner.lua miner.lua

local TURTLE_AI = {
    name = "FixedMiner",
    version = "4.2",
    current_turtle = nil,
    target_blocks = {},
    home_position = {x = 0, y = 0, z = 0, facing = 0},
    current_position = {x = 0, y = 0, z = 0, facing = 0},
    path_history = {},
    debug_mode = true
}

-- Debug logging
function TURTLE_AI:debug(message)
    if self.debug_mode then
        print("[DEBUG] " .. message)
    end
end

-- Initialize turtle
function TURTLE_AI:init()
    if turtle then
        self.current_turtle = turtle
        print("✓ Turtle connected successfully!")
        
        local fuel = turtle.getFuelLevel()
        print("✓ Fuel level: " .. fuel)
        
        if fuel == 0 then
            print("⚠ WARNING: No fuel! Place coal in inventory and use 'refuel'")
        end
        
        self:set_home()
        self:update_status()
        return true
    else
        print("✗ ERROR: No turtle found!")
        return false
    end
end

-- Set home position
function TURTLE_AI:set_home()
    self.home_position = {
        x = self.current_position.x,
        y = self.current_position.y, 
        z = self.current_position.z,
        facing = self.current_position.facing
    }
    print("✓ Home position set")
    return true
end

-- Update status
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

-- Movement functions
function TURTLE_AI:move_forward()
    self:debug("Attempting to move forward...")
    
    local success, data = turtle.inspect()
    if success then
        self:debug("Block detected: " .. data.name)
        if not turtle.dig() then
            self:debug("Failed to dig block")
            return false
        end
    end
    
    if turtle.forward() then
        self:update_position("forward")
        table.insert(self.path_history, "forward")
        return true
    else
        self:debug("Failed to move forward")
        return false
    end
end

function TURTLE_AI:move_back()
    self:debug("Attempting to move back...")
    
    if turtle.back() then
        self:update_position("back")
        table.insert(self.path_history, "back")
        return true
    else
        self:debug("Failed to move back")
        return false
    end
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
    self:debug("Attempting to move up...")
    
    local success, data = turtle.inspectUp()
    if success then
        self:debug("Block above detected: " .. data.name)
        if not turtle.digUp() then
            self:debug("Failed to dig block above")
            return false
        end
    end
    
    if turtle.up() then
        self.current_position.y = self.current_position.y + 1
        table.insert(self.path_history, "up")
        return true
    else
        self:debug("Failed to move up")
        return false
    end
end

function TURTLE_AI:move_down()
    self:debug("Attempting to move down...")
    
    local success, data = turtle.inspectDown()
    if success then
        self:debug("Block below detected: " .. data.name)
        if not turtle.digDown() then
            self:debug("Failed to dig block below")
            return false
        end
    end
    
    if turtle.down() then
        self.current_position.y = self.current_position.y - 1
        table.insert(self.path_history, "down")
        return true
    else
        self:debug("Failed to move down")
        return false
    end
end

-- Update position
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

-- Test movement
function TURTLE_AI:test_movement()
    print("=== Movement Test ===")
    
    local tests = {
        {name = "Forward", func = function() return self:move_forward() end},
        {name = "Turn Left", func = function() self:turn_left() return true end},
        {name = "Turn Right", func = function() self:turn_right() return true end},
        {name = "Up", func = function() return self:move_up() end},
        {name = "Down", func = function() return self:move_down() end}
    }
    
    for _, test in ipairs(tests) do
        print("Testing " .. test.name .. "...")
        if test.func() then
            print("✓ " .. test.name .. ": SUCCESS")
        else
            print("✗ " .. test.name .. ": FAILED")
        end
    end
    
    self:show_position()
end

-- Refuel function
function TURTLE_AI:refuel()
    local fuel_needed = 64 - turtle.getFuelLevel()
    
    if fuel_needed <= 0 then
        return true, "Already has enough fuel"
    end
    
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            if string.find(item.name, "coal") or string.find(item.name, "lava") then
                turtle.select(i)
                if turtle.refuel(1) then
                    print("✓ Refueled using " .. item.name)
                    self:update_status()
                    return true
                end
            end
        end
    end
    
    print("✗ No fuel items found")
    return false
end

-- Show position
function TURTLE_AI:show_position()
    local directions = {"north", "east", "south", "west"}
    print("📍 Position: X=" .. self.current_position.x .. ", Y=" .. self.current_position.y .. ", Z=" .. self.current_position.z)
end

-- Return home
function TURTLE_AI:return_home()
    print("🔄 Returning home...")
    
    while self.current_position.y > self.home_position.y do
        if not self:move_down() then break end
    end
    
    while self.current_position.y < self.home_position.y do
        if not self:move_up() then break end
    end
    
    while self.current_position.x > self.home_position.x do
        while self.current_position.facing ~= 3 do self:turn_left() end
        if not self:move_forward() then break end
    end
    
    while self.current_position.x < self.home_position.x do
        while self.current_position.facing ~= 1 do self:turn_right() end
        if not self:move_forward() then break end
    end
    
    while self.current_position.z > self.home_position.z do
        while self.current_position.facing ~= 2 do self:turn_left() end
        if not self:move_forward() then break end
    end
    
    while self.current_position.z < self.home_position.z do
        while self.current_position.facing ~= 0 do self:turn_right() end
        if not self:move_forward() then break end
    end
    
    while self.current_position.facing ~= self.home_position.facing do
        self:turn_right()
    end
    
    if self.current_position.x == self.home_position.x and
       self.current_position.y == self.home_position.y and
       self.current_position.z == self.home_position.z then
        print("✅ Successfully returned home!")
        return true
    else
        print("⚠ Returned close to home")
        self:show_position()
        return false
    end
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

-- Learn block
function TURTLE_AI:learn_block(block_name)
    if not self.target_blocks[block_name] then
        self.target_blocks[block_name] = true
        print("📚 Learned: " .. block_name)
        return true
    end
    return false
end

-- Simple mine test
function TURTLE_AI:simple_mine_test()
    print("⛏️ Mining test...")
    
    local success, data = turtle.inspect()
    if success then
        print("Found: " .. data.name)
        if turtle.dig() then
            print("✓ Mined successfully")
            return true
        else
            print("✗ Failed to mine")
            return false
        end
    else
        print("No block in front")
        return false
    end
end

-- Command parser
function TURTLE_AI:parse_command(command)
    local cmd = string.lower(command)
    
    if cmd == "help" then
        return self:show_help()
    elseif cmd == "status" then
        self:update_status()
        return "⛽ Fuel: " .. self.fuel_level
    elseif cmd == "test" then
        self:test_movement()
        return "Test completed"
    elseif cmd == "refuel" then
        return self:refuel() and "Refueled" or "Refuel failed"
    elseif cmd == "forward" then
        return self:move_forward() and "Moved forward" or "Failed"
    elseif cmd == "back" then
        return self:move_back() and "Moved back" or "Failed"
    elseif cmd == "up" then
        return self:move_up() and "Moved up" or "Failed"
    elseif cmd == "down" then
        return self:move_down() and "Moved down" or "Failed"
    elseif cmd == "left" then
        self:turn_left()
        return "Turned left"
    elseif cmd == "right" then
        self:turn_right()
        return "Turned right"
    elseif cmd == "dig" then
        return self:simple_mine_test() and "Mined" or "Mine failed"
    elseif cmd == "home" then
        return self:return_home() and "Home" or "Return failed"
    elseif cmd == "sethome" then
        self:set_home()
        return "Home set"
    elseif string.find(cmd, "learn") then
        local block_name = string.match(cmd, "learn%s+(.+)")
        if block_name then
            return self:learn_block(block_name) and "Learned: " .. block_name or "Known: " .. block_name
        else
            return "Usage: learn <block_name>"
        end
    else
        return "Unknown command"
    end
end

-- Show help
function TURTLE_AI:show_help()
    return [[
=== Turtle Commands ===
Movement: forward, back, up, down, left, right
Actions: dig, refuel, home, sethome
Info: status, test, learn <block>
]]
end

-- Main control
function TURTLE_AI:start_control()
    if not self:init() then
        return
    end
    
    print("=== Fixed Turtle Miner ===")
    print("Type 'test' to test movement")
    print("Type 'help' for commands")
    
    local common_blocks = {
        "minecraft:stone",
        "minecraft:coal_ore",
        "minecraft:iron_ore"
    }
    
    for _, block in ipairs(common_blocks) do
        self:learn_block(block)
    end
    
    while true do
        write("Turtle> ")
        local command = read()
        
        if command == "exit" then
            print("Shutting down...")
            break
        end
        
        local result = self:parse_command(command)
        print(result)
    end
end

-- Start program
TURTLE_AI:start_control()
