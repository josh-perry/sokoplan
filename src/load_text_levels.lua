local load_text_levels = function(file_path)
    local levels = {}

    -- ; 1
    -- 
    -- ####
    -- # .#
    -- #  ###
    -- #*@  #
    -- #  $ #
    -- #  ###
    -- ####
    -- 
    -- ; 2
    -- 
    -- ######
    -- #    #
    -- # #@ #
    -- # $* #
    -- # .* #
    -- #    #
    -- ######
    -- 
    -- ; 3
    -- 
    --   ####
    -- ###  ####
    -- #     $ #
    -- # #  #$ #
    -- # . .#@ #
    -- #########

    -- # is a wall
    -- blank is a floor
    -- . is a hole
    -- $ is a boulder
    -- @ is the player

    -- loop over these lines and create an image data for each

    local lines = love.filesystem.lines(file_path)

    local current_level = {
        name = "",
        tiles = {}
    }

    for line in lines do
        if line:sub(1, 1) == ";" then
            current_level = {
                name = line:sub(3),
                tiles = {},
                width = 0,
                height = 0
            }

            table.insert(levels, current_level)
        elseif line == "" then
        else
            local row = {}

            for i = 1, #line do
                local char = line:sub(i, i)
                current_level.width = math.max(current_level.width, i)

                if char == "#" then
                    table.insert(row, { wall = true })
                elseif char == " " then
                    table.insert(row, { floor = true })
                elseif char == "." then
                    table.insert(row, { hole = true })
                elseif char == "$" then
                    table.insert(row, { boulder = true })
                elseif char == "*" then
                    table.insert(row, { boulder = true, hole = true })
                elseif char == "@" then
                    table.insert(row, { player = true })
                end
            end

            table.insert(current_level.tiles, row)
            current_level.height = current_level.height + 1
        end
     end

    return levels
end

return load_text_levels