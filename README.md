# Round End Sounds (Win/Lose Sounds) for Gmod TTT
**Add some sounds for when you win or lose a round in TTT**, fully compatible with Custom Roles!\
(Also works just fine without it)\
\
Comes with over**30 possible sounds**, all can be toggled on or off.\
\
If a custom role wins, a random sound will play that only does when that role wins.\
(E.g. a jester win will instead play a random jester win sound)

## Adding your own sounds (Optional)
*If you're hosting a game through the main menu*\
Navigate to: C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod, or wherever you have Garry's Mod installed.\
Create a folder called "sound" and inside that, a folder called "ttt_round_end_sounds".\
Create a folder called "win" or "loss" or for a custom role sound, the name of the role.\
(e.g. "jester")\
Place your sound(s) in the folder!\
\
If your sound isn't working, it might not be in a format Garry's Mod can read, try this:\
Go to this website: https://onlineaudioconverter.com \
Click and drag your sound in, then above "Sample Rate", click on "44.1 kHz" and click convert\
Put your newly converted sound in the folder!\
\
*If you're hosting a dedicated server*\
Do the above, but instead navigate to your server's "garrysmod" folder.\
\
*If you're a mod-maker*\
Any mod contaning:*sound/ttt_round_end_sounds/[win/loss/customrolename]/[soundfile(s)]* will automatically have its sounds played by this mod.\
\
Also, there is a**client-side** hook avaliable for adding sounds to user-made custom roles, or adding sounds to individual innocent/traitor roles.\
The hook passes the player the sound is playing on (ply) and the win enumerator of the role that won (result).\
Return the path to the sound that will play for that player, relative to the sounds folder.\
\
Here are two examples:\

```lua
-- If you win as a hypnotist, play the "ahhohhehey" sound:
    hook.Add("TTTChooseRoundEndSound", "HypnotyistWinSound", function(ply, result)
        if ply:GetRole() == ROLE_HYPNOTIST and result == WIN_TRAITOR then return "ttt_round_end_sounds/clown/ahhohhehey.mp3" end
    end)

-- If the "Bee" won (a user-made role), play the "Not the Bees!" sound:
    hook.Add("TTTChooseRoundEndSound", "BeeWinSound", function(ply, result)
        if result == WIN_BEE then return "ttt_round_end_sounds/bees/not_the_bees.mp3" end
    end)
```

## Turning sounds on or off
**Sounds are NOT disabled until you restart the server or change maps**\
\
*If you're hosting a game through the main menu*\
Go into a map and press ` or ~.\
Then start typing into the console "ttt_roundendsounds" and you'll see the whole list of sounds. (Including sounds you've added yourself!)\
\
You can then scroll though the list of sounds with the up and down arrow keys and hit enter on any that end in "playsound" to hear the sound.\
Once you've found the sound you want to turn off, backspace the "_playsound" off the end and replace it with a " 0" and hit enter.\
\
For example:\
*ttt_roundendsounds_loss_smallest_violin.mp3_playsound*\
plays the world's smallest violin sound.\
\
*ttt_roundendsounds_loss_smallest_violin.mp3 0*\
turns off the world's smallest violin sound.\
\
Alternatively, any line from the list below can be added to your listenserver.cfg:\
\
*If you're hosting a dedicated server*\
Add any of the following on separate lines in your server's server.cfg:
```
ttt_roundendsounds_bees_not_the_bees.mp3 0

ttt_roundendsounds_boxer_knockout.mp3 0

ttt_roundendsounds_clown_ahhohhehey.mp3 0

ttt_roundendsounds_communist_anthem.mp3 0

ttt_roundendsounds_cupid_harp.mp3 0

ttt_roundendsounds_frenchman_chic_magnet_end.mp3 0

ttt_roundendsounds_hivemind_multiple_echoing_laugh.mp3 0

ttt_roundendsounds_jester_directed_by_robert_b_weide.mp3 0

ttt_roundendsounds_killer_kikikimamama.mp3 0

ttt_roundendsounds_krampus_echoing_laugh.mp3 0

ttt_roundendsounds_loss_classic_hurt.mp3 0
ttt_roundendsounds_loss_impostorwin.mp3 0
ttt_roundendsounds_loss_mission_failed.mp3 0
ttt_roundendsounds_loss_oh_no.mp3 0
ttt_roundendsounds_loss_oof.mp3 0
ttt_roundendsounds_loss_overwatch_defeat.mp3 0
ttt_roundendsounds_loss_pac_man.mp3 0
ttt_roundendsounds_loss_price_is_right_losing_horn.mp3 0
ttt_roundendsounds_loss_sad_trombone.mp3 0
ttt_roundendsounds_loss_sad_violin.mp3 0
ttt_roundendsounds_loss_smallest_violin.mp3 0
ttt_roundendsounds_loss_wasted.mp3 0

ttt_roundendsounds_oldmanloss_yogpod_old_man.mp3 0
ttt_roundendsounds_oldmanwin_tranzit.mp3 0

ttt_roundendsounds_thething_echoing_laugh.mp3 0

ttt_roundendsounds_vampire_phantom_of_the_opera.mp3 0

ttt_roundendsounds_vindicator_echoing_laugh.mp3 0

ttt_roundendsounds_win_cheering.mp3 0
ttt_roundendsounds_win_congratulations.mp3 0
ttt_roundendsounds_win_crewmatewin.mp3 0
ttt_roundendsounds_win_ff_victory.mp3 0
ttt_roundendsounds_win_heathstone_victory.mp3 0
ttt_roundendsounds_win_kevin_macleod_who_likes_to_party.mp3 0
ttt_roundendsounds_win_old_yogs_outro.mp3 0
ttt_roundendsounds_win_sonic_3_fanfare.mp3 0
ttt_roundendsounds_win_tf2_victory.mp3 0
ttt_roundendsounds_win_windows_98_tada.mp3 0
ttt_roundendsounds_win_wow_level_up.mp3 0
ttt_roundendsounds_win_yippee.mp3 0

ttt_roundendsounds_zombie_zombies_round_end.mp3 0
ttt_roundendsounds_zombie_zombies_round_start.mp3 0
```
The format for your own sounds is the same:*ttt_roundendsounds_[win/loss/customrolename]_[filename] 0*\
\
*ttt_roundendsounds 0* will turn the mod off, and no sounds will play.\
*ttt_roundendsounds 1* will turn it back on.

## Convars/Options
*ttt_roundendsounds_sound_name_message 0*\
Whether a message in chat displays the name of the sound playing\
\
*ttt_roundendsounds_team_win_sound 0*\
Whether an innocent/traitor team win sound should play instead of a win sound for the winners and a lose sound for the losers.\
Place your sounds in an "innocent_team" and "traitor_team" folder, as opposed to the usual "win" and "loss" folders.

## Credits
Musical notes in the workshop icon is from: https://game-icons.net/ \
\
"Long Laugh 1" by ryanconway from: https://freesound.org/people/ryanconway/sounds/239576/ \
Licenced under CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
