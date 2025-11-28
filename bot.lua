-- ULTIMATE MINING TURTLE 9000
-- Advanced AI-Powered Mining System
-- wget https://raw.githubusercontent.com/Alescha393/ski/main/ultimate_miner.lua miner.lua

local ULTIMATE_MINER = {
    name = "UltimateMiner9000",
    version = "10.0",
    config_file = "miner_config.dat",
    state_file = "miner_state.dat"
}

-- ========== CORE SYSTEMS ==========
ULTIMATE_MINER.config = {
    -- Mining parameters
    depth = 50,
    length = 100,
    width = 3,
    height = 3,
    
    -- Mining modes
    mode = "quarry", -- quarry, tunnel, vein, branch, spiral, layered
    
    -- Return conditions
    fuel_threshold = 100,
    inventory_threshold = 2,
    time_limit = 3600, -- seconds
    block_limit = 1000,
    
    -- Behavior
    auto_refuel = true,
    emergency_return = true,
    smart_pathfinding = true,
    avoid_lava = true,
    
    -- Target blocks
    targets = {
        "minecraft:coal_ore",
        "minecraft:iron_ore",
        "minecraft:gold_ore",
        "minecraft:diamond_ore",
        "minecraft:redstone_ore",
        "minecraft:lapis_ore"
    }
}

ULTIMATE_MINER.state = {
    -- Position tracking
    position = {x=0, y=0, z=0, facing=0},
    home = {x=0, y=0, z=0, facing=0},
    path_history = {},
    
    -- Mining stats
    blocks_mined = 0,
    session_start = 0,
    session_time = 0,
    total_blocks = 0,
    
    -- System state
    is_mining = false,
    is_paused = false,
    should_return = false,
    emergency_mode = false
}

-- ========== CONFIGURATION SYSTEM ==========
function ULTIMATE_MINER:save_config()
    local data = textutils.serialize(self.config)
    local file = fs.open(self.config_file, "w")
    file.write(data)
    file.close()
end

function ULTIMATE_MINER:load_config()
    if fs.exists(self.config_file) then
        local file = fs.open(self.config_file, "r")
        local data = file.readAll()
        file.close()
        self.config = textutils.unserialize(data) or self.config
    end
end

function ULTIMATE_MINER:save_state()
    local data = textutils.serialize(self.state)
    local file = fs.open(self.state_file, "w")
    file.write(data)
    file.close()
end

function ULTIMATE_MINER:load_state()
    if fs.exists(self.state_file) then
        local file = fs.open(self.state_file, "r")
        local data = file.readAll()
        file.close()
        self.state = textutils.unserialize(data) or self.state
    end
end

function ULTIMATE_MINER:reset_config()
    self.config = {
        depth = 50,
        length = 100,
        width = 3,
        height = 3,
        mode = "quarry",
        fuel_threshold = 100,
        inventory_threshold = 2,
        time_limit = 3600,
        block_limit = 1000,
        auto_refuel = true,
        emergency_return = true,
        smart_pathfinding = true,
        avoid_lava = true,
        targets = {
            "minecraft:coal_ore",
            "minecraft:iron_ore",
            "minecraft:gold_ore",
            "minecraft:diamond_ore",
            "minecraft:redstone_ore",
            "minecraft:lapis_ore"
        }
    }
    self:save_config()
end

-- ========== BLOCK MANAGEMENT SYSTEM ==========
function ULTIMATE_MINER:add_block(block_id)
    for _, target in ipairs(self.config.targets) do
        if target == block_id then
            return false, "Block already in list"
        end
    end
    table.insert(self.config.targets, block_id)
    self:save_config()
    return true, "Block added: " .. block_id
end

function ULTIMATE_MINER:remove_block(block_id)
    for i, target in ipairs(self.config.targets) do
        if target == block_id then
            table.remove(self.config.targets, i)
            self:save_config()
            return true, "Block removed: " .. block_id
        end
    end
    return false, "Block not found: " .. block_id
end

function ULTIMATE_MINER:clear_blocks()
    self.config.targets = {}
    self:save_config()
    return true, "All blocks cleared"
end

function ULTIMATE_MINER:list_blocks()
    if #self.config.targets == 0 then
        return "No target blocks configured"
    end
    return "Target blocks: " .. table.concat(self.config.targets, ", ")
end

function ULTIMATE_MINER:is_target_block(block_name)
    for _, target in ipairs(self.config.targets) do
        if string.find(block_name, target) then
            return true
        end
    end
    return false
end

-- ========== FUEL MANAGEMENT SYSTEM ==========
function ULTIMATE_MINER:get_fuel_info()
    local current = turtle.getFuelLevel()
    local limit = turtle.getFuelLimit()
    local percent = math.floor((current / limit) * 100)
    return current, limit, percent
end

function ULTIMATE_MINER:refuel()
    local fuels = {
        "minecraft:coal",
        "minecraft:coal_block",
        "minecraft:lava_bucket",
        "minecraft:blaze_rod",
        "minecraft:charcoal"
    }
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            for _, fuel in ipairs(fuels) do
                if string.find(item.name, fuel) then
                    turtle.select(slot)
                    local needed = math.min(64, turtle.getFuelLimit() - turtle.getFuelLevel())
                    for i = 1, needed do
                        if turtle.refuel(1) then
                            local new_fuel = turtle.getFuelLevel()
                            if new_fuel >= self.config.fuel_threshold then
                                return true, "Refueled to " .. new_fuel
                            end
                        else
                            break
                        end
                    end
                end
            end
        end
    end
    return false, "No fuel items found"
end

function ULTIMATE_MINER:check_fuel()
    local current, limit, percent = self:get_fuel_info()
    if current <= self.config.fuel_threshold then
        if self.config.auto_refuel then
            return self:refuel()
        else
            return false, "Low fuel: " .. current
        end
    end
    return true, "Fuel OK: " .. current
end

-- ========== INVENTORY MANAGEMENT SYSTEM ==========
function ULTIMATE_MINER:get_inventory_info()
    local used = 0
    local total = 16
    for i = 1, total do
        if turtle.getItemCount(i) > 0 then
            used = used + 1
        end
    end
    local free = total - used
    return used, free, total
end

function ULTIMATE_MINER:drop_items(slot)
    if slot == "all" then
        for i = 1, 16 do
            turtle.select(i)
            turtle.drop()
        end
        return true, "All items dropped"
    else
        slot = tonumber(slot)
        if slot and slot >= 1 and slot <= 16 then
            turtle.select(slot)
            turtle.drop()
            return true, "Slot " .. slot .. " dropped"
        end
    end
    return false, "Invalid slot"
end

function ULTIMATE_MINER:store_items()
    -- Try to place items in chest
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount(i) > 0 then
            if turtle.drop() then
                -- Success
            end
        end
    end
    return true, "Items stored"
end

-- ========== MOVEMENT SYSTEM ==========
function ULTIMATE_MINER:update_position(direction)
    local facing = self.state.position.facing
    
    if direction == "forward" then
        if facing == 0 then self.state.position.z = self.state.position.z - 1
        elseif facing == 1 then self.state.position.x = self.state.position.x + 1
        elseif facing == 2 then self.state.position.z = self.state.position.z + 1
        elseif facing == 3 then self.state.position.x = self.state.position.x - 1 end
    elseif direction == "back" then
        if facing == 0 then self.state.position.z = self.state.position.z + 1
        elseif facing == 1 then self.state.position.x = self.state.position.x - 1
        elseif facing == 2 then self.state.position.z = self.state.position.z - 1
        elseif facing == 3 then self.state.position.x = self.state.position.x + 1 end
    elseif direction == "up" then
        self.state.position.y = self.state.position.y + 1
    elseif direction == "down" then
        self.state.position.y = self.state.position.y - 1
    end
    
    table.insert(self.state.path_history, {
        direction = direction,
        position = {x=self.state.position.x, y=self.state.position.y, z=self.state.position.z},
        time = os.time()
    })
    
    if #self.state.path_history > 1000 then
        table.remove(self.state.path_history, 1)
    end
end

function ULTIMATE_MINER:smart_move(direction)
    -- Check fuel first
    local fuel_ok, fuel_msg = self:check_fuel()
    if not fuel_ok then
        return false, fuel_msg
    end
    
    -- Check for blocks and handle them
    local success, data
    if direction == "forward" then
        success, data = turtle.inspect()
        if success then
            if self:is_target_block(data.name) then
                if turtle.dig() then
                    self.state.blocks_mined = self.state.blocks_mined + 1
                    self.state.total_blocks = self.state.total_blocks + 1
                end
            else
                -- Non-target block
                if self.config.mode == "tunnel" then
                    turtle.dig()
                end
            end
        end
        success = turtle.forward()
    elseif direction == "back" then
        success = turtle.back()
    elseif direction == "up" then
        success, data = turtle.inspectUp()
        if success and self:is_target_block(data.name) then
            turtle.digUp()
            self.state.blocks_mined = self.state.blocks_mined + 1
            self.state.total_blocks = self.state.total_blocks + 1
        end
        success = turtle.up()
    elseif direction == "down" then
        success, data = turtle.inspectDown()
        if success and self:is_target_block(data.name) then
            turtle.digDown()
            self.state.blocks_mined = self.state.blocks_mined + 1
            self.state.total_blocks = self.state.total_blocks + 1
        end
        success = turtle.down()
    end
    
    if success then
        self:update_position(direction)
        self:save_state()
        return true, "Moved " .. direction
    end
    
    return false, "Cannot move " .. direction
end

function ULTIMATE_MINER:turn_left()
    turtle.turnLeft()
    self.state.position.facing = (self.state.position.facing - 1) % 4
    self:save_state()
end

function ULTIMATE_MINER:turn_right()
    turtle.turnRight()
    self.state.position.facing = (self.state.position.facing + 1) % 4
    self:save_state()
end

function ULTIMATE_MINER:face_direction(target_facing)
    while self.state.position.facing ~= target_facing do
        local diff = (target_facing - self.state.position.facing) % 4
        if diff <= 2 then
            self:turn_right()
        else
            self:turn_left()
        end
    end
end

-- ========== MINING PATTERNS ==========
function ULTIMATE_MINER:mine_quarry()
    print("🏗️ Starting quarry mining...")
    
    for layer = 1, self.config.depth do
        if self:should_stop_mining() then break end
        
        print("⏬ Moving to layer " .. layer)
        for i = 1, self.config.height do
            self:smart_move("down")
        end
        
        for x = 1, self.config.width do
            for z = 1, self.config.length do
                if self:should_stop_mining() then break end
                
                -- Mine around current position
                self:mine_around()
                
                if z < self.config.length then
                    self:smart_move("forward")
                end
            end
            
            if x < self.config.width then
                if x % 2 == 1 then
                    self:turn_right()
                    self:smart_move("forward")
                    self:turn_right()
                else
                    self:turn_left()
                    self:smart_move("forward")
                    self:turn_left()
                end
            end
        end
        
        -- Return to start of layer position
        self:return_to_layer_start()
    end
end

function ULTIMATE_MINER:mine_tunnel()
    print("🚇 Starting tunnel mining...")
    
    for i = 1, self.config.length do
        if self:should_stop_mining() then break end
        
        self:mine_around()
        self:smart_move("forward")
    end
end

function ULTIMATE_MINER:mine_vein()
    print("🕸️ Starting vein mining...")
    
    local visited = {}
    local queue = {{x=0, y=0, z=0}}
    
    while #queue > 0 and not self:should_stop_mining() do
        self:mine_around()
        
        -- Check adjacent blocks for same vein
        local directions = {
            {dx=1, dy=0, dz=0}, {dx=-1, dy=0, dz=0},
            {dx=0, dy=1, dz=0}, {dx=0, dy=-1, dz=0},
            {dx=0, dy=0, dz=1}, {dx=0, dy=0, dz=-1}
        }
        
        for _, dir in ipairs(directions) do
            local new_pos = {
                x = self.state.position.x + dir.dx,
                y = self.state.position.y + dir.dy, 
                z = self.state.position.z + dir.dz
            }
            
            local pos_key = new_pos.x .. "," .. new_pos.y .. "," .. new_pos.z
            if not visited[pos_key] then
                visited[pos_key] = true
                table.insert(queue, new_pos)
            end
        end
        
        if #queue > 0 then
            local next_pos = table.remove(queue, 1)
            self:move_to_position(next_pos)
        end
    end
end

function ULTIMATE_MINER:mine_branch()
    print("🌿 Starting branch mining...")
    
    local main_tunnel_length = math.floor(self.config.length / 3)
    
    -- Dig main tunnel
    for i = 1, main_tunnel_length do
        if self:should_stop_mining() then break end
        self:mine_around()
        self:smart_move("forward")
    end
    
    -- Dig branches
    for branch = 1, self.config.width do
        if self:should_stop_mining() then break end
        
        self:turn_right()
        for i = 1, self.config.length do
            if self:should_stop_mining() then break end
            self:mine_around()
            self:smart_move("forward")
        end
        
        -- Return to main tunnel
        self:turn_around()
        for i = 1, self.config.length do
            self:smart_move("forward")
        end
        self:turn_right()
        
        if branch < self.config.width then
            self:smart_move("forward")
        end
    end
end

function ULTIMATE_MINER:mine_around()
    -- Check all directions for target blocks
    local checks = {
        {name="forward", inspect=turtle.inspect, dig=turtle.dig},
        {name="up", inspect=turtle.inspectUp, dig=turtle.digUp},
        {name="down", inspect=turtle.inspectDown, dig=turtle.digDown},
        {name="left", turn=self.turn_left, restore=self.turn_right},
        {name="right", turn=self.turn_right, restore=self.turn_left}
    }
    
    for _, check in ipairs(checks) do
        if check.turn then check.turn(self) end
        
        local success, data = check.inspect()
        if success and self:is_target_block(data.name) then
            check.dig()
            self.state.blocks_mined = self.state.blocks_mined + 1
            self.state.total_blocks = self.state.total_blocks + 1
        end
        
        if check.restore then check.restore(self) end
    end
end

-- ========== RETURN & NAVIGATION SYSTEM ==========
function ULTIMATE_MINER:should_stop_mining()
    if self.state.should_return then
        return true
    end
    
    -- Check fuel
    local current_fuel = turtle.getFuelLevel()
    if current_fuel <= self.config.fuel_threshold then
        print("⚠ Low fuel: " .. current_fuel)
        return true
    end
    
    -- Check inventory
    local used, free, total = self:get_inventory_info()
    if free <= self.config.inventory_threshold then
        print("⚠ Inventory full: " .. free .. " slots left")
        return true
    end
    
    -- Check time limit
    local elapsed = os.time() - self.state.session_start
    if elapsed > self.config.time_limit then
        print("⚠ Time limit reached: " .. elapsed .. "s")
        return true
    end
    
    -- Check block limit
    if self.state.blocks_mined >= self.config.block_limit then
        print("⚠ Block limit reached: " .. self.state.blocks_mined)
        return true
    end
    
    return false
end

function ULTIMATE_MINER:return_home()
    print("🏠 Returning home...")
    self.state.should_return = false
    
    -- First return to surface
    while self.state.position.y < self.state.home.y do
        self:smart_move("up")
    end
    while self.state.position.y > self.state.home.y do
        self:smart_move("down")
    end
    
    -- Then return to home XZ
    while self.state.position.x ~= self.state.home.x or self.state.position.z ~= self.state.home.z do
        -- Move in X direction
        while self.state.position.x > self.state.home.x do
            self:face_direction(3) -- west
            self:smart_move("forward")
        end
        while self.state.position.x < self.state.home.x do
            self:face_direction(1) -- east
            self:smart_move("forward")
        end
        
        -- Move in Z direction
        while self.state.position.z > self.state.home.z do
            self:face_direction(2) -- south
            self:smart_move("forward")
        end
        while self.state.position.z < self.state.home.z do
            self:face_direction(0) -- north
            self:smart_move("forward")
        end
    end
    
    -- Face home direction
    self:face_direction(self.state.home.facing)
    
    print("✅ Successfully returned home!")
    self.state.is_mining = false
    self:save_state()
end

function ULTIMATE_MINER:set_home()
    self.state.home = {
        x = self.state.position.x,
        y = self.state.position.y,
        z = self.state.position.z,
        facing = self.state.position.facing
    }
    self:save_state()
    return "Home position set!"
end

function ULTIMATE_MINER:get_position()
    local directions = {"north", "east", "south", "west"}
    return string.format("📍 Position: X=%d Y=%d Z=%d Facing=%s",
        self.state.position.x, self.state.position.y, self.state.position.z,
        directions[self.state.position.facing + 1])
end

function ULTIMATE_MINER:get_distance()
    local dx = math.abs(self.state.position.x - self.state.home.x)
    local dy = math.abs(self.state.position.y - self.state.home.y)
    local dz = math.abs(self.state.position.z - self.state.home.z)
    local distance = dx + dy + dz
    return "📏 Distance to home: " .. distance .. " blocks"
end

-- ========== COMMAND SYSTEM ==========
function ULTIMATE_MINER:show_status()
    local fuel_current, fuel_limit, fuel_percent = self:get_fuel_info()
    local used_slots, free_slots, total_slots = self:get_inventory_info()
    local elapsed = os.time() - self.state.session_start
    
    return string.format([[
=== ULTIMATE MINER STATUS ===

🔋 Fuel: %d/%d (%d%%)
🎒 Inventory: %d/%d slots used
⛏️  Blocks mined: %d (session) / %d (total)
⏱️  Session time: %d seconds
📍 %s
🏠 %s
🔧 Mining: %s | Paused: %s
    ]], fuel_current, fuel_limit, fuel_percent, used_slots, total_slots,
        self.state.blocks_mined, self.state.total_blocks, elapsed,
        self:get_position(), self:get_distance(),
        tostring(self.state.is_mining), tostring(self.state.is_paused))
end

function ULTIMATE_MINER:show_stats()
    local efficiency = 0
    if self.state.session_time > 0 then
        efficiency = math.floor(self.state.blocks_mined / self.state.session_time)
    end
    
    return string.format([[
=== MINING STATISTICS ===

📊 Session Stats:
  Blocks mined: %d
  Time elapsed: %d seconds
  Efficiency: %d blocks/second

📈 Total Stats:
  Total blocks: %d
  Total sessions: %d
  Average efficiency: %d blocks/s
    ]], self.state.blocks_mined, self.state.session_time, efficiency,
        self.state.total_blocks, 1, efficiency) -- Placeholder for multi-session stats
end

function ULTIMATE_MINER:show_progress()
    if not self.state.is_mining then
        return "❌ Not currently mining"
    end
    
    local depth_progress = math.floor((self.state.position.y / self.config.depth) * 100)
    local time_progress = math.floor(((os.time() - self.state.session_start) / self.config.time_limit) * 100)
    local block_progress = math.floor((self.state.blocks_mined / self.config.block_limit) * 100)
    
    return string.format([[
=== MINING PROGRESS ===

⏬ Depth: %d%%
⏱️  Time: %d%%
⛏️  Blocks: %d%%
🎯 Targets: %d blocks
    ]], depth_progress, time_progress, block_progress, #self.config.targets)
end

function ULTIMATE_MINER:quick_setup()
    self:reset_config()
    print("✅ Quick setup complete!")
    print("Target blocks: coal, iron, gold, diamond, redstone, lapis")
    print("Mining mode: quarry")
    print("Depth: 50")
    print("Use 'start' to begin mining!")
end

function ULTIMATE_MINER:show_help()
    return [[
=== ULTIMATE MINER 9000 - COMMANDS ===

🚀 BASIC:
  start       - Begin mining
  stop        - Stop mining
  pause       - Pause mining
  resume      - Resume mining
  return      - Return to home

⚙️ CONFIG:
  set depth <n>      - Set mining depth
  set length <n>     - Set tunnel length
  set width <n>      - Set quarry width
  set mode <mode>    - Set mode: quarry/tunnel/vein/branch
  set fuel <n>       - Set fuel threshold
  set time <s>       - Set time limit (seconds)
  set blocks <n>     - Set block limit

🧱 BLOCKS:
  add <block_id>     - Add target block
  remove <block_id>  - Remove target block
  list               - List target blocks
  clear              - Clear all targets
  scan               - Scan area for blocks

🏠 NAVIGATION:
  home        - Set home position
  position    - Show current position
  distance    - Show distance to home
  goto x y z  - Move to coordinates

⛏️ PATTERNS:
  quarry      - Start quarry mining
  tunnel      - Start tunnel mining
  vein        - Start vein mining
  branch      - Start branch mining

🔧 MAINTENANCE:
  refuel      - Manual refuel
  inventory   - Show inventory
  drop <slot> - Drop items (or 'all')
  store       - Store items in chest

📊 INFO:
  status      - System status
  stats       - Mining statistics
  progress    - Mining progress
  targets     - Target blocks list
  config      - Show configuration

🔄 SYSTEM:
  save        - Save state
  load        - Load state
  reset       - Reset to defaults
  quick       - Quick setup
  help        - Show this help
  exit        - Exit program

💡 EXAMPLES:
  add thermal:tin_ore
  set depth 30
  set mode quarry
  start
    ]]
end

function ULTIMATE_MINER:execute_command(command)
    local cmd = string.lower(command)
    
    -- Basic commands
    if cmd == "start" then
        self:start_mining()
        return "Mining started"
    elseif cmd == "stop" then
        self.state.is_mining = false
        return "Mining stopped"
    elseif cmd == "pause" then
        self.state.is_paused = true
        return "Mining paused"
    elseif cmd == "resume" then
        self.state.is_paused = false
        return "Mining resumed"
    elseif cmd == "return" then
        self.state.should_return = true
        return "Returning home..."
        
    -- Configuration
    elseif string.find(cmd, "set depth") then
        local depth = tonumber(string.match(cmd, "set depth%s+(%d+)"))
        if depth then
            self.config.depth = depth
            self:save_config()
            return "Depth set to: " .. depth
        end
    elseif string.find(cmd, "set mode") then
        local mode = string.match(cmd, "set mode%s+(%a+)")
        if mode and (mode == "quarry" or mode == "tunnel" or mode == "vein" or mode == "branch") then
            self.config.mode = mode
            self:save_config()
            return "Mode set to: " .. mode
        end
        
    -- Block management
    elseif string.find(cmd, "add") then
        local block = string.match(cmd, "add%s+(.+)")
        if block then
            local success, msg = self:add_block(block)
            return msg
        end
    elseif string.find(cmd, "remove") then
        local block = string.match(cmd, "remove%s+(.+)")
        if block then
            local success, msg = self:remove_block(block)
            return msg
        end
    elseif cmd == "list" then
        return self:list_blocks()
    elseif cmd == "clear" then
        local success, msg = self:clear_blocks()
        return msg
        
    -- Navigation
    elseif cmd == "home" or cmd == "sethome" then
        return self:set_home()
    elseif cmd == "position" then
        return self:get_position()
    elseif cmd == "distance" then
        return self:get_distance()
        
    -- Mining patterns
    elseif cmd == "quarry" then
        self:mine_quarry()
        return "Quarry mining completed"
    elseif cmd == "tunnel" then
        self:mine_tunnel()
        return "Tunnel mining completed"
    elseif cmd == "vein" then
        self:mine_vein()
        return "Vein mining completed"
    elseif cmd == "branch" then
        self:mine_branch()
        return "Branch mining completed"
        
    -- Maintenance
    elseif cmd == "refuel" then
        local success, msg = self:refuel()
        return msg
    elseif cmd == "inventory" then
        local used, free, total = self:get_inventory_info()
        return "Inventory: " .. used .. "/" .. total .. " slots used"
    elseif string.find(cmd, "drop") then
        local slot = string.match(cmd, "drop%s+(.+)")
        local success, msg = self:drop_items(slot or "all")
        return msg
    elseif cmd == "store" then
        local success, msg = self:store_items()
        return msg
        
    -- Info
    elseif cmd == "status" then
        return self:show_status()
    elseif cmd == "stats" then
        return self:show_stats()
    elseif cmd == "progress" then
        return self:show_progress()
    elseif cmd == "targets" then
        return self:list_blocks()
    elseif cmd == "config" then
        return "Current config: depth=" .. self.config.depth .. ", mode=" .. self.config.mode
        
    -- System
    elseif cmd == "save" then
        self:save_state()
        self:save_config()
        return "State saved"
    elseif cmd == "load" then
        self:load_state()
        self:load_config()
        return "State loaded"
    elseif cmd == "reset" then
        self:reset_config()
        return "Configuration reset"
    elseif cmd == "quick" then
        self:quick_setup()
        return ""
    elseif cmd == "help" then
        return self:show_help()
        
    else
        return "❌ Unknown command: " .. command .. "\nType 'help' for available commands."
    end
    
    return "Command executed: " .. command
end

-- ========== MAIN MINING FUNCTION ==========
function ULTIMATE_MINER:start_mining()
    if not turtle then
        print("❌ This program must run on a turtle!")
        return
    end
    
    -- Check fuel
    local fuel_ok, fuel_msg = self:check_fuel()
    if not fuel_ok then
        print("❌ " .. fuel_msg)
        return
    end
    
    -- Check targets
    if #self.config.targets == 0 then
        print("❌ No target blocks configured!")
        print("Use 'add <block_id>' to add blocks")
        return
    end
    
    -- Initialize mining session
    self.state.is_mining = true
    self.state.is_paused = false
    self.state.should_return = false
    self.state.blocks_mined = 0
    self.state.session_start = os.time()
    
    print("🚀 Starting Ultimate Miner 9000!")
    print("🎯 Targets: " .. #self.config.targets .. " blocks")
    print("⛏️  Mode: " .. self.config.mode)
    print("⏬ Depth: " .. self.config.depth)
    
    -- Execute mining based on mode
    if self.config.mode == "quarry" then
        self:mine_quarry()
    elseif self.config.mode == "tunnel" then
        self:mine_tunnel()
    elseif self.config.mode == "vein" then
        self:mine_vein()
    elseif self.config.mode == "branch" then
        self:mine_branch()
    end
    
    -- Return home when done
    if self.config.emergency_return then
        self:return_home()
    end
    
    -- Session summary
    self.state.session_time = os.time() - self.state.session_start
    local efficiency = math.floor(self.state.blocks_mined / math.max(self.state.session_time, 1))
    
    print("📊 Session Complete!")
    print("⏱️  Time: " .. self.state.session_time .. "s")
    print("⛏️  Blocks: " .. self.state.blocks_mined)
    print("📈 Efficiency: " .. efficiency .. " blocks/s")
    
    self.state.is_mining = false
    self:save_state()
end

-- ========== INITIALIZATION ==========
function ULTIMATE_MINER:initialize()
    -- Load saved state and config
    self:load_config()
    self:load_state()
    
    -- Set home if not set
    if self.state.home.x == nil then
        self:set_home()
    end
    
    print("=== ULTIMATE MINER 9000 ===")
    print("Version: " .. self.version)
    print("Type 'quick' for instant setup")
    print("Type 'help' for commands")
    print()
end

function ULTIMATE_MINER:run()
    self:initialize()
    
    while true do
        write("MINER> ")
        local command = read()
        
        if command == "exit" or command == "quit" then
            print("👋 Goodbye!")
            break
        end
        
        local result = self:execute_command(command)
        if result ~= "" then
            print(result)
        end
        print()
    end
end

-- Start the ultimate miner
ULTIMATE_MINER:run()
