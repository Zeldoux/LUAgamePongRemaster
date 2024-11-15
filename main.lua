-- Loading assets
menumusic = love.audio.newSource("sound/arcade.mp3", "stream")
playmusic = love.audio.newSource("sound/2d.mp3", "stream")
padhit = love.audio.newSource("sound/PadHit.mp3", "static")
ballloose = love.audio.newSource("sound/LooseBall.mp3", "static")

winimg = love.graphics.newImage("spritesheets/Win.png")
looseimg = love.graphics.newImage("spritesheets/Loose.png")
local Rbackground = love.graphics.newImage("spritesheets/background.png")

local iaBoostCooldown = 5  -- Cooldown for AI boost (in seconds)
local iaBoostReady = true  -- Can the AI boost the ball?

-- Menu definition
local menu = {
    x = 0,
    y = 0,
    img = {
        l = love.graphics.newImage("spritesheets/Menucoteg.png"),
        lx = 0,
        ly = 0,
        r = love.graphics.newImage("spritesheets/Menucoted.png"),
        rx = 20,
        ry = -5
    },
    logo = love.graphics.newImage("spritesheets/Logomenu.png"),
    imgstat = false
}

-- Background definition
local background = {
    sheet = love.graphics.newImage("spritesheets/Backgroundspritesheet.png"),
    img = {},
    frame = 1
}
for i = 1, 7 do
    background.img[i] = love.graphics.newQuad((i-1)*800, 0, 800, 600, background.sheet:getDimensions())
end

-- Ball definition
local ball = {
    x = 0,
    y = 0,
    xv = 200,
    yv = -200,
    height = 16,
    width = 16,
    frame = 1,
    sheet = love.graphics.newImage("spritesheets/Ball.png"),
    img = {}
}
for i = 1, 4 do
    ball.img[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, ball.sheet:getDimensions())
end

-- Sidebars definition
local sidebar1 = {
    sheet = love.graphics.newImage("spritesheets/Sidebar1.png"),
    img = {},
    width = 50,
    height = 600,
    frame = 1
}
for i = 1, 6 do
    sidebar1.img[i] = love.graphics.newQuad((i-1)*50, 0, 50, 600, sidebar1.sheet:getDimensions())
end

local sidebar2 = {
    sheet = love.graphics.newImage("spritesheets/Sidebar2.png"),
    img = {},
    width = 50,
    height = 600,
    frame = 1
}
for i = 1, 6 do
    sidebar2.img[i] = love.graphics.newQuad((i-1)*50, 0, 50, 600, sidebar2.sheet:getDimensions())
end

-- Paddles definition
local pad1 = {
    x = 400,
    y = 590,
    life = 3,
    frame = 1,
    width = 80,
    height = 20,
    sheet = love.graphics.newImage("spritesheets/Pad1.png"),
    img = {}
}
for i = 1, 4 do
    pad1.img[i] = love.graphics.newQuad((i-1)*80, 0, 80, 20, pad1.sheet:getDimensions())
end

local pad2 = {
    x = 400,
    y = 10,
    life = 3,
    frame = 1,
    width = 80,
    height = 20,
    sheet = love.graphics.newImage("spritesheets/Pad2.png"),
    img = {}
}
for i = 1, 4 do
    pad2.img[i] = love.graphics.newQuad((i-1)*80, 0, 80, 20, pad2.sheet:getDimensions())
end

local traillist = {}
local boostT = 1
local playerBoost = false
local aiBoost = false
local xbefore, ybefore  -- Store original ball speed
local aiBoostT = 1

-- Game states
local GameState = {
    current = "menu",  -- Other states: "ingame", "win", "lose"
    countdown = 1,
}
local aiBoostCooldown = 5  -- Cooldown duration for AI boost
local aiBoostReady = true  -- Boolean to track if AI can use boost

-- Function to reset the game
function resetGame()
    -- Reset doors to closed position
    menu.img.lx = 0
    menu.img.rx = 20
    menu.imgstat = false  -- Ensure doors are not in transition state
    playerBoost = false
    aiBoost = false
    boostT = 1

    -- Reset player lives
    pad1.life = 3
    pad2.life = 3

    -- Reset paddle positions
    pad1.x = screenwidth / 2
    pad1.y = screenheight - pad1.height / 2
    pad2.x = screenwidth / 2
    pad2.y = pad2.height / 2

    -- Reset ball position and velocity
    ball.x = screenwidth / 2
    ball.y = screenheight / 2
    ball.xv = 200
    ball.yv = -200
    boost = false
    boostT = 1

    -- Reset frames
    pad1.frame = 1
    pad2.frame = 1
    ball.frame = 1

    -- Reset countdown and clear trails
    GameState.countdown = 1
    traillist = {}
end

function love.load()
    screenwidth = love.graphics.getWidth()
    screenheight = love.graphics.getHeight()
    print(screenwidth)
    print(screenheight)

    resetGame()
end

-- Function to handle player input
local function handlePlayerInput(dt)
    local moveSpeed = 200 * dt  -- Adjust speed as necessary
    if love.keyboard.isDown("left") and pad1.x > pad1.width / 2 + sidebar1.width then
        pad1.x = pad1.x - moveSpeed
    elseif love.keyboard.isDown("right") and pad1.x < screenwidth - sidebar1.width - pad1.width / 2 then
        pad1.x = pad1.x + moveSpeed
    end
end

function love.keypressed(key)
    if key == "space" then
        -- Activate the boost if the player has more than 1 life
        if pad1.life > 1 then
            playerBoost = true
            pad1.life = pad1.life - 1
        end
    end

    if GameState.current == "menu" then
        if key == "return" then
            menu.imgstat = true  -- Activate door animation
            GameState.current = "transition"  -- Switch to transition state
        end
    elseif GameState.current == "win" or GameState.current == "lose" then
        if key == "escape" then
            resetGame()
            GameState.current = "menu"
        elseif key == "return" then
            resetGame()
            GameState.current = "ingame"
        end
    end
end

function love.update(dt)
    if GameState.current == "menu" then
        if not menumusic:isPlaying() then
            menumusic:play()
        end
        playmusic:stop()

    elseif GameState.current == "transition" then
        -- Handle door animation
        menu.img.lx = menu.img.lx - 100 * dt
        menu.img.rx = menu.img.rx + 100 * dt

        -- Check if doors are fully opened
        if menu.img.lx <= -800 and menu.img.rx >= screenwidth then
            menu.imgstat = false  -- Disable door animation
            GameState.current = "ingame"  -- Switch to game mode
            resetGame()  -- Reset the game
        end

    elseif GameState.current == "ingame" then
        -- Start game music if not already playing
        if not playmusic:isPlaying() then
            playmusic:play()
        end
        menumusic:stop()

        -- Store initial ball speed for reset
        xbefore = ball.xv
        ybefore = ball.yv

        -- Player Boost Logic
        if playerBoost then
            ball.frame = 3
            ball.xv = ball.xv * 1.001
            ball.yv = ball.yv * 1.001
            boostT = boostT + dt
            if boostT > 2 then
                playerBoost = false
                boostT = 1
                ball.xv = xbefore
                ball.yv = ybefore
            end
        end

        -- AI Boost Logic
        local playerPadY = screenheight - pad1.height
        local boostTriggerY = playerPadY - 250
        local playerAligned = math.abs(ball.x - pad1.x) < 100

        if aiBoostReady and pad2.life > 1 and ball.y > boostTriggerY and ball.y < playerPadY and playerAligned then
            aiBoost = true
            aiBoostReady = false
            ball.frame = 2
            pad2.life = pad2.life - 1
            ball.xv = ball.xv * 1.001
            ball.yv = ball.yv * 1.001
            aiBoostT = 0  -- Reset AI boost timer
            print("AI used boost! Lives remaining: " .. pad2.life)
        end

        -- AI Boost Duration Control
        if aiBoost then
            aiBoostT = aiBoostT + dt
            if aiBoostT > 2 then
                aiBoost = false
                ball.xv = xbefore
                ball.yv = ybefore
            end
        end

        -- AI Boost Cooldown
        if not aiBoostReady then
            aiBoostCooldown = aiBoostCooldown - dt
            if aiBoostCooldown <= 0 then
                aiBoostReady = true
                aiBoostCooldown = 5
            end
        end

        -- Update trails
        for n = #traillist, 1, -1 do
            local t = traillist[n]
            t.lt = t.lt - dt
            if aiBoost or playerBoost then
                t.x = t.x + t.vx
                t.y = t.y + t.vy
            end
            if t.lt <= 0 then
                table.remove(traillist, n)
            end
        end
        local trail = {
            x = ball.x,
            y = ball.y,
            vx = math.random(-1, 1),
            vy = math.random(-1, 1),
            lt = 0.5
        }
        table.insert(traillist, trail)

        -- Player 1 movement
        handlePlayerInput(dt)

        -- Update paddle positions
        pad1.y = screenheight - pad1.height / 2
        pad2.y = pad2.height / 2

        -- Update ball position
        ball.x = ball.x + ball.xv * dt
        ball.y = ball.y + ball.yv * dt

        
        local aiMoveSpeed = 1.5  -- Adjust speed as necessary
        -- AI paddle movement
        if pad2.x < ball.x and pad2.x < screenwidth - sidebar2.width - pad2.width / 2 then
            pad2.x = pad2.x + aiMoveSpeed
        elseif pad2.x > ball.x and pad2.x > pad2.width / 2 + sidebar1.width then
            pad2.x = pad2.x - aiMoveSpeed
        end

        -- Handle collisions with walls
        if ball.x + (ball.width / 2) >= screenwidth - sidebar1.width then
            ball.x = screenwidth - sidebar1.width - ball.width / 2
            ball.xv = -ball.xv
            padhit:play()
        end
        if ball.x - (ball.width / 2) <= sidebar1.width then
            ball.x = sidebar1.width + ball.width / 2
            ball.xv = -ball.xv
            padhit:play()
        end

        -- Handle collisions with paddles
        local ycollB = pad1.y - pad1.height / 2 - ball.height / 2
        if ball.y > ycollB then
            local dist = math.abs(pad1.x - ball.x)
            print(dist)
            if dist < pad1.width / 2 then
                ball.yv = -math.abs(ball.yv)
                ball.y = ycollB
                padhit:play()
            end
        end

        local ycollR = pad2.y + pad2.height / 2 + ball.height / 2
        if ball.y < ycollR then
            local dist = math.abs(pad2.x - ball.x)
            print(dist)
            if dist < pad2.width / 2 then
                ball.yv = math.abs(ball.yv)
                ball.y = ycollR
                padhit:play()
            end
        end

        -- Handle collisions with top and bottom
        if ball.y + ball.height / 2 <= 0 then 
            pad2.life = pad2.life - 1
            resetBallAfterScore(-200, 200)
            ballloose:play()
            
            -- Check if the AI (pad2) has lost
            if pad2.life <= 0 then
                GameState.current = "win"  -- Player has won
            end
        end

        if ball.y + ball.height / 2 >= screenheight then
            pad1.life = pad1.life - 1
            resetBallAfterScore(200, -200)
            ballloose:play()
            
            -- Check if the player (pad1) has lost
            if pad1.life <= 0 then
                GameState.current = "lose"  -- Player has lost
            end
        end

        -- Update frames
        background.frame = background.frame + 0.5 * dt
        if background.frame > #background.img then
            background.frame = 1
        end

        sidebar1.frame = sidebar1.frame + 1 * dt
        if sidebar1.frame > #sidebar1.img then
            sidebar1.frame = 1
        end

        sidebar2.frame = sidebar2.frame + 1 * dt
        if sidebar2.frame > #sidebar2.img then
            sidebar2.frame = 1
        end

        -- Update frames of paddles and ball based on lives
        if pad2.life == 2 then
            pad2.frame = 2
        elseif pad2.life == 1 then
            pad2.frame = 3
        elseif pad2.life <= 0 then
            pad2.frame = 4
            print("You have won!")
        end

        if pad1.life == 2 then
            pad1.frame = 2
        elseif pad1.life == 1 then
            pad1.frame = 3
        elseif pad1.life <= 0 then
            pad1.frame = 4
            print("Game over")
        end

    elseif GameState.current == "win" or GameState.current == "lose" then
        if not menumusic:isPlaying() then
            menumusic:play()
        end
        playmusic:stop()
    end
end

local function drawGame()
    -- Draw the background
    local bframe = math.floor(background.frame)
    love.graphics.draw(background.sheet, background.img[bframe], 0, 0)
    love.graphics.draw(Rbackground, 0, 0)

    -- Draw the sidebars
    local s1frame = math.floor(sidebar1.frame)
    love.graphics.draw(sidebar1.sheet, sidebar1.img[s1frame], 0, 0)

    local s2frame = math.floor(sidebar2.frame)
    love.graphics.draw(sidebar2.sheet, sidebar2.img[s2frame], screenwidth - sidebar2.width, 0)

    -- Draw the ball
    local bframeBall = math.floor(ball.frame)
    love.graphics.draw(ball.sheet, ball.img[bframeBall], ball.x - ball.width / 2, ball.y - ball.height / 2)

    -- Draw the paddles
    local plframe = math.floor(pad1.frame)
    love.graphics.draw(pad1.sheet, pad1.img[plframe], pad1.x - pad1.width / 2, pad1.y - pad1.height / 2)

    local pl2frame = math.floor(pad2.frame)
    love.graphics.draw(pad2.sheet, pad2.img[pl2frame], pad2.x - pad2.width / 2, pad2.y - pad2.height / 2)

    -- Draw the trails
    love.graphics.push("all")
    for _, t in ipairs(traillist) do
        love.graphics.setColor(1, 1, 1, t.lt)
        love.graphics.draw(ball.sheet, ball.img[bframeBall], t.x - ball.width / 2, t.y - ball.height / 2)
    end
    love.graphics.pop()
end

function love.draw()
    -- Draw the game during or after the door animation
    if GameState.current == "ingame" or GameState.current == "transition" then
        drawGame()  -- Draw the game

        -- Draw the doors if we are in transition
        if GameState.current == "transition" then
            love.graphics.draw(menu.img.l, menu.img.lx, menu.img.ly)
            love.graphics.draw(menu.img.r, menu.img.rx, menu.img.ry)
        end
    end

    if GameState.current == "menu" then
        -- Draw the menu only when the animation is not in progress
        love.graphics.draw(menu.img.l, menu.img.lx, menu.img.ly)
        love.graphics.draw(menu.img.r, menu.img.rx, menu.img.ry)
        love.graphics.draw(menu.logo, 0, 0)  -- Draw the menu text
    elseif GameState.current == "win" then
        -- Draw the victory screen
        love.graphics.draw(winimg, 0, 0)
    elseif GameState.current == "lose" then
        -- Draw the defeat screen
        love.graphics.draw(looseimg, 0, 0)
    end
end

-- Helper function to reset ball position and boosts after scoring
function resetBallAfterScore(newXv, newYv)
    GameState.start = false
    playerBoost = false
    aiBoost = false
    boostT, aiBoostT = 1, 1
    ball.x, ball.y = screenwidth / 2, screenheight / 2
    ball.xv, ball.yv = newXv, newYv
end