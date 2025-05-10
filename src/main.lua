import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
import "CoreLibs/crank"

local debug = true
local debugTime = false

local gfx <const> = playdate.graphics

local ticksPerRevolution = 6

local clockSprite = nil
local nuclearSprite = nil
local introSprite = nil

local secondArrowSprite = nil
local minuteArrowSprite = nil
local hourArrowSprite = nil


local second = 1000
local minute = second * 60
local hour = minute * 60
local day = hour * 24

local initTime = 60 * second

local timeToDetonate = initTime

local days = 0
local hours = 0
local minutes = 0
local seconds = 0

local state = "start"

local speed = 1
local fps = playdate.getFPS()
local secondRotation = 0
local minuteRotation = 0

local timeSpeed = second

local tickSoundPlayer, err = playdate.sound.fileplayer.new("assets/sound/ticking")
print(err)

local droneSoundPlayer, err = playdate.sound.fileplayer.new("assets/sound/drone")
print(err)

local introImage = gfx.image.new("assets/intro.png")
    assert( introImage )

function setupGame()
    local gameData = playdate.datastore.read()

    if debug == true then
        print("save loading")
        print(gameData.state)
        print(gameData.currentTimeToDetonate)
        print("save loaded")
    end

    if gameData then
        state = gameData.currentState
        timeToDetonate = gameData.currentTimeToDetonate
    end

    if debug == true then
        print("state", state)
        print("timeToDetonate", timeToDetonate)
    end

    if not timeToDetonate then
        timeToDetonate = initTime
    end

    local clockImage = gfx.image.new("assets/clock.png")
    assert( clockImage )

    clockSprite = gfx.sprite.new( clockImage )
    clockSprite:moveTo( 200, 120 )
    clockSprite:add()

    local secondArrowImage = gfx.image.new("assets/second.png")
    assert( secondArrowImage )

    secondArrowSprite = gfx.sprite.new( secondArrowImage )
    secondArrowSprite:moveTo( 200, 120 )
    secondArrowSprite:add()

    local minuteArrowImage = gfx.image.new("assets/minute.png")
    assert( minuteArrowImage )

    minuteArrowSprite = gfx.sprite.new( minuteArrowImage )
    minuteArrowSprite:moveTo( 200, 120 )
    minuteArrowSprite:add()

    local hourArrowImage = gfx.image.new("assets/hour.png")
    assert( hourArrowImage )

    hourArrowSprite = gfx.sprite.new( hourArrowImage )
    hourArrowSprite:moveTo( 200, 120 )
    hourArrowSprite:add()

    local nuclearSpriteImage = gfx.image.new("assets/nuclear.png")
    assert( nuclearSpriteImage )

    nuclearSprite = gfx.sprite.new( nuclearSpriteImage )
    nuclearSprite:moveTo( 200, 140 )
    nuclearSprite:add()
    nuclearSprite:setVisible(false)

    if debug then
        print("volume",tickSoundPlayer:getVolume())
        print("len", tickSoundPlayer:getLength())
    end
    
    
end

setupGame()

function playdate.update()
    if debug == true and debugTime == true then
        print(timeToDetonate)
    end

    local crankTicks = playdate.getCrankTicks(ticksPerRevolution)

    if crankTicks == 1 then
        timeToDetonate -= timeSpeed
    elseif crankTicks == -1 then
        timeToDetonate += timeSpeed
    end

    if state == "start" then 
        gfx.clear()
        introImage:drawCentered(200,120)
        gfx.drawTextAligned("*rotate the crank to win more time*", 200, 140, kTextAlignment.center)
        gfx.drawTextAligned("press A to start", 200, 200, kTextAlignment.center)
        if playdate.buttonIsPressed( playdate.kButtonA ) then
            state = "active"
            tickSoundPlayer:play()
        end
        return
    end

    if timeToDetonate > 2147483647 then
        timeToDetonate = -2147483648
    end

    if state == "active" and timeToDetonate < 0 then 
        state = "game_over"
        tickSoundPlayer:stop()
        droneSoundPlayer:play()
        saveState()
    end

    if state == "game_over" then 
        gfx.clear()
        nuclearSprite:setVisible(true)
        gfx.sprite.update()
        gfx.drawTextAligned("*THE END IS HERE*", 200, 20, kTextAlignment.center)
        
        if playdate.buttonIsPressed( playdate.kButtonDown ) then
            if playdate.buttonIsPressed( playdate.kButtonA ) then
                if playdate.buttonIsPressed( playdate.kButtonB ) then
                    state = "start"
                    timeToDetonate = initTime
                    saveState()
                    nuclearSprite:setVisible(false)
                    droneSoundPlayer:stop()
                    gfx.clear()
                    playdate.restart()
                end
            end
        end

        return
    end

    days = timeToDetonate // day
    hours = timeToDetonate % day // hour
    minutes = timeToDetonate % day % hour // minute
    seconds = timeToDetonate % day % hour % minute // second


    if days > 0 then 
        timeSpeed = day
    else
        if hours > 0 then 
            timeSpeed = hour 
        else 
            if minutes > 0 then
                timeSpeed = minute
            else
                timeSpeed = second
            end
        end
    end

    gfx.sprite.update()

    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:draw()
    end

    gfx.drawTextAligned("*THE END IS NIGH*", 200, 10, kTextAlignment.center)
    gfx.drawTextAligned(string.format("*%02.f d %02.f h %02.f m %02.f s*", days, hours, minutes, seconds), 200, 220, kTextAlignment.center)
    secondArrowSprite:setRotation(secondRotation)
    minuteArrowSprite:setRotation(minuteRotation)

    if playdate.buttonIsPressed( playdate.kButtonUp ) then
        clockSprite:moveBy( 0, -speed )
        secondArrowSprite:moveBy( 0, -speed )
        minuteArrowSprite:moveBy( 0, -speed )
        hourArrowSprite:moveBy( 0, -speed )
    end
    if playdate.buttonIsPressed( playdate.kButtonRight ) then
        clockSprite:moveBy( speed, 0 )
        secondArrowSprite:moveBy( speed, 0 )
        minuteArrowSprite:moveBy( speed, 0 )
        hourArrowSprite:moveBy( speed, 0 )
    end
    if playdate.buttonIsPressed( playdate.kButtonDown ) then
        clockSprite:moveBy( 0, speed )
        secondArrowSprite:moveBy( 0, speed )
        minuteArrowSprite:moveBy( 0, speed )
        hourArrowSprite:moveBy( 0, speed )
    end
    if playdate.buttonIsPressed( playdate.kButtonLeft ) then
        clockSprite:moveBy( -speed, 0 )
        secondArrowSprite:moveBy( -speed, 0 )
        minuteArrowSprite:moveBy( -speed, 0 )
        hourArrowSprite:moveBy( -speed, 0 )
    end

    timeToDetonate -= second / fps
    secondRotation = -6 * timeToDetonate / second
    if secondRotation < -360 then
        secondRotation =  secondRotation + 360
    end

    minuteRotation = -6 * timeToDetonate / minute
    if minuteRotation < -360 then
        minuteRotation =  minuteRotation + 360
    end

    hourRotation = -2 * timeToDetonate / hour
    if hourRotation < -360 then
        hourRotation =  hourRotation + 360
    end
end

function saveState()
    local gameData = {}
    gameData.currentState = state
    gameData.currentTimeToDetonate = timeToDetonate

    if debug == true then
        print("saving")
        print(gameData.currentState)
        print(gameData.currentTimeToDetonate)
        print("saved")
    end

    playdate.datastore.write(gameData)
end

function playdate.gameWillTerminate()
    state = "start"
    saveState()
end

function playdate.gameWillSleep()
    saveState()
end