local SpriteSheet = class({
	name = "spritesheet",
})

local json = require("lib.json")

function SpriteSheet:new(imageName)
	self.jsonPath = ("%s.json"):format(imageName)
	self.image_path = ("%s.png"):format(imageName)
	self.image = love.graphics.newImage(self.image_path)

	self.sprite_quads = {}

	local data = json.decode(love.filesystem.read(self.jsonPath))
	local w, h = data.meta.size.w, data.meta.size.h

	for _, slice in ipairs(data.meta.slices) do
		local frame = slice.keys[1]

		self.sprite_quads[slice.name] = love.graphics.newQuad(frame.bounds.x, frame.bounds.y, frame.bounds.w, frame.bounds.h, w, h)
	end
end

function SpriteSheet:draw_sprite(sprite_name, x, y, rot, sx, sy, ox, oy)
	assert(self.sprite_quads[sprite_name], ("Sprite '%s' not found"):format(sprite_name))
	love.graphics.draw(self.image, self.sprite_quads[sprite_name], x, y, rot or 0, sx or 1, sy or 1, ox or 0, oy or 0)
end

return SpriteSheet
