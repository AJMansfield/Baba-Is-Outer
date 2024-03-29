-- Copied From: https://github.com/PlasmaFlare/BASED-mod
-- These are some extra configurations
local mod_config = {
    -- Displays a lua error message on level start, showing which sentences in baserules.lua were invalid.
    -- You can disable this if you want to avoid all the excess error messages. But invalid sentences will still be ignored.
    report_invalid_sentences = true,

    -- When set to true, this disables the game from automatically inserting "text is push", "level is stop", and "cursor is select" as baserules.
    -- Note that this affects the levelpack as a whole, and cannot be configured per level. If you want some levels to have the above rules,
    -- configure "level_baserules" at the bottom of this file.
    disable_normal_baserules = false,
}

--[[ 
    persist_baserules are always applied in every level in the levelpack. Just put in your list of sentences below.
    Example:
    local persist_baserules = {
        "baba is keke",
        "keke make me",
        "me is blue and pink",
    }

    NOTE: There is a bug where adding group-related rules as persist baserule doesn't work without having at least one text object in the level.
    The fix would require some lua function overriding in rules.lua, which I don't want to do for compatability reasons. There might be other rules that also have this
    problem. So to be on the safe side, make sure you have at least one text object in you level.
 ]]
local persist_baserules = {
}



--[[
    levelpack_baserules are just like persist_baserules where every sentence is applied to every level in the levelpack.
    However, each "set" of sentences is applied only when the game detects the rule "level is X", where X can be any string you want.

    The format for each entry in levelpack_baserules is:
        <text block name> = {
            <sentence 1>,
            <sentence 2>,
            <sentence 3>,
            ...
        }
    Where <text block name> does not have "text_" prepended ("push", "shift", "ice" etc).

    Note: Only full rules are allowed. So no "baba is keke is push", where it would've been parsed as two sentences in game.

    The below example will apply "baba is sleep and pet" and "level is pink" when "level is lovebaba" is formed. A similar thing happens when you form "level is poem"

        local levelpack_baserules = {
            lovebaba = {
                "baba is sleep and pet",
                "all near baba is love",
                "level is pink",
            },
            poem = {
                "rose is red",
                "violet is blue",
                "flag is win",
                "baba is you",
            },
        }
 ]]
local levelpack_baserules = {
    space = {
        "text is not push",
        "text on tile is hide",
        "tile is hide",

        "text on belt is nudgeright",
        "text on bug is nudgeleft",
        "bug is you",
        "belt near bug is you",
        "bug is lockedleft",
        "bug is lockedright",
        "belt is lockedleft",
        "belt is lockedright",
        "bug is hide",
        "belt is hide",

        "text on bird is nudgedown",
        "text on me is nudgeup",
        "me is you",
        "bird near me is you",
        "me is lockedup",
        "me is lockeddown",
        "bird is lockedup",
        "bird is lockeddown",
        "me is hide",
        "bird is hide",

        "pipe is stop",
        "pipe is hide"
    }
}




--[[ 
    level baserules are baserules that only apply to specific levels in your levelpack.
    The format for each entry is:
        [<level name>] = {
            <text block name> = {
                <sentence 1>,
                <sentence 2>,
                <sentence 3>,
                ...
            }
        }
    Where <level name> is CASE-SENSITIVE and can be EITHER: 
        - the name of the level ingame (Ex: "the return of scenic pond", "skull house", "prison")
        - the name of the .ld file (excluding ".ld")
    The rest of the format is exactly the same as global baserules.
    
    Note: level baserules will be used instead of global baserules when playing a level that you specified in the variable below.

    The below example applies "baba is green" when "level is baserule1" is formed when playing a level named "woah". 
    It also applies "keke is purple" when "level is baserule1" is formed when playing a level whose .ld file is "23level.ld". 

        local level_baserules = {
            ["woah"] = {
                baserule1 = {
                    "baba is green"
                }
            },
            ["23level"] = {
                baserule1 = {
                    "keke is purple"
                }
            }
        }
 ]]
local level_baserules = {
    -- ["7level"] = {
    --     thrust_baserule = {
    --     }

    -- }
}

-- Ignore this last part. It's needed to load all the baserules into the mod
return mod_config, levelpack_baserules, level_baserules, persist_baserules