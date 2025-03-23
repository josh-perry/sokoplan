local levels = require("data.levels")
local state = require("state")
local assets = require("assets")
local colour_cycle = require("colour_cycle")

local input = require("input")
local flux = require("lib.flux")

local button_width = 128
local button_height = 48
local button_start_x = 16
local button_selected_x = 48

return {
    enter = function(s)
        s.levels = functional.map(levels, function(level)
            return {
                name = level.name,
                path = "assets/levels/" .. level.filename .. ".png",
                image = love.graphics.newImage("assets/levels/" .. level.filename.. ".png"),
                unlocked = false,
                crown_rank = level.crown_rank
            }
        end)

        state:load()

        s.bonus_unlocked = functional.all(s.levels, function(level)
            local level_score = state.level_scores[level.name]

            if not level_score then
                return false
            end

            local crown_rank = level.crown_rank
            return level_score.bonks <= crown_rank.bonks and level_score.moves <= crown_rank.moves and level_score.time <= crown_rank.time
        end)

        for i = 1, #s.levels do
            local previous_level_has_score = i == 1 and true or state.level_scores[s.levels[i - 1].name]
            s.levels[i].unlocked = previous_level_has_score
        end

        if s.bonus_unlocked then
            local load_text_levels = require("load_text_levels")
            local bonus_levels = load_text_levels("assets/levels/microban/Microban.txt")

            for _, v in ipairs(bonus_levels) do
                table.insert(s.levels, {
                    name = "[Bonus] " .. v.name,
                    path = nil,
                    image = nil,
                    crown_rank = {
                        bonks = 0,
                        moves = 0,
                        time = 0
                    },
                    unlocked = true,
                    width = v.width,
                    height = v.height,
                    tiles = v.tiles
                })
            end
        end

        s.level_buttons = functional.map(s.levels, function(level, i)
            return {
                x = button_start_x,
                y = i * button_height,
                width = button_width,
                height = button_height,
                level = level
            }
        end)

        for i, v in ipairs(s.levels) do
            if v.unlocked and not v.path then
                local image_data = love.image.newImageData(v.width, v.height)

                for x = 1, v.width do
                    for y = 1, v.height do
                        local tile = v.tiles[y][x]

                        if not tile or tile.wall then
                            image_data:setPixel(x - 1, y - 1, 0, 0, 0, 1)
                        elseif tile.floor then
                            image_data:setPixel(x - 1, y - 1, 1, 1, 1, 1)
                        elseif tile.hole and tile.boulder then
                            image_data:setPixel(x - 1, y - 1, 0, 1, 0, 1)
                        elseif tile.hole then
                            image_data:setPixel(x - 1, y - 1, 1, 1, 0, 1)
                        elseif tile.boulder then
                            image_data:setPixel(x - 1, y - 1, 1, 0, 0, 1)
                        elseif tile.player then
                            image_data:setPixel(x - 1, y - 1, 0, 0, 1, 1)
                        end
                    end
                end

                v.image_data = image_data
                v.image = love.graphics.newImage(image_data)
            end
        end

        s.selected_level_index = 1

        if state.level then
            for i, v in ipairs(s.levels) do
                if v.name == state.level.name then
                    s.selected_level_index = i
                    break
                end
            end
        end
    end,
    draw = function(s)
        love.graphics.setFont(assets.small_font)
        love.graphics.print("Select a level", 16, 16)

        love.graphics.push()
        love.graphics.translate(0, (-s.selected_level_index * button_height + 480 / 2) - button_height / 2)
        love.graphics.setScissor(0, 64, 300, 320)

        for i, v in ipairs(s.level_buttons) do
            if i == s.selected_level_index then
                colour_cycle()
            else
                love.graphics.setColor(1, 1, 1)
            end

            local level = v.level
            local level_score = state.level_scores[level.name]

            love.graphics.print(level.unlocked and level.name or "???", v.x, v.y)

            local all_crowns = level_score and level_score.bonks <= level.crown_rank.bonks and level_score.moves <= level.crown_rank.moves and level_score.time <= level.crown_rank.time

            if all_crowns then
                local text_width = love.graphics.getFont():getWidth(level.name)

                colour_cycle()
                assets.spritesheet:draw_sprite("crown", v.x + text_width + 8, v.y)
            end
        end

        love.graphics.setScissor()
        love.graphics.pop()

        love.graphics.setColor(1, 1, 1)

        local level_preview_x = (640 / 3) * 2
        local level_preview_y = (320 / 3)
        local level_preview_image = s.levels[s.selected_level_index].image

        love.graphics.setColor(1, 1, 1)

        if s.levels[s.selected_level_index].unlocked then
            love.graphics.setColor(1, 1, 1)

            if level_preview_image then
                love.graphics.draw(level_preview_image, level_preview_x, level_preview_y, 0, 8, 8, level_preview_image:getWidth() / 2, level_preview_image:getHeight() / 2)
            end
        else
            love.graphics.printf("???", level_preview_x - 100, level_preview_y, 200, "center")
        end

        local level = s.levels[s.selected_level_index]
        local level_score = state.level_scores[level.name]

        local stats_width = 200
        local stats_x = 640 - stats_width - 32 - 48
        local stats_y = 320 - 16 - 16 * 4
        
        love.graphics.setColor(1, 1, 1)

        if level_score then
            love.graphics.setFont(assets.small_font)
            love.graphics.printf("Bonks: ", stats_x, stats_y, stats_width, "left")
            love.graphics.printf(level_score.bonks or "n/a", stats_x, stats_y, stats_width, "right")

            love.graphics.printf("Moves: ", stats_x, stats_y + 16, stats_width, "left")
            love.graphics.printf(level_score.moves or "n/a", stats_x, stats_y + 16, stats_width, "right")

            love.graphics.printf("Time : ", stats_x, stats_y + 32, stats_width, "left")
            love.graphics.printf(("%.2f"):format(level_score.time) or "n/a", stats_x, stats_y + 32, stats_width, "right")

            if level_score.bonks <= level.crown_rank.bonks then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", stats_x + stats_width + 8, stats_y)
            end

            if level_score.moves <= level.crown_rank.moves then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", stats_x + stats_width + 8, stats_y + 16)
            end

            if level_score.time <= level.crown_rank.time then
                colour_cycle()
                assets.spritesheet:draw_sprite("crown", stats_x + stats_width + 8, stats_y + 32)
            end

            local all_crowns = level_score.bonks <= level.crown_rank.bonks and level_score.moves <= level.crown_rank.moves and level_score.time <= level.crown_rank.time

            if all_crowns then
                colour_cycle()

                love.graphics.setScissor(stats_x, stats_y + 48, stats_width, 16)
                
                local perfect_width = love.graphics.getFont():getWidth("PERFECT ")
                for i = 1, 4 do
                    local min_x = stats_x - perfect_width
                    local max_x = min_x + perfect_width * 4

                    local x = love.timer.getTime() * 100 - (stats_x + (i - 1) * perfect_width)

                    x = x % (max_x - min_x) + min_x

                    love.graphics.print("PERFECT ", x, stats_y + 48)
                end
                
                love.graphics.setScissor()

                assets.spritesheet:draw_sprite("crown", stats_x + stats_width + 8, stats_y + 48)
            end

            love.graphics.setColor(1, 1, 1)
        elseif level.unlocked then
            love.graphics.setFont(assets.small_font)
            love.graphics.printf("Not cleared", stats_x, stats_y, 200, "center")
        else
            love.graphics.setFont(assets.small_font)
            love.graphics.printf("Locked", stats_x, stats_y, 200, "center")

            love.graphics.setFont(assets.very_small_font)
            love.graphics.printf("Clear previous level to unlock", stats_x, stats_y + 24, 200, "center")
        end
    end,
    update = function(s)
        local previous_selected_level_index = s.selected_level_index

        if input:pressed("up") then
            assets.sfx.up:clone():play()
            s.selected_level_index = s.selected_level_index - 1
        end

        if input:pressed("down") then
            assets.sfx.down:clone():play()
            s.selected_level_index = s.selected_level_index + 1
        end

        if input:pressed("left") then
            assets.sfx.left:clone():play()
            s.selected_level_index = math.clamp(s.selected_level_index - 5, 1, #s.levels)
        end

        if input:pressed("right") then
            assets.sfx.right:clone():play()
            s.selected_level_index = math.clamp(s.selected_level_index + 5, 1, #s.levels)
        end

        s.selected_level_index = math.wrap(s.selected_level_index, 1, #s.levels + 1)

        if input:pressed("cheat") then
            for i = 1, #s.levels do
                s.levels[i].unlocked = true
            end

            assets.sfx.hit:clone():play()
        end

        s.selected_level_index = math.clamp(s.selected_level_index, 1, #s.levels)

        if s.selected_level_index ~= previous_selected_level_index then
            for i, v in ipairs(s.level_buttons) do
                if i == s.selected_level_index then
                    flux.to(v, 0.3, { x = button_selected_x, y = i * button_height }, "outquart")
                else
                    flux.to(v, 0.3, { x = button_start_x, y = i * button_height }, "outquart")
                end
            end
        end

        if input:pressed("confirm") then
            local selected_level = s.levels[s.selected_level_index]

            if not selected_level.unlocked then
                assets.sfx.no:clone():play()
                return
            end
            
            assets.sfx.confirm:clone():play()
            local Level = require("level")
            state.level = Level(selected_level.path, selected_level.name, selected_level.crown_rank, selected_level.image_data)
            return "level"
        end

        if input:pressed("cancel") then
            assets.sfx.no:clone():play()
            return "menu"
        end
    end
}
