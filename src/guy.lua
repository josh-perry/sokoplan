local Guy = class({
    name = "Guy"
})

local flux = require("lib.flux")

local assets = require("assets")
local input = require("input")

function Guy:new(level, x, y)
    assert(level, "Guy must be created with a level")

    self.x = x or 1
    self.y = y or 1

    self.draw_x = self.x * 16
    self.draw_y = self.y * 16

    self.level = level

    self.moves = 0
    self.bonks = 0

    self.move_record = {}
    self.moves_complete = false
    self.recording = false

    local function wait(t)
        local start = love.timer.getTime()

        while love.timer.getTime() - start < t do
            coroutine.yield()
        end
    end

    self.play_moves_coroutine = coroutine.create(function()
        while #self.move_record > 0 do
            local move = table.remove(self.move_record, 1)

            if not move then
                return
            end

            self.moves = self.moves + 1

            local previous_x, previous_y = self.x, self.y

            if move == "left" then
                self.x = self.x - 1
            end

            if move == "right" then
                self.x = self.x + 1
            end

            if move == "up" then
                self.y = self.y - 1
            end

            if move == "down" then
                self.y = self.y + 1
            end

            if self.level.tiles[self.x][self.y].solid then
                self.x, self.y = previous_x, previous_y
                self.bonks = self.bonks + 1
                pubsub:publish("BONKED")
                assets.sfx.no:clone():play()
            end

            if self.x ~= previous_x or self.y ~= previous_y then
                self:move_boulders(move, previous_x, previous_y)
                assets.sfx.step:clone():play()
                flux.to(self, 0.1, { draw_x = self.x * 16, draw_y = self.y * 16 })
            end

            pubsub:publish("MOVE_COMPLETE")
            wait(0.5)
        end

        self.moves_complete = true

        if not self.level:is_complete() then
            assets.sfx.fail:clone():play()
        end
    end)

    self.recording_coroutine = coroutine.create(function()
        for i = 1, 3 do
            pubsub:publish("POPUP_MESSAGE", { message = 4 - i })

            assets.sfx.countdown[i]:clone():play()
            wait(1)
        end

        pubsub:publish("POPUP_MESSAGE", { message = "GO!" })
        assets.sfx.countdown.go:clone():play()
        wait(1)

        self.recording = true

        local start_time = love.timer.getTime()

        while true do
            if input:pressed("left") then
                table.insert(self.move_record, "left")
                pubsub:publish("MOVE_RECORDED", "left")
                assets.sfx.left:clone():play()
            end

            if input:pressed("right") then
                table.insert(self.move_record, "right")
                pubsub:publish("MOVE_RECORDED", "right")
                assets.sfx.right:clone():play()
            end

            if input:pressed("up") then
                table.insert(self.move_record, "up")
                pubsub:publish("MOVE_RECORDED", "up")
                assets.sfx.up:clone():play()
            end

            if input:pressed("down") then
                table.insert(self.move_record, "down")
                pubsub:publish("MOVE_RECORDED", "down")
                assets.sfx.down:clone():play()
            end

            if input:pressed("confirm") then
                assets.sfx.confirm:clone():play()

                pubsub:publish("POPUP_MESSAGE", { message = "OK", time = 0.5 })
                assets.sfx.countdown[1]:clone():play()
                wait(0.5)
                pubsub:publish("POPUP_MESSAGE", { message = "LET'S", time = 0.5 })
                assets.sfx.countdown[2]:clone():play()
                wait(0.5)
                pubsub:publish("POPUP_MESSAGE", { message = "GO!", time = 0.5 })
                assets.sfx.countdown[3]:clone():play()
                wait(0.5)
                assets.sfx.countdown.go:clone():play()

                pubsub:publish("PLAYBACK_START")

                break
            end

            coroutine.yield()
        end

        self.recording_time = love.timer.getTime() - start_time
        self.recording = false
    end)
end

function Guy:draw()
    if self.level:is_complete() then
        assets.spritesheet:draw_sprite("guywin", self.draw_x, self.draw_y)
        return
    end

    if love.timer.getTime() % 1 < 0.5 then
        assets.spritesheet:draw_sprite("guy", self.draw_x, self.draw_y)
    else
        assets.spritesheet:draw_sprite("guy2", self.draw_x, self.draw_y)
    end
end

function Guy:update(dt)
    if coroutine.status(self.recording_coroutine) ~= "dead" then
        local success, error = coroutine.resume(self.recording_coroutine)

        if not success then
            print(error)
            return
        end

        return
    end

    if coroutine.status(self.play_moves_coroutine) ~= "dead" then
        local success, error = coroutine.resume(self.play_moves_coroutine)

        if not success then
            print(error)
            return
        end
    end
end

function Guy:move_boulders(move, previous_x, previous_y)
    for _, v in ipairs(self.level.boulders) do
        if v.x ~= self.x or v.y ~= self.y then
            goto continue
        end

        local boulder_x, boulder_y = v.x, v.y

        if move == "left" then
            boulder_x = boulder_x - 1
        end

        if move == "right" then
            boulder_x = boulder_x + 1
        end

        if move == "up" then
            boulder_y = boulder_y - 1
        end

        if move == "down" then
            boulder_y = boulder_y + 1
        end

        if self.level.tiles[boulder_x][boulder_y].solid then
            self.x, self.y = previous_x, previous_y
            self.bonks = self.bonks + 1
            pubsub:publish("BONKED")
            return
        end

        for _, b in ipairs(self.level.boulders) do
            if b ~= v and b.x == boulder_x and b.y == boulder_y then
                self.x, self.y = previous_x, previous_y
                self.bonks = self.bonks + 1
                pubsub:publish("BONKED")
                return
            end
        end

        if self.level.tiles[boulder_x][boulder_y].hole then
            assets.sfx.hit:clone():play()
            v.highlight_time = 1

            pubsub:publish("BOULDER_PLACED")
        else
            assets.sfx.move_boulder:clone():play()
        end

        v.x, v.y = boulder_x, boulder_y
        flux.to(v, 0.1, { draw_x = v.x * 16, draw_y = v.y * 16 })
        ::continue::
    end
end

return Guy