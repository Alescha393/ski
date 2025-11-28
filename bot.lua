-- Turtle Control AI System for ComputerCraft
local turtleAI = {
    name = "TurtleController",
    version = "1.0",
    current_turtle = nil,
    inventory = {},
    fuel_level = 0,
    position = {x = 0, y = 0, z = 0, facing = 0}
}

-- Directions: 0=north, 1=east, 2=south, 3=west
turtleAI.directions = {"north", "east", "south", "west"}

-- Initialize turtle connection
function turtleAI:init()
    if turtle then
        self.current_turtle = turtle
        self:update_status()
        return true
    else
        return false
    end
end

-- Update turtle status
function turtleAI:update_status()
    self.fuel_level = turtle.getFuelLevel()
    
    -- Scan inventory
    self.inventory = {}
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            self.inventory[i] = {
                name = item.name,
                count = item.count,
                damage = item.damage
            }
        end
    end
end

-- Basic movement commands
function turtleAI:move_forward()
    if self.current_turtle.forward() then
        self:update_position("forward")
        return true
    end
    return false
end

function turtleAI:move_back()
    if self.current_turtle.back() then
        self:update_position("back")
        return true
    end
    return false
end

function turtleAI:move_up()
    if self.current_turtle.up() then
        self.position.y = self.position.y + 1
        return true
    end
    return false
end

function turtleAI:move_down()
    if self.current_turtle.down() then
        self.position.y = self.position.y - 1
        return true
    end
    return false
end

function turtleAI:turn_left()
    if self.current_turtle.turnLeft() then
        self.position.facing = (self.position.facing - 1) % 4
        return true
    end
    return false
end

function turtleAI:turn_right()
    if self.current_turtle.turnRight() then
        self.position.facing = (self.position.facing + 1) % 4
        return true
    end
    return false
end

-- Update position based on movement
function turtleAI:update_position(direction)
    local facing = self.position.facing
    
    if direction == "forward" then
        if facing == 0 then self.position.z = self.position.z - 1
        elseif facing == 1 then self.position.x = self.position.x + 1
        elseif facing == 2 then self.position.z = self.position.z + 1
        elseif facing == 3 then self.position.x = self.position.x - 1 end
    elseif direction == "back" then
        if facing == 0 then self.position.z = self.position.z + 1
        elseif facing == 1 then self.position.x = self.position.x - 1
        elseif facing == 2 then self.position.z = self.position.z - 1
        elseif facing == 3 then self.position.x = self.position.x + 1 end
    end
end

-- Mining commands
function turtleAI:dig_forward()
    return self.current_turtle.dig()
end

function turtleAI:dig_up()
    return self.current_turtle.digUp()
end

function turtleAI:dig_down()
    return self.current_turtle.digDown()
end

-- Inventory management
function turtleAI:select_slot(slot)
    if slot >= 1 and slot <= 16 then
        self.current_turtle.select(slot)
        return true
    end
    return false
end

function turtleAI:get_item_count(item_name)
    local total = 0
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == item_name then
            total = total + item.count
        end
    end
    return total
end

function turtleAI:find_item(item_name)
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == item_name then
            return i
        end
    end
    return nil
end

-- Resource collection patterns
function turtleAI:mine_vein(block_name, limit)
    local mined = 0
    local max_attempts = limit or 64
    
    for i = 1, max_attempts do
        local success, data = turtle.inspect()
        if success and string.find(data.name, block_name) then
            if self:dig_forward() then
                mined = mined + 1
                self:update_status()
            end
        else
            break
        end
        
        -- Try moving around the vein
        if not success then
            self:turn_left()
            success, data = turtle.inspect()
            if success and string.find(data.name, block_name) then
                if self:dig_forward() then
                    mined = mined + 1
                    self:update_status()
                end
            else
                self:turn_right()
                self:turn_right()
                success, data = turtle.inspect()
                if success and string.find(data.name, block_name) then
                    if self:dig_forward() then
                        mined = mined + 1
                        self:update_status()
                    end
                else
                    self:turn_left()
                    break
                end
            end
        end
    end
    
    return mined
end

function turtleAI:quarry(depth, width, height)
    local total_mined = 0
    
    for y = 1, height do
        for z = 1, depth do
            for x = 1, width do
                -- Mine current position
                if turtle.dig() then
                    total_mined = total_mined + 1
                end
                
                -- Move forward if not at end of row
                if x < width then
                    self:move_forward()
                end
            end
            
            -- Turn around at end of row
            if z % 2 == 1 then
                if z < depth then
                    self:turn_right()
                    self:move_forward()
                    self:turn_right()
                end
            else
                if z < depth then
                    self:turn_left()
                    self:move_forward()
                    self:turn_left()
                end
            end
        end
        
        -- Move down if not at bottom
        if y < height then
            self:dig_down()
            self:move_down()
        end
    end
    
    self:update_status()
    return total_mined
end

function turtleAI:collect_resources(resource_type, amount)
    local collected = 0
    local target_amount = amount or 64
    
    print("Starting collection of " .. resource_type .. "...")
    
    while collected < target_amount do
        -- Check what's in front
        local success, data = turtle.inspect()
        
        if success and string.find(data.name, resource_type) then
            if self:dig_forward() then
                collected = collected + 1
                self:update_status()
                print("Collected " .. collected .. "/" .. target_amount)
            end
        else
            -- Search pattern
            local found = false
            for _, dir in ipairs({"left", "right", "up", "down"}) do
                if dir == "left" then
                    self:turn_left()
                elseif dir == "right" then
                    self:turn_right()
                elseif dir == "up" then
                    success, data = turtle.inspectUp()
                elseif dir == "down" then
                    success, data = turtle.inspectDown()
                end
                
                if success and string.find(data.name, resource_type) then
                    if dir == "up" then
                        if self:dig_up() then
                            collected = collected + 1
                            found = true
                        end
                    elseif dir == "down" then
                        if self:dig_down() then
                            collected = collected + 1
                            found = true
                        end
                    else
                        if self:dig_forward() then
                            collected = collected + 1
                            found = true
                        end
                    end
                    break
                end
                
                -- Return to original facing
                if dir == "left" then
                    self:turn_right()
                elseif dir == "right" then
                    self:turn_left()
                end
            end
            
            if not found then
                -- Move forward to explore
                if not self:move_forward() then
                    -- Try different direction
                    self:turn_right()
                    if not self:move_forward() then
                        self:turn_left()
                        self:turn_left()
                        self:move_forward()
                    end
                end
            end
        end
        
        -- Check fuel
        if self.fuel_level < 10 then
            print("Low fuel! Need to refuel.")
            break
        end
        
        -- Check inventory space
        local empty_slots = 0
        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                empty_slots = empty_slots + 1
            end
        end
        
        if empty_slots == 0 then
            print("Inventory full!")
            break
        end
        
        if collected >= target_amount then
            break
        end
    end
    
    self:update_status()
    return collected
end

-- Smart resource detection
function turtleAI:smart_mine(resource_list, max_time)
    local start_time = os.time()
    local collected = {}
    
    for _, resource in ipairs(resource_list) do
        collected[resource] = 0
    end
    
    while (max_time == nil or os.time() - start_time < max_time) do
        local found_any = false
        
        -- Check all directions for resources
        for _, resource in ipairs(resource_list) do
            -- Check forward
            local success, data = turtle.inspect()
            if success and self:is_desired_resource(data.name, resource_list) then
                if self:dig_forward() then
                    collected[data.name] = (collected[data.name] or 0) + 1
                    found_any = true
                end
            end
            
            -- Check up
            success, data = turtle.inspectUp()
            if success and self:is_desired_resource(data.name, resource_list) then
                if self:dig_up() then
                    collected[data.name] = (collected[data.name] or 0) + 1
                    found_any = true
                end
            end
            
            -- Check down
            success, data = turtle.inspectDown()
            if success and self:is_desired_resource(data.name, resource_list) then
                if self:dig_down() then
                    collected[data.name] = (collected[data.name] or 0) + 1
                    found_any = true
                end
            end
        end
        
        if not found_any then
            -- Explore new area
            local moves = {"forward", "left", "right", "up", "down"}
            local moved = false
            
            for _, move in ipairs(moves) do
                if move == "forward" and self:move_forward() then
                    moved = true
                    break
                elseif move == "left" then
                    self:turn_left()
                    if self:move_forward() then
                        moved = true
                        break
                    else
                        self:turn_right()
                    end
                elseif move == "right" then
                    self:turn_right()
                    if self:move_forward() then
                        moved = true
                        break
                    else
                        self:turn_left()
                    end
                elseif move == "up" and self:move_up() then
                    moved = true
                    break
                elseif move == "down" and self:move_down() then
                    moved = true
                    break
                end
            end
            
            if not moved then
                print("Stuck! Can't move anywhere.")
                break
            end
        end
        
        self:update_status()
        
        -- Check stopping conditions
        if self.fuel_level < 20 then
            print("Fuel level critical: " .. self.fuel_level)
            break
        end
    end
    
    return collected
end

function turtleAI:is_desired_resource(block_name, resource_list)
    for _, resource in ipairs(resource_list) do
        if string.find(block_name, resource) then
            return true
        end
    end
    return false
end

-- Command parser
function turtleAI:parse_command(command)
    local cmd = string.lower(command)
    
    if string.find(cmd, "move forward") or string.find(cmd, "вперед") then
        return self:move_forward()
    elseif string.find(cmd, "move back") or string.find(cmd, "назад") then
        return self:move_back()
    elseif string.find(cmd, "turn left") or string.find(cmd, "налево") then
        return self:turn_left()
    elseif string.find(cmd, "turn right") or string.find(cmd, "направо") then
        return self:turn_right()
    elseif string.find(cmd, "dig") or string.find(cmd, "копать") then
        return self:dig_forward()
    elseif string.find(cmd, "status") or string.find(cmd, "статус") then
        self:update_status()
        return self:get_status()
    elseif string.find(cmd, "mine coal") or string.find(cmd, "добывать уголь") then
        local amount = tonumber(string.match(cmd, "%d+")) or 64
        return self:collect_resources("coal", amount)
    elseif string.find(cmd, "mine iron") or string.find(cmd, "добывать железо") then
        local amount = tonumber(string.match(cmd, "%d+")) or 64
        return self:collect_resources("iron", amount)
    elseif string.find(cmd, "mine diamond") or string.find(cmd, "добывать алмаз") then
        local amount = tonumber(string.match(cmd, "%d+")) or 16
        return self:collect_resources("diamond", amount)
    elseif string.find(cmd, "mine stone") or string.find(cmd, "добывать камень") then
        local amount = tonumber(string.match(cmd, "%d+")) or 64
        return self:collect_resources("stone", amount)
    else
        return "Unknown command: " .. command
    end
end

-- Get status report
function turtleAI:get_status()
    local status = "=== Turtle Status ===\n"
    status = status .. "Position: " .. self.position.x .. ", " .. self.position.y .. ", " .. self.position.z .. "\n"
    status = status .. "Facing: " .. self.directions[self.position.facing + 1] .. "\n"
    status = status .. "Fuel: " .. self.fuel_level .. "\n"
    status = status .. "Inventory:\n"
    
    for i = 1, 16 do
        if self.inventory[i] then
            status = status .. "  Slot " .. i .. ": " .. self.inventory[i].name .. " x" .. self.inventory[i].count .. "\n"
        end
    end
    
    return status
end

-- Interactive control interface
function turtleAI:start_control()
    if not self:init() then
        print("Error: No turtle found!")
        return
    end
    
    print("=== Turtle Control AI ===")
    print("Turtle initialized successfully!")
    print("Fuel: " .. self.fuel_level)
    print("Position: " .. self.position.x .. ", " .. self.position.y .. ", " .. self.position.z)
    print()
    print("Available commands:")
    print("move forward/back, turn left/right")
    print("dig, mine coal/iron/diamond/stone [amount]")
    print("status, quit")
    print()
    
    while true do
        write("Turtle Command: ")
        local command = read()
        
        if command == "quit" or command == "exit" then
            print("Shutting down turtle control...")
            break
        end
        
        local result = self:parse_command(command)
        print("Result: " .. tostring(result))
        print()
    end
end

-- Start the turtle control system
turtleAI:start_control()
