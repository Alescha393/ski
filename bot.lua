-- Fixed Turtle AI with Movement Debugging
-- Use: wget https://raw.githubusercontent.com/Alescha393/ski/main/fixed_miner.lua miner.lua

local TURTLE_AI = {
    name = "FixedMiner",
    version = "4.1",
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

-- Initialize turtle with better error handling
function TURTLE_AI:init()
    if turtle then
        self.current_turtle = turtle
        print("✓ Turtle connected successfully!")
        
        -- Check fuel
        local fuel = turtle.getFuelLevel()
        print("✓ Fuel level: " .. fuel)
        
        if fuel == 0 then
            print("⚠ WARNING: No fuel! Turtle cannot move.")
            print("Place coal or other fuel in inventory and use 'refuel'")
        end
        
        -- Set home position
        self:set_home()
        self:update_status()
        return true
    else
        print("✗ ERROR: No turtle found!")
        print("Please run this program on a turtle, not a computer")
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
    print("✓ Home position set to: " .. self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z)
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

-- Improved movement with obstacle handling
function TURTLE_AI:move_forward()
    self:debug("Attempting to move forward...")
    
    -- Check if there's a block in front
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
        self:debug("Moved forward to: " .. self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z)
        return true
    else
        self:debug("Failed to move forward")
        return false
end

function TURTLE_AI:move_back()
    self:debug("Attempting to move back...")
    
    if turtle.back() then
        self:update_position("back")
        table.insert(self.path_history, "back")
        self:debug("Moved back to: " .. self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z)
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
    self:debug("Turned left, now facing: " .. self.current_position.facing)
    return true
end

function TURTLE_AI:turn_right()
    turtle.turnRight()
    self.current_position.facing = (self.current_position.facing + 1) % 4
    table.insert(self.path_history, "turn_right")
    self:debug("Turned right, now facing: " .. self.current_position.facing)
    return true
end

function TURTLE_AI:move_up()
    self:debug("Attempting to move up...")
    
    -- Check if there's a block above
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
        self:debug("Moved up to: " .. self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z)
        return true
    else
        self:debug("Failed to move up")
        return false
    end
end

function TURTLE_AI:move_down()
    self:debug("Attempting to move down...")
    
    -- Check if there's a block below
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
        self:debug("Moved down to: " .. self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z)
        return true
    else
        self:debug("Failed to move down")
        return false
    end
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

-- Test basic movement
function TURTLE_AI:test_movement()
    print("=== Movement Test ===")
    
    print("Testing forward movement...")
    if self:move_forward() then
        print("✓ Forward movement: SUCCESS")
    else
        print("✗ Forward movement: FAILED")
    end
    
    print("Testing turn left...")
    self:turn_left()
    print("✓ Turn left: SUCCESS")
    
    print("Testing turn right...")
    self:turn_right()
    print("✓ Turn right: SUCCESS")
    
    print("Testing up movement...")
    if self:move_up() then
        print("✓ Up movement: SUCCESS")
    else
        print("✗ Up movement: FAILED")
    end
    
    print("Testing down movement...")
    if self:move_down() then
        print("✓ Down movement: SUCCESS")
    else
        print("✗ Down movement: FAILED")
    end
    
    self:show_position()
end

-- Refuel function
function TURTLE_AI:refuel(amount)
    amount = amount or 64
    local fuel_needed = amount - turtle.getFuelLevel()
    
    if fuel_needed <= 0 then
        return true, "Already has enough fuel"
    end
    
    -- Look for fuel items
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            if string.find(item.name, "coal") or 
               string.find(item.name, "lava") or
               string.find(item.name, "fuel") then
                turtle.select(i)
                if turtle.refuel(1) then
                    print("✓ Refueled using " .. item.name)
                    self:update_status()
                    return true
                end
            end
        end
    end
    
    print("✗ No fuel items found in inventory")
    return false
end

-- Show current position
function TURTLE_AI:show_position()
    local directions = {"north", "east", "south", "west"}
    print("📍 Position: X=" .. self.current_position.x .. 
          ", Y=" .. self.current_position.y .. 
          ", Z=" .. self.current_position.z .. 
          ", Facing=" .. directions[self.current_position.facing + 1])
end

-- Calculate distance to home
function TURTLE_AI:get_distance_to_home()
    local dx = math.abs(self.current_position.x - self.home_position.x)
    local dy = math.abs(self.current_position.y - self.home_position.y)
    local dz = math.abs(self.current_position.z - self.home_position.z)
    return dx + dy + dz
end

-- Simple return home (direct path)
function TURTLE_AI:return_home_simple()
    print("🔄 Returning home (simple path)...")
    
    -- First align Y coordinate
    while self.current_position.y > self.home_position.y do
        if not self:move_down() then
            print("✗ Cannot move down, trying to dig...")
            if not self:dig_down() then
                print("✗ Cannot dig down either")
                break
            end
        end
    end
    
    while self.current_position.y < self.home_position.y do
        if not self:move_up() then
            print("✗ Cannot move up, trying to dig...")
            if not self:dig_up() then
                print("✗ Cannot dig up either")
                break
            end
        end
    end
    
    -- Then align X coordinate
    while self.current_position.x > self.home_position.x do
        -- Face west
        while self.current_position.facing ~= 3 do
            self:turn_left()
        end
        if not self:move_forward() then
            print("✗ Cannot move west")
            break
        end
    end
    
    while self.current_position.x < self.home_position.x do
        -- Face east
        while self.current_position.facing ~= 1 do
            self:turn_right()
        end
        if not self:move_forward() then
            print("✗ Cannot move east")
            break
        end
    end
    
    -- Finally align Z coordinate
    while self.current_position.z > self.home_position.z do
        -- Face south
        while self.current_position.facing ~= 2 do
            self:turn_left()
        end
        if not self:move_forward() then
            print("✗ Cannot move south")
            break
        end
    end
    
    while self.current_position.z < self.home_position.z do
        -- Face north
        while self.current_position.facing ~= 0 do
            self:turn_right()
        end
        if not self:move_forward() then
            print("✗ Cannot move north")
            break
        end
    end
    
    -- Face original direction
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

-- Learn new block ID
function TURTLE_AI:learn_block(block_name)
    if not self.target_blocks[block_name] then
        self.target_blocks[block_name] = true
        print("📚 Learned new block: " .. block_name)
        return true
    end
    return false
end

-- Simple mining with movement test
function TURTLE_AI:simple_mine_test()
    print("⛏️ Starting simple mining test...")
    
    -- Try to mine forward
    local success, data = turtle.inspect()
    if success then
        print("Found block: " .. data.name)
        if turtle.dig() then
            print("✓ Successfully mined block")
            return true
        else
            print("✗ Failed to mine block")
            return false
        end
    else
        print("No block in front")
        return false
    end
end

-- Command parser with simple commands
function TURTLE_AI:parse_command(command)
    local cmd = string.lower(command)
    
    if cmd == "help" then
        return self:show_help()
    
    elseif cmd == "status" then
        self:update_status()
        return "⛽ Fuel: " .. self.fuel_level .. 
               " | 📍 Position: " .. self.current_position.x .. "," .. self.current_position.y .. "," .. self.current_position.z
    
    elseif cmd == "test" then
        self:test_movement()
        return "Movement test completed"
    
    elseif cmd == "refuel" then
        return self:refuel() and "Refueled successfully" or "Refuel failed"
    
    elseif cmd == "forward" or cmd == "f" then
        return self:move_forward() and "Moved forward" or "Failed to move forward"
    
    elseif cmd == "back" or cmd == "b" then
        return self:move_back() and "Moved back" or "Failed to move back"
    
    elseif cmd == "up" or cmd == "u" then
        return self:move_up() and "Moved up" or "Failed to move up"
    
    elseif cmd == "down" or cmd == "d" then
        return self:move_down() and "Moved down" or "Failed to move down"
    
    elseif cmd == "left" or cmd == "l" then
        self:turn_left()
        return "Turned left"
    
    elseif cmd == "right" or cmd == "r" then
        self:turn_right()
        return "Turned right"
    
    elseif cmd == "dig" then
        return self:simple_mine_test() and "Mining test completed" or "Mining test failed"
    
    elseif cmd == "home" then
        return self:return_home_simple() and "Returned home" or "Return home failed"
    
    elseif cmd == "sethome" then
        self:set_home()
        return "Home position set"
    
    elseif string.find(cmd, "learn") then
        local block_name = string.match(cmd, "learn%s+(.+)")
        if block_name then
            return self:learn_block(block_name) and "Learned: " .. block_name or "Already known: " .. block_name
        else
            return "Usage: learn <block_name>"
        end
    
    else
        return "Unknown command. Type 'help' for available commands."
    end
end

-- Show help
function TURTLE_AI:show_help()
    return [[
=== Turtle Commands ===

Movement:
  forward, f    - Move forward
  back, b       - Move back  
  up, u         - Move up
  down, d       - Move down
  left, l       - Turn left
  right, r      - Turn right

Actions:
  dig           - Mine block in front
  refuel        - Refuel turtle
  home          - Return to home
  sethome       - Set current position as home

Info:
  status        - Show fuel and position
  test          - Test all movements
  learn <block> - Learn new block type

Examples:
  learn minecraft:stone
  learn minecraft:coal_ore
  learn minecraft:iron_ore
]]
end

-- Main control interface
function TURTLE_AI:start_control()
    if not self:init() then
        return
    end
    
    print("=== Fixed Turtle Miner ===")
    print("Version: " .. self.version)
    print()
    print("IMPORTANT: Make sure turtle has fuel!")
    print("Use 'refuel' command if needed")
    print()
    print("Type 'test' to test movement")
    print("Type 'help' for all commands")
    print()
    
    -- Pre-learn common blocks
    local common_blocks = {
        "minecraft:stone",
        "minecraft:coal_ore",
        "minecraft:iron_ore", 
        "minecraft:gold_ore",
        "minecraft:diamond_ore"
    }
    
    for _, block in ipairs(common_blocks) do
        self:learn_block(block)
    end
    
    while true do
        write("Turtle> ")
        local command = read()
        
        if command == "exit" or command == "quit" then
            print("Shutting down...")
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
