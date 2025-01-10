-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2025 astra0081. (partake-kudos-only@duck.com)
-- Inspired from antispam mod by appgurueu (https://github.com/appgurueu/antispam)

local PLAYERS_MSG = {}
local PLAYERS_FREQ = {}
local PLAYER_KICKS = {}

local SPAM_SPEED = 5
local SPAM_SPEED_MSECS = SPAM_SPEED * 1e6
local SPAM_WARN = 3
local SPAM_KICK = SPAM_WARN + 4
local SPAM_MUTE_AFTER_KICKS = 2
local RESET_TIME = 30
local WARNING_COLOR = minetest.get_color_escape_sequence("#FFBB33")
local MUTE_TIME = 60*10

local function init_player_state(player_name)
    if not PLAYER_KICKS[player_name] then PLAYER_KICKS[player_name] = 0 end
    PLAYERS_MSG[player_name] = {}
end

local function increment_spam_counter(name)
    PLAYER_KICKS[name] = PLAYER_KICKS[name] + 1
    if PLAYER_KICKS[name] >= SPAM_MUTE_AFTER_KICKS then
        local expires = os.time() + MUTE_TIME
        local ok, e = xban.mute_player(name, "Antispam", expires, "Muted for spamming")

        if ok then
            minetest.log("action", string.format("[Antispam] Player %s muted for %d minutes due to spam", name, MUTE_TIME/60))
        else
            minetest.log("action", string.format("[Antispam] Failed to mute player %s: %s", name, e))
        end

        -- Reset player data after get muted
        PLAYER_KICKS[name] = nil
        PLAYERS_MSG[name] = nil
        PLAYERS_FREQ[name] = nil
        init_player_state(name)
        return true
    else
        minetest.kick_player(name, "Kicked for spamming.")
        minetest.log("action", "[Antispam] Player " .. name .. " kicked for spamming.")
        return false
    end
end

local function handle_message(name, message)
    local current_time = minetest.get_us_time()

    if PLAYERS_MSG[name][message] then
        local message_info = PLAYERS_MSG[name][message]
        message_info[1] = message_info[1] + 1
        message_info[2] = current_time

        if message_info[1] >= SPAM_KICK then
            if increment_spam_counter(name) then
                return true  -- Player is muted, stop further processing
            end
        elseif message_info[1] >= SPAM_WARN then
            minetest.chat_send_player(name, WARNING_COLOR .. "Warning! You've sent the message '" .. message .. "' too often. Wait at least " .. RESET_TIME .. " seconds before sending it again.")
        end
    else
        PLAYERS_MSG[name][message] = {1, current_time}
    end
	local warns = PLAYERS_FREQ[name][4]
    local amount = PLAYERS_FREQ[name][2]
    local speed = PLAYERS_FREQ[name][1]
    local delay = minetest.get_us_time() - PLAYERS_FREQ[name][3]
    speed = (speed * amount + delay) / (amount + 1)

    if amount >= warns then
        if warns + 1 >= SPAM_KICK - SPAM_WARN then
            if increment_spam_counter(name) then
                return true
            end
        elseif speed <= SPAM_SPEED_MSECS then
            minetest.chat_send_player(name, WARNING_COLOR .. "Warning! You're sending messages too fast. Wait at least " .. SPAM_SPEED .. " seconds.")
            warns = warns + 1
            speed = SPAM_SPEED_MSECS
            amount = SPAM_WARN
        else
            speed = 0
            amount = 0
            warns = 0
        end
    end

    PLAYERS_FREQ[name] = {
        speed,
        amount + 1,
        minetest.get_us_time(),
        warns
    }

    return false
end

minetest.register_chatcommand("antispam", {
    params = "<option> <value>",
    description = "Change spam settings: <option> can be 'speed', 'warn', 'kick', or 'mute_threshold'. <value> is the new value for that option.",
    privs = {server = true},
    func = function(name, param)
        local argv = param:split(" ")
        if #argv ~= 2 then
            return false, "Invalid parameters. Usage: /antispam <option> <value>"
        end

        local option = argv[1]
        local value = tonumber(argv[2])

        if not value then
            return false, "Invalid value. Please provide a valid number."
        end

        if option == "limit" then
            SPAM_SPEED = value
            SPAM_SPEED_MSECS = SPAM_SPEED * 1e6
        elseif option == "warn" then
            SPAM_WARN = value
            SPAM_KICK = SPAM_WARN + 4
        elseif option == "mute_threshold" then
            SPAM_MUTE_AFTER_KICKS = value
        else
            return false, "Invalid option. Available options: speed, warn, kick, mute_threshold."
        end

        return true, minetest.colorize("#FF0000", "[Antispam] ") .. minetest.colorize("#00FF00", "Option " .. option .. " set to " .. value)
    end
})

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    PLAYERS_MSG[pname] = nil
    PLAYERS_FREQ[pname] = nil
end)

minetest.register_on_joinplayer(function(player)
    init_player_state(player:get_player_name())
end)

minetest.register_on_chat_message(function(name, message)
    handle_message(name, message)
end)
