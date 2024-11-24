local soundNameMessageCvar = CreateConVar("ttt_roundendsounds_sound_name_message", 0, FCVAR_REPLICATED, "Whether a message in chat displays the name of the sound playing", 0, 1)

if engine.ActiveGamemode() == "terrortown" and SERVER then
    CreateConVar("ttt_roundendsounds", "1", nil, "Turns on/off round end sounds playing at all. 1 = on, 0 = off", 0, 1)
    local teamWinSoundCvar = CreateConVar("ttt_roundendsounds_team_win_sound", 0, nil, "Whether an innocent/traitor team win sound should play instead of a win sound for the winners and a lose sound for the losers", 0, 1)
    util.AddNetworkString("RoundEndSoundsWin")
    local sounds = {}
    local _, foundDirectories = file.Find("sound/ttt_round_end_sounds/*", "GAME")

    -- Initialising all sound files located in the "sound/ttt_round_end_sounds" folder, including custom added sounds
    for i, dir in ipairs(foundDirectories) do
        local disabledSounds = {}
        sounds[dir] = file.Find("sound/ttt_round_end_sounds/" .. dir .. "/*", "GAME")

        -- Pre-caching all sounds as they are found, and forcing connecting clients to download them
        for j, fileName in ipairs(sounds[dir]) do
            Sound("sound/ttt_round_end_sounds/" .. dir .. "/" .. fileName)
            resource.AddSingleFile("sound/ttt_round_end_sounds/" .. dir .. "/" .. fileName)

            -- Creating a convar for each sound to turn it off
            local convar = CreateConVar("ttt_roundendsounds_" .. dir .. "_" .. fileName, "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Set this to 0 to turn off this round end sound", 0, 1)

            -- Removing any round end sounds that have been turned off
            if not convar:GetBool() then
                table.insert(disabledSounds, fileName)
            end
        end

        for k, fileName in ipairs(disabledSounds) do
            table.RemoveByValue(sounds[dir], fileName)
        end
    end

    hook.Add("TTTEndRound", "TTTRoundEndSounds", function(winEnum)
        local winEnumToTeamName = {}

        -- List of win condition names and their enumerators
        -- Have to do this at the end of each round because mods could add a new win condition mid-round, e.g. Mal's bees win randomat
        for key, value in pairs(_G) do
            if isnumber(value) and key:StartsWith("WIN_") then
                key = key:sub(5):lower()
                winEnumToTeamName[value] = key
            end
        end

        -- Other appropriate win sound folders to pick a sound from if the team's win sound folder is empty
        local backupTeamWinSound = {
            innocent = "innocent_team",
            timelimit = "innocent_team",
            traitor = "traitor_team",
            monster = "zombie",
            bee = "bees",
            sponge = "jester",
            detectoclown = "clown"
        }

        -- Sound played depends on who wins
        local winningTeam = winEnumToTeamName[winEnum] or "noteam"
        local backupTeam = backupTeamWinSound[winningTeam]
        local chosenSound = "nosound"
        local winSound = "nosound"
        local lossSound = "nosound"

        if (winningTeam == "innocent" or winningTeam == "timelimit" or winningTeam == "traitor") and not teamWinSoundCvar:GetBool() then
            -- Choose a win/lose sound if the innocents or traitors win, or the time runs out (Time running out is also an innocent win, but its own winEnum)
            winSound = "ttt_round_end_sounds/win/" .. sounds["win"][math.random(#sounds["win"])]
            lossSound = "ttt_round_end_sounds/loss/" .. sounds["loss"][math.random(#sounds["loss"])]
        elseif winningTeam ~= "noteam" and sounds[winningTeam] ~= nil then
            -- Choose a random sound from the winning team's pool of sounds
            chosenSound = "ttt_round_end_sounds/" .. winningTeam .. "/" .. sounds[winningTeam][math.random(#sounds[winningTeam])]
        elseif backupTeam and sounds[backupTeam] ~= nil then
            -- If there's an alternative folder to get this winEnum's win sound from, and it has sounds, then choose a sound from there
            -- Play an innocent/traitor team win sound if the convar is enabled
            chosenSound = "ttt_round_end_sounds/" .. backupTeam .. "/" .. sounds[backupTeam][math.random(#sounds[backupTeam])]
        elseif sounds["loss"][1] ~= nil and winEnum ~= WIN_NONE then
            -- If a win condition happens that's not in the "wins" table, (E.g. a new role's win), choose a random 'loss' sound to play for everyone
            chosenSound = "ttt_round_end_sounds/loss/" .. sounds["loss"][math.random(#sounds["loss"])]
        end

        -- Play the sound for everyone, if enabled
        if GetConVar("ttt_roundendsounds"):GetBool() then
            timer.Simple(0.1, function()
                net.Start("RoundEndSoundsWin")
                net.WriteString(winningTeam)
                net.WriteString(winSound)
                net.WriteString(lossSound)
                net.WriteString(chosenSound)
                net.WriteInt(winEnum, 8)
                net.Broadcast()
            end)
        end
    end)
end

if engine.ActiveGamemode() == "terrortown" and CLIENT then
    local function PlayRoundEndSound(snd)
        surface.PlaySound(snd)

        if soundNameMessageCvar:GetBool() then
            snd = string.sub(snd, 22)
            chat.AddText("Playing sound:\n" .. snd)
        end
    end

    -- Play the win sound, if any, on the client so only that player hears it
    net.Receive("RoundEndSoundsWin", function()
        local winningTeam = net.ReadString()
        local winSound = net.ReadString()
        local lossSound = net.ReadString()
        local chosenSound = net.ReadString()
        local winEnum = net.ReadInt(8)
        local ply = LocalPlayer()
        -- Hook to let user-made roles define their own win/loss sounds, or other manipulations
        local hookChosenSound = hook.Call("TTTChooseRoundEndSound", nil, ply, winEnum)

        if hookChosenSound then
            chosenSound = hookChosenSound
        end

        -- If a special role won, play one of that role's special win sounds
        if chosenSound ~= "nosound" then
            PlayRoundEndSound(chosenSound)
        elseif winSound ~= "nosound" and lossSound ~= "nosound" and CR_VERSION then
            -- When Custom roles is installed
            if (winningTeam == "innocent" or winningTeam == "timelimit") and ply.IsInnocentTeam and ply:IsInnocentTeam() then
                PlayRoundEndSound(winSound)
            elseif winningTeam == "traitor" and ply.IsTraitorTeam and ply:IsTraitorTeam() then
                PlayRoundEndSound(winSound)
            else
                PlayRoundEndSound(lossSound)
            end
        elseif winSound ~= "nosound" and lossSound ~= "nosound" then
            -- When Custom roles isn't installed
            if (winningTeam == "innocent" or winningTeam == "timelimit") and (ply:GetRole() == ROLE_INNOCENT or ply:GetRole() == ROLE_DETECTIVE) then
                PlayRoundEndSound(winSound)
            elseif winningTeam == "traitor" and ply:GetRole() == ROLE_TRAITOR then
                PlayRoundEndSound(winSound)
            else
                PlayRoundEndSound(lossSound)
            end
        end
    end)
    -- If WIN_NONE was the winEnum, chosenSound, winSound and lossSound are all "nosound", so nothing is played
end