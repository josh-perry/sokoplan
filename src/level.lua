local Level = class({
    name = "Level"
})

local Guy = require("guy")

local assets = require("assets")
local colour_cycle = require("colour_cycle")

function Level:new(path, name, crown_rank, image_data)
    self.path = path
    self.name = name
    self.crown_rank = crown_rank
    self.image_data = image_data

    self:reset()
end

function Level:draw()
    love.graphics.push()
    love.graphics.translate(320 - self.width * 16 / 2, 160 - self.height * 16 / 2)
    love.graphics.translate(-16, -16)

    if self:is_complete() then
        colour_cycle()
    end

    for i = 1, self.width do
        for j = 1, self.height do
            local x, y = i * 16, j * 16

            if self.tiles[i][j].hole then
                assets.spritesheet:draw_sprite("hole", x, y)
            else
                assets.spritesheet:draw_sprite(self.tiles[i][j].solid and "wall" or "floor", x, y)
            end
        end
    end

    for _, boulder in ipairs(self.boulders) do
        if boulder.highlight_time > 0 then
            colour_cycle()
        elseif not self:is_complete() then
            love.graphics.setColor(1, 1, 1)
        end

        local boulder_in_hole = self.tiles[boulder.x][boulder.y].hole
        assets.spritesheet:draw_sprite(boulder_in_hole and "boulderplaced" or "boulder", boulder.draw_x, boulder.draw_y)
    end

    if not self:is_complete() then
        love.graphics.setColor(1, 1, 1)
    end

    self.guy:draw()

    love.graphics.pop()
end

function Level:update(dt)
    self.guy:update(dt)

    for _, boulder in ipairs(self.boulders) do
        boulder.highlight_time = math.max(0, boulder.highlight_time - dt)
    end
end

function Level:is_complete()
    if #self.guy.move_record > 0 then
        return false
    end

    if not self.guy.moves_complete then
        return false
    end

    for _, boulder in ipairs(self.boulders) do
        local x, y = boulder.x, boulder.y

        if not self.tiles[x][y].hole then
            return false
        end
    end

    return true
end

function Level:load_from_image()
    local image_data = self.image_data or love.image.newImageData(self.path)
    self.width, self.height = image_data:getDimensions()
    local guy_x, guy_y = 1, 1

    self.tiles = {}
    self.boulders = {}

    for x = 1, self.width do
        self.tiles[x] = {}

        for y = 1, self.height do
            self.tiles[x][y] = {}
        end
    end

    for i = 0, self.width - 1 do
        for j = 0, self.height - 1 do
            local x = i + 1
            local y = j + 1

            local r, g, b, a = image_data:getPixel(i, j)

            -- black = floor
            -- yellow = hole
            -- red = boulder
            -- blue = guy

            local tile = self.tiles[x][y]

            if r == 1 and g == 1 and b == 1 then
                tile.solid = false
            elseif r == 0 and g == 0 and b == 0 then
                tile.solid = true
            elseif r == 1 and g == 1 and b == 0 then
                tile.hole = true
            elseif r == 0 and g == 1 and b == 0 then
                tile.hole = true

                table.insert(self.boulders, {
                    x = x,
                    y = y,
                    draw_x = x * 16,
                    draw_y = y * 16,
                    highlight_time = 0
                })
            elseif r == 1 and g == 0 and b == 0 then
                table.insert(self.boulders, {
                    x = x,
                    y = y,
                    draw_x = x * 16,
                    draw_y = y * 16,
                    highlight_time = 0
                })
            elseif r == 0 and g == 0 and b == 1 then
                guy_x, guy_y = x, y
            end
        end
    end

    self.guy = Guy(self, guy_x, guy_y)


end

function Level:reset()
    assets.music.level:stop()
    self:load_from_image()

    pubsub:publish("LEVEL_RESET")
end

return Level