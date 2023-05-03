local customobjects = {}

----------------
-- Object Format
----------------

--[[
    name: string                        -- The object's name.
                                           This appears in the rules list in the pause menu.
                                           Text objects' names are prefixed with "text_".

    unittype: string                    -- Whether this object is a regular object or a text object.
        "object"
        "text"

    tags: {string, string, ...}         -- The object's tags that are used in object searches.
        "common"        "movement"      "animal"
        "obstacle"      "floor"         "danger"
        "plant"         "item"          "water"
        "decorative"    "cave"          "machine"
        "mountain"      "sky"           "forest"
        "town"          "ruins"         "abstract"
        "autumn"        "colour"        "music"
        "text_verb"     "text_quality"  "text_condition"
        "text_prefix"   "text_letter"   "text_special"

    tiling: number                      -- Animation style (how the object's sprites are used).
        -1                                 None; static appearance      (Flag)
        0                                  Directional                  (Ghost)
        4                                  Animated per turn            (Bat)
        3                                  Animated & directional       (Belt)
        2                                  Character                    (Baba)
        1                                  Tiled                        (Wall)

    type: number                        -- The kind of text this object is.
                                           (For regular objects, type may be 0.)
        0                                  Objects
        1                                  Verbs
        2                                  Properties/Qualities
        3                                  Prefix conditions
        4                                  The word "not"
        5                                  Letters
        6                                  The word "and"
        7                                  Infix condition with parameters

    layer: number                       -- Change the order the sprites are rendered.
                                           Larger values are further in front.
                                           For text, layer should probably be 20.

    colour: {number, number}            -- The object's color as a coordinate on the color pallete.
                                           Check Data/Palletes to see the game's color palletes.
                                           {0, 0} is the top left, while {6, 4} is the bottom right.
                                           For text, this is the standard faded-out color.

    colour_active: {number, number}     -- The lit-up color that text uses when it's in a valid
                                            sentence.

    sprite_in_root: bool                -- Where the object's sprites are found.
                                           You should put your object sprites in your levelpack
                                            folder and set this to false.
        true                               Data/Sprites
        false                              Data/Worlds/[your levelpack folder]/Sprites
--]]

-----------
-- Settings
-----------

-- Defines the order of custom objects in the object list.
-- Objects are appended to the end of the list.
-- Please ensure every object is in here.
customobjects.tileorder =
{
    "universe_eye",
	"nomai",
	"text_nomai",
	"traveler",
	"text_traveler",
	"them",
	"text_them",
	"anglerfish_monster",
	"text_orbit",
	"text_deorbit",
	"text_older",
}

-- Defines custom objects.
-- Changing the order of objects in this table may cause errors.
-- If you wish to change the order of custom objects in the object list,
-- please change customobjects.tileorder instead.
customobjects.tiles =
{
	{
		name = "eye",
		listname = "universe_eye",
		unittype = "object",
		tags = {"sky","decorative","outer wilds"},
		tiling = -1,
		type = 0,
		layer = 16,
		colour = {0, 1},
		sprite = "universe_eye",
		sprite_in_root = false,
	},
	{
		name = "nomai",
		unittype = "object",
		tags = {"animal","outer wilds"},
		tiling = 2,
		type = 0,
		layer = 18,
		colour = {0, 3},
		sprite_in_root = false,
	},
	{
		name = "text_nomai",
		unittype = "text",
		tags = {"animal","outer wilds"},
		tiling = -1,
		type = 0,
		layer = 20,
		colour = {4, 0},
		colour_active = {4, 1},
		sprite_in_root = false,
	},
	{
		name = "traveler",
		unittype = "object",
		tags = {"animal","outer wilds"},
		tiling = 2,
		type = 0,
		layer = 18,
		colour = {3, 2},
		sprite = "hearthian",
		sprite_in_root = false,
	},
	{
		name = "text_traveler",
		unittype = "text",
		tags = {"animal","outer wilds"},
		tiling = -1,
		type = 0,
		layer = 20,
		colour = {1, 1},
		colour_active = {1, 2},
		sprite_in_root = false,
	},
	{
		name = "them",
		unittype = "object",
		tags = {"animal","outer wilds"},
		tiling = 2,
		type = 0,
		layer = 18,
		colour = {3, 2},
		sprite = "hearthian",
		sprite_in_root = false,
	},
	{
		name = "text_them",
		unittype = "text",
		tags = {"animal","outer wilds"},
		tiling = -1,
		type = 0,
		layer = 20,
		colour = {1, 1},
		colour_active = {1, 2},
		sprite_in_root = false,
	},
	{
		name = "monster",
		listname = "anglerfish_monster",
		unittype = "object",
		tags = {"danger","animal","outer wilds"},
		tiling = 2,
		type = 0,
		layer = 18,
		colour = {4, 2},
		sprite = "anglerfish",
		sprite_in_root = false,
	},
	{
		name = "text_orbit",
		unittype = "text",
		tags = {"text_verb","movement"},
		tiling = -1,
		type = 1,
		layer = 20,
		colour = {5, 1},
		colour_active = {5, 3},
		sprite_in_root = false,
	},
	{
		name = "text_deorbit",
		unittype = "text",
		tags = {"text_verb","movement"},
		tiling = -1,
		type = 1,
		layer = 20,
		colour = {5, 1},
		colour_active = {5, 3},
		sprite_in_root = false,
	},
	{
		name = "text_older",
		unittype = "text",
		tags = {"text_quality","text_special","abstract"},
		tiling = -1,
		type = 2,
		layer = 20,
		colour = {5, 1},
		colour_active = {5, 3},
		sprite_in_root = false,
	},
}

-- Set the custom object index prefix.
-- This is to ensure that official objects' indices don't clash with custom ones.
-- Changing it after you have added custom objects to a level may cause errors.
customobjects.prefix = "aj_"

----------------
-- Functionality
----------------

function formatobjlist()
	for i,v in pairs(editor_objlist) do
		editor_objlist_reference[v.listname or v.name] = i
	end
end

local function addtiles(tiles, tileorder, prefix)
	-- -- Assert tile order is formatted correctly
	-- for _, tile in pairs(tiles) do
	-- 	-- Ensure object exists in tile order
	-- 	local contains = false
	-- 	for _, tilename in pairs(tileorder) do
	-- 		contains = contains or tile.name == tilename
	-- 	end
	-- 	assert(contains, "Missing object from tile order: "..tile.name)
	-- end

	-- local previndex = {}
	-- for _, tilename in pairs(tileorder) do
	-- 	-- Ensure object exists in tiles
	-- 	local contains = false
	-- 	for _, tile in pairs(tiles) do
	-- 		contains = contains or tilename == tile.name
	-- 	end
	-- 	assert(contains, "Nonexistent object in tile order: "..tilename)

	-- 	-- Ensure no duplicates
	-- 	local nodupes = (previndex[tilename] == nil)
	-- 	previndex[tilename] = true
	-- 	assert(nodupes, "Duplicate object in tile order: "..tilename)
	-- end

	-- Add custom objects to the order in the object list
	for _, tilename in pairs(tileorder) do
		table.insert(editor_objlist_order, tilename)
	end

	-- Add custom objects to the object list
	for _, tile in pairs(tiles) do
		local index = prefix..(tile.listname or tile.name)
		editor_objlist[index] = tile
	end

	formatobjlist()

end

addtiles(customobjects.tiles, customobjects.tileorder, customobjects.prefix)