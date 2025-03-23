return function()
    local r, g, b = colour.hsl_to_rgb(love.timer.getTime() / 3, 0.6, 0.7)
    love.graphics.setColor(r, g, b)

    return r, g, b
end