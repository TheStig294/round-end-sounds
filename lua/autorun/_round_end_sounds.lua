local soundNameMessageCvar = CreateConVar("ttt_roundendsounds_sound_name_message", 0, FCVAR_REPLICATED, "Whether a message in chat displays the name of the sound playing", 0, 1)

if engine.ActiveGamemode() == "terrortown" and SERVER then
    CreateConVar("ttt_roundendsounds", "1", nil, "Turns on/off round end sounds playing at all. 1 = on, 0 = off", 0, 1)
    local teamWinSoundCvar = CreateConVar("ttt_roundendsounds_team_win_sound", 0, nil, "Whether an innocent/traitor team win sound should play instead of a win sound for the winners and a lose sound for the losers", 0, 1)
    util.AddNetworkString("RoundEndSoundsWin")
    util.AddNetworkString("RoundEndSoundsPlay")
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

            -- Adding a console command to play the sound
            concommand.Add("ttt_roundendsounds_" .. dir .. "_" .. fileName .. "_playsound", function(plyexe, cc, arg)
                net.Start("RoundEndSoundsPlay")
                net.WriteString("ttt_round_end_sounds/" .. dir .. "/" .. fileName)
                net.Send(plyexe)
            end)

            -- Removing any round end sounds that have been turned off
            if not convar:GetBool() then
                table.insert(disabledSounds, fileName)
            end
        end

        for k, fileName in ipairs(disabledSounds) do
            table.RemoveByValue(sounds[dir], fileName)
        end
    end

    hook.Add("TTTEndRound", "TTTRoundEndSounds", function(result)
        -- Hard-coded list of win condition names and their enumerators cause idk how to dynamically get them
        local wins = {}
        wins["time"] = WIN_TIMELIMIT
        wins["innocent"] = WIN_INNOCENT
        wins["traitor"] = WIN_TRAITOR
        wins["jester"] = WIN_JESTER
        wins["killer"] = WIN_KILLER
        wins["zombie"] = WIN_ZOMBIE
        wins["clown"] = WIN_CLOWN
        wins["monster"] = WIN_MONSTER
        wins["vampire"] = WIN_VAMPIRE
        wins["bees"] = WIN_BEES
        wins["bee"] = WIN_BEE
        wins["boxer"] = WIN_BOXER
        wins["communist"] = WIN_COMMUNIST
        wins["frenchman"] = WIN_FRENCHMAN
        wins["cupid"] = WIN_CUPID
        wins["sponge"] = WIN_SPONGE
        wins["arsonist"] = WIN_ARSONIST
        wins["hivemind"] = WIN_HIVEMIND
        wins["vindicator"] = WIN_VINDICATOR
        wins["detectoclown"] = WIN_DETECTOCLOWN
        wins["krampus"] = WIN_KRAMPUS
        wins["thething"] = WIN_THETHING
        -- Sound played depends on who wins
        local winningTeam = "noteam"
        local chosenSound = "nosound"
        local winSound = "nosound"
        local lossSound = "nosound"
        local oldmanWinSound = "nosound"
        local oldmanLossSound = "nosound"
        local oldman = false

        -- Getting the name of the team that won
        for i, winNumber in pairs(wins) do
            if result == winNumber then
                winningTeam = table.KeyFromValue(wins, winNumber)
            end
        end

        -- Handling an old man win/loss, which can have its own set of win/loss sounds
        for i, ply in ipairs(player.GetAll()) do
            if ply:GetRole() == ROLE_OLDMAN and ply:Alive() and not ply:IsSpec() then
                ply:SetNWBool("OldManWinSound", true)
                oldman = true
            elseif ply:GetRole() == ROLE_OLDMAN and ply:IsSpec() and not ply:Alive() then
                ply:SetNWBool("OldManLossSound", true)
                oldman = true
            end
        end

        if sounds["oldmanwin"][1] ~= nil and oldman then
            oldmanWinSound = "ttt_round_end_sounds/oldmanwin/" .. sounds["oldmanwin"][math.random(#sounds["oldmanwin"])]
        elseif sounds["oldmanloss"][1] ~= nil and oldman then
            oldmanLossSound = "ttt_round_end_sounds/oldmanloss/" .. sounds["oldmanloss"][math.random(#sounds["oldmanloss"])]
        end

        -- Checking if there's enabled sounds in innocent/traitor sound folders, which override the win/loss sound logic and have a innocent/traitor win sound play for everyone instead
        local innocentSound = false
        local traitorSound = false

        if istable(sounds["innocent"]) and not table.IsEmpty(sounds["innocent"]) then
            innocentSound = true
        end

        if istable(sounds["traitor"]) and not table.IsEmpty(sounds["traitor"]) then
            traitorSound = true
        end

        if (winningTeam == "innocent" and not innocentSound) or (winningTeam == "traitor" and not traitorSound) or (winningTeam == "time" and not innocentSound) then
            -- Play an innocent/traitor team win sound instead if the convar is enabled
            -- (Sounds need to be added to an innocent_team or traitor_team sound folder to work)
            if teamWinSoundCvar:GetBool() then
                if winningTeam == "innocent" then
                    chosenSound = "ttt_round_end_sounds/innocent_team/" .. sounds["innocent_team"][math.random(#sounds["innocent_team"])]
                elseif winningTeam == "traitor" then
                    chosenSound = "ttt_round_end_sounds/traitor_team/" .. sounds["traitor_team"][math.random(#sounds["traitor_team"])]
                end
            else
                -- Choose a win/lose sound if the innocents or traitors win, or the time runs out (because it is its own win condition, but displays as an innocent win)
                winSound = "ttt_round_end_sounds/win/" .. sounds["win"][math.random(#sounds["win"])]
                lossSound = "ttt_round_end_sounds/loss/" .. sounds["loss"][math.random(#sounds["loss"])]
            end
        elseif winningTeam ~= "noteam" and sounds[winningTeam] ~= nil then
            -- Choose a random sound from the winning team's pool of sounds
            chosenSound = "ttt_round_end_sounds/" .. winningTeam .. "/" .. sounds[winningTeam][math.random(#sounds[winningTeam])]
        elseif winningTeam == "monster" then
            -- If the monster team wins, and there are no monster team sounds, choose a random zombies sound
            chosenSound = "ttt_round_end_sounds/zombie/" .. sounds["zombie"][math.random(#sounds["zombie"])]
        elseif winningTeam == "bee" then
            -- If it's a bee win, and there are no bee win sounds, choose a random bees win sound
            chosenSound = "ttt_round_end_sounds/bees/" .. sounds["bees"][math.random(#sounds["bees"])]
        elseif winningTeam == "sponge" then
            -- If it's a sponge win, and there are no sponge win sounds, choose a random jester win sound
            chosenSound = "ttt_round_end_sounds/jester/" .. sounds["jester"][math.random(#sounds["jester"])]
        elseif winningTeam == "detectoclown" then
            -- If it's a detectoclown win, and there are no detectoclown win sounds, choose a random clown win sound
            chosenSound = "ttt_round_end_sounds/clown/" .. sounds["clown"][math.random(#sounds["clown"])]
        elseif sounds["loss"][1] ~= nil and result ~= WIN_NONE then
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
                net.WriteString(oldmanWinSound)
                net.WriteString(oldmanLossSound)
                net.WriteInt(result, 8)
                net.Broadcast()
            end)

            -- Reset the old man win/loss sound
            timer.Simple(5, function()
                for i, ply in ipairs(player.GetAll()) do
                    ply:SetNWBool("OldManWinSound", false)
                    ply:SetNWBool("OldManLossSound", false)
                end
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

    net.Receive("RoundEndSoundsPlay", function()
        local snd = net.ReadString()
        PlayRoundEndSound(snd)
    end)

    -- Play the win sound, if any, on the client so only that player hears it
    net.Receive("RoundEndSoundsWin", function()
        local winningTeam = net.ReadString()
        local winSound = net.ReadString()
        local lossSound = net.ReadString()
        local chosenSound = net.ReadString()
        local oldmanWinSound = net.ReadString()
        local oldmanLossSound = net.ReadString()
        local result = net.ReadInt(8)
        local ply = LocalPlayer()
        -- Hook to let user-made roles define their own win/loss sounds, or other manipulations
        local hookChosenSound = hook.Call("TTTChooseRoundEndSound", nil, ply, result)

        if hookChosenSound then
            chosenSound = hookChosenSound
        end

        -- If a special role won, play one of that role's special win sounds
        if chosenSound ~= "nosound" then
            PlayRoundEndSound(chosenSound)
            -- Old man win/loss
        elseif ply:GetNWBool("OldManWinSound", false) and oldmanWinSound ~= "nosound" then
            PlayRoundEndSound(oldmanWinSound)
        elseif ply:GetNWBool("OldManLossSound", false) and oldmanLossSound ~= "nosound" then
            PlayRoundEndSound(oldmanLossSound)
        elseif winSound ~= "nosound" and lossSound ~= "nosound" and CR_VERSION then
            -- When Custom roles is installed
            if (winningTeam == "innocent" or winningTeam == "time") and ply.IsInnocentTeam and ply:IsInnocentTeam() then
                PlayRoundEndSound(winSound)
            elseif winningTeam == "traitor" and ply.IsTraitorTeam and ply:IsTraitorTeam() then
                PlayRoundEndSound(winSound)
            elseif ply:GetNWBool("OldManWinSound", false) then
                -- If there's no oldmanwin sounds, play an ordinary win sound
                PlayRoundEndSound(winSound)
            else
                PlayRoundEndSound(lossSound)
            end
        elseif winSound ~= "nosound" and lossSound ~= "nosound" then
            -- When Custom roles isn't installed
            if (winningTeam == "innocent" or winningTeam == "time") and (ply:GetRole() == ROLE_INNOCENT or ply:GetRole() == ROLE_DETECTIVE) then
                PlayRoundEndSound(winSound)
            elseif winningTeam == "traitor" and ply:GetRole() == ROLE_TRAITOR then
                PlayRoundEndSound(winSound)
            else
                PlayRoundEndSound(lossSound)
            end
        end
    end)
    -- If WIN_NONE was the win result, chosenSound, winSound and lossSound are all "nosound", so nothing is played
end