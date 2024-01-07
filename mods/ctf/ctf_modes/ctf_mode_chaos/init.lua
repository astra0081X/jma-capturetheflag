local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
ctf_modebase.register_mode("chaos", {
	hp_regen = 4,
	-- treasures = {} -- no treasures!
	crafts = {
		"ctf_map:damage_cobble",
		"ctf_map:spike",
		"ctf_map:reinforced_cobble 2",
	},
	physics = {sneak_glitch = true, new_move = true},
	blacklisted_nodes = {"default:apple"},
	team_chest_items = {
		"default:cobble 80", "default:wood 80", "ctf_map:damage_cobble 20", "ctf_map:reinforced_cobble 20",
		"default:torch 30", "ctf_teams:door_steel 2", "default:obsidian 35", "bucket:bucket_water"
	},
	rankings = rankings,
	recent_rankings = recent_rankings,
	summary_ranks = {
		_sort = "score",
		"score",
		"flag_captures", "flag_attempts",
		"kills", "kill_assists", "bounty_kills",
		"deaths",
		"hp_healed"
	},
	build_timer = 60 * 1.5,

	is_bound_item = function(_, name)
		if name == "grenade_launcher:launcher" or name == "ctf_mode_classes:scaling_ladder" then
			return true
		end
	end,
	stuff_provider = function(player)
		return {
			"grenade_launcher:launcher",
			"ctf_mode_classes:scaling_ladder",
			"default:pick_steel",
			"default:axe_steel",
			"default:cobble 30"
		}
	end,
	initial_stuff_item_levels = features.initial_stuff_item_levels,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = ctf_modebase.bounty_algo.kd.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = ctf_modebase.bounty_algo.kd.get_next_bounty
		random_gifts.run_spawn_timer()
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty
		random_gifts.stop_spawn_timer()
	end,
	on_new_match = features.on_new_match,
	on_match_end = features.on_match_end,
	team_allocator = features.team_allocator,
	on_allocplayer = features.on_allocplayer,
	on_leaveplayer = features.on_leaveplayer,
	on_dieplayer = features.on_dieplayer,
	on_respawnplayer = features.on_respawnplayer,
	can_take_flag = features.can_take_flag,
	on_flag_take = features.on_flag_take,
	on_flag_drop = features.on_flag_drop,
	on_flag_capture = features.on_flag_capture,
	on_flag_rightclick = function() end,
	get_chest_access = features.get_chest_access,
	player_is_pro = features.player_is_pro,
	can_punchplayer = features.can_punchplayer,
	on_punchplayer = function(player, hitter, damage, unneeded, tool_capabilities, ...)
		return features.on_punchplayer(player, hitter, damage, unneeded, tool_capabilities, ...)
	end,
	on_healplayer = features.on_healplayer,
	calculate_knockback = function()
		return 0
	end,
})
