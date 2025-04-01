local Util = WarpDeplete.Util
local L = WarpDeplete.L

local function font(name, profileVar, updateFn, extraOptions)
	local result = {
		type = "select",
		dialogControl = "LSM30_Font",
		name = name,
		values = WarpDeplete.LSM:HashTable("font"),
		get = function(_)
			return WarpDeplete.db.profile[profileVar]
		end,
		set = function(_, value)
			WarpDeplete.db.profile[profileVar] = value
			WarpDeplete[updateFn](WarpDeplete)
		end,
	}

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

local function range(name, profileVar, updateFn, extraOptions)
	local result = {
		type = "range",
		name = name,
		min = 8,
		max = 40,
		step = 1,
		get = function(_)
			return WarpDeplete.db.profile[profileVar]
		end,
		set = function(_, value)
			WarpDeplete.db.profile[profileVar] = value
			WarpDeplete[updateFn](WarpDeplete)
		end,
	}

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

local function toggle(name, profileVar, updateFn, extraOptions)
	local result = {
		type = "toggle",
		name = name,
		get = function(_)
			return WarpDeplete.db.profile[profileVar]
		end,
		set = function(_, value)
			WarpDeplete.db.profile[profileVar] = value
			WarpDeplete[updateFn](WarpDeplete)
		end,
	}

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

local function fontFlags(name, profileVar, updateFn, extraOptions)
	local result = {
		type = "select",
		name = name,
		desc = L["Default:"] .. " " .. L["OUTLINE"],
		values = {
			["OUTLINE"] = L["OUTLINE"],
			["THICKOUTLINE"] = L["THICKOUTLINE"],
			["MONOCHROME"] = L["MONOCHROME"],
			["NONE"] = L["NONE"],
		},
		get = function(_)
			return WarpDeplete.db.profile[profileVar]
		end,
		set = function(_, value)
			WarpDeplete.db.profile[profileVar] = value
			WarpDeplete[updateFn](WarpDeplete)
		end,
	}

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

local function lineBreak(hidden, width)
	local result = {
		type = "description",
		name = "\n",
		hidden = hidden or false,
	}

	if width then
		result.width = width
	end

	return result
end

local function color(name, profileVar, updateFn, extraOptions)
	local result = {
		type = "color",
		name = name,
		get = function(_)
			local r, g, b, a = Util.hexToRGB(WarpDeplete.db.profile[profileVar])
			return r, g, b, a or 1
		end,
		set = function(_, r, g, b, a)
			WarpDeplete.db.profile[profileVar] = Util.rgbToHex(r, g, b, a)
			WarpDeplete[updateFn](WarpDeplete)
		end,
	}

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

local function barTexture(name, profileVar, updateFn, extraOptions)
	local result = {
		name = name,
		type = "select",
		dialogControl = "LSM30_Statusbar",
		values = WarpDeplete.LSM:HashTable("statusbar"),
		get = function(_)
			return WarpDeplete.db.profile[profileVar]
		end,
		set = function(_, value)
			WarpDeplete.db.profile[profileVar] = value
			WarpDeplete[updateFn](WarpDeplete)
		end,
	}

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

local function group(name, inline, args, extraOptions)
	local order = 1

	local result = {
		name = name,
		inline = inline,
		type = "group",
		args = {},
	}

	for _, arg in pairs(args) do
		arg.order = order
		result.args[arg.type .. order] = arg
		order = order + 1
	end

	if extraOptions and type(extraOptions) == "table" then
		for k, v in pairs(extraOptions) do
			result[k] = v
		end
	end

	return result
end

function WarpDeplete:InitOptions()
	self.isUnlocked = false

	local options = {
		name = "WarpDeplete",
		handler = self,
		type = "group",
		childGroups = "tab",
		args = {
			unlocked = {
				order = 1,
				type = "toggle",
				name = L["Unlocked"],
				desc = L["Unlocks the timer window and allows it to be moved around"],
				get = function(_)
					return WarpDeplete.isUnlocked
				end,
				set = WarpDeplete.SetUnlocked,
			},

			demo = {
				order = 2,
				type = "toggle",
				name = L["Demo Mode"],
				desc = L["Enables the demo mode, used for configuring the timer"],
				get = function(_)
					return WarpDeplete.state.demoModeActive
				end,
				set = function(_, value)
					if value then
						WarpDeplete:EnableDemoMode()
					else
						WarpDeplete:DisableDemoMode()
					end
				end,
			},
			general = group(L["General"], false, {
				lineBreak(),
				toggle(L["Insert Keystone Automatically"], "insertKeystoneAutomatically", "RenderLayout"),
				toggle(
					L["Show millisecond precision after dungeon completion"],
					"showMillisecondsWhenDungeonCompleted",
					"RenderLayout"
				),
				lineBreak(),

				group(L["Forces Display"], true, {
					toggle(L["Show Forces above 100%"], "unClampForcesPercent", "RenderLayout", {
						desc = L["Once the forces objective is completed, it'll go above 100%.\nNOTE: Disconnects or reloads will reset the count back down to 100%."],
						width = 2,
					}),
					lineBreak(),
					{
						type = "select",
						name = L["Forces Text Format"],
						desc = L["Choose how your forces progress will be displayed"],
						sorting = {
							":percent:",
							":percentafterpull:",
							":count:/:totalcount:",
							":count:/:totalcount: - :percent:",
							":custom:",
						},
						values = {
							[":percent:"] = "82.52%",
							[":percentafterpull:"] = "87.84%",
							[":count:/:totalcount:"] = "198/240",
							[":count:/:totalcount: - :percent:"] = "198/240 - 82.52%",
							[":custom:"] = L["Custom"],
						},
						get = function(_)
							return WarpDeplete.db.profile.forcesFormat
						end,
						set = function(_, value)
							WarpDeplete.db.profile.forcesFormat = value
							WarpDeplete:RenderLayout()
						end,
					},
					lineBreak(function()
						return WarpDeplete.db.profile.forcesFormat == ":custom:"
					end, 2),

					{
						type = "input",
						name = L["Custom Forces Text Format"],
						desc = L["Use the following tags to set your custom format"]
							.. ":"
							.. "\n- :percent: "
							.. L["Shows the current forces percentage (e.g. 82.52%)"]
							.. "\n- :count: "
							.. L["Shows the current forces count (e.g. 198)"]
							.. "\n- :totalcount: "
							.. L["Shows the total forces count (e.g. 240)"]
							.. "\n- :remainingcount: "
							.. L["Shows the remaining amount of forces needed to complete"]
							.. "\n- :countafterpull: "
							.. L["Shows the current forces count including current pull (e.g. 205)"]
							.. "\n- :remainingcountafterpull: "
							.. L["Shows the remaining amount of forces needed to complete after current pull"]
							.. "\n- :remainingpercent: "
							.. L["Shows the remaining percentage of forces to achieve 100%"]
							.. "\n- :percentafterpull: "
							.. L["Shows the current forces percentage including current pull (e.g. 87.84%)"]
							.. "\n- :remainingpercentafterpull: "
							.. L["Shows the remaining percentage of forces to achieve 100% after current pull"],
						multiline = false,
						width = 2,
						hidden = function()
							return WarpDeplete.db.profile.forcesFormat ~= ":custom:"
						end,
						get = function(_)
							return WarpDeplete.db.profile.customForcesFormat
						end,
						set = function(_, value)
							WarpDeplete.db.profile.customForcesFormat = value
							WarpDeplete:RenderLayout()
						end,
					},

					{
						type = "select",
						name = L["Current Pull Text Format"],
						desc = L["Choose how your current pull count will be displayed"],
						sorting = {
							"(+:percent:)",
							"(+:count:)",
							"(+:count: - :percent:)",
							":custom:",
						},
						values = {
							["(+:percent:)"] = "(+5.32%)",
							["(+:count:)"] = "(+14)",
							["(+:count: - :percent:)"] = "(+14 / 5.32%)",
							[":custom:"] = L["Custom"],
						},
						get = function(_)
							return WarpDeplete.db.profile.currentPullFormat
						end,
						set = function(_, value)
							WarpDeplete.db.profile.currentPullFormat = value
							WarpDeplete:RenderLayout()
						end,
					},
					lineBreak(function()
						return WarpDeplete.db.profile.currentPullFormat == ":custom:"
					end, 2),

					{
						type = "input",
						name = L["Custom Current Pull Text Format"],
						desc = L["Use the following tags to set your custom format"]
							.. ":"
							.. "\n- :percent: "
							.. L["Shows the current pull percentage (e.g. 82.52%)"]
							.. "\n- :count: "
							.. L["Shows the current pull count (e.g. 198)"]
							.. "\n- :countafterpull: "
							.. L["Shows the current forces count including current pull (e.g. 205)"]
							.. "\n- :remainingcountafterpull: "
							.. L["Shows the remaining amount of forces needed to complete after current pull"]
							.. "\n- :percentafterpull: "
							.. L["Shows the current forces percentage including current pull (e.g. 87.84%)"]
							.. "\n- :remainingpercentafterpull: "
							.. L["Shows the remaining percentage of forces to achieve 100% after current pull"]
							.. "\n"
							.. "\n"
							.. L["NOTE: Some of the tags available here overlap with the tags in the forces text."]
							.. "\n"
							.. L["However, this field will be hidden when there is no current pull."],
						multiline = false,
						width = 2,
						hidden = function()
							return WarpDeplete.db.profile.currentPullFormat ~= ":custom:"
						end,
						get = function(_)
							return WarpDeplete.db.profile.customCurrentPullFormat
						end,
						set = function(_, value)
							WarpDeplete.db.profile.customCurrentPullFormat = value
							WarpDeplete:RenderLayout()
						end,
					},
				}),

				group(L["Forces Count in Tooltip"], true, {
					toggle(L["Show Forces Count in Tooltip"], "showTooltipCount", "RenderLayout", {
						desc = L["Add a line to the tooltip, showing how much count a mob will award upon death"],
					}),
					lineBreak(function()
						return not WarpDeplete.db.profile.showTooltipCount
					end, 3),

					{
						type = "select",
						name = L["Tooltip Forces Text Format"],
						desc = L["Choose how count will be displayed in the tooltip"],
						sorting = {
							"+:count: / :percent:",
							"+:count:",
							"+:percent:",
							":custom:",
						},
						values = {
							["+:percent:"] = "+5.32%",
							["+:count:"] = "+14",
							["+:count: / :percent:"] = "+14 / 5.32%",
							[":custom:"] = L["Custom"],
						},
						hidden = function()
							return not WarpDeplete.db.profile.showTooltipCount
						end,
						get = function(_)
							return WarpDeplete.db.profile.tooltipCountFormat
						end,
						set = function(_, value)
							WarpDeplete.db.profile.tooltipCountFormat = value
							WarpDeplete:RenderLayout()
						end,
					},

					{
						type = "input",
						name = L["Custom Tooltip Forces Count Format"],
						desc = L["Use the following tags to set your custom format"]
							.. ":"
							.. "\n- :percent: "
							.. L["Shows the forces percentage the enemy will award (e.g. 1.4%)"]
							.. "\n- :count: "
							.. L["Shows the count the enemy will award (e.g. 4)"],
						multiline = false,
						width = 2,
						hidden = function()
							return WarpDeplete.db.profile.tooltipCountFormat ~= ":custom:"
								or not WarpDeplete.db.profile.showTooltipCount
						end,
						get = function(_)
							return WarpDeplete.db.profile.customTooltipCountFormat
						end,
						set = function(_, value)
							WarpDeplete.db.profile.customTooltipCountFormat = value
							WarpDeplete:RenderLayout()
						end,
					},
				}),

				group(L["Forces Glow"], true, {
					{
						type = "toggle",
						name = L["Show Forces Glow"],
						desc = L["Show a glow around the forces action bar if the current pull will bring it to 100%"],
						get = function(_)
							return WarpDeplete.db.profile.showForcesGlow
						end,
						set = function(_, value)
							WarpDeplete.db.profile.showForcesGlow = value
							WarpDeplete:RenderLayout()
						end,
					},

					{
						type = "toggle",
						name = L["Show in Demo Mode"],
						desc = L["Show the forces glow in demo mode"],
						hidden = function()
							return not WarpDeplete.db.profile.showForcesGlow
						end,
						get = function(_)
							return WarpDeplete.db.profile.demoForcesGlow
						end,
						set = function(_, value)
							WarpDeplete.db.profile.demoForcesGlow = value
							WarpDeplete:RenderLayout()
						end,
					},

					lineBreak(function()
						return not WarpDeplete.db.profile.showForcesGlow
					end, 3),

					color(L["Color"], "forcesGlowColor", "UpdateGlowAppearance", {
						hidden = function()
							return not WarpDeplete.db.profile.showForcesGlow
						end,
						width = 1 / 2,
					}),

					lineBreak(function()
						return not WarpDeplete.db.profile.showForcesGlow
					end, 3),

					range(L["Line Count"], "forcesGlowLineCount", "UpdateGlowAppearance", {
						hidden = function()
							return not WarpDeplete.db.profile.showForcesGlow
						end,
						min = 1,
						max = 30,
						step = 1,
						width = 5 / 6,
					}),

					range(L["Line Length"], "forcesGlowLength", "UpdateGlowAppearance", {
						hidden = function()
							return not WarpDeplete.db.profile.showForcesGlow
						end,
						min = 1,
						max = 10,
						step = 1,
						width = 5 / 6,
					}),

					range(L["Line Thickness"], "forcesGlowThickness", "UpdateGlowAppearance", {
						hidden = function()
							return not WarpDeplete.db.profile.showForcesGlow
						end,
						min = 1,
						max = 5,
						step = 0.1,
						width = 5 / 6,
					}),

					range(L["Frequency"], "forcesGlowFrequency", "UpdateGlowAppearance", {
						hidden = function()
							return not WarpDeplete.db.profile.showForcesGlow
						end,
						min = 0.05,
						max = 0.5,
						step = 0.01,
						width = 5 / 6,
					}),
				}),

				group(L["Death Log Tooltip"], true, {
					{
						type = "toggle",
						name = L["Show Death Log When Hovering Deaths Text"],
						desc = L["NOTE: This will only record deaths that happen while you're online. If you disconnect and/or reconnect, this will not show deaths that happened previously."],
						get = function(_)
							return WarpDeplete.db.profile.showDeathsTooltip
						end,
						set = function(_, value)
							WarpDeplete.db.profile.showDeathsTooltip = value
						end,
						width = 3 / 2,
					},
					{
						type = "select",
						name = L["Death Log Style"],
						desc = L["Choose how players deaths will be displayed in the tooltip. Hover the deaths text while in demo mode for a preview."],
						sorting = {
							"count",
							"time",
						},
						values = {
							["count"] = L["Overall amount of deaths by player"],
							["time"] = L["Recent deaths with timestamps"],
						},
						hidden = function()
							return not WarpDeplete.db.profile.showDeathsTooltip
						end,
						get = function(_)
							return WarpDeplete.db.profile.deathLogStyle
						end,
						set = function(_, value)
							WarpDeplete.db.profile.deathLogStyle = value
						end,
						width = 3 / 2,
					},
				}),

				group(L["Splits"], true, {
					{
						type = "toggle",
						name = L["Enable Splits"],
						desc = L["Show time difference to best objective completion times"],
						get = function(_)
							return WarpDeplete.db.profile.splitsEnabled
						end,
						set = function(_, value)
							WarpDeplete.db.profile.splitsEnabled = value
							self:RenderLayout()
						end,
						width = 3 / 2,
					},
					{
						type = "toggle",
						name = L["Show Split Records During Countdown"],
						desc = L["Show your personal best times for splits during the countdown at the start of runs"],
						hidden = function()
							return not WarpDeplete.db.profile.splitsEnabled
						end,
						get = function(_)
							return WarpDeplete.db.profile.showPbsDuringCountdown
						end,
						set = function(_, value)
							WarpDeplete.db.profile.showPbsDuringCountdown = value
						end,
						width = 3 / 2,
					},
				}),
			}, { order = 3 }),

			texts = group(L["Display"], false, {
				group(L["General"], true, {
					range(L["Scale"], "frameScale", "RenderLayout", { min = 0.5, max = 2, step = 0.01, width = 3 }),
					{
						type = "select",
						name = L["Text Alignment"],
						desc = L["Choose the alignment for all texts in the timer window"],
						sorting = { "right", "left" },
						values = {
							["left"] = L["Left"],
							["right"] = L["Right"],
						},
						get = function(_)
							return WarpDeplete.db.profile.alignTexts
						end,
						set = function(_, value)
							WarpDeplete.db.profile.alignTexts = value
							WarpDeplete:RenderLayout()
						end,
					},
					{
						type = "select",
						name = L["Bar Text Alignment"],
						desc = L["Choose the alignment for the captions on the timer and forces bars"],
						sorting = { "right", "left" },
						values = {
							["left"] = L["Left"],
							["right"] = L["Right"],
						},
						get = function(_)
							return WarpDeplete.db.profile.alignBarTexts
						end,
						set = function(_, value)
							WarpDeplete.db.profile.alignBarTexts = value
							WarpDeplete:RenderLayout()
						end,
					},
					{
						type = "select",
						name = L["Boss Clear Time Position"],
						desc = L["Choose where the clear times for bosses will be displayed"],
						sorting = { "start", "end" },
						values = {
							["start"] = L["Start"],
							["end"] = L["End"],
						},
						get = function(_)
							return WarpDeplete.db.profile.alignBossClear
						end,
						set = function(_, value)
							WarpDeplete.db.profile.alignBossClear = value
							WarpDeplete:RenderObjectives()
						end,
					},

					lineBreak(),

					range(L["Element Padding"], "verticalOffset", "RenderLayout", { min = 0, max = 100, step = 0.01 }),
					range(
						L["Boss Name Padding"],
						"objectivesOffset",
						"RenderLayout",
						{ min = 0, max = 100, step = 0.01 }
					),
					range(L["Bar Padding"], "barPadding", "RenderLayout", { min = 0, max = 100, step = 0.01 }),
				}),

				group(L["Timer Colors"], true, {
					color(L["Timer Color"], "timerRunningColor", "RenderLayout"),
					color(L["Timer Success Color"], "timerSuccessColor", "RenderLayout"),
					color(L["Timer Expired Color"], "timerExpiredColor", "RenderLayout"),
				}, { desc = L["These colors are used for both the main timer, as well as the bar texts."] }),

				group(L["Main Timer"], true, {
					font(L["Timer Font"], "timerFont", "RenderLayout"),
					range(L["Timer Font Size"], "timerFontSize", "RenderLayout", { max = 80 }),
					fontFlags(L["Timer Font Flags"], "timerFontFlags", "RenderLayout"),
				}),

				group(L["Deaths"], true, {
					font(L["Deaths Font"], "deathsFont", "RenderLayout"),
					range(L["Deaths Font Fize"], "deathsFontSize", "RenderLayout"),
					fontFlags(L["Deaths Font Flags"], "deathsFontFlags", "RenderLayout"),
					color(L["Deaths Color"], "deathsColor", "RenderLayout"),
				}),

				group(L["Key Details"], true, {
					font(L["Key Font"], "keyFont", "RenderLayout"),
					range(L["Key Font Size"], "keyFontSize", "RenderLayout"),
					fontFlags(L["Key Font Flags"], "keyFontFlags", "RenderLayout"),
					color(L["Key Color"], "keyColor", "RenderLayout"),

					lineBreak(),

					font(L["Key Details Font"], "keyDetailsFont", "RenderLayout"),
					range(L["Key Details Font Size"], "keyDetailsFontSize", "RenderLayout"),
					fontFlags(L["Key Details Font Flags"], "keyDetailsFontFlags", "RenderLayout"),
					color(L["Key Details Color"], "keyDetailsColor", "RenderLayout"),
				}),

				group(L["Bars"], true, {
					range(L["Bar Width"], "barWidth", "RenderLayout", { width = "full", min = 10, max = 600 }),
					range(L["Bar Height"], "barHeight", "RenderLayout", { width = "full", min = 4, max = 50 }),
				}),

				group(L["+1 Timer"], true, {
					font(L["+1 Timer Font"], "bar1Font", "RenderLayout"),
					range(L["+1 Timer Font Size"], "bar1FontSize", "RenderLayout"),
					fontFlags(L["+1 Timer Font Flags"], "bar1FontFlags", "RenderLayout"),

					barTexture(L["+1 Timer Bar Texture"], "bar1Texture", "RenderLayout", { width = "double" }),
					color(L["+1 Timer Bar Color"], "bar1TextureColor", "RenderLayout"),
				}),

				group(L["+2 Timer"], true, {
					font(L["+2 Timer Font"], "bar2Font", "RenderLayout"),
					range(L["+2 Timer Font Size"], "bar2FontSize", "RenderLayout"),
					fontFlags(L["+2 Timer Font Flags"], "bar2FontFlags", "RenderLayout"),

					barTexture(L["+2 Timer Bar Texture"], "bar2Texture", "RenderLayout", { width = "double" }),
					color(L["+2 Timer Bar Color"], "bar2TextureColor", "RenderLayout"),
				}),

				group(L["+3 Timer"], true, {
					font(L["+3 Timer Font"], "bar3Font", "RenderLayout"),
					range(L["+3 Timer Font Size"], "bar3FontSize", "RenderLayout"),
					fontFlags(L["+3 Timer Font Flags"], "bar3FontFlags", "RenderLayout"),

					barTexture(L["+3 Timer Bar Texture"], "bar3Texture", "RenderLayout", { width = "double" }),
					color(L["+3 Timer Bar Color"], "bar3TextureColor", "RenderLayout"),
				}),

				group(L["Forces"], true, {
					font(L["Forces Font"], "forcesFont", "RenderLayout"),
					range(L["Forces Font Size"], "forcesFontSize", "RenderLayout"),
					fontFlags(L["Forces Font Flags"], "forcesFontFlags", "RenderLayout"),
					color(L["Forces Color"], "forcesColor", "RenderLayout"),
					color(L["Completed Forces Color"], "completedForcesColor", "RenderLayout"),

					lineBreak(),

					barTexture(L["Forces Bar Texture"], "forcesTexture", "RenderLayout", { width = "double" }),
					color(L["Forces Bar Color"], "forcesTextureColor", "RenderLayout"),

					lineBreak(),

					barTexture(
						L["Current Pull Bar Texture"],
						"forcesOverlayTexture",
						"RenderLayout",
						{ width = "double" }
					),
					color(L["Current Pull Bar Color"], "forcesOverlayTextureColor", "RenderLayout"),
				}),

				group(L["Objectives"], true, {
					font(L["Objectives Font"], "objectivesFont", "RenderLayout", { width = 3 / 2 }),
					fontFlags(L["Objectives Font Flags"], "objectivesFontFlags", "RenderLayout", { width = 3 / 2 }),
					range(L["Objectives Font Size"], "objectivesFontSize", "RenderLayout", { width = 3 / 2 }),
					color(L["Objectives Color"], "objectivesColor", "RenderLayout"),
					color(L["Completed Objective Color"], "completedObjectivesColor", "RenderLayout", {
						width = 7 / 6,
					}),
					color(L["New Best Objective Split"], "splitFasterTimeColor", "RenderLayout", {
						desc = L["The color to use when you've set a new best objective clear time"],
						width = 7 / 6,
					}),
					color(L["Slower Objective Split"], "splitSlowerTimeColor", "RenderLayout", {
						desc = L["The color to use for objective clear times slower than your best time"],
					}),
				}),
			}, { order = 4 }),
		},
	}

	local debugOptions = group("Debug", false, {
		{
			type = "range",
			name = L["Timer limit (Minutes)"],
			min = 1,
			max = 100,
			step = 1,
			get = function(_)
				return math.floor(WarpDeplete.state.timeLimit / 60)
			end,
			set = function(_, value)
				WarpDeplete.state.timeLimit = value * 60
				WarpDeplete:RenderTimer()
			end,
		},

		{
			type = "range",
			name = L["Timer current (Minutes)"],
			min = 0,
			max = 100,
			step = 1,
			get = function(_)
				return math.floor(WarpDeplete.state.timer / 60)
			end,
			set = function(_, value)
				WarpDeplete.state.timer = value * 60
				WarpDeplete:RenderTimer()
			end,
		},

		{
			type = "range",
			name = L["Forces total"],
			min = 1,
			max = 500,
			step = 1,
			get = function(_)
				return WarpDeplete.state.totalCount
			end,
			set = function(_, value)
				WarpDeplete:SetForcesTotal(value)
			end,
		},

		{
			type = "range",
			name = L["Forces pull"],
			min = 1,
			max = 500,
			step = 1,
			get = function(_)
				return WarpDeplete.state.pullCount
			end,
			set = function(_, value)
				WarpDeplete:SetForcesPull(value)
			end,
		},

		{
			type = "range",
			name = L["Forces current"],
			min = 1,
			max = 500,
			step = 1,
			get = function(_)
				return WarpDeplete.state.currentCount
			end,
			set = function(_, value)
				WarpDeplete:SetForcesCurrent(value)
			end,
		},

		{
			type = "toggle",
			name = L["Forces complete"],
			get = function(_)
				return WarpDeplete.state.forcesCompleted
			end,
			set = function(_, value)
				WarpDeplete.state.forcesCompleted = value

				if value then
					WarpDeplete.state.forcesCompletionTime = 3000
				else
					WarpDeplete.state.forcesCompletionTime = nil
				end

				self:RenderForces()
			end,
			width = 3 / 2,
		},
		{
			type = "toggle",
			name = L["Challenger's Peril"],
			get = function(_)
				return WarpDeplete.state.hasChallengersPeril
			end,
			set = function(_, value)
				WarpDeplete.state.hasChallengersPeril = value
				self:SetTimeLimit(self.state.timeLimit)
				self:RenderLayout()
				self:RenderTimer()
			end,
			width = 3 / 2,
		},
	})

	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	if self.db.global.DEBUG then
		options.args.debug = debugOptions
	end

	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	LibStub("AceConfig-3.0"):RegisterOptionsTable("WarpDeplete", options)
	self.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions("WarpDeplete", "WarpDeplete")

	self.configDialog = AceConfigDialog
end

function WarpDeplete:InitChatCommands()
	self:RegisterChatCommand("wdp", "HandleChatCommand")
	self:RegisterChatCommand("warp", "HandleChatCommand")
	self:RegisterChatCommand("warpdeplete", "HandleChatCommand")
	self:RegisterChatCommand("WarpDeplete", "HandleChatCommand")
end

function WarpDeplete:HandleChatCommand(input)
	local cmd = string.lower(input)

	if cmd == "clearallsplits" then
		self.db.global.splits = {}
		return
	end

	if cmd == "splits" then
		for mapId, mapSplits in pairs(self.db.global.splits) do
			for level, levelSplits in pairs(mapSplits) do
				self:Print("Splits for map " .. tostring(mapId) .. " " .. tostring(level))
				if levelSplits.best then
					self:Print("Best")
					for objective, split in pairs(levelSplits.best) do
						self:Print("  " .. tostring(objective) .. ": " .. tostring(split))
					end
				end

				if levelSplits.current then
					self:Print("Current")
					for objective, split in pairs(levelSplits.current) do
						self:Print("  " .. tostring(objective) .. ": " .. tostring(split))
					end
				end

				if levelSplits.currentDiff then
					self:Print("Current Diff")
					for objective, split in pairs(levelSplits.currentDiff) do
						self:Print("  " .. tostring(objective) .. ": " .. tostring(split))
					end
				end
			end
		end
		return
	end

	if cmd == "toggle" then
		self:SetUnlocked(not self.isUnlocked)
		return
	end

	if cmd == "unlock" then
		self:SetUnlocked(true)
		return
	end

	if cmd == "lock" then
		self:SetUnlocked(false)
		return
	end

	if cmd == "demo" then
		if self.state.demoModeActive then
			self:DisableDemoMode()
		else
			self:EnableDemoMode()
		end
		return
	end

	if cmd == "debug" then
		self.db.global.DEBUG = not self.db.global.DEBUG
		if self.db.global.DEBUG then
			self:Print("|cFF479AEDDEBUG|r Debug mode enabled")
		else
			self:Print("|cFF479AEDDEBUG|r Debug mode disabled")
		end
		return
	end

	Settings.OpenToCategory("WarpDeplete")
end

function WarpDeplete.SetUnlocked(_, value)
	local self = WarpDeplete
	if value == self.isUnlocked then
		return
	end

	self.isUnlocked = value
	self.frames.root.texture:SetColorTexture(0, 0, 0, self.isUnlocked and 0.3 or 0)
	self.frames.root:SetMovable(self.isUnlocked)
	self.frames.root:EnableMouse(self.isUnlocked)
end

function WarpDeplete:OnProfileChanged()
	self:RenderLayout()

	self:RenderForces()
	self:RenderTimer()
	self:RenderObjectives()
end

function WarpDeplete:UpdateGlowAppearance()
	if not self.state.pullGlowActive then
		return
	end

	-- LibCustomGlow doesn't let us change the glow properties
	-- once it's running, so this is the easiest way. Pretty sure
	-- everybody does this.
	self:HideGlow()
	self:ShowGlow()
end
