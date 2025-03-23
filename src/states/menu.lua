local input = require("input")
local assets = require("assets")
local colour_cycle = require("colour_cycle")

return {
    enter = function(s)
        s.menu = {
            {
                text = "Start",
                action = function()
                    return "level_select"
                end
            },
            {
                text = "Quit",
                action = function()
                    love.event.quit()
                end
            }
        }

        s.selected_menu_index = 1
    end,
    draw = function(s)
        love.graphics.setFont(assets.big_font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Sokoplan", 16, 16, 640, "center")

        love.graphics.setFont(assets.small_font)

        for i, v in ipairs(s.menu) do
            if i == s.selected_menu_index then
                colour_cycle()
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.printf(v.text, 16, 160 + 16 + i * 24, 640, "center")
        end

        love.graphics.setColor(1, 1, 1)
    end,
    update = function(s, dt)
        if input:pressed("confirm") then
            assets.sfx.confirm:clone():play()
            return s.menu[s.selected_menu_index].action()
        end

        if input:pressed("up") then
            assets.sfx.up:clone():play()
            s.selected_menu_index = s.selected_menu_index - 1
        end

        if input:pressed("down") then
            assets.sfx.down:clone():play()
            s.selected_menu_index = s.selected_menu_index + 1
        end

        s.selected_menu_index = math.clamp(s.selected_menu_index, 1, #s.menu)
    end
}