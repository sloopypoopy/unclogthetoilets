local plumber = {
    x = 400,
    y = 300,
    speed = 300,  -- Increase the speed
    sprite = nil,
    poopSprite = nil,
    width = 120,
    height = 120,
    timeSinceLastUnclog = 0,
    gameOver = false,
    gameOverTimer = 0,
    showerCollision = false,
    showerTimer = 0,
    showerDuration = 0.5,
    loading = false,
    loadingTimer = 0,
    loadingDuration = 0.5,
} -- plumber as the player

local toilets = {}
local backgroundImage
local toiletImage
local cloggedToiletImage
local showerImage
local showerWidth = 60
local showerHeight = 60
local showers = {}
local barrierWidth = 16  -- Width of the barrier (thinner)
local clogTimer = 0
local clogInterval = 3  -- Interval for clogging toilets in seconds
local unclogTime = 0.5  -- Time to unclog a toilet in seconds
local unclogTimer = 0
local uncloggingToilet = nil
local progressBarWidth = 100
local progressBarHeight = 20
local score = 0  -- Score counter for clogged toilets

local showerSpawnTimer = 0
local showerSpawnInterval = 5  -- Interval for spawning showers in seconds
local showerDuration = 2  -- Duration of showers in seconds
local showerUnclogTime = 2  -- Time to unclog shower in seconds

function love.load()
    -- Load assets
    backgroundImage = love.graphics.newImage("background.png")
    toiletImage = love.graphics.newImage("toilet.png")
    cloggedToiletImage = love.graphics.newImage("clogged_toilet.png")
    showerImage = love.graphics.newImage("shower.png")
    plumber.sprite = love.graphics.newImage("plumber.png")
    plumber.poopSprite = love.graphics.newImage("plumber_poop.png")
    
    -- Set window dimensions
    love.window.setMode(plumber.width * 8, plumber.height * 6)
    
    -- Create toilets
    toilets = {
        {x = 50, y = 50, clogged = false, clogTimer = 0},
        {x = 750, y = 50, clogged = false, clogTimer = 0},
        {x = 50, y = 550, clogged = false, clogTimer = 0},
        {x = 750, y = 550, clogged = false, clogTimer = 0}
    }
end

function love.update(dt)
    if not plumber.gameOver then
        -- Player movement
        if love.keyboard.isDown("w") then
            plumber.y = plumber.y - plumber.speed * dt
        elseif love.keyboard.isDown("s") then
            plumber.y = plumber.y + plumber.speed * dt
        end
        
        if love.keyboard.isDown("a") then
            plumber.x = plumber.x - plumber.speed * dt
        elseif love.keyboard.isDown("d") then
            plumber.x = plumber.x + plumber.speed * dt
        end
        
        -- Ensure player stays within the game area
        plumber.x = math.min(math.max(plumber.x, barrierWidth), love.graphics.getWidth() - plumber.width - barrierWidth)
        plumber.y = math.min(math.max(plumber.y, barrierWidth), love.graphics.getHeight() - plumber.height - barrierWidth)
        
        -- Update clog timer
        clogTimer = clogTimer + dt
        if clogTimer >= clogInterval then
            -- Reset timer
            clogTimer = 0
            -- Randomly select a toilet to clog
            local index = love.math.random(1, #toilets)
            toilets[index].clogged = true
            toilets[index].clogTimer = 0
        end
        
        -- Update unclog timer
        if uncloggingToilet then
            unclogTimer = unclogTimer + dt
            if unclogTimer >= unclogTime then
                -- Unclog the toilet
                uncloggingToilet.clogged = false
                uncloggingToilet = nil
                unclogTimer = 0
                score = score + 1  -- Increment score when a toilet gets unclogged
            end
        end
        
        -- Update time since last unclog and plumber sprite
        for i, toilet in ipairs(toilets) do
            if toilet.clogged then
                toilet.clogTimer = toilet.clogTimer + dt
                if toilet.clogTimer >= 5 then
                    plumber.sprite = plumber.poopSprite
                end
            else
                toilet.clogTimer = 0
            end
        end
        
        -- Check collision between plumber and clogged toilet
        for i, toilet in ipairs(toilets) do
            if toilet.clogged then
                if checkCollision(plumber.x, plumber.y, plumber.width, plumber.height, toilet.x, toilet.y, toiletImage:getWidth(), toiletImage:getHeight()) then
                    if love.keyboard.isDown("e") then
                        uncloggingToilet = toilet
                        unclogTimer = 0
                        break
                    end
                end
            end
        end
        
        -- Update shower spawn timer
        showerSpawnTimer = showerSpawnTimer + dt
        if showerSpawnTimer >= showerSpawnInterval then
            -- Reset timer
            showerSpawnTimer = 0
            -- Spawn a shower closer to the middle of the screen
            local shower = {
                x = love.graphics.getWidth() / 2 - showerWidth / 2,
                y = love.graphics.getHeight() / 2 - showerHeight / 2,
                timer = 0,  -- Timer to track shower duration
                unclogging = false,
                progress = 0
            }
            table.insert(showers, shower)
        end
        
        -- Update shower duration and remove showers that have expired
        for i, shower in ipairs(showers) do
            shower.timer = shower.timer + dt
            if shower.timer >= showerDuration then
                table.remove(showers, i)
            end
        end
        
        -- Check collision between plumber and shower
        for i, shower in ipairs(showers) do
            if checkCollision(plumber.x, plumber.y, plumber.width, plumber.height, shower.x, shower.y, showerWidth, showerHeight) then
                plumber.showerCollision = true
                if love.keyboard.isDown("e") and not plumber.loading then
                    plumber.loading = true
                end
            else
                plumber.showerCollision = false
            end
        end
        
        -- Update loading timer
        if plumber.loading then
            plumber.loadingTimer = plumber.loadingTimer + dt
            if plumber.loadingTimer >= plumber.loadingDuration then
                plumber.sprite = love.graphics.newImage("plumber.png")
                plumber.loading = false
                plumber.loadingTimer = 0
            end
        end
        
        -- Check if game over
        if plumber.sprite == plumber.poopSprite then
            plumber.gameOverTimer = plumber.gameOverTimer + dt
            if plumber.gameOverTimer >= 7 then
                plumber.gameOver = true
            end
        end
    else
        -- Reset game if game over
        if love.keyboard.isDown("r") then
            love.load()
        end
    end
end

function love.draw()
    -- Draw background
    love.graphics.draw(backgroundImage, 0, 0, 0, love.graphics.getWidth() / backgroundImage:getWidth(), love.graphics.getHeight() / backgroundImage:getHeight())
    
    -- Draw invisible barriers
    love.graphics.setColor(0, 0, 0, 0)  -- Set the color to invisible
    love.graphics.rectangle("fill", 0, 0, barrierWidth, love.graphics.getHeight())  -- Left barrier
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), barrierWidth)  -- Top barrier
    love.graphics.rectangle("fill", love.graphics.getWidth() - barrierWidth, 0, barrierWidth, love.graphics.getHeight())  -- Right barrier
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - barrierWidth, love.graphics.getWidth(), barrierWidth)  -- Bottom barrier
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    
    -- Draw toilets
    for i, toilet in ipairs(toilets) do
        if toilet.clogged then
            love.graphics.draw(cloggedToiletImage, toilet.x, toilet.y)
            if uncloggingToilet == toilet then
                love.graphics.setColor(0, 1, 0)  -- Green color for progress bar
                love.graphics.rectangle("fill", toilet.x, toilet.y - progressBarHeight, progressBarWidth * (unclogTimer / unclogTime), progressBarHeight)
                love.graphics.setColor(1, 1, 1, 1)
            end
        else
            love.graphics.draw(toiletImage, toilet.x, toilet.y)
        end
    end
    
    -- Draw plumber (player)
    love.graphics.draw(plumber.sprite, plumber.x, plumber.y, 0, plumber.width / plumber.sprite:getWidth(), plumber.height / plumber.sprite:getHeight())
    
    -- Draw showers
    for i, shower in ipairs(showers) do
        love.graphics.draw(showerImage, shower.x, shower.y)
    end
    
    -- Draw game over message
    if plumber.gameOver then
        love.graphics.setColor(1, 0, 0)  -- Red color for game over message
        local font = love.graphics.newFont(36)
        love.graphics.setFont(font)
        love.graphics.printf("Game Over!", 0, love.graphics.getHeight() / 2 - font:getHeight() / 2, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
    
    -- Draw loading bar
    if plumber.loading then
        love.graphics.setColor(0, 1, 0)  -- Green color for loading bar
        love.graphics.rectangle("fill", plumber.x, plumber.y - 20, plumber.width * (plumber.loadingTimer / plumber.loadingDuration), 5)
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
end

function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end
