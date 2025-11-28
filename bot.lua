-- Advanced Mining Turtle System
-- Use: wget https://raw.githubusercontent.com/Alescha393/ski/main/advanced_miner.lua miner.lua

local MINER = {
    name = "AdvancedMiner",
    version = "5.0",
    config = {
        mine_depth = 50,
        tunnel_length = 100,
        tunnel_width = 3,
        target_blocks = {},
        return_conditions = {
            on_fuel_low = true,
            fuel_threshold = 100,
            on_inventory_full = true,
            on_time_limit = false,
            time_limit_minutes = 60,
            on_blocks_mined = false,
            blocks_limit = 500
        },
        mining_mode = "quarry", -- "quarry", "tunnel", "vein_miner"
        auto_refuel = true,
        emergency_return = true
    },
    status = {
        total_blocks_mined = 0,
        session_start_time = 0,
        current_depth = 0,
        is_mining = false,
        should_return = false
    }
}

-- Configuration Management
function MINER:load_config()
    -- Try to load saved config
    if fs.exists("miner_config.txt") then
        local file = fs.open("miner_config.txt", "r")
        local data = file.readAll()
        file.close()
        self.config = textutils.unserialize(data) or self.config
        print("✓ Configuration loaded")
    else
        print("✓ Using default configuration")
    end
end

function MINER:save_config()
    local file = fs.open("miner_config.txt", "w")
    file.write(textutils.serialize(self.config))
    file.close()
    print("✓ Configuration saved")
end

function MINER:reset_config()
    self.config = {
        mine_depth = 50,
        tunnel_length = 100,
        tunnel_width = 3,
        target_blocks = {},
        return_conditions = {
            on_fuel_low = true,
            fuel_threshold = 100,
            on_inventory_full = true,
            on_time_limit = false,
            time_limit_minutes = 60,
            on_blocks_mined = false,
            blocks_limit = 500
        },
        mining_mode = "quarry",
        auto_refuel = true,
        emergency_return = true
    }
    self:save_config()
    print("✓ Configuration reset to defaults")
end

-- Block Management
function MINER:add_target_block(block_id)
    if not self.config.target_blocks[block_id] then
        self.config.target_blocks[block_id] = true
        print("✓ Added target block: " .. block_id)
        self:save_config()
        return true
    end
    print("ℹ Block already in target list: " .. block_id)
    return false
end

function MINER:remove_target_block(block_id)
    if self.config.target_blocks[block_id] then
        self.config.target_blocks[block_id] = nil
        print("✓ Removed target block: " .. block_id)
        self:save_config()
        return true
    end
    print("✗ Block not found: " .. block_id)
    return false
end

function MINER:list_target_blocks()
    local blocks = {}
    for block_id, _ in pairs(self.config.target_blocks) do
        table.insert(blocks, block_id)
    end
    if #blocks == 0 then
        return "No target blocks configured"
    else
        return "Target blocks: " .. table.concat(blocks, ", ")
    end
end

function MINER:is_target_block(block_name)
    -- Check exact match first
    if self.config.target_blocks[block_name] then
        return true
    end
    
    -- Check partial matches for mod support
    for target_id, _ in pairs(self.config.target_blocks) do
        if string.find(block_name, target_id) then
            return true
        end
    end
    
    return false
end

-- Fuel Management
function MINER:check_fuel()
    local fuel = turtle.getFuelLevel()
    local fuel_limit = turtle.getFuelLimit()
    
    if fuel == "unlimited" then
        return true, 9999
    end
    
    return fuel, fuel_limit
end

function MINER:refuel_if_needed()
    if not self.config.auto_refuel then
        return true
    end
    
    local current_fuel, fuel_limit = self:check_fuel()
    
    -- If fuel is unlimited or we have enough, return
    if current_fuel == true or current_fuel > self.config.return_conditions.fuel_threshold then
        return true
    end
    
    print("⛽ Low fuel (" .. current_fuel .. "), attempting to refuel...")
    
    -- Look for fuel items
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            -- Common fuel items
            if string.find(item.name, "coal") or 
               string.find(item.name, "lava") or
               string.find(item.name, "charcoal") or
               string.find(item.name, "blaze") then
                turtle.select(slot)
                local needed = math.min(64, fuel_limit - current_fuel)
                for i = 1, needed do
                    if turtle.refuel(1) then
                        current_fuel = turtle.getFuelLevel()
                        if current_fuel >= self.config.return_conditions.fuel_threshold then
                            print("✓ Refueled to " .. current_fuel)
                            return true
                        end
                    else
                        break
                    end
                end
            end
        end
    end
    
    print("✗ No fuel items found or refueling failed")
    return false
end

function MINER:should_return_home()
    if self.status.should_return then
        return true
    end
    
    local current_fuel = turtle.getFuelLevel()
    
    -- Check fuel
    if self.config.return_conditions.on_fuel_low and 
       current_fuel <= self.config.return_conditions.fuel_threshold then
        print("⚠ Low fuel, returning home")
        return true
    end
    
    -- Check inventory
    if self.config.return_conditions.on_inventory_full then
        local empty_slots = 0
        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                empty_slots = empty_slots + 1
            end
        end
        if empty_slots <= 2 then
            print("⚠ Inventory full, returning home")
            return true
        end
    end
    
    -- Check time limit
    if self.config.return_conditions.on_time_limit then
        local elapsed = os.time() - self.status.session_start_time
        if elapsed > self.config.return_conditions.time_limit_minutes * 60 then
            print("⚠ Time limit reached, returning home")
            return true
        end
    end
    
    -- Check blocks mined
    if self.config.return_conditions.on_blocks_mined then
        if self.status.total_blocks_mined >= self.config.return_conditions.blocks_limit then
            print("⚠ Block limit reached, returning home")
            return true
        end
    end
    
    return false
end

-- Advanced Movement System
function MINER:smart_move_forward()
    -- Check for blocks and dig if necessary
    local success, data = turtle.inspect()
    if success then
        if self:is_target_block(data.name) then
            if turtle.dig() then
                self.status.total_blocks_mined = self.status.total_blocks_mined + 1
                print("⛏️ Mined: " .. data.name)
            end
        else
            -- Non-target block, check if we should dig through it
            if self.config.mining_mode == "tunnel" then
                turtle.dig()
            else
                return false, "Block in way: " .. data.name
            end
        end
    end
    
    -- Check fuel before moving
    if not self:refuel_if_needed() then
        return false, "Low fuel"
    end
    
    -- Attempt to move
    if turtle.forward() then
        return true
    else
        return false, "Movement blocked"
    end
end

function MINER:smart_move_down()
    local success, data = turtle.inspectDown()
    if success then
        if self:is_target_block(data.name) then
            if turtle.digDown() then
                self.status.total_blocks_mined = self.status.total_blocks_mined + 1
                print("⛏️ Mined below: " .. data.name)
            end
        end
    end
    
    if not self:refuel_if_needed() then
        return false, "Low fuel"
    end
    
    if turtle.down() then
        self.status.current_depth = self.status.current_depth + 1
        return true
    else
        return false, "Cannot move down"
    end
end

function MINER:smart_move_up()
    local success, data = turtle.inspectUp()
    if success then
        if self:is_target_block(data.name) then
            if turtle.digUp() then
                self.status.total_blocks_mined = self.status.total_blocks_mined + 1
                print("⛏️ Mined above: " .. data.name)
            end
        end
    end
    
    if not self:refuel_if_needed() then
        return false, "Low fuel"
    end
    
    if turtle.up() then
        self.status.current_depth = self.status.current_depth - 1
        return true
    else
        return false, "Cannot move up"
    end
end

function MINER:turn_around()
    turtle.turnLeft()
    turtle.turnLeft()
end

-- Mining Patterns
function MINER:dig_to_depth(target_depth)
    print("⬇ Digging to depth: " .. target_depth)
    
    while self.status.current_depth < target_depth do
        if self:should_return_home() then
            return false, "Return condition met"
        end
        
        local success, reason = self:smart_move_down()
        if not success then
            -- Try to handle obstacles
            for i = 1, 4 do
                turtle.turnLeft()
                local moved, _ = self:smart_move_forward()
                if moved then
                    self:smart_move_down()
                    self:smart_move_forward()
                    turtle.turnRight()
                    turtle.turnRight()
                    self:smart_move_forward()
                    turtle.turnLeft()
                    break
                end
            end
        end
        
        -- Scan and mine blocks around while descending
        self:scan_and_mine_around()
    end
    
    print("✓ Reached target depth: " .. target_depth)
    return true
end

function MINER:scan_and_mine_around()
    -- Check all directions for target blocks
    local directions = {
        {name = "forward", inspect = turtle.inspect, dig = turtle.dig},
        {name = "up", inspect = turtle.inspectUp, dig = turtle.digUp},
        {name = "down", inspect = turtle.inspectDown, dig = turtle.digDown},
        {name = "left", turn = turtle.turnLeft, restore = turtle.turnRight},
        {name = "right", turn = turtle.turnRight, restore = turtle.turnLeft}
    }
    
    for _, dir in ipairs(directions) do
        if self:should_return_home() then
            break
        end
        
        if dir.turn then
            dir.turn()
        end
        
        local success, data = dir.inspect()
        if success and self:is_target_block(data.name) then
            dir.dig()
            self.status.total_blocks_mined = self.status.total_blocks_mined + 1
            print("⛏️ Mined " .. dir.name .. ": " .. data.name)
        end
        
        if dir.restore then
            dir.restore()
        end
    end
end

function MINER:mine_quarry_pattern()
    print("🏗️ Starting quarry mining pattern...")
    
    local mined_in_layer = 0
    for x = 1, self.config.tunnel_width do
        for z = 1, self.config.tunnel_length do
            if self:should_return_home() then
                return
            end
            
            -- Mine current position and around
            self:scan_and_mine_around()
            
            -- Move forward if not at end of row
            if z < self.config.tunnel_length then
                local success, reason = self:smart_move_forward()
                if not success then
                    print("⚠ Cannot move forward: " .. reason)
                    break
                end
            end
        end
        
        -- Turn around at end of row
        if x < self.config.tunnel_width then
            if x % 2 == 1 then
                turtle.turnRight()
                self:smart_move_forward()
                turtle.turnRight()
            else
                turtle.turnLeft()
                self:smart_move_forward()
                turtle.turnLeft()
            end
        end
    end
end

function MINER:mine_tunnel_pattern()
    print("🚇 Starting tunnel mining pattern...")
    
    for i = 1, self.config.tunnel_length do
        if self:should_return_home() then
            return
        end
        
        -- Mine forward and check sides
        self:scan_and_mine_around()
        
        local success, reason = self:smart_move_forward()
        if not success then
            print("⚠ Cannot continue tunnel: " .. reason)
            break
        end
    end
end

function MINER:mine_vein_pattern()
    print("🕸️ Starting vein mining pattern...")
    
    local visited_positions = {}
    local queue = {{x=0, y=0, z=0}}
    
    while #queue > 0 and not self:should_return_home() do
        -- This is a simplified vein miner - would need position tracking
        self:scan_and_mine_around()
        
        -- Try to find connected veins
        for _, dir in ipairs({"forward", "up", "down", "left", "right"}) do
            local moved = false
            if dir == "left" then turtle.turnLeft() end
            if dir == "right" then turtle.turnRight() end
            
            local success, data = turtle.inspect()
            if success and self:is_target_block(data.name) then
                if dir == "forward" then
                    turtle.dig()
                    turtle.forward()
                    moved = true
                elseif dir == "up" then
                    turtle.digUp()
                    turtle.up()
                    moved = true
                elseif dir == "down" then
                    turtle.digDown()
                    turtle.down()
                    moved = true
                end
            end
            
            if moved then
                self.status.total_blocks_mined = self.status.total_blocks_mined + 1
                self:scan_and_mine_around()
                
                -- Return to original position
                if dir == "forward" then
                    self:turn_around()
                    turtle.forward()
                    self:turn_around()
                elseif dir == "up" then
                    turtle.down()
                elseif dir == "down" then
                    turtle.up()
                end
            end
            
            if dir == "left" then turtle.turnRight() end
            if dir == "right" then turtle.turnLeft() end
        end
        
        table.remove(queue, 1)
    end
end

-- Return System
function MINER:return_to_surface()
    print("🔼 Returning to surface...")
    
    while self.status.current_depth > 0 do
        local success, reason = self:smart_move_up()
        if not success then
            print("⚠ Cannot move up: " .. reason)
            -- Try to dig if blocked
            if turtle.digUp() then
                print("⛏️ Cleared blockage above")
            else
                -- Emergency escape - try to move horizontally
                for i = 1, 4 do
                    turtle.turnLeft()
                    if turtle.forward() then
                        print("➡ Emergency horizontal move")
                        break
                    end
                end
            end
        end
    end
    
    print("✅ Successfully returned to surface!")
    self.status.is_mining = false
end

-- Main Mining Function
function MINER:start_mining_session()
    if not turtle then
        print("✗ This program must be run on a turtle!")
        return false
    end
    
    local fuel, limit = self:check_fuel()
    if fuel ~= true and fuel < 50 then
        print("✗ Not enough fuel to start mining")
        print("Current fuel: " .. fuel .. "/" .. limit)
        return false
    end
    
    if next(self.config.target_blocks) == nil then
        print("✗ No target blocks configured!")
        print("Use 'addblock <block_id>' to add blocks to mine")
        return false
    end
    
    -- Initialize mining session
    self.status = {
        total_blocks_mined = 0,
        session_start_time = os.time(),
        current_depth = 0,
        is_mining = true,
        should_return = false
    }
    
    print("⛏️ Starting mining session...")
    print("Target blocks: " .. self:list_target_blocks())
    print("Mining mode: " .. self.config.mining_mode)
    print("Fuel: " .. fuel .. "/" .. limit)
    
    -- Dig to target depth
    local success, reason = self:dig_to_depth(self.config.mine_depth)
    if not success then
        print("⚠ " .. reason)
        if self.config.emergency_return then
            self:return_to_surface()
        end
        return false
    end
    
    -- Execute mining pattern based on mode
    if self.config.mining_mode == "quarry" then
        self:mine_quarry_pattern()
    elseif self.config.mining_mode == "tunnel" then
        self:mine_tunnel_pattern()
    elseif self.config.mining_mode == "vein_miner" then
        self:mine_vein_pattern()
    end
    
    -- Return to surface
    self:return_to_surface()
    
    -- Session summary
    local session_time = os.time() - self.status.session_start_time
    print("📊 Mining session completed!")
    print("⏱️  Time: " .. session_time .. " seconds")
    print("⛏️  Blocks mined: " .. self.status.total_blocks_mined)
    
    return true
end

-- Command Interface
function MINER:show_status()
    local fuel, limit = self:check_fuel()
    return string.format([[
=== Mining Turtle Status ===
Fuel: %s/%s
Depth: %d
Blocks mined: %d
Mining: %s
Target blocks: %d
Mining mode: %s
]], fuel, limit, self.status.current_depth, self.status.total_blocks_mined,
   tostring(self.status.is_mining), self:count_target_blocks(), self.config.mining_mode)
end

function MINER:count_target_blocks()
    local count = 0
    for _ in pairs(self.config.target_blocks) do
        count = count + 1
    end
    return count
end

function MINER:parse_command(command)
    local cmd = string.lower(command)
    
    if cmd == "help" then
        return self:show_help()
        
    elseif cmd == "status" then
        return self:show_status()
        
    elseif cmd == "start" then
        self:start_mining_session()
        return "Mining session completed"
        
    elseif cmd == "return" then
        self.status.should_return = true
        return "Returning home on next check"
        
    elseif cmd == "emergency" then
        self:return_to_surface()
        return "Emergency return executed"
        
    elseif string.find(cmd, "addblock") then
        local block_id = string.match(cmd, "addblock%s+(.+)")
        if block_id then
            return self:add_target_block(block_id) and "Block added" or "Block already exists"
        else
            return "Usage: addblock <block_id>"
        end
        
    elseif string.find(cmd, "removeblock") then
        local block_id = string.match(cmd, "removeblock%s+(.+)")
        if block_id then
            return self:remove_target_block(block_id) and "Block removed" or "Block not found"
        else
            return "Usage: removeblock <block_id>"
        end
        
    elseif cmd == "listblocks" then
        return self:list_target_blocks()
        
    elseif string.find(cmd, "set depth") then
        local depth = tonumber(string.match(cmd, "set depth%s+(%d+)"))
        if depth and depth > 0 then
            self.config.mine_depth = depth
            self:save_config()
            return "Mining depth set to: " .. depth
        else
            return "Usage: set depth <number>"
        end
        
    elseif string.find(cmd, "set mode") then
        local mode = string.match(cmd, "set mode%s+(%a+)")
        if mode and (mode == "quarry" or mode == "tunnel" or mode == "vein_miner") then
            self.config.mining_mode = mode
            self:save_config()
            return "Mining mode set to: " .. mode
        else
            return "Usage: set mode <quarry|tunnel|vein_miner>"
        end
        
    elseif cmd == "config" then
        self:show_config()
        return ""
        
    elseif cmd == "reset" then
        self:reset_config()
        return "Configuration reset"
        
    else
        return "Unknown command. Type 'help' for available commands."
    end
end

function MINER:show_config()
    print("=== Current Configuration ===")
    print("Mining depth: " .. self.config.mine_depth)
    print("Tunnel length: " .. self.config.tunnel_length)
    print("Tunnel width: " .. self.config.tunnel_width)
    print("Mining mode: " .. self.config.mining_mode)
    print("Auto refuel: " .. tostring(self.config.auto_refuel))
    print("Emergency return: " .. tostring(self.config.emergency_return))
    print("\nReturn conditions:")
    print("  On low fuel: " .. tostring(self.config.return_conditions.on_fuel_low))
    print("  Fuel threshold: " .. self.config.return_conditions.fuel_threshold)
    print("  On inventory full: " .. tostring(self.config.return_conditions.on_inventory_full))
    print("  On time limit: " .. tostring(self.config.return_conditions.on_time_limit))
    if self.config.return_conditions.on_time_limit then
        print("  Time limit: " .. self.config.return_conditions.time_limit_minutes .. " minutes")
    end
    print("  On blocks mined: " .. tostring(self.config.return_conditions.on_blocks_mined))
    if self.config.return_conditions.on_blocks_mined then
        print("  Blocks limit: " .. self.config.return_conditions.blocks_limit)
    end
end

function MINER:show_help()
    return [[
=== Advanced Mining Turtle ===

Basic Commands:
  start          - Begin mining session
  status         - Show current status
  return         - Signal to return home
  emergency      - Immediate return to surface

Block Management:
  addblock <id>  - Add block to mine (e.g. minecraft:diamond_ore)
  removeblock <id> - Remove block from targets
  listblocks     - List target blocks

Configuration:
  set depth <n>  - Set mining depth
  set mode <type> - Set mining mode (quarry/tunnel/vein_miner)
  config         - Show current configuration
  reset          - Reset to default configuration

Examples:
  addblock minecraft:iron_ore
  addblock thermal:tin_ore
  set depth 30
  set mode quarry
  start
]]
end

-- Initialize and start
function MINER:start_control()
    self:load_config()
    
    print("=== Advanced Mining Turtle ===")
    print("Version: " .. self.version)
    print("Type 'help' for commands")
    print("Configure target blocks before starting!")
    print()
    
    while true do
        write("Miner> ")
        local command = read()
        
        if command == "exit" or command == "quit" then
            print("Goodbye!")
            break
        end
        
        local result = self:parse_command(command)
        if result ~= "" then
            print(result)
        end
        print()
    end
end

-- Start the program
MINER:start_control()
