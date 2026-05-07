-- ReckCounter icon + numeric stack display variant for WoW 1.12-style clients.

RECKCOUNTER_HELP = "ReckCounter Commands:";
RECKCOUNTER_HELP2 = "help | show | hide | lock | unlock | showtext | hidetext | verbose | quiet";
RECKCOUNTER_SHOW = "ReckCounter now displaying.";
RECKCOUNTER_HIDE = "ReckCounter hidden. Type /reck for commands.";
RECKCOUNTER_LOCK = "ReckCounter locked.";
RECKCOUNTER_UNLOCK = "ReckCounter unlocked.";
RECKCOUNTER_SHOWTEXT = "ReckCounter text now displaying.";
RECKCOUNTER_HIDETEXT = "ReckCounter text hidden.";
RECKCOUNTER_VERBOSE = "ReckCounter now in Verbose mode.";
RECKCOUNTER_QUIET = "ReckCounter now in Quiet mode.";

RECK_RED = .8;
RECK_GREEN = .8;
RECK_BLUE = 0;

reckcount = 0;
auto_attack = false;
reckcounter_movable = true;
reckcounter_verbose = false;

function reckcounter_OnLoad()
    this:RegisterForDrag("LeftButton");
    this:RegisterEvent("VARIABLES_LOADED");

    SLASH_RECKCOUNTER1 = "/reckcounter";
    SLASH_RECKCOUNTER2 = "/reck";
    SlashCmdList["RECKCOUNTER"] = reckcounter_Command;
end

function reckcounter_Command(msg)
    if (msg) then
        reck_command = string.lower(msg);

        if (reck_command == "show") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_SHOW, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_core:Show();
        elseif (reck_command == "hide") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HIDE, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_core:Hide();
        elseif (reck_command == "lock") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_LOCK, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_movable = false;
        elseif (reck_command == "unlock") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_UNLOCK, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_movable = true;
        elseif (reck_command == "showtext") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_SHOWTEXT, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_display:Show();
        elseif (reck_command == "hidetext") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HIDETEXT, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_display:Hide();
        elseif (reck_command == "verbose") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_VERBOSE, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_verbose = true;
        elseif (reck_command == "quiet") then
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_QUIET, RECK_RED, RECK_GREEN, RECK_BLUE);
            reckcounter_verbose = false;
        else
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HELP, RECK_RED, RECK_GREEN, RECK_BLUE);
            DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HELP2, RECK_RED, RECK_GREEN, RECK_BLUE);
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HELP, RECK_RED, RECK_GREEN, RECK_BLUE);
        DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HELP2, RECK_RED, RECK_GREEN, RECK_BLUE);
    end
end

function reckcounter_initialize()
    if (UnitClass("player") ~= "Paladin") then
        reckcounter_core:Hide();
        DEFAULT_CHAT_FRAME:AddMessage(RECKCOUNTER_HIDE, RECK_RED, RECK_GREEN, RECK_BLUE);
    end

    reckcounter_display:SetText("ReckCounter");
    update_reckcounter(0);
end

function update_reckcounter(reck)
    -- One Reckoning icon with a centered stack number.
    -- The animated glow is copied/adapted from DoiteAuras and only starts at 4 stacks.
    if (reck and reck > 0) then
        ReckCounterIcon:SetAlpha(1);
        ReckCounterCount:SetText(reck);
        ReckCounterCount:Show();
    else
        ReckCounterIcon:SetAlpha(.35);
        ReckCounterCount:SetText("");
        ReckCounterCount:Hide();
    end

    if (reck and reck >= 4) then
        ReckCounterGlow.Start(ReckCounterIconFrame);
    else
        ReckCounterGlow.Stop(ReckCounterIconFrame);
    end
end

function reckcounter_OnEvent()
    if (event == "VARIABLES_LOADED") then
        reckcounter_initialize();
        this:RegisterEvent("PLAYER_ENTER_COMBAT");
        this:RegisterEvent("PLAYER_LEAVE_COMBAT");
        this:RegisterEvent("PLAYER_DEAD");
        this:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS");
        this:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES");
        this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS");
        this:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS");
        this:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE");
    end

    if (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS" or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE") then
        if (arg1 and not auto_attack) then
            if (reckcount < 4 and string.find(arg1, "crits you")) then
                reckcount = reckcount + 1;
                update_reckcounter(reckcount);
            end
        end
    end

    if (event == "PLAYER_ENTER_COMBAT") then
        auto_attack = true;
    end

    if (event == "PLAYER_LEAVE_COMBAT") then
        auto_attack = false;
        reckcounter_reset("Player changed targets after activating auto attack.");
    end

    if (event == "PLAYER_DEAD") then
        auto_attack = false;
        reckcounter_reset("Player has died.");
    end

    if (event == "CHAT_MSG_COMBAT_SELF_HITS") then
        if (arg1 and (string.find(arg1, RECKCOUNTER_YOUHIT) ~= nil or string.find(arg1, RECKCOUNTER_YOUCRIT) ~= nil)) then
            reckcounter_reset("Player started auto attack (hit).");
        end
    end

    if (event == "CHAT_MSG_COMBAT_SELF_MISSES") then
        reckcounter_reset("Player started auto attack (miss).");
    end
end

function reckcounter_OnDragStart()
    if (reckcounter_movable == true) then
        this:StartMoving();
        this.isMoving = true;
    end
end

function reckcounter_OnDragStop()
    this:StopMovingOrSizing();
    this.isMoving = false;
end

function reckcounter_reset(reason)
    if (reckcounter_verbose == true and reckcount > 0) then
        DEFAULT_CHAT_FRAME:AddMessage("ReckCounter Reset! " .. reason, RECK_RED, RECK_GREEN, RECK_BLUE);
    end

    reckcount = 0;
    update_reckcounter(reckcount);
end
