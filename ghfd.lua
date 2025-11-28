-- Tetris for ComputerCraft
-- Для работы требуется advanced computer или advanced turtle

-- Размеры игрового поля
local width, height = 10, 20
local score = 0
local level = 1
local linesCleared = 0

-- Игровое поле (0 - пусто, 1 - занято)
local grid = {}
for x = 1, width do
    grid[x] = {}
    for y = 1, height do
        grid[x][y] = 0
    end
end

-- Фигуры тетрамино и их цвета
local shapes = {
    {
        {1,1,1,1}, -- I
        color = colors.cyan
    },
    {
        {1,1,1,0,1}, -- T
        color = colors.purple
    },
    {
        {1,1,1,0,0,0,1}, -- L
        color = colors.orange
    },
    {
        {1,1,1,0,0,0,0,1}, -- J
        color = colors.blue
    },
    {
        {1,1,0,1,1}, -- O
        color = colors.yellow
    },
    {
        {0,1,1,1,1,0}, -- S
        color = colors.lime
    },
    {
        {1,1,0,0,1,1}, -- Z
        color = colors.red
    }
}

local currentPiece
local currentX, currentY
local currentRotation

-- Функция для создания новой случайной фигуры
local function newPiece()
    local shapeIndex = math.random(1, #shapes)
    currentPiece = shapes[shapeIndex]
    currentX = math.floor(width / 2) - 1
    currentY = 1
    currentRotation = 1
end

-- Функция поворота фигуры
local function rotatePiece()
    local oldRotation = currentRotation
    currentRotation = (currentRotation % 4) + 1
    
    -- Проверка столкновения после поворота
    for i = 1, 4 do
        for j = 1, 4 do
            if currentPiece[(currentRotation - 1) * 4 + j] and 
               currentPiece[(currentRotation - 1) * 4 + j][i] == 1 then
                local x = currentX + i - 1
                local y = currentY + j - 1
                if x < 1 or x > width or y > height or (y >= 1 and grid[x][y] == 1) then
                    currentRotation = oldRotation
                    return
                end
            end
        end
    end
end

-- Проверка столкновений
local function checkCollision(dx, dy)
    for i = 1, 4 do
        for j = 1, 4 do
            if currentPiece[(currentRotation - 1) * 4 + j] and 
               currentPiece[(currentRotation - 1) * 4 + j][i] == 1 then
                local x = currentX + i - 1 + dx
                local y = currentY + j - 1 + dy
                if x < 1 or x > width or y > height or (y >= 1 and grid[x][y] == 1) then
                    return true
                end
            end
        end
    end
    return false
end

-- Фиксация фигуры на поле
local function lockPiece()
    for i = 1, 4 do
        for j = 1, 4 do
            if currentPiece[(currentRotation - 1) * 4 + j] and 
               currentPiece[(currentRotation - 1) * 4 + j][i] == 1 then
                local x = currentX + i - 1
                local y = currentY + j - 1
                if y >= 1 then
                    grid[x][y] = currentPiece.color
                end
            end
        end
    end
end

-- Проверка и удаление заполненных линий
local function clearLines()
    local linesToClear = {}
    
    for y = 1, height do
        local full = true
        for x = 1, width do
            if grid[x][y] == 0 then
                full = false
                break
            end
        end
        if full then
            table.insert(linesToClear, y)
        end
    end
    
    for _, y in ipairs(linesToClear) do
        for yy = y, 2, -1 do
            for x = 1, width do
                grid[x][yy] = grid[x][yy-1]
            end
        end
        for x = 1, width do
            grid[x][1] = 0
        end
    end
    
    local cleared = #linesToClear
    if cleared > 0 then
        linesCleared = linesCleared + cleared
        score = score + cleared * 100 * level
        level = math.floor(linesCleared / 10) + 1
    end
end

-- Отрисовка игрового поля
local function draw()
    term.clear()
    term.setCursorPos(1, 1)
    print("Тетрис")
    print("Счет: " .. score)
    print("Уровень: " .. level)
    print("Линий: " .. linesCleared)
    
    -- Рисуем границы
    for x = 1, width + 2 do
        term.setCursorPos(x, 5)
        term.write("#")
        term.setCursorPos(x, height + 6)
        term.write("#")
    end
    
    for y = 5, height + 6 do
        term.setCursorPos(1, y)
        term.write("#")
        term.setCursorPos(width + 2, y)
        term.write("#")
    end
    
    -- Рисуем сетку
    for x = 1, width do
        for y = 1, height do
            if grid[x][y] ~= 0 then
                term.setCursorPos(x + 1, y + 5)
                term.setBackgroundColor(grid[x][y])
                term.write(" ")
                term.setBackgroundColor(colors.black)
            end
        end
    end
    
    -- Рисуем текущую фигуру
    if currentPiece then
        for i = 1, 4 do
            for j = 1, 4 do
                if currentPiece[(currentRotation - 1) * 4 + j] and 
                   currentPiece[(currentRotation - 1) * 4 + j][i] == 1 then
                    local x = currentX + i
                    local y = currentY + j + 4
                    if y > 5 then
                        term.setCursorPos(x, y)
                        term.setBackgroundColor(currentPiece.color)
                        term.write(" ")
                        term.setBackgroundColor(colors.black)
                    end
                end
            end
        end
    end
end

-- Основной игровой цикл
local function gameLoop()
    newPiece()
    local lastFall = os.clock()
    local fallSpeed = 1 - (level - 1) * 0.1
    if fallSpeed < 0.1 then fallSpeed = 0.1 end
    
    while true do
        local currentTime = os.clock()
        
        -- Автоматическое падение
        if currentTime - lastFall >= fallSpeed then
            if not checkCollision(0, 1) then
                currentY = currentY + 1
            else
                lockPiece()
                clearLines()
                newPiece()
                if checkCollision(0, 0) then
                    term.clear()
                    term.setCursorPos(1, 1)
                    print("Игра окончена!")
                    print("Финальный счет: " .. score)
                    return
                end
            end
            lastFall = currentTime
        end
        
        -- Обработка ввода
        local event, key = os.pullEvent("key")
        if key == keys.left and not checkCollision(-1, 0) then
            currentX = currentX - 1
        elseif key == keys.right and not checkCollision(1, 0) then
            currentX = currentX + 1
        elseif key == keys.down and not checkCollision(0, 1) then
            currentY = currentY + 1
            score = score + 1
        elseif key == keys.up then
            rotatePiece()
        elseif key == keys.space then
            -- Ускоренное падение
            while not checkCollision(0, 1) do
                currentY = currentY + 1
                score = score + 2
            end
        elseif key == keys.q then
            term.clear()
            term.setCursorPos(1, 1)
            print("Выход из игры")
            return
        end
        
        draw()
    end
end

-- Запуск игры
if not term.isColor() then
    print("Для этой игры требуется advanced computer!")
    return
end

term.clear()
print("Добро пожаловать в Тетрис!")
print("Управление:")
print("Стрелки: движение")
print("Пробел: ускоренное падение")
print("Q: выход")
print("Нажмите любую клавишу для начала...")
os.pullEvent("key")

gameLoop()
