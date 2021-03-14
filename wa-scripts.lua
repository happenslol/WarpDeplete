-- Bars (check on: WA_DELAYED_PLAYER_ENTERING_WORLD OPTIONS_CLOSED CHALLENGE_MODE_START CHALLENGE_MODE_COMPLETED FRAME_UPDATE WORLD_STATE_TIMER_START)
function(states, e, ...)
  local function formatDeaths(deaths, deathtime)
      if not deathtime or not deaths then return "" end
      
      local deathtext = ""..deaths
      if deaths == 1 then deathtext = deathtext.." Death "
      else deathtext = deathtext.." Deaths " end
      
      local deathAddedTime = ((deathtime == 0 and "") or (deathtime < 60 and "(+"..deathtime.."s)") or "(+"..aura_env.formattime(deathtime)..")")
      return deathtext..deathAddedTime
  end
  
  local function formatChestTimers(timer, max, two, three)
      local threeD = (timer < three and aura_env.formattime(three-aura_env.timer)) or ""
      local twoD = (timer < two and aura_env.formattime(two-timer)) or ""
      local maxD = (timer < max and aura_env.formattime(max-timer)) 
      or (timer > max and "|cFFFF0000+"..aura_env.formattime(timer-max).."|r")
      or ""
      
      return maxD, twoD, threeD
  end
  
  local function formatChestTimerPrint(chest, which, chestTimer, timer)
      return (chest >= which and aura_env.color.."-"..aura_env.formattime(chestTimer-timer).."|r")
      or " |cFFFF0000+"..aura_env.formattime(timer-chestTimer).."|r"
  end
  
  local function getBarPercent(bar, timeremain, timelimit)
      local percent = ((timelimit - timeremain) / timelimit) * 100
      
      if bar == 3 then
          return (percent >= 60 and 100) or (percent * (10 / 6))
      elseif bar == 2 then
          return (percent >= 80 and 100) or (percent < 60 and 0) or ((percent - 60) * 5)
      elseif bar == 1 then
          return (percent < 80 and 0) or ((percent - 80) * 5)
      end
  end
  
  if e == "OPTIONS" or e == "OPTIONS_CLOSED" then
      aura_env.finish = (select(3, C_ChallengeMode.GetCompletionInfo()) == 0 and 0) or select(3, C_ChallengeMode.GetCompletionInfo())
      local mapID = C_ChallengeMode.GetActiveChallengeMapID();
      
      if mapID then
          local time = GetTime()
          aura_env.start = (select(2, GetWorldElapsedTime(1)) < 2 and time) or aura_env.start
          aura_env.timelimit  = select(3, C_ChallengeMode.GetMapUIInfo(mapID))
          local timeremain = aura_env.timelimit-aura_env.timer
          
          if aura_env.timelimit >= aura_env.timer then
              aura_env.deaths, aura_env.deathtime = C_ChallengeMode.GetDeathCount()
          else
              aura_env.deaths = C_ChallengeMode.GetDeathCount()
          end
          
          aura_env.timer = (aura_env.start and time-aura_env.start+aura_env.deathtime) or select(2, GetWorldElapsedTime(1)) or 0
          
          aura_env.deaths = aura_env.deaths or 0
          aura_env.deathtime = aura_env.deathtime or 0
          aura_env.deathresult = formatDeaths(aura_env.deaths, aura_env.deathtime)
          
          aura_env.two = aura_env.timelimit*0.8
          aura_env.three = aura_env.timelimit*0.6
          aura_env.maxD, aura_env.twoD, aura_env.threeD = formatChestTimers(aura_env.timer, aura_env.timelimit, aura_env.two, aura_env.three)
          local percent = getBarPercent(aura_env.which_bar, timeremain, aura_env.timelimit)
          
          states[""] = {
              show = true,
              progressType = "static",
              value = percent,
              total = 100,
              changed = true,
          }
          return true
      end
  elseif e == "CHALLENGE_MODE_COMPLETED" and aura_env.timelimit > 0  then
      local time = select(3, C_ChallengeMode.GetCompletionInfo())
      if aura_env.which_bar == 1 and time ~= 0 then
          local timer = (time/1000)  
          local timeMS  = select(2, strsplit(".", (timer))) or select(2, strsplit(".", (GetTime()-timer)))
          local timertext = ""
          timeMS = (aura_env.decimalsF == 0 and 0) or (timeMS and string.sub(timeMS, 1, aura_env.decimalsF))
          if timer > 0 and timeMS and timeMS ~= 0 then
              timeMS = (".%s"):format(timeMS)
          else
              timeMS = ""
          end
          
          local current = aura_env.formattime(math.floor(timer))
          timertext = ("%s%s"):format(current, timeMS) or "00:00"
          timertext = timertext.." / "..aura_env.formattime(aura_env.timelimit)
          
          local chest = select(5, C_ChallengeMode.GetCompletionInfo())
          aura_env.threeDD = formatChestTimerPrint(chest, 3, aura_env.three, timer)
          aura_env.twoDD = formatChestTimerPrint(chest, 2, aura_env.two, timer)
          aura_env.maxDD = formatChestTimerPrint(chest, 1, aura_env.timelimit, timer)
          aura_env.threeDD, aura_env.twoDD, aura_env.maxDD = "+3: "..aura_env.threeDD, "+2: "..aura_env.twoDD, "+1: "..aura_env.maxDD
          
          if select(4, C_ChallengeMode.GetCompletionInfo()) then
              timertext = aura_env.color..timertext.."|r"
          else
              timertext = " |cFFFF0000"..timertext.."|r"
          end
          
          print("Finish Time:"..timertext, aura_env.threeDD, aura_env.twoDD, aura_env.maxDD)
      end
      return true
  elseif e == "CHALLENGE_MODE_START" and ... then
      aura_env.finish = 0
      aura_env.start = nil
  elseif (e == "WORLD_STATE_TIMER_START" or e == "WA_DELAYED_PLAYER_ENTERING_WORLD") and aura_env.finish == 0 then
      local mapID = C_ChallengeMode.GetActiveChallengeMapID()
      aura_env.dungeon = aura_env.maptoname[mapID] or ""
      aura_env.level, aura_env.affixes = C_ChallengeMode.GetActiveKeystoneInfo()
      aura_env.icon = ""
      for k, v in pairs(aura_env.affixes) do
          if aura_env.icon == "" then
              aura_env.icon = select(1, C_ChallengeMode.GetAffixInfo(v))
          else
              aura_env.icon = aura_env.icon.." "..select(1, C_ChallengeMode.GetAffixInfo(v))
          end
      end
      
      aura_env.keyinfo = "["..aura_env.level.."] "
      for i=1, 4 do
          if select(i, strsplit(" ", aura_env.icon)) then
              if i > 1 then aura_env.keyinfo = aura_env.keyinfo.." - " end
              aura_env.keyinfo = aura_env.keyinfo..select(i, strsplit(" ", aura_env.icon)).." "
          end
      end
      
      if mapID then
          local time = GetTime()
          aura_env.start = (select(2, GetWorldElapsedTime(1)) < 2 and time) or aura_env.start
          aura_env.timelimit  = select(3, C_ChallengeMode.GetMapUIInfo(mapID))
          
          if aura_env.timelimit >= aura_env.timer then
              aura_env.deaths, aura_env.deathtime = C_ChallengeMode.GetDeathCount()
          else
              aura_env.deaths = C_ChallengeMode.GetDeathCount()
          end
          
          aura_env.deaths = aura_env.deaths or 0
          aura_env.deathtime = aura_env.deathtime or 0
          aura_env.deathresult = formatDeaths(aura_env.deaths, aura_env.deathtime)
          
          aura_env.timer = (aura_env.start and time-aura_env.start+aura_env.deathtime) or select(2, GetWorldElapsedTime(1)) or 0
          local timeremain = aura_env.timelimit-aura_env.timer
          
          aura_env.two = aura_env.timelimit*0.8
          aura_env.three = aura_env.timelimit*0.6
          aura_env.maxD, aura_env.twoD, aura_env.threeD = formatChestTimers(aura_env.timer, aura_env.timelimit, aura_env.two, aura_env.three)
          local percent = getBarPercent(aura_env.which_bar, timeremain, aura_env.timelimit)
          
          states[""] = {
              show = true,
              progressType = "static",
              value = percent,
              total = 100,
              changed = true,
          }
          return true
      end
  elseif e == "FRAME_UPDATE" and ((not aura_env.last) or aura_env.last < GetTime()-0.10) and select(3, C_ChallengeMode.GetCompletionInfo()) == 0  then
      aura_env.last = GetTime()
      if aura_env.timelimit >= aura_env.timer then
          aura_env.deaths, aura_env.deathtime = C_ChallengeMode.GetDeathCount()
      else
          aura_env.deaths = C_ChallengeMode.GetDeathCount()
      end
      
      aura_env.timer = (aura_env.start and aura_env.last-aura_env.start+aura_env.deathtime) or select(2, GetWorldElapsedTime(1)) or 0
      local timeremain = aura_env.timelimit-aura_env.timer
      
      aura_env.deaths = aura_env.deaths or 0
      aura_env.deathtime = aura_env.deathtime or 0
      aura_env.deathresult = formatDeaths(aura_env.deaths, aura_env.deathtime)
      
      local timermath = (aura_env.start and math.floor(aura_env.timer)) or aura_env.timer
      
      aura_env.threeD = (timermath <= aura_env.three and aura_env.formattime(aura_env.three-timermath)) or ""
      aura_env.twoD = (timermath <= aura_env.two and aura_env.formattime(aura_env.two-timermath))  or ""
      aura_env.maxD = (timermath <= aura_env.timelimit and aura_env.formattime(aura_env.timelimit-timermath)) 
      or (timermath > aura_env.timelimit and "|cFFFF0000+"..aura_env.formattime(timermath-aura_env.timelimit).."|r")
      or ""
      
      -- calculate bar percentage
      local percent = getBarPercent(aura_env.which_bar, timeremain, aura_env.timelimit)
      
      if not states[""] then
          states[""] = {
              show = true,
              progressType = "static",
              value = percent,
              total = 100,
              status = chest,
              changed = true,
          }
      else
          states[""].status = chest
          states[""].value = percent
          states[""].total = 100
          states[""].changed = true
      end
      return true
  end
end

-- Actions init
aura_env.decimals = aura_env.config["Decimals"]
aura_env.decimalsF = aura_env.config["DecimalsF"]
aura_env.deaths = aura_env.deaths or C_ChallengeMode.GetDeathCount() or 0
aura_env.timer = aura_env.timer or 0
aura_env.timelimit = aura_env.timelimit or 0
aura_env.two = aura_env.two or 0
aura_env.three = aura_env.three or 0
aura_env.twoD = aura_env.twoD or 0
aura_env.threeD = aura_env.threeD or 0
aura_env.maxD = aura_env.maxD or 0
aura_env.keyinfo  = aura_env.keyinfo or ""
aura_env.finish = (select(3, C_ChallengeMode.GetCompletionInfo()) == 0 and 0) or select(3, C_ChallengeMode.GetCompletionInfo()) or 0
aura_env.intime = aura_env.intime or false
aura_env.chest = aura_env.chest or 0
aura_env.deathresult = aura_env.deathresult  or  "\124TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12\124t"..0
aura_env.deathfake = "\124TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12\124t2(+10s)"
aura_env.showinfo = aura_env.config["KeyInfo"]
aura_env.showdeaths = aura_env.config["DeathInfo"]
aura_env.showchests = aura_env.config["ChestTimers"]

aura_env.which_bar = 1

local c = aura_env.config.color

local col = {}

for i=1, 4 do
    if i == 1 then 
        col[i] = string.format("%x", c[i] *255*255)
    else
        col[i] = string.format("%x", c[i] *255)
    end
    if col[i] == "0" then
        col[i] = "00"
    end
end

aura_env.color = "|c"..col[4]..col[1]..col[2]..col[3]

aura_env.keyfake = "+30 JY "
for i=1, 4 do
    aura_env.keyfake = aura_env.keyfake.."\124T"..select(i, strsplit(" ", "463829 132333 132090 442737"))..":13:13:"..1-i..":0:64:64:6:60:6:60\124t"
end

aura_env.formattime = function(time, MS, dec)
    if time then
        local timeMin = math.floor(time / 60)
        local timeSec = math.floor(time - (timeMin*60))
        if timeMin < 10 then
            timeMin = ("0%d"):format(timeMin)
        end
        if timeSec < 10 then
            timeSec = ("0%d"):format(timeSec)
        end
        if MS and aura_env.decimals > 0 then
            local timeMS  = select(2, strsplit(".", (time))) or select(2, strsplit(".", (GetTime()-time))) or 0
            local timeMS100 = math.floor(timeMS/100) or 0
            local timeMS10 = math.floor((timeMS-(timeMS100*100))/10) or 0
            local timeMS1 =timeMS-(timeMS100*100)-(timeMS10*10) or 0
            timeMS = string.sub((".%s%s%s"):format(timeMS100, timeMS10, timeMS1), 1, dec+1)
            return ("%s:%s%s|r"):format(timeMin, timeSec, timeMS)
        end
        
        return ("%s:%s"):format(timeMin, timeSec)
    end
end

aura_env.maptoname = {
    [244] = "AD",
    [245] = "FH",
    [246] = "TD",
    [247] = "ML",
    [248] = "WM",
    [249] = "KR",
    [250] = "ToS",
    [251] = "UR",
    [252] = "SotS",
    [353] = "SoB",
    [369] = "JY",
    [370] = "WS",
    
    [375] = "MoTS",
    [376] = "TNW",
    [377] = "DoS",
    [378] = "HoA",
    [379] = "PF",
    [380] = "SD",
    [381] = "SoA",
    [382] = "ToP",
}

-- Forces bar (check on CLEU:UNIT_DIED ENCOUNTER_END PLAYER_DEAD PLAYER_REGEN_ENABLED UNIT_THREAT_LIST_UPDATE SCENARIO_POI_UPDATE WORLD_STATE_TIMER_START CHALLENGE_MODE_START CHALLENGE_MODE_COMPLETED)
function(states, e, ...)
  local state = states[""]
  aura_env.update = false
  if e == "OPTIONS" then
      aura_env.finish = false
  elseif e == "CHALLENGE_MODE_START" and select(2, GetWorldElapsedTime(1)) < 2 then
      aura_env.finish = false
      aura_env.done = select(4, C_ChallengeMode.GetCompletionInfo())
      
      for _, k in pairs(states) do
          k.show = false
          k.changed = true
      end
      aura_env.obdef = 0
      aura_env.update = true
      
      
  elseif e == "SCENARIO_POI_UPDATE" or e == "WORLD_STATE_TIMER_START" or e == "CHALLENGE_MODE_COMPLETED" or e == "OPTIONS_CLOSED" then
      aura_env.update = true
      if e == "WORLD_STATE_TIMER_START" and select(2, GetWorldElapsedTime(1)) < 2 then
          aura_env.start = GetTime() or aura_env.start
          aura_env.done = false
      end
      
      local progress, mobCount, currentMC, totalMC = aura_env.GetProgress()
      totalMC = totalMC or 0
      aura_env.total = totalMC
      
      if e =="CHALLENGE_MODE_COMPLETED" and select(3, C_ChallengeMode.GetCompletionInfo()) ~= 0 then
          progress = 100
      end
      if progress then
          currentMC = currentMC or 0
          mobCount = mobCount or 0
          local total = 100
          
          aura_env.total = aura_env.total or 0
          
          if progress >= 100 and state and not aura_env.done then
              
              aura_env.done = true
              
              local cur = (aura_env.start and GetTime()-aura_env.start+(C_ChallengeMode.GetDeathCount()*5)) or select(2, GetWorldElapsedTime(1)) or 0
              aura_env.finish = aura_env.formattime(cur)
              
              if state then
                  state.value = progress
                  state.total = total
                  state.mobCount = mobCount
                  state.currentMC = state.totalMC
                  state.mcCompare = state.totalMC/100*total - state.currentMC
                  state.leftCompare = total - progress
                  state.current = string.format("%.2f%%", progress)
                  state.left = string.format("%.2f%%", total - progress)
                  state.additionalProgress = {
                      { 
                          direction = "forward",
                          width = 0,
                          offset = 0,
                      }
                  }
                  state.changed = true
              end
              
          elseif not state then
              local _, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
              aura_env.teeming = false
              aura_env.prideful = false
              for _, affixID in ipairs(affixes) do
                  if affixID == 5 then
                      aura_env.teeming = true
                  end
                  if affixID == 121 and aura_env.pride then
                      aura_env.prideful = true
                  end
              end
              states[""] = {
                  progressType = "static",
                  value = progress,
                  total = total,
                  currentMC = currentMC,
                  totalMC = totalMC,
                  mobCount = mobCount,
                  pull = {},
                  pullText = "",
                  mcpullText = "",
                  pullCompare = 1,
                  mcpullCompare = 1,
                  mcCompare = totalMC/100*total - currentMC,
                  leftCompare = total - progress,
                  current = string.format("%.2f%%", progress),
                  left = string.format("%.2f%%", total - progress),
                  show = true,
                  additionalProgress = {
                      { 
                          direction = "forward",
                          width = 0,
                          offset = 0,
                      }
                  },
                  changed = true,
              }
              aura_env.total = total
          elseif progress < 100 and state then
              state.value = progress
              state.total = total
              state.mobCount = mobCount
              state.currentMC = currentMC
              state.totalMC = totalMC
              state.mcCompare = totalMC/100*total - currentMC
              state.leftCompare = total - progress
              state.current = string.format("%.2f%%", progress)
              state.left = string.format("%.2f%%", total - progress)
              state.changed = true
              
              
              
              local rawValue, percentValue = 0, 0
              for _, value in pairs(state.pull) do 
                  if value ~= "DEAD" then
                      rawValue = rawValue + value[1]
                      percentValue = percentValue + value[2]
                  end
              end
              
              local rawtext, text = "", ""
              if percentValue > 0 or rawValue > 0 then
                  rawtext = rawValue
                  text = percentValue
              end
              
              state.mcpullCompare = state.mcCompare - rawValue
              state.mcpullText = rawtext
              
              state.pullCompare = state.leftCompare - percentValue
              state.pullText = text ~= "" and string.format("%.2f%%", text) or text
              
              state.additionalProgress = {
                  { 
                      direction = "forward",
                      width = (percentValue+state.value < 100 and percentValue) or 100,
                      offset = 0,
                  }
              }
          end
      end
      
  elseif e == "COMBAT_LOG_EVENT_UNFILTERED" then
      local _, se, _, _, _, _, _, destGUID = ...
      if se == "UNIT_DIED" then
          if state then
              if aura_env.MDT and destGUID and state.pull[destGUID]then
                  state.pull[destGUID] = "DEAD"
              end
          end
      end
  end
  if aura_env.pullcount and aura_env.MDT and state then
      if e == "UNIT_THREAT_LIST_UPDATE" and InCombatLockdown() then
          local unit = ...
          if unit and UnitExists(unit) then
              local guid = UnitGUID(unit)
              if guid and not state.pull[guid] then
                  local npc_id = select(6, strsplit("-", guid))
                  if npc_id then
                      local value
                      if aura_env.teeming then
                          value = select(4, aura_env.MDT:GetEnemyForces(tonumber(npc_id)))
                      else
                          value = aura_env.MDT:GetEnemyForces(tonumber(npc_id))
                      end
                      if value and value ~= 0 then
                          state.pull[guid] = {value, (value / (aura_env.total)) * 100}
                          aura_env.update = true
                      end
                  end
              end            
          end
          
      elseif e == "ENCOUNTER_END" or e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_DEAD" then
          for k, _ in pairs(state.pull) do
              state.pull[k] = nil
          end
          aura_env.update = true
      end
      
      if aura_env.update then
          local rawValue, percentValue = 0, 0
          for _, value in pairs(state.pull) do 
              if value ~= "DEAD" then
                  rawValue = rawValue + value[1]
                  percentValue = percentValue + value[2]
              end
          end
          
          local rawtext, text = "", ""
          if percentValue > 0 or rawValue > 0 then
              rawtext = rawValue
              text = percentValue
          end
          
          
          if aura_env.countD == 2 then
              rawtext = (state.currentMC and rawtext ~= "" and tonumber(rawtext)+state.currentMC) or ""
              text = rawtext ~= "" and (rawtext/aura_env.total)*100 or ""
          end
          
          state.mcpullCompare = state.mcCompare - rawValue
          state.mcpullText = rawtext
          
          
          state.pullCompare = state.leftCompare - percentValue
          state.pullText = text ~= "" and string.format("%.2f%%", text) or text
          state.additionalProgress = {
              { 
                  direction = "forward",
                  width = (percentValue+state.value < 100 and percentValue) or 100,
                  offset = 0,
              }
          }
      end
  end
  return aura_env.update
end

-- Forces condition:
function(state)
  if aura_env.prideful and state[1] and state[1].currentMC and state[1].mcpullCompare and state[1].mcCompare and state[1].mcpullCompare ~= state[1].mcCompare and state[1].totalMC then
      local cur = math.floor((state[1].currentMC/state[1].totalMC)*5)
      local afterpull = math.floor(((state[1].currentMC+(state[1].mcCompare-state[1].mcpullCompare))/state[1].totalMC)*5)
      if afterpull > cur then
          return true
      end
  end
end

--Bosses (check on WA_DELAYED_PLAYER_ENTERING_WORLD CHAT_MSG_ADDON ENCOUNTER_START ENCOUNTER_END CLEU:UNIT_DIED CHALLENGE_MODE_START SCENARIO_CRITERIA_UPDATE WORLD_STATE_TIMER_START)
function(states, e, ...)
  if e == "OPTIONS" then
      local decimals = aura_env.config["Decimals"]
      local shortenCount = aura_env.config["shortenBossNames"]
      local time = (decimals == 0 and "[10:53]") or (decimals == 1 and "[10:53.2]") or (decimals == 2 and "[10:53.27]") or (decimals == 3 and "[10:53.271]")
      for i =11, 15 do
          local bossName = "Test Boss Name "..i-10
          if shortenCount > 0 then
              bossName = strsub(bossName, 1, shortenCount)
          end
          
          states[i] = {
              name = bossName,
              index = i, 
              time = time,
              show = true,
              done = true,
              changed = true
          }
      end
      states[14].done = false
      states[15].done = false
      return true
  elseif e == "CHAT_MSG_ADDON" then
      local prefix, msg, _, send = ...
      if prefix == "RELOE_M+_SYNCH" then
          local sender = send or UnitName("player")
          sender = gsub(sender, "%-[^|]+", "")
          if sender == UnitName("player") or not UnitExists(sender) or not UnitIsVisible(sender) then return end
          if strsplit(" ", msg) == "Obelisk" then
              local id = select(2, strsplit(" ", msg))
              if aura_env.obelisks[id] then 
                  aura_env.obelisks[id] = false
                  for k, _ in pairs(states) do
                      if states[k].name == "Obelisks" and states[k].defeated < 4 then
                          states[k].defeated = states[k].defeated+1
                          aura_env.obdef = states[k].defeated
                          states[k].changed = true
                          if states[k].defeated == 4 then
                              if not states[k].time then
                                  local cur = (aura_env.start and GetTime()-aura_env.start+(C_ChallengeMode.GetDeathCount()*5)) or select(2, GetWorldElapsedTime(1)) or 0  
                                  states[k].timer = cur
                                  states[k].time = aura_env.formattime(cur)
                                  states[k].MS = select(2, strsplit(".", (cur))) or select(2, strsplit(".", (GetTime()-cur)))
                                  states[k].done = true
                                  states[k].changed = true
                                  aura_env.bosstime[k] = cur
                              end
                          end
                          return true
                      end
                  end
              end
          elseif msg =="SYNCHPLS" then
              local text = ""
              local count = 0
              for k, _ in pairs(states) do
                  if states[k].time then
                      count = count+1
                      text = text.." "..k.." "..states[k].timer.." "..states[k].MS
                  end 
              end
              if count > 0 then
                  text = count..text
                  C_ChatInfo.SendAddonMessage("RELOE_M+_SYNCH", text, "PARTY")
              end
              for k, v in pairs(aura_env.obelisks) do
                  if not v then
                      C_ChatInfo.SendAddonMessage("RELOE_M+_SYNCH", "Obelisk "..k, "PARTY")
                  end
              end
          else
              local count = strsplit(" ", msg)
              count = tonumber(count)
              
              msg = string.sub(msg, 3, string.len(msg))
              local updatestate = false
              if count > 0 then
                  for i=1, count do
                      local index, newtime, MS = select(1+(3*i)-3, strsplit(" ", msg))
                      index = tonumber(index)
                      newtime = tonumber(newtime)
                      MS = tonumber(string.sub(MS, 1, aura_env.decimals))
                      if states[index] then
                          if (not states[index].timer) or newtime < states[index].timer then
                              local cur = (aura_env.start and GetTime()-aura_env.start+(C_ChallengeMode.GetDeathCount()*5)) or select(2, GetWorldElapsedTime(1)) or 0  
                              states[index].timer = newtime
                              states[index].time = aura_env.formattime(newtime, MS)
                              states[index].MS = MS
                              states[index].done = true
                              states[index].changed = true
                              aura_env.bosstime[index] = cur
                              updatestate = true
                              
                          end
                      end
                  end
                  return updatestate
              end
          end
          
      end
      
  elseif e == "SCENARIO_CRITERIA_UPDATE" or e == "WORLD_STATE_TIMER_START" or e == "CHALLENGE_MODE_START" or e =="WA_DELAYED_PLAYER_ENTERING_WORLD" or e == "OPTIONS_CLOSED" then
      aura_env.level = C_ChallengeMode.GetActiveKeystoneInfo()
      if e == "CHALLENGE_MODE_START" then 
          if e == "CHALLENGE_MODE_START" and select(2, GetWorldElapsedTime(1)) < 2 then
              for _, k in pairs(states) do
                  k.show = false
                  k.changed = true
              end
              aura_env.obelisks = {
                  ["161241"] = true,
                  ["161243"] = true,
                  ["161244"] = true,
                  ["161124"] = true,
              }
              aura_env.bossname = {}
              aura_env.bosstime = {}
              aura_env.obdef = 0
          end
          if aura_env.bossname ~= {} then
              WeakAuras.ScanEvents("RELOE_SETBGHEIGHT", #states)
          else
              WeakAuras.ScanEvents("RELOE_SETBGHEIGHT", 0)
          end
          return true
      end
      if e == "WORLD_STATE_TIMER_START" then
          if #aura_env.bossname < 2 then
              aura_env.setbossnames()
          end
          aura_env.start = (select(2, GetWorldElapsedTime(1)) < 2 and GetTime()) or aura_env.start
      end
      if e == "WA_DELAYED_PLAYER_ENTERING_WORLD" then
          C_ChatInfo.SendAddonMessage("RELOE_M+_SYNCH", "SYNCHPLS", "PARTY")
      end
      local max = select(3, C_Scenario.GetStepInfo())
      if #aura_env.bossname < max-1 then
          aura_env.setbossnames()
      end
      for i=1, max do
          if select(7, C_Scenario.GetCriteriaInfo(i)) ~= 0 then
              local num = i
              if C_ChallengeMode.GetActiveChallengeMapID() == 370 then 
                  num = i+4
              end
              aura_env.name = aura_env.bossname[num]
              if aura_env.name and string.len(aura_env.name) > 25 then aura_env.name = string.sub(aura_env.name, 1, 25) end
              
              if aura_env.name and not states[i] then
                  states[i] = {
                      name = aura_env.name,
                      index = i,
                      show = true,
                      done = false,
                      changed = true,
                      
                  }
                  if aura_env.bosstime[i] then
                      local cur = aura_env.bosstime[i]
                      states[i].timer = cur
                      states[i].MS = select(2, strsplit(".", (cur))) or select(2, strsplit(".", (GetTime()-cur)))
                      states[i].time = aura_env.formattime(cur)
                      states[i].done = true
                      states[i].changed = true
                  end
              end
              
              if select(3, C_Scenario.GetCriteriaInfo(i)) then
                  if states[i] and not states[i].time then
                      local cur = (aura_env.start and GetTime()-aura_env.start+(C_ChallengeMode.GetDeathCount()*5)) or select(2, GetWorldElapsedTime(1)) or 0
                      states[i].timer = cur
                      states[i].MS = select(2, strsplit(".", (cur))) or select(2, strsplit(".", (GetTime()-cur)))
                      states[i].time = aura_env.formattime(cur)
                      states[i].done = true
                      states[i].changed = true
                      aura_env.bosstime[i] = cur
                  end
              end
              
              if i == max and aura_env.obeliskE and aura_env.level > 9 and aura_env.plevel ~= 60 then
                  if not states[i+1] then
                      states[i+1] = {
                          name = "Obelisks",
                          defeated = aura_env.obdef or 0,
                          formating = " - ",
                          formating2 = "/",
                          max = 4,
                          done = false,
                          index = i, 
                          show = true,
                          changed = true
                      }
                      if aura_env.bosstime[i+1] then
                          local cur = aura_env.bosstime[i+1]
                          states[i+1].timer = cur
                          states[i+1].MS = select(2, strsplit(".", (cur))) or select(2, strsplit(".", (GetTime()-cur)))
                          states[i+1].time = aura_env.formattime(cur)
                          states[i+1].done = true
                          states[i+1].changed = true
                      end
                  end
              end
          elseif i == max and aura_env.obeliskE and aura_env.level > 9 and aura_env.plevel ~= 60 then
              if not states[i] then
                  states[i] = {
                      name = "Obelisks",
                      defeated = aura_env.obdef or 0,
                      formating = " - ",
                      formating2 = "/",
                      max = 4,
                      done = false,
                      index = i,
                      show = true,
                      changed = true
                  }
                  if aura_env.bosstime[i] then
                      local cur = aura_env.bosstime[i]
                      states[i].timer = cur
                      states[i].MS = select(2, strsplit(".", (cur))) or select(2, strsplit(".", (GetTime()-cur)))
                      states[i].time = aura_env.formattime(cur)
                      states[i].done = true
                      states[i].changed = true
                  end
              end
          end
      end
      if e == "WORLD_STATE_TIMER_START" then
          if aura_env.bossname ~= {} then
              WeakAuras.ScanEvents("RELOE_SETBGHEIGHT", #states)
          else
              WeakAuras.ScanEvents("RELOE_SETBGHEIGHT", 0)
          end
      end
      return true
  elseif e == "ENCOUNTER_START" and aura_env.obeliskE then
      for k, _ in pairs(states) do
          if states[k].name == "Obelisks" then 
              aura_env.obeliskstore = states[k].defeated 
              break
          end
      end
  elseif e == "ENCOUNTER_END" and select(5, ...) == 0 and aura_env.obeliskE then 
      for k, _ in pairs(states) do
          if states[k].name == "Obelisks" then
              states[k].defeated  = aura_env.obeliskstore
              aura_env.obdef = states[k].defeated
              if aura_env.obdef < 4 then 
                  states[k].time = nil
                  states[k].timer = nil
                  states[k].MS = nil
                  states[k].done = false
                  states[k].changed = true
                  for l, _ in pairs(aura_env.obelisks) do
                      aura_env.obelisks[l] = true
                  end
              end
              return true
          end
      end
  elseif aura_env.obeliskE then
      local destGUID = select(8, ...)
      local unitID = destGUID and select(6, strsplit("-", destGUID))
      if aura_env.obelisks[unitID] then
          aura_env.obelisks[unitID] = false
          C_ChatInfo.SendAddonMessage("RELOE_M+_SYNCH", "Obelisk "..unitID, "PARTY")
          for k, _ in pairs(states) do
              if states[k].name == "Obelisks" and states[k].defeated < 4 then
                  states[k].defeated = states[k].defeated+1
                  aura_env.obdef = states[k].defeated
                  states[k].changed = true
                  if states[k].defeated == 4 then
                      if not states[k].time then
                          local cur = (aura_env.start and GetTime()-aura_env.start+(C_ChallengeMode.GetDeathCount()*5)) or select(2, GetWorldElapsedTime(1)) or 0  
                          states[k].timer = cur
                          states[k].time = aura_env.formattime(cur)
                          states[k].MS = select(2, strsplit(".", (cur))) or select(2, strsplit(".", (GetTime()-cur)))
                          states[k].done = true
                          states[k].changed = true
                          aura_env.bosstime[k] = cur
                      end
                  end
                  return true
              end
          end
      end
  end
end

--forces action init
aura_env.decimals = aura_env.config["Decimals"]
aura_env.obeliskE = aura_env.config["ObeliskE"]
aura_env.level = 0
aura_env.obelisks = {
    ["161241"] = true,
    ["161243"] = true,
    ["161244"] = true,
    ["161124"] = true,
}
aura_env.plevel = UnitLevel("player")
aura_env.obeliskstore = aura_env.obeliskstore or 0
aura_env.bossname = {}

aura_env.formattime = function(time, msg)
    local timeMin = math.floor(time / 60)
    local timeSec = math.floor(time - (timeMin*60))
    if timeMin < 10 then
        timeMin = ("0%d"):format(timeMin)
    end
    if timeSec < 10 then
        timeSec = ("0%d"):format(timeSec)
    end
    
    local timeMS  = msg or select(2, strsplit(".", (time))) or select(2, strsplit(".", (GetTime()-time)))
    local timeMS100 = math.floor(timeMS/100)
    local timeMS10 = math.floor((timeMS-(timeMS100*100))/10)
    local timeMS1 =timeMS-(timeMS100*100)-(timeMS10*10)
    
    
    timeMS = (".%s%s%s"):format(timeMS100, timeMS10, timeMS1)
    timeMS = (aura_env.decimals == 0 and "") or (timeMS and string.sub(timeMS, 1, aura_env.decimals+1))
    return ("[%s:%s%s|r]"):format(timeMin, timeSec, timeMS)
end

aura_env.obdef = aura_env.obdef or 0


C_ChatInfo.RegisterAddonMessagePrefix("RELOE_M+_SYNCH")
aura_env.bosstime = aura_env.bosstime or {}



LoadAddOn("Blizzard_EncounterJournal")



aura_env.maptoinst = {
    [1677] = 1188, -- De Other Side
    [1678] = 1188, -- De Other Side
    [1679] = 1188, -- De Other Side
    [1680] = 1188, -- De Other Side
    [1669] = 1184, -- Mists of Tirna Scithe
    [1697] = 1183, -- Plaguefall
    [1675] = 1189, -- Sanguine Depths
    [1676] = 1189, -- Sanguine Depths
    [1692] = 1186, -- Spires of Ascension
    [1693] = 1186, -- Spires of Ascension
    [1694] = 1186, -- Spires of Ascension
    [1695] = 1186, -- Spires of Ascension
    [1666] = 1182, -- The Necrotic Wake
    [1667] = 1182, -- The Necrotic Wake
    [1668] = 1182, -- The Necrotic Wake
    [1683] = 1187, -- Theater of Pain
    [1684] = 1187, -- Theater of Pain
    [1685] = 1187, -- Theater of Pain
    [1686] = 1187, -- Theater of Pain
    [1687] = 1187, -- Theater of Pain
    [1663] = 1185, -- Halls of Atonement
    [1664] = 1185, -- Halls of Atonement
    [1665] = 1185, -- Halls of Atonement
}

aura_env.setbossnames = function()
    EncounterJournal_OpenJournal()
    if EncounterJournalBossButton1 then
        EncounterJournalBossButton1:Click()
        EncounterJournalNavBarHomeButton:Click()
    end
    if aura_env.plevel == 120 or aura_env.plevel == 50 then
        EJ_SelectTier(8)
    elseif aura_env.plevel == 60 then
        EJ_SelectTier(9)
    end
    EncounterJournalInstanceSelectDungeonTab:Click()
    local mapID = C_Map.GetBestMapForUnit("player")
    local instanceID = EJ_GetInstanceForMap(mapID)
    if instanceID == 0 then 
        instanceID = aura_env.maptoinst[mapID]
    end
    if instanceID and instanceID ~= 0 then
        EJ_SelectInstance(instanceID)
        local shortenCount = aura_env.config["shortenBossNames"]
        for i=1, 10 do
            local name = EJ_GetEncounterInfoByIndex(i, instanceID)
            if name then
                if shortenCount > 0 then
                    aura_env.bossname[i] = strsub(name, 1, shortenCount)
                else
                    aura_env.bossname[i] = name
                end
            end
        end
        if EncounterJournalBossButton2 then
            EncounterJournalBossButton2:Click()
            EncounterJournalNavBarHomeButton:Click()
        end
        EncounterJournalInstanceSelectDungeonTab:Click()
        EncounterJournal.CloseButton:Click()
    else
        EncounterJournal.CloseButton:Click()
        print("bad instanceID for mapID: "..mapID)
    end
end

-- util (check on GOSSIP_SHOW CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN)
function(e, ...)
  if e == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" and aura_env.keyslot then
      local index = select(3, GetInstanceInfo())
      if index == 8 or index == 23 then
          for bagID = 0, NUM_BAG_SLOTS do
              for invID = 1, GetContainerNumSlots(bagID) do
                  local itemID = GetContainerItemID(bagID, invID)
                  if itemID and (itemID == 180653) then
                      PickupContainerItem(bagID, invID)
                      C_Timer.After(0.1, function()
                              if CursorHasItem() then
                                  C_ChallengeMode.SlotKeystone()
                              end
                      end)
                  end
              end
          end
      end
  elseif e == "GOSSIP_SHOW" and aura_env.gossipS and UnitExists("target") and UnitExists("npc") and UnitName("target") == UnitName("npc") and not IsControlKeyDown() then
      local GUID = UnitGUID("npc")
      local id = select(6, strsplit("-", GUID))
      id = tonumber(id)
      if not aura_env.blacklist[id] then
          local title = {C_GossipInfo.GetOptions()}
          
          for i = 1, C_GossipInfo.GetNumOptions() do
              if title[i][1]["type"] == "gossip" then
                  local popupWasShown = aura_env.popup()
                  C_GossipInfo.SelectOption(i)
                  local popupIsShown = aura_env.popup()
                  if popupIsShown then
                      if not popupWasShown then
                          StaticPopup1Button1:Click()
                          C_GossipInfo.CloseGossip()
                      end
                  else
                      C_GossipInfo.CloseGossip()
                  end
                  break
              end
          end
      end
  end
end

-- action init
aura_env.keyslot = aura_env.config["KeySlot"]
aura_env.gossipS = aura_env.config["GossipS"]
aura_env.blacklist = {
    -- [123] = true
}


aura_env.popup = function()
    for index = 1, STATICPOPUP_NUMDIALOGS do
        local frame = _G["StaticPopup"..index]
        if frame and frame:IsShown() then
            return true
        end
    end
    return false
end


local function decRound(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end



local _, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
local teeming = false
for _, affixID in ipairs(affixes) do
    if affixID == 5 then
        teeming = true
    end
end

local tooltip = aura_env.config["Tooltip"]
local function addtotooltip(self, unit)
    local GUID = UnitGUID("mouseover")
    if GUID and MDT then
        local npcID = select(6, strsplit("-", GUID))
        local count
        local max
        if teeming then
            max, count = select(3, MDT:GetEnemyForces(tonumber(npcID)))
        else
            count, max = MDT:GetEnemyForces(tonumber(npcID))
        end
        if count and max and count ~= 0 and max ~= 0 then
            local percent = decRound((count/max)*100, 2).."%"
            
            local string = (tooltip == 4 and count.." ("..percent..")") or (tooltip  == 3 and percent) or (tooltip  == 2 and count)
            if string then
                GameTooltip:AppendText(" - "..string)
            end
        end
    end
end



if tooltip ~= 1 and not aura_env.region.addtotooltip then
    aura_env.region.addtotooltip = true
    GameTooltip:HookScript("OnTooltipSetUnit", addtotooltip)
    --  hooksecurefunc(GameTooltip, "OnTooltipSetUnit", addtotooltip)
end