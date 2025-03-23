local Spritesheet = require("spritesheet")

return {
    spritesheet = Spritesheet("assets/spritesheet"),
    controller = love.graphics.newImage("assets/controller.png"),
    small_font = love.graphics.newFont("assets/fonts/Arcade Legacy.ttf", 16),
    very_small_font = love.graphics.newFont("assets/fonts/Arcade Legacy.ttf", 8),
    big_font = love.graphics.newFont("assets/fonts/Arcade Legacy.ttf", 48),
    sfx = {
        up = love.audio.newSource("assets/sfx/up.wav", "static"),
        down = love.audio.newSource("assets/sfx/down.wav", "static"),
        left = love.audio.newSource("assets/sfx/left.wav", "static"),
        right = love.audio.newSource("assets/sfx/right.wav", "static"),
        move_boulder = love.audio.newSource("assets/sfx/move_boulder.wav", "static"),
        place_boulder = love.audio.newSource("assets/sfx/place_boulder.wav", "static"),
        tada = love.audio.newSource("assets/sfx/tada.mp3", "static"),
        confirm = love.audio.newSource("assets/sfx/confirm.wav", "static"),
        step = love.audio.newSource("assets/sfx/step.wav", "static"),
        no = love.audio.newSource("assets/sfx/no.wav", "static"),
        countdown = {
            love.audio.newSource("assets/sfx/countdown3.wav", "static"),
            love.audio.newSource("assets/sfx/countdown2.wav", "static"),
            love.audio.newSource("assets/sfx/countdown1.wav", "static"),
            go = love.audio.newSource("assets/sfx/countdowngo.wav", "static")
        },
        hit = love.audio.newSource("assets/sfx/hit.wav", "static"),
        fail = love.audio.newSource("assets/sfx/fail.wav", "static"),
        quitting = love.audio.newSource("assets/sfx/quitting.wav", "static")
    },
    music = {
        level = love.audio.newSource("assets/music/song.wav", "static")
    }
}