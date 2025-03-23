local json = require("lib.json")

local state = {
    level = nil,
    level_scores = {},
    save = function(self)
        local save_data = {
            level_scores = self.level_scores
        }

        love.filesystem.write("save.json", json.encode(save_data))
    end,
    load = function(self)
        local save_data = love.filesystem.read("save.json")

        if save_data then
            save_data = json.decode(save_data)
            self.level_scores = save_data.level_scores
        end
    end
}

return state