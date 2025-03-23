require("lib.batteries"):export()
love.graphics.setDefaultFilter("nearest", "nearest")
pubsub:new()

local input = require("input")
local flux = require("lib.flux")

local state = state_machine(require("states"), "menu")
local assets = require("assets")

local canvas = love.graphics.newCanvas(640, 320)

function love.update(dt)
    input:update()
    flux.update(dt)
    state:update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    state:draw()

    love.graphics.setCanvas()

    local max_scale_x = love.graphics.getWidth() / canvas:getWidth()
    local max_scale_y = love.graphics.getHeight() / canvas:getHeight()
    local scale = math.floor(math.min(max_scale_x, max_scale_y))

    love.graphics.draw(canvas, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, scale, scale, canvas:getWidth() / 2, canvas:getHeight() / 2)

    if input:down("help") then
        love.graphics.draw(assets.controller)
    end
end

function love.joystickadded(joystick)
    input.joystick = joystick
end