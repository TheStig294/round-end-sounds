if engine.ActiveGamemode() == "terrortown" and SERVER then
    util.AddNetworkString("RoundEndSoundsWin")
    util.AddNetworkString("RoundEndSoundsPlay")
    local sounds = {}
    local _, foundDirectories = file.Find("sound/ttt_round_end_sounds/*", "THIRDPARTY")

    -- Initialising all sound files located in the "sound/ttt_round_end_sounds" folder
    for i, dir in ipairs(foundDirectories) do
        local disabledSounds = {}
        sounds[dir] = file.Find("sound/ttt_round_end_sounds/" .. dir .. "/*", "THIRDPARTY")

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

    local _, foundDirectoriesCustom = file.Find("ttt_round_end_sounds/*", "DATA")

    -- Initialising all sound files located in the "data/ttt_round_end_sounds" folder, to add support for custom sounds
    for i, dir in ipairs(foundDirectoriesCustom) do
        local disabledSounds = {}
        table.Add(sounds[dir], file.Find("ttt_round_end_sounds/" .. dir .. "/*", "DATA"))

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
        wins["lover"] = WIN_LOVER
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
            oldmanWinSound = "ttt_round_end_sounds/oldmanwin/" .. sounds["oldmanwin"][math.random(1, #sounds["oldmanwin"])]
        elseif sounds["oldmanloss"][1] ~= nil and oldman then
            oldmanLossSound = "ttt_round_end_sounds/oldmanloss/" .. sounds["oldmanloss"][math.random(1, #sounds["oldmanloss"])]
        end

        if winningTeam == "innocent" or winningTeam == "traitor" or winningTeam == "time" then
            -- Choose a win/lose sound if the innocents or traitors win, or the time runs out (because it is its own win condition, but displays as an innocent win)
            winSound = "ttt_round_end_sounds/win/" .. sounds["win"][math.random(1, #sounds["win"])]
            lossSound = "ttt_round_end_sounds/loss/" .. sounds["loss"][math.random(1, #sounds["loss"])]
        elseif winningTeam ~= "noteam" and sounds[winningTeam][1] ~= nil then
            -- Choose a random sound from the winning team's pool of sounds
            chosenSound = "ttt_round_end_sounds/" .. winningTeam .. "/" .. sounds[winningTeam][math.random(1, #sounds[winningTeam])]
        elseif winningTeam == "monster" then
            -- If the monster team wins, and there are no monster team sounds, choose a random zombies sound
            chosenSound = "ttt_round_end_sounds/zombie/" .. sounds["zombie"][math.random(1, #sounds["zombie"])]
        elseif sounds["loss"][1] ~= nil and result ~= WIN_NONE then
            -- If a win condition happens that's not in the "wins" table, (E.g. a new role's win), choose a random 'loss' sound to play for everyone
            chosenSound = "ttt_round_end_sounds/loss/" .. sounds["loss"][math.random(1, #sounds["loss"])]
        end

        -- Play the sound for everyone
        timer.Simple(0.1, function()
            net.Start("RoundEndSoundsWin")
            net.WriteString(winningTeam)
            net.WriteString(winSound)
            net.WriteString(lossSound)
            net.WriteString(chosenSound)
            net.WriteString(oldmanWinSound)
            net.WriteString(oldmanLossSound)
            net.Broadcast()
        end)

        -- Reset the old man win/loss sound
        timer.Simple(5, function()
            for i, ply in ipairs(player.GetAll()) do
                ply:SetNWBool("OldManWinSound", false)
                ply:SetNWBool("OldManLossSound", false)
            end
        end)
    end)
end

if engine.ActiveGamemode() == "terrortown" and CLIENT then
    net.Receive("RoundEndSoundsPlay", function()
        local snd = net.ReadString()
        surface.PlaySound(snd)
    end)

    -- Play the win sound, if any, on the client so only that player hears it
    net.Receive("RoundEndSoundsWin", function()
        local winningTeam = net.ReadString()
        local winSound = net.ReadString()
        local lossSound = net.ReadString()
        local chosenSound = net.ReadString()
        local oldmanWinSound = net.ReadString()
        local oldmanLossSound = net.ReadString()

        -- If a special role won, play one of that role's special win sounds
        if chosenSound ~= "nosound" then
            surface.PlaySound(chosenSound)
            -- Old man win/loss
        elseif LocalPlayer():GetNWBool("OldManWinSound", false) and oldmanWinSound ~= "nosound" then
            surface.PlaySound(oldmanWinSound)
        elseif LocalPlayer():GetNWBool("OldManLossSound", false) and oldmanLossSound ~= "nosound" then
            surface.PlaySound(oldmanLossSound)
        elseif winSound ~= "nosound" and lossSound ~= "nosound" and CR_VERSION then
            -- When Custom roles is installed
            if (winningTeam == "innocent" or winningTeam == "time") and LocalPlayer():IsInnocentTeam() then
                surface.PlaySound(winSound)
            elseif winningTeam == "traitor" and LocalPlayer():IsTraitorTeam() then
                surface.PlaySound(winSound)
            elseif LocalPlayer():GetNWBool("OldManWinSound", false) then
                -- If there's no oldmanwin sounds, play an ordinary win sound
                surface.PlaySound(winSound)
            else
                surface.PlaySound(lossSound)
            end
        elseif winSound ~= "nosound" and lossSound ~= "nosound" then
            -- When Custom roles isn't installed
            if (winningTeam == "innocent" or winningTeam == "time") and (LocalPlayer():GetRole() == ROLE_INNOCENT or LocalPlayer():GetRole() == ROLE_DETECTIVE) then
                surface.PlaySound(winSound)
            elseif winningTeam == "traitor" and LocalPlayer():GetRole() == ROLE_TRAITOR then
                surface.PlaySound(winSound)
            else
                surface.PlaySound(lossSound)
            end
        end
    end)
    -- If WIN_NONE was the win result, chosenSound, winSound and lossSound are all "nosound", so nothing is played
end