local baton = require("lib.baton")

local input = baton.new({
    controls = {
        left = {"key:left", "axis:leftx-", "button:dpleft"},
        right = {"key:right", "axis:leftx+", "button:dpright"},
        up = {"key:up", "axis:lefty-", "button:dpup"},
        down = {"key:down", "axis:lefty+", "button:dpdown"},
        confirm = {"key:space", "button:a"},
        reset = {"key:r", "button:rightshoulder"},
        cancel = {"key:escape", "button:b"},
        cheat = {"key:c" },
        help = {"key:h", "button:leftshoulder" },
    },
    pairs = {
        move = {"left", "right", "up", "down"}
    },
    joystick = love.joystick.getJoysticks()[1],
})

return input