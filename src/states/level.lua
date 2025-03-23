local state = require("state")
local assets = require("assets")
local input = require("input")
local flux = require("lib.flux")

local colour_cycle = require("colour_cycle")

local popup_messages = {}
local flying_arrows = {}
local screen_shake_intensity = 0
local quit_timer = 0

pubsub:subscribe("POPUP_MESSAGE", function(message)
    table.insert(popup_messages, {
        time = 0,
        max_time = message.time or 1,
        message = message.message
    })
end)

pubsub:subscribe("MOVE_RECORDED", function(move)
    local arrow = {
        x = 320,
        y = 160,
        move = move,
        time = 0,
        scale = 4
    }

    table.insert(flying_arrows, arrow)

    local current_flying_arrows = #flying_arrows

    flux.to(arrow, 0.5, {
        x = move == "left" and arrow.x - 64 or move == "right" and arrow.x + 64 or arrow.x,
        y = move == "up" and arrow.y - 64 or move == "down" and arrow.y + 64 or arrow.y
    }):ease("quadout")
      :oncomplete(function()
        arrow.flying = true

        flux.to(arrow, 0.5, {
            x = 32,
            y = 32 + current_flying_arrows * 24,
            scale = 1
        }):oncomplete(function()
            arrow.flying = false
            arrow.in_sidebar = true
        end)
    end)
end)

pubsub:subscribe("MOVE_COMPLETE", function()
    flying_arrows[1].complete = true

    flux.to(flying_arrows[1], 0.1, {
        scale = 0
    }):oncomplete(function()
        table.remove(flying_arrows, 1)
    end)

    for i = 2, #flying_arrows do
        flux.to(flying_arrows[i], 0.1, {
            y = flying_arrows[i - 1].y
        })
    end

    if flying_arrows[2] then
        flux.to(flying_arrows[2], 0.1, {
            scale = 2
        })
    end
end)

pubsub:subscribe("PLAYBACK_START", function()
    assets.music.level:setLooping(true)
    assets.music.level:play()
end)

pubsub:subscribe("PLAYBACK_STOP", function()
    assets.music.level:stop()
end)

pubsub:subscribe("BOULDER_PLACED", function()
    screen_shake_intensity = screen_shake_intensity + 20
end)

local ow_messages = {
    "ow",
    "ouch",
    "bonk",
    "nose bonked",
    "that hurt",
    "ouchie",
    "careful"
}

pubsub:subscribe("BONKED", function()
    screen_shake_intensity = screen_shake_intensity + 10

    table.insert(popup_messages, {
        time = 0,
        max_time = 0.2,
        message = table.pick_random(ow_messages)
    })
end)

pubsub:subscribe("LEVEL_RESET", function()
    flying_arrows = {}
    popup_messages = {}
    screen_shake_intensity = 0
end)

return {
    enter = function(s)
        s.played_tada = false

        flying_arrows = {}
        popup_messages = {}
        screen_shake_intensity = 0
        quit_timer = 0
    end,
    draw = function(s)
        love.graphics.setFont(assets.small_font)

        local guy = state.level.guy

        if guy.recording then
            love.graphics.setFont(assets.very_small_font)
            colour_cycle()

            local width = love.graphics.getFont():getWidth("RECORDING ")

            for x = -width, 640, width do
                for y = 0, 320, 16 do
                    local offset = 0
                    local speed = 48

                    if y % 32 == 0 then
                        offset = offset + love.timer.getTime() * speed
                    else
                        offset = offset - love.timer.getTime() * speed
                    end

                    offset = offset % width
                    love.graphics.print("RECORDING ", x + offset, y + 4)
                end
            end
        end

        local shake_x = (love.math.simplexNoise(love.timer.getTime()) * 2 - 1) * screen_shake_intensity
        local shake_y = (love.math.simplexNoise(love.timer.getTime(), 1000) * 2 - 1) * screen_shake_intensity
        love.graphics.push()
        love.graphics.translate(-shake_x, -shake_y)
        love.graphics.setColor(1, 1, 1)

        state.level:draw()

        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(shake_x, shake_y)

        for i, v in ripairs(flying_arrows) do
            if not v.in_sidebar or (not guy.recording and i == 1) then
                colour_cycle()
            else
                love.graphics.setColor(1, 1, 1)
            end

            assets.spritesheet:draw_sprite(v.move, v.x, v.y, 0, v.scale, v.scale, 8, 8)
        end

        if state.level:is_complete() then
            local width = 200

            love.graphics.setFont(assets.small_font)
            love.graphics.setColor(1, 1, 1)

            love.graphics.printf("Bonks: ", 16, 16, width, "left")
            love.graphics.printf(guy.bonks, 16, 16, width, "right")

            love.graphics.printf("Moves: ", 16, 32, width, "left")
            love.graphics.printf(guy.moves, 16, 32, width, "right")

            love.graphics.printf("Time: ", 16, 48, width, "left")
            love.graphics.printf(("%.2f"):format(guy.recording_time), 16, 48, width, "right")

            local crown_rank = state.level.crown_rank

            if guy.bonks <= crown_rank.bonks then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", 16 + width + 8, 16)
            else
                love.graphics.setColor(1, 1, 1)
            end

            if guy.moves <= crown_rank.moves then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", 16 + width + 8, 32)
            else
                love.graphics.setColor(1, 1, 1)
            end


            if guy.recording_time <= crown_rank.time then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", 16 + width + 8, 48)
            else
                love.graphics.setColor(1, 1, 1)
            end

            local all_crowns = guy.bonks <= crown_rank.bonks and guy.moves <= crown_rank.moves and guy.recording_time <= crown_rank.time

            if all_crowns then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", 16 + width + 8, 64)

                love.graphics.setScissor(16, 64, width, 16)

                local perfect_width = love.graphics.getFont():getWidth("PERFECT ")

                for i = 1, 4 do
                    local min_x = 16 - perfect_width
                    local max_x = min_x + perfect_width * 4

                    local x = love.timer.getTime() * 100 - (16 + (i - 1) * perfect_width)

                    x = x % (max_x - min_x) + min_x

                    love.graphics.print("PERFECT ", x, 64)
                end

                love.graphics.setScissor()
            end
        elseif guy.moves_complete then
            love.graphics.printf("Press R (or RB on controller) to reset", 16, 16, 640 - 32, "left")
        end

        love.graphics.setFont(assets.big_font)
        colour_cycle()
        for _, v in ipairs(popup_messages) do
            local center_y = 160 - love.graphics.getFont():getHeight() / 2

            love.graphics.printf(v.message, 0, center_y, 640, "center")
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.pop()

        if quit_timer > 0 then
            local radius = 8
            local text_x = 640 - 16 - radius / 2 - 128

            love.graphics.setFont(assets.very_small_font)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Hold to quit", text_x, 16 - 4)

            love.graphics.arc("fill", 640 - 16 - radius / 2, 16, radius, 0, quit_timer * 2 * math.pi, 100)
        end
    end,
    update = function(s, dt)
        state.level:update(dt)

        screen_shake_intensity = math.max(0, screen_shake_intensity - dt * 50)

        for i, v in ripairs(popup_messages) do
            v.time = v.time + dt

            if v.time > v.max_time then
                table.remove(popup_messages, i)
            end
        end

        if state.level:is_complete() and not s.played_tada then
            assets.music.level:stop()
            assets.sfx.tada:clone():play()
            s.played_tada = true
        end

        if state.level:is_complete() and input:pressed("confirm") then
            pubsub:publish("PLAYBACK_STOP")

            state.level_scores[state.level.name] = {
                bonks = math.min(state.level.guy.bonks, state.level_scores[state.level.name] and state.level_scores[state.level.name].bonks or math.huge),
                moves = math.min(state.level.guy.moves, state.level_scores[state.level.name] and state.level_scores[state.level.name].moves or math.huge),
                time = math.min(state.level.guy.recording_time, state.level_scores[state.level.name] and state.level_scores[state.level.name].time or math.huge)
            }

            state:save()
            assets.sfx.confirm:clone():play()
            return "level_select"
        end

        if input:pressed("reset") then
            state.level:reset()
        end

        if input:pressed("cancel") then
            assets.sfx.quitting:play()

            if quit_timer > 0 then
                assets.sfx.quitting:seek(quit_timer / assets.sfx.quitting:getDuration(), "seconds")
            end
        end

        if input:down("cancel") then
            quit_timer = quit_timer + dt

            if quit_timer > 1 then
                assets.music.level:stop()
                assets.sfx.no:clone():play()

                return "level_select"
            end
        else
            quit_timer = math.max(quit_timer - dt * 2, 0)
            assets.sfx.quitting:stop()
        end
    end
}
