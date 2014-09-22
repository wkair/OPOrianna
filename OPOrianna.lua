-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.5

local scriptName = "OPOrianna"


local champions = {
    ["Orianna"]      = true,
}

if not champions[player.charName] then autoUpdate = nil silentUpdate = nil version = nil scriptName = nil champions = nil collectgarbage() return end

--[[ Updater and library downloader ]]

local sourceLibFound = true
if FileExist(LIB_PATH .. "SourceLib.lua") then
    require "SourceLib"
else
    sourceLibFound = false
    DownloadFile("https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua", function() print("<font color=\"#6699ff\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">SourceLib downloaded! Please reload!</font>") end)
end

if not sourceLibFound then return end

if autoUpdate then
    SourceUpdater(scriptName, version, "raw.github.com", "/wkair/OPOrianna/master/OPOrianna.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/wkair/OPOrianna/master/version.txt"):SetSilent(silentUpdate):CheckUpdate()
end

local libDownloader = Require(scriptName)
if VIP_USER then
    libDownloader:Add("Prodiction",  "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/master/Test/Prodiction/Prodiction.lua")
end
libDownloader:Add("VPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
libDownloader:Add("SOW",         "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
libDownloader:Check()

if libDownloader.downloadNeeded then return end

--[[ Class initializing ]]

for k, _ in pairs(champions) do
    local className = k:gsub("%s+", "")
    class(className)
    champions[k] = _G[className]
end

--[[ Static Variables ]]--


--[[ Script Variables ]]--

local champ = champions[player.charName]
local menu  = nil
local VP    = nil
local OW    = nil
local STS   = nil
local DM    = nil
local DLib  = nil

local spellData = {}

local spells   = {}
local circles  = {}
local AAcircle = nil

local champLoaded = false
local skip        = false
local myRecall    = false

local __colors = {
    { current = 255, step = 1, min = 0, max = 255, mode = -1 },
    { current = 255, step = 2, min = 0, max = 255, mode = -1 },
    { current = 255, step = 3, min = 0, max = 255, mode = -1 },
}

--[[ General Callbacks ]]--

function OnLoad()

    -- Load dependencies
    VP   = VPrediction()
    OW   = SOW(VP)
    STS  = SimpleTS()
    DM   = DrawManager()
    DLib = DamageLib()

    -- Load champion
    champ = champ()

    -- Prevent errors
    if not champ then print("There was an error while loading " .. player.charName .. ", please report the shown error to wkair, thanks!") return else champLoaded = true end

    -- Auto attack range circle
    --AAcircle = DM:CreateCircle(player, OW:MyRange(), 3)
    AAcircle = DM:CreateCircle(player, player.range, 3)
    -- Load menu
    loadMenu()


    -- Regular callbacks registering
    if champ.OnUnload       then AddUnloadCallback(function()                     champ:OnUnload()                  end) end
    if champ.OnExit         then AddExitCallback(function()                       champ:OnExit()                    end) end
    if champ.OnDraw         then AddDrawCallback(function()                       champ:OnDraw()                    end) end
    if champ.OnReset        then AddResetCallback(function()                      champ:OnReset()                   end) end
    if champ.OnSendChat     then AddChatCallback(function(text)                   champ:OnSendChat(text)            end) end
    if champ.OnRecvChat     then AddRecvChatCallback(function(text)               champ:OnRecvChat(text)            end) end
    if champ.OnWndMsg       then AddMsgCallback(function(msg, wParam)             champ:OnWndMsg(msg, wParam)       end) end
    --if champ.OnCreateObj    then AddCreateObjCallback(function(obj)               champ:OnCreateObj(object)         end) end
    --if champ.OnDeleteObj    then AddDeleteObjCallback(function(obj)               champ:OnDeleteObj(object)         end) end
    if champ.OnProcessSpell then AddProcessSpellCallback(function(unit, spell)    champ:OnProcessSpell(unit, spell) end) end
    if champ.OnSendPacket   then AddSendPacketCallback(function(p)                champ:OnSendPacket(p)             end) end
    if champ.OnRecvPacket   then AddRecvPacketCallback(function(p)                champ:OnRecvPacket(p)             end) end
    if champ.OnBugsplat     then AddBugsplatCallback(function()                   champ:OnBugsplat()                end) end
    if champ.OnAnimation    then AddAnimationCallback(function(object, animation) champ:OnAnimation()               end) end
    if champ.OnNotifyEvent  then AddNotifyEventCallback(function(event, unit)     champ:OnNotify(event, unit)       end) end
    if champ.OnParticle     then AddParticleCallback(function(unit, particle)     champ:OnParticle(unit, particle)  end) end

    -- Advanced callbacks registering
    if champ.OnGainBuff     then AdvancedCallback:bind('OnGainBuff',   function(unit, buff) champ:OnGainBuff(unit, buff)   end) end
    if champ.OnUpdateBuff   then AdvancedCallback:bind('OnUpdateBuff', function(unit, buff) champ:OnUpdateBuff(unit, buff) end) end
    if champ.OnLoseBuff     then AdvancedCallback:bind('OnLoseBuff',   function(unit, buff) champ:OnLoseBuff(unit, buff)   end) end
end

function OnTick()

    -- Prevent error spamming
    if not champLoaded then return end

    if not VIP_USER and menu.prediction.predictionType == 2 then
        menu.prediction.predictionType = 1
        PrintChat("You Can't use Prodiction. only vip")
    end

    if champ.OnTick then
        champ:OnTick()
    end

    -- Skip combo once
    if skip then
        skip = false
        return
    end

    if champ.OnCombo and menu.combo and menu.combo.active then
        champ:OnCombo()
    elseif champ.OnHarass and menu.harass and menu.harass.active then
        champ:OnHarass()
    end

end

function OnDraw()

    -- Prevent error spamming
    if not champLoaded then return end

    __mixColors()
    AAcircle.color[1] = 90
    AAcircle.color[2] = __colors[1].current
    AAcircle.color[3] = __colors[2].current
    AAcircle.color[4] = __colors[3].current
    AAcircle.range    = OW:MyRange() 

end

-- Spudgy please...
function OnCreateObj(object) if champLoaded and champ.OnCreateObj then champ:OnCreateObj(object) end end

function OnDeleteObj(object) if champLoaded and champ.OnDeleteObj then champ:OnDeleteObj(object) end end

--[[ Other Functions ]]--

function loadMenu()
    menu = MenuWrapper("[" .. scriptName .. "] " .. player.charName, "unique" .. player.charName:gsub("%s+", ""))

    menu:SetTargetSelector(STS)
    menu:SetOrbwalker(OW)

    -- Apply menu as normal script config
    menu = menu:GetHandle()

    -- Prediction
    menu:addSubMenu("Prediction", "prediction")
        menu.prediction:addParam("predictionType", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "Prodiction(VIP)" })
        _G.srcLib.spellMenu =  menu.prediction

    -- Combo
    if champ.OnCombo then
    menu:addSubMenu("Combo", "combo")
        menu.combo:addParam("active", "Combo active", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    end

    -- Harass
    if champ.OnHarass then
    menu:addSubMenu("Harass", "harass")
        menu.harass:addParam("active", "Harass active", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
    end

    -- Apply champ menu values
    if champ.ApplyMenu then champ:ApplyMenu() end
end

function initializeSpells()
    -- Create spells and circles
    for id, data in pairs(spellData) do
        -- Range
        local range = type(data.range) == "number" and data.range or data.range[1]
        -- Spell
        local spell = Spell(id, range)
        if data.skillshotType then
            spell:SetSkillshot(VP, data.skillshotType, data.width, data.delay, data.speed, data.collision)
        end
        table.insert(spells, id, spell)
        -- Circle
        local circle = DM:CreateCircle(player, range):LinkWithSpell(spell)
        circle:SetDrawCondition(function() return spell:GetLevel() > 0 end)
        table.insert(circles, id, circle)
    end
end

function getBestTarget(range, condition)
    condition = condition or function() return true end
    local target = STS:GetTarget(range)
    if not target or not condition(target) then
        target = nil
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy, range) and condition(enemy) then
                if not target or enemy.health < target.health then
                    target = enemy
                end
            end
        end
    end
    return target
end

function skipCombo()
    skip = true
end

function __mixColors()
    for i = 1, #__colors do
        local color = __colors[i]
        color.current = color.current + color.mode * color.step
        if color.current < color.min then
            color.current = color.min
            color.mode = 1
        elseif color.current > color.max then
            color.current = color.max
            color.mode = -1
        end
    end
end

function GetPredictedPos(unit, delay, speed, source)
    if menu.prediction.predictionType == 1 then
        return VP:GetPredictedPos(unit, delay, speed, source)
    elseif menu.prediction.predictionType == 2 then
        return Prodiction.GetPrediction(unit, math.huge, speed, delay, 1, source)
    end
end

function CountAllyHeroInRange(range, point)
    local n = 0
    for i, ally in ipairs(GetAllyHeroes()) do
        if ValidTarget(ally, math.huge, false) and GetDistanceSqr(point, ally) <= range * range then
            n = n + 1
        end
    end
    return n
end

function GetDistanceToClosestAlly(p)
    local d = GetDistance(p, myHero)
    for i, ally in ipairs(GetAllyHeroes()) do
        if ValidTarget(ally, math.huge, false) then
            local dist = GetDistance(p, ally)
            if dist < d then
                d = dist
            end
        end
    end
    return d
end  

--[[
     ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗███╗   ██╗ █████╗ 
    ██╔═══██╗██╔══██╗██║██╔══██╗████╗  ██║████╗  ██║██╔══██╗
    ██║   ██║██████╔╝██║███████║██╔██╗ ██║██╔██╗ ██║███████║
    ██║   ██║██╔══██╗██║██╔══██║██║╚██╗██║██║╚██╗██║██╔══██║
    ╚██████╔╝██║  ██║██║██║  ██║██║ ╚████║██║ ╚████║██║  ██║
     ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝  ╚═╝
]]

function Orianna:__init()

    spellData = {
        [_Q] = { range = 815, skillshotType = SKILLSHOT_LINEAR, width = 80,  delay = 0,    speed = 1200, radius = 145, collision = false },
        [_W] = { range = -1,                                    width = 235, delay = 0.25 },
        [_E] = { range = 1095,                                  width = 80,  delay = 0.25, speed = 1700 },
        [_R] = { range = -1,                                    width = 380, delay = 0.6  },
    }
    initializeSpells()

    -- Finetune spells
    spells[_E]:SetSkillshot(VP, SKILLSHOT_LINEAR, spellData[_E].width, spellData[_E].delay, spellData[_E].speed, false)
    spells[_E].skillshotType = nil
    if VIP_USER then
        spells[_W].packetCast = true
        spells[_R].packetCast = true
    end

    -- Circle customization
    circles[_Q].color = { 255, 255, 100, 0 }
    circles[_Q].width = 2
    circles[_W].enabled = false
    circles[_E].enabled = false
    circles[_R].enabled = false

    -- Minions
    self.enemyMinions  = minionManager(MINION_ENEMY,  spells[_Q].range, player, MINION_SORT_MAXHEALTH_DEC)
    self.jungleMinions = minionManager(MINION_JUNGLE, spells[_Q].range, player, MINION_SORT_MAXHEALTH_DEC)

    self.mainCombo = { _AA, _AA, _Q, _W, _R, _Q, _IGNITE }
    self.levelSequence = { 1,2,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3 }
    --ks
    self.ksclock = 0
    self.Kscombolist ={
        {combo = {_E,_AA}      , spells = function() if(menu.ks.UseE and spells[_E]:IsReady())then return {_E} else return nil end end },  
        {combo = {_Q}          , spells = function() if(menu.ks.UseQ and spells[_Q]:IsReady())then return {_Q} else return nil end end },                 
        {combo = {_W}          , spells = function() if(menu.ks.UseW and spells[_W]:IsReady())then return {_W} else return nil end end },              
        {combo = {_Q,_W}       , spells = function() if(menu.ks.UseQ and spells[_Q]:IsReady() and menu.ks.UseW and spells[_W]:IsReady())then return {_Q} else return nil end end },              
        {combo = {_W,_Q}       , spells = function() if(menu.ks.UseQ and not spells[_Q]:IsReady() and menu.ks.UseW and spells[_W]:IsReady())then return {_W} else return nil end end },              
        {combo = {_R}          , spells = function() if(menu.ks.UseR and spells[_R]:IsReady() and self:GetEnemiesHitByR() >= menu.ks.numR)then return {_R} else return nil end end },              
        {combo = {_Q,_R}       , spells = function() if(menu.ks.UseQ and spells[_Q]:IsReady() and menu.ks.UseR and spells[_R]:IsReady() )then return {_Q} else return nil end end },              
        {combo = {_R,_W}       , spells = function() if(menu.ks.UseR and spells[_R]:IsReady() and menu.ks.UseW and spells[_W]:IsReady())then return {_R,_W} else return nil end end },              
        {combo = {_Q,_R,_W}    , spells = function() if(menu.ks.UseQ and spells[_Q]:IsReady() and menu.ks.UseR and spells[_R]:IsReady() and menu.ks.UseW and spells[_W]:IsReady())then return {_Q} else return nil end end },              
        --{combo = {_IGNITE,_AA} , spells = function() if(menu.ks.UseI and player:CanUseSpell(_IGNITE) == READY )then return {_IGNITE} else return nil end end },              
        --{combo = {_IGNITE,_Q}  , spells = function() if(menu.ks.UseI and player:CanUseSpell(_IGNITE) == READY and menu.ks.UseQ and spells[_Q]:IsReady())then return {_IGNITE,_Q} else return nil end end },              
        {combo = {_IGNITE,_AA} , spells = function() if(menu.ks.UseI )then return {_IGNITE} else return nil end end },              
        {combo = {_IGNITE,_Q}  , spells = function() if(menu.ks.UseI and menu.ks.UseQ and spells[_Q]:IsReady())then return {_IGNITE,_Q} else return nil end end },              
    }

    -- Register damage sources
    DLib:RegisterDamageSource(_Q, _MAGIC, 60,  30, _MAGIC, _AP, 0.5, function() return spells[_Q]:IsReady() end)
    DLib:RegisterDamageSource(_W, _MAGIC, 70,  45, _MAGIC, _AP, 0.7, function() return spells[_W]:IsReady() end)
    DLib:RegisterDamageSource(_E, _MAGIC, 60,  30, _MAGIC, _AP, 0.3, function() return spells[_E]:IsReady() end)
    DLib:RegisterDamageSource(_R, _MAGIC, 150, 75, _MAGIC, _AP, 0.7, function() return spells[_R]:IsReady() end)
    DLib:RegisterDamageSource(_PASIVE, _MAGIC, 0, 0, _MAGIC, _AP, 0.15, nil, function(target) return 10 + (player.level > 3 and (math.floor((player.level - 1) / 3) * 8) or 0) end)

    self.ballPos = player
    self.ballMoving = false

    self.ballCircles = {
        DM:CreateCircle(self.ballPos, 50, 3, { 255, 200, 0, 0 }):SetDrawCondition(function() return not self.ballMoving and (not self.ballPos.networkID or self.ballPos.networkID ~= player.networkID) end),
        DM:CreateCircle(self.ballPos, spellData[_W].width, 1, { 200, 200, 0, 255 }):SetDrawCondition(function() return not self.ballMoving and spells[_W]:IsReady() end),
        DM:CreateCircle(self.ballPos, spellData[_R].width, 1, { 255, 200, 0, 255 }):SetDrawCondition(function() return not self.ballMoving and spells[_R]:IsReady() end)
    }

    -- Auto update ball circles
    TickLimiter(function()
        for i = 1, #self.ballCircles do
            self.ballCircles[i].position = self.ballPos
        end
    end, 10)

    -- Used for initiator shielding
    self.lastSpellUsed = {}

    self.initiatorList = {
        ["Vi"]         = { { spellName = "ViQ",                  displayName = "Vi - Vault Breaker (Q)"           },
                           { spellName = "ViR",                  displayName = "Vi - Assault and Battery (R)"     } },
        ["Malphite"]   = { { spellName = "Landslide",            displayName = "Malphite - Unstoppable Force (R)" } },
        ["Nocturne"]   = { { spellName = "NocturneParanoia",     displayName = "Nocturne - Paranoia (R)"          } },
        ["Zac"]        = { { spellName = "ZacE",                 displayName = "Zac - Elastic Slingshot (E)"      } },
        ["MonkeyKing"] = { { spellName = "MonkeyKingNimbus",     displayName = "Wukong - Nimbus Strike (E)"       },
                           { spellName = "MonkeyKingSpinToWin",  displayName = "Wukong - Cyclone (R)"             },
                           { spellName = "SummonerFlash",        displayName = "Wukong - Flash"                   } },
        ["Shyvana"]    = { { spellName = "ShyvanaTransformCast", displayName = "Shyvana - Dragon\'s Descent (R)"  } },
        ["Thresh"]     = { { spellName = "threshqleap",          displayName = "Thresh - Death Leap (Q2)"         } },
        ["Aatrox"]     = { { spellName = "AatroxQ",              displayName = "Aatrox - Dark Flight (Q)"         } },
        ["Renekton"]   = { { spellName = "RenektonSliceAndDice", displayName = "Renekton - Slice & Dice (E)"      } },
        ["Kennen"]     = { { spellName = "KennenLightningRush",  displayName = "Kennen - Lightning Rush (E)"      },
                           { spellName = "SummonerFlash",        displayName = "Kennen - Flash"                   } },
        ["Olaf"]       = { { spellName = "OlafRagnarok",         displayName = "Olaf - Ragnarok (R)"              } },
        ["Udyr"]       = { { spellName = "UdyrBearStance",       displayName = "Udyr - Bear Stance (E)"           } },
        ["Volibear"]   = { { spellName = "VolibearQ",            displayName = "Volibear - Rolling Thunder (Q)"   } },
        ["Talon"]      = { { spellName = "TalonCutthroat",       displayName = "Talon - Cutthroat (E)"            } },
        ["JarvanIV"]   = { { spellName = "JarvanIVDragonStrike", displayName = "Jarvan IV - Dragon Strike (Q)"    } },
        ["Warwick"]    = { { spellName = "InfiniteDuress",       displayName = "Warwick - Infinite Duress (R)"    } },
        ["Jax"]        = { { spellName = "JaxLeapStrike",        displayName = "Jax - Leap Strike (Q)"            } },
        ["Yasuo"]      = { { spellName = "YasuoRKnockUpComboW",  displayName = "Yasuo - Last Breath (R)"          } },
        ["Diana"]      = { { spellName = "DianaTeleport",        displayName = "Diana - Lunar Rush (R)"           } },
        ["LeeSin"]     = { { spellName = "BlindMonkQTwo",        displayName = "Lee Sin - Resonating Strike (Q2)" } },
        ["Shen"]       = { { spellName = "ShenShadowDash",       displayName = "Shen - Shadow Dash (E)"           } },
        ["Alistar"]    = { { spellName = "Headbutt",             displayName = "Alistar - Headbutt (W)"           } },
        ["Amumu"]      = { { spellName = "BandageToss",          displayName = "Amumu - Bandage Toss (Q)"         } },
        ["Urgot"]      = { { spellName = "UrgotSwap2",           displayName = "Urgot - HK Position Reverser (R)" } },
        ["Rengar"]     = { { spellName = "RengarR",              displayName = "Rengar - Thrill of the Hunt (R)"  } },
        ["Katarina"]   = { { spellName = "KatarinaE",            displayName = "Katarina - Shunpo (E)"            } },
        ["Leona"]      = { { spellName = "LeonaZenithBlade",     displayName = "Leona - Zenith Blade (E)"         } },
        ["Maokai"]     = { { spellName = "MaokaiUnstableGrowth", displayName = "Maokai - Twisted Advance (W)"     } },
        ["XinZhao"]    = { { spellName = "XenZhaoSweep",         displayName = "Xin Zhao - Audacious Charge (E)"  } }
    }

    self.interruptList = {
        ["Katarina"] = "KatarinaR",
        ["Malzahar"] = "AlZaharNetherGrasp",
        ["Warwick"]  = "InfiniteDuress",
        ["Velkoz"]   = "VelkozR"
    }

    -- Precise packet hooks
    if VIP_USER then
        PacketHandler:HookOutgoingPacket(Packet.headers.S_CAST, function(p) self:OnCastSpell(p) end)
    end

    -- Other helper values
    self.nearEnemyHeroes = false
    self.farRange = 1.3

end

function Orianna:OnTick()
    if menu.misc.autolv then autoLevelSetSequence(self.levelSequence) end

    -- Enemy check
    self.nearEnemyHeroes = CountEnemyHeroInRange(spells[_Q].range + spellData[_R].width)

    OW:EnableAttacks()
    OW:ForceTarget()

    -- Disable spellcasting attempts while ball is moving
    if self.ballMoving then skipCombo() return end

    if menu.misc.shield and spells[_E]:IsReady() then  
        spells[_E]:Cast(player)
    end

    -- Lane farm
    if menu.farm.freeze or menu.farm.lane then
        self:OnFarm()
    end
    
    -- Jungle farm
    if menu.jfarm.active then
        self:OnJungleFarm()
    end

    -- Auto E initiators
    if menu.misc.autoE.active and spells[_E]:IsReady() then
        for _, ally in ipairs(GetAllyHeroes()) do
            if _GetDistanceSqr(ally) < spells[_E].rangeSqr then
                local data = self.initiatorList[ally.charName]
                if data then
                    for _, spell in ipairs(data) do
                        if self.lastSpellUsed[ally.networkID] and menu.misc.autoE[spell.spellName .. self.lastSpellUsed[ally.networkID].spellName] and (os.clock() - self.lastSpellUsed[ally.networkID].time < 1.5) then
                            spells[_E]:Cast(ally)
                        end
                    end
                end
            end
        end
    end

    -- No checks when no enemies around
    if self.nearEnemyHeroes == 0 then return end

    -- Kill Steal
    if not skip and menu.ks.Enable then
        self:OnKillSteal()
    end 

    -- Auto W
    if menu.misc.autoW > 1 and spells[_W]:IsReady() then
        local hitNum = self:GetEnemiesHitByW()
        if hitNum >= menu.misc.autoW - 1 then
            spells[_W]:Cast()
        end
    end
    
    -- Auto R
    if menu.misc.autoR > 1 and spells[_R]:IsReady() then
        local hitNum = self:GetEnemiesHitByR()
        if hitNum >= menu.misc.autoR - 1 and self:GetDistanceToClosestAlly(self.ballPos) < spells[_Q].rangeSqr * self.farRange then
            spells[_R]:Cast()
        end     
    end

    -- Auto R interrupt
    if menu.misc.interrupt then
        for _, enemy in ipairs(GetEnemyHeroes()) do
            for champion, spell in pairs(self.interruptList) do
                if _GetDistanceSqr(enemy) < spells[_Q].rangeSqr and self.lastSpellUsed[enemy.networkID] and spell == self.lastSpellUsed[enemy.networkID].spellName and (os.clock() - self.lastSpellUsed[enemy.networkID].time < 1) then
                    spells[_Q]:Cast(enemy.x, enemy.z)
                    if _GetDistanceSqr(self.ballPos, enemy) < spellData[_R].width ^ 2 then
                        spells[_R]:Cast()
                    end
                end
            end
        end
    end

    -- Harass toggle
    if not skip and not menu.harass.active and not menu.combo.active and menu.harass.toggle and not myRecall then
        self:OnHarass()
    end

end

function Orianna:SpellToString( SpellId )
    if SpellId == _Q then 
        return "Q"
    elseif SpellId == _W then 
        return "W"
    elseif SpellId == _E then 
        return "E"
    elseif SpellId == _R then 
        return "R"
    elseif SpellId == _IGNITE then 
        return "IGNIT"
    elseif SpellId == _AA then 
        return "AA"
    end

    return "UnkownSpell"

end

function Orianna:ComboToString( COMBO )
    local str = "[ "
    for _, SPELL in ipairs(COMBO) do
        str = str..self:SpellToString(SPELL).." "
    end
    return str.."]"

end

function Orianna:OnKillSteal()
    if os.clock() - self.ksclock < 0.1 then return end
    self.ksclock = os.clock()

    for _, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, spellData[_Q].range + spellData[_R].width)then
            for i, Combo in ipairs(self.Kscombolist) do
                local spellList = Combo.spells()
                if spellList and DLib:IsKillable(enemy, Combo.combo) then 
                    
                    local IsSpellValid = false
                    for _, ksspell in ipairs(spellList) do
                        if ksspell == _Q then 
                            IsSpellValid = self:PredictCastQ(enemy)
                        elseif ksspell == _W then 
                            IsSpellValid = self:PredictCastW(enemy)
                        elseif ksspell == _E then 
                            IsSpellValid = self:PredictCastE(enemy)
                        elseif ksspell == _R and menu.ks.numR >= self:GetEnemiesHitByR() then 
                            IsSpellValid = self:PredictCastR(enemy)
                        elseif ksspell == _IGNITE then 
                            IsSpellValid = self:PredictCastI(enemy)
                        end
                    end
                    if IsSpellValid and menu.ks.Debug then 
                        PrintChat(enemy.charName.." is killable. "..self:ComboToString(Combo.combo)) 
                        return 
                    end
                end
            end
        end
    end

end

function Orianna:OnCombo()

    -- Fighting a single target
    if self.nearEnemyHeroes == 1 then

        local target = STS:GetTarget(spells[_Q].range + spells[_Q].width)

        -- No target found, return
        if not target then return end

        -- -- Disable autoattacks due to danger or target being too close
        -- if ((_GetDistanceSqr(target) < 300 * 300) or ((player.health / player.maxHealth < 0.25) and (player.health / player.maxHealth < target.health / target.maxHealth))) then
        --     OW:DisableAttacks()
        -- end

        -- Cast Q
        if menu.combo.useQ and spells[_Q]:IsReady() then
            self:PredictCastQ(target)
        end

        -- Cast ult if target is killable
        if menu.combo.useR and spells[_R]:IsReady() and CountEnemyHeroInRange(1000, target) >= CountAllyHeroInRange(1000, target)  then
            if DLib:IsKillable(target, self.mainCombo) and GetDistanceToClosestAlly(self.ballPos) < spells[_Q].range * self.farRange then
                if self:GetEnemiesHitByR() >= menu.combo.numR then
                    spells[_R]:Cast()
                end
            end
        end

        -- Cast W if it will hit
        if menu.combo.useW and spells[_W]:IsReady() then
            if self:GetEnemiesHitByW() > 0 then
                spells[_W]:Cast()
            end
        end
        
        -- Cast E
        if menu.combo.useE and spells[_E]:IsReady() then
            -- Cast E on ally for gap closing
            for _, ally in ipairs(GetAllyHeroes()) do
                if ValidTarget(ally, spells[_E].range, false) and CountEnemyHeroInRange(400, ally) > 0 and _GetDistanceSqr(ally, target) < 400 * 400 then
                    spells[_E]:Cast(ally)
                    return
                end
            end
            -- Cast E on self for damaging target
            if self:GetEnemiesHitByE(player) > 0 then
                spells[_E]:Cast(player)
            end
        end

        if menu.combo.ignite and _IGNITE then
            local igniteTarget = STS:GetTarget(600)
            if igniteTarget and DLib:IsKillable(igniteTarget, self.mainCombo) then
                CastSpell(_IGNITE, igniteTarget)
            end
        end

    -- Fighting multiple targets
    elseif self.nearEnemyHeroes > 1 then

        local target = STS:GetTarget(spells[_Q].range + spells[_Q].width)

        -- No target found, return
        if not target then return end

        -- Disable attacks due to danger mode or target too close
        -- for _, enemy in ipairs(GetEnemyHeroes()) do
        --     if ValidTarget(enemy, 300) and (player.health / player.maxHealth < 0.25) then
        --         OW:DisableAttacks()
        --     end
        -- end

        -- Cast Q on best location
        if menu.combo.useQ and spells[_Q]:IsReady() then
            local castPosition, hitNum = self:GetBestPositionQ(target)
            
            if castPosition and hitNum > 1 then
                spells[_Q]:Cast(castPosition.x, castPosition.z)
            else
                self:PredictCastQ(target)
            end
        end

        -- Cast R on best location
        if menu.combo.useR and spells[_R]:IsReady() then
            if CountEnemyHeroInRange(800, self.ballPos) > 1 then
                local hitNum, enemiesHit = self:GetEnemiesHitByR()
                local potentialKills, kills = 0, 0
                if hitNum >= 2 then
                    for _, enemy in ipairs(enemiesHit) do
                        if enemy.health - DLib:CalcComboDamage(enemy, self.mainCombo) < 0.4 * enemy.maxHealth or (DLib:CalcComboDamage(enemy, self.mainCombo) >= 0.4 * enemy.maxHealth) then
                            potentialKills = potentialKills + 1
                        end
                        if DLib:IsKillable(enemy, self.mainCombo) then
                            kills = kills + 1
                        end
                    end
                end
                if ((GetDistanceToClosestAlly(self.ballPos) < spells[_Q].range * self.farRange and hitNum >= CountEnemyHeroInRange(800, self.ballPos) or potentialKills > 1) or kills > 0) and hitNum >= menu.combo.numR then
                    spells[_R]:Cast()
                end
            elseif menu.combo.numR == 1 then
                if self:GetEnemiesHitByR() > 0 and DLib:IsKillable(target, {_Q, _W, _R}) and GetDistanceToClosestAlly(self.ballPos) < spells[_Q].range * self.farRange then
                    spells[_R]:Cast()
                end
            end
        end
        
        -- Cast W if it will hit
        if menu.combo.useW and spells[_W]:IsReady() then
            if self:GetEnemiesHitByW() > 0 then
                spells[_W]:Cast()
            end
        end

        -- Force the new target
        if OW:InRange(target) then
            OW:ForceTarget(target)
        end
        
        -- Cast E
        if menu.combo.useE and spells[_E]:IsReady() then
            -- Cast on self for damaging enemies
            if CountEnemyHeroInRange(800, self.ballPos) < 3 then
                if self:GetEnemiesHitByE(player) > 0 then
                    spells[_E]:Cast(player)
                    return
                end
            else
                if self:GetEnemiesHitByE(player) > 1 then
                    spells[_E]:Cast(player)
                    return
                end
            end
            -- Cast on allies for gap closing
            for _, ally in ipairs(GetAllyHeroes()) do
                if ValidTarget(ally, spells[_E].range, false) and CountEnemyHeroInRange(300, ally) > 2 and _GetDistanceSqr(ally, target) < 300 * 300 then
                    spells[_E]:Cast(ally)
                    return
                end
            end
        end

        if menu.combo.ignite and _IGNITE then
            local igniteTarget = STS:GetTarget(600)
            if igniteTarget and DLib:IsKillable(igniteTarget, self.mainCombo) then
                CastSpell(_IGNITE, igniteTarget)
            end
        end
    end

end

function Orianna:OnHarass()
    if menu.harass.mana > (player.mana / player.maxMana) * 100 or menu.harass.hp > (player.health / player.maxHealth) * 100 then return end

    if menu.harass.useQ and spells[_Q]:IsReady() then
        self:PredictCastQ(STS:GetTarget(spells[_Q].range + spells[_Q].width))
    end

    if menu.harass.useW and spells[_W]:IsReady() then
        if self:GetEnemiesHitByW() > 0 then
            spells[_W]:Cast()
        end
    end

end

function Orianna:OnFarm()

    if menu.farm.mana > (player.mana / player.maxMana) * 100 then return end

    self.enemyMinions:update()

    local useQ = spells[_Q]:IsReady() and (menu.farm.lane and (menu.farm.useQ >= 3) or (menu.farm.useQ == 2))
    local useW = spells[_W]:IsReady() and (menu.farm.lane and (menu.farm.useW >= 3) or (menu.farm.useW == 2))
    local useE = spells[_E]:IsReady() and (menu.farm.lane and (menu.farm.useE >= 3) or (menu.farm.useE == 2))
    
    if useQ then
        if useW then
            local hitNum = 0
            local castPosition = 0
            for _, minion in ipairs(self.enemyMinions.objects) do
                if _GetDistanceSqr(minion) < spells[_Q].rangeSqr then
                    local minionPosition = GetPredictedPos(minion, spells[_Q].delay, spells[_Q].speed, self.ballPos)
                    local minionHits = CountObjectsNearPos(minion, nil, spellData[_W].width, self.enemyMinions.objects)
                    if minionHits >= hitNum then
                        hitNum = minionHits
                        castPosition = minionPosition
                    end
                end
            end
            if hitNum > 0 and castPosition then
                spells[_Q]:Cast(castPosition.x, castPosition.z)
            end
        else
            for _, minion in ipairs(self.enemyMinions.objects) do
                if DLib:IsKillable(minion, {_Q}) and not OW:InRange(minion) then
                    local minionPosition = GetPredictedPos(minion, spells[_Q].delay, spells[_Q].speed, self.ballPos)
                    spells[_Q]:Cast(minionPosition.x, minionPosition.z)
                    break
                end
            end
        end
    end

    if useW then
        local minionHits = CountObjectsNearPos(self.ballPos, nil, spellData[_W].width, self.enemyMinions.objects)
        if minionHits >= 3 then
            spells[_W]:Cast()
        end
    end

    if useE and not useW then
        local minionHits = self:GetMinionsHitE()
        if minionHits >= 3 then
            spells[_E]:Cast(player)
        end
    end

end

function Orianna:OnJungleFarm()

    self.jungleMinions:update()

    local useQ = menu.jfarm.useQ and spells[_Q]:IsReady()
    local useW = menu.jfarm.useW and spells[_W]:IsReady()
    local useE = menu.jfarm.useE and spells[_E]:IsReady()
    
    local minion = self.jungleMinions.objects[1]
    
    if minion then
        if useQ then
            local position = GetPredictedPos(minion, spells[_Q].delay, spells[_Q].speed, self.ballPos)
            CastSpell(_Q, position.x, position.z)
        end
        
        if useW and _GetDistanceSqr(self.ballPos, minion) < spellData[_W].width ^ 2 then
            spells[_W]:Cast()
        end
        
        if useE and not useW and _GetDistanceSqr(minion) < 700 ^ 2 then
            local target = player
            local distance = _GetDistanceSqr(minion)
            for _, ally in ipairs(GetAllyHeroes()) do
                local dist = _GetDistanceSqr(ally, minion)
                if ValidTarget(ally, spells[_E].range, false) and dist < distance then
                    distance = dist
                    target = ally
                end
            end
            spells[_E]:Cast(target)
        end
    end

end

function Orianna:PredictCastQ(target)

    -- No target found, return
    if not target then return false end

    -- Helpers
    local castPoint = nil

    spells[_Q]:SetSourcePosition(self.ballPos)
    spells[_Q]:SetRange(math.huge)
    local castPosition, hitChance, position = spells[_Q]:GetPrediction(target)
    spells[_Q]:SetRange(spellData[_Q].range)

    -- Update castPoint
    castPoint = castPosition

    -- Hitchance too low, return
    if hitChance < 2 then return false end

    -- Main target out of range, getting new target
    if _GetDistanceSqr(position) > spells[_Q].rangeSqr + (spellData[_W].width + VP:GetHitBox(target)) ^ 2 then
        target2 = STS:GetTarget(spells[_Q].range + spellData[_W].width + 250, 2)
        if target2 then
            spells[_Q]:SetRange(math.huge)
            castPoint = spells[_Q]:GetPrediction(target2)
            spells[_Q]:SetRange(spellData[_Q].range)
        else return false end
    end

    -- Second target out of range aswell, return
    if _GetDistanceSqr(position) > spells[_Q].rangeSqr + (spellData[_W].width + VP:GetHitBox(target)) ^ 2 then
        do return false end
    end

    -- EQ calculation for faster Q on target, only if enabled in menu
    if spells[_E]:IsReady() and menu.misc.EQ ~= 0 then
        local travelTime = _GetDistanceSqr(self.ballPos, castPoint) / (spells[_Q].speed ^ 2)
        local minTravelTime = _GetDistanceSqr(castPoint) / (spells[_Q].speed ^ 2) + _GetDistanceSqr(self.ballPos) / (spells[_E].speed ^ 2)
        local target = player

        for _, ally in ipairs(GetAllyHeroes()) do
            if ally.networkID ~= player.networkID and ValidTarget(ally, spells[_E].range, false) then
                local time = _GetDistanceSqr(ally, castPoint) / (spells[_Q].speed ^ 2) + _GetDistanceSqr(ally, self.ballPos) / (spells[_E].speed ^ 2)
                if time < minTravelTime then
                    minTravelTime = time
                    target = ally
                end
            end
        end

        if minTravelTime < (menu.misc.EQ / 100) * travelTime and (not target.isMe or _GetDistanceSqr(self.ballPos) > 100 * 100) and _GetDistanceSqr(target) < _GetDistanceSqr(castPoint) then
            spells[_E]:Cast(target)
            return false
        end
    end

    -- Cast point adjusting if it's slightly out of range
    if _GetDistanceSqr(castPoint) > spells[_Q].rangeSqr then
        castPoint = Vector(player.visionPos) + spells[_Q].range * (Vector(castPoint) - Vector(player.visionPos)):normalized()
    end

    -- Cast Q
    spells[_Q]:Cast(castPoint.x, castPoint.z)
    return true

end

function Orianna:PredictCastW(target)
    if target then
        local position = GetPredictedPos(target, spellData[_W].delay)
        if ValidTarget(target) and _GetDistanceSqr(position, self.ballPos) < spellData[_W].width ^ 2 and _GetDistanceSqr(target, self.ballPos) < spellData[_W].width ^ 2 then
            spells[_W]:Cast()
            return true
        end
    end
    return false

end

function Orianna:PredictCastE(target)
    local hitcount, enemies = self:GetEnemiesHitByE(player)
    if hitcount > 0  then
        for _, enemy in ipairs(enemies) do
            if target == enemy then
                spells[_E]:Cast(player)
                return true
            end
        end
    end
    return false

end

function Orianna:PredictCastR(target)
    if target then
        local position = GetPredictedPos(target, spellData[_R].delay)
        if ValidTarget(target) and _GetDistanceSqr(position, self.ballPos) < spellData[_R].width ^ 2 and _GetDistanceSqr(target, self.ballPos) < spellData[_R].width ^ 2 then
            spells[_R]:Cast()
            return true
        end
    end
    return false

end

function Orianna:PredictCastI(target)
    if target then
        if _IGNITE and ValidTarget(target) and _GetDistanceSqr(target, player) < 600 ^ 2 then
            CastSpell(_IGNITE, target)
            return true
        end
    end
    return false

end

function Orianna:GetBestPositionQ(target)

    local points = {}
    local targets = {}
    
    spells[_Q]:SetSourcePosition(self.ballPos)
    local castPosition, hitChance, position = spells[_Q]:GetPrediction(target)

    table.insert(points, position)
    table.insert(targets, target)
    
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, spells[_Q].range + spellData[_R].width) and enemy.networkID ~= target.networkID then
            castPosition, hitChance, position = spells[_Q]:GetPrediction(enemy)
            table.insert(points, position)
            table.insert(targets, enemy)
        end
    end
    
    for o = 1, 5 do
        local circle = MEC(points):Compute()
        
        if circle.radius <= spellData[_R].width and #points >= 3 and spells[_R]:IsReady() then
            return circle.center, 3
        end
    
        if circle.radius <= spellData[_W].width and #points >= 2 and spells[_W]:IsReady() then
            return circle.center, 2
        end
        
        if #points == 1 then
            return circle.center, 1
        elseif circle.radius <= spellData[_Q].radius and #points >= 1 then
            return circle.center, 2
        end
        
        local distance = -1
        local mainPoint = points[1]
        local index = 0
        
        for i = 2, #points do
            if _GetDistanceSqr(points[i], mainPoint) > distance then
                distance = _GetDistanceSqr(points[i], mainPoint)
                index = i
            end
        end
        if index > 0 then
            table.remove(points, index)
        end
    end

end

function Orianna:GetEnemiesHitByW()

    local enemies = {}
    for _, enemy in ipairs(GetEnemyHeroes()) do
        local position = GetPredictedPos(enemy, spellData[_W].delay)
        if ValidTarget(enemy) and _GetDistanceSqr(position, self.ballPos) < spellData[_W].width ^ 2 and _GetDistanceSqr(enemy, self.ballPos) < spellData[_W].width ^ 2 then
            table.insert(enemies, enemy)
        end
    end
    return #enemies, enemies

end

function Orianna:GetEnemiesHitByE(destination)

    local enemies = {}
    local sourcePoint = Vector(self.ballPos.x, 0, self.ballPos.z)
    local destPoint = Vector(destination.x, 0, destination.z)
    spells[_E].range = math.huge
    spells[_E].skillshotType = SKILLSHOT_LINEAR
    spells[_E]:SetSourcePosition(sourcePoint)
    for _, enemy in ipairs(GetEnemyHeroes()) do
        local _, _, position = spells[_E]:GetPrediction(enemy)
        if position then
            local pointInLine, _, isOnSegment = VectorPointProjectionOnLineSegment(sourcePoint, destPoint, position)
            if ValidTarget(enemy) and isOnSegment and _GetDistanceSqr(pointInLine, position) < (spells[_E].width + VP:GetHitBox(enemy)) ^ 2 and _GetDistanceSqr(pointInLine, enemy) < (spells[_E].width * 2 + 30) ^ 2 then
                table.insert(enemies, enemy)
            end
        end
    end
    spells[_E].skillshotType = nil
    spells[_E].range = spellData[_E].range
    return #enemies, enemies

end

function Orianna:GetEnemiesHitByR()

    local enemies = {}
    for _, enemy in ipairs(GetEnemyHeroes()) do
        local position = GetPredictedPos(enemy, spellData[_R].delay)
        if ValidTarget(enemy) and _GetDistanceSqr(position, self.ballPos) < spellData[_R].width ^ 2 and _GetDistanceSqr(enemy, self.ballPos) < (1.25 * spellData[_R].width) ^ 2  then
            table.insert(enemies, enemy)
        end
    end
    return #enemies, enemies

end

function Orianna:GetMinionsHitE()

    local minions = {}
    local sourcePoint = Vector(self.ballPos.x, 0, self.ballPos.z)
    local destPoint = Vector(player.x, 0, player.z)
    for _, minion in ipairs(self.enemyMinions.objects) do
        local position = Vector(minion.x, 0, minion.z)
        local pointInLine = VectorPointProjectionOnLineSegment(sourcePoint, destPoint, position)
        if _GetDistanceSqr(pointInLine, position) < spells[_E].width ^ 2 then
            table.insert(minions, minion)
        end
    end
    return #minions, minions

end

function Orianna:GetDistanceToClosestAlly(point)

    local distance = _GetDistanceSqr(point)
    for _, ally in ipairs(GetAllyHeroes()) do
        if ValidTarget(ally, math.huge, false) then
            local dist = _GetDistanceSqr(point, ally)
            if dist < distance then
                distance = dist
            end
        end
    end
    return distance

end

function Orianna:OnCreateObj(object)

    -- Validating
    if not object or not object.name then return end

    -- Ball to pos
    if object.name:lower():find("yomu_ring_green") then
        self.ballPos = Vector(object)
        self.ballMoving = false
    -- Ball back to player
    elseif object.name:lower():find("orianna_ball_flash_reverse") then
        self.ballPos = player
        self.ballMoving = false
    -- Ball to hero
    elseif object.name:lower():find("oriana_ghost_bind_assaisin") then
        self.ballMoving = false
    -- recallcheack for autoHarass
    elseif object.name:lower():find("teleporthome") and GetDistance(object) < 20 then
        self.myRecall = true
    end

end

function Orianna:OnDeleteObj(object)
    -- Validating
    if not object or not object.name then return end
    
    -- ball pickup
    if object.name:lower():find("yomu_ring_green") then
        self.ballPos = player
        self.ballMoving = false
    -- recallcheack for autoHarass
    elseif object.name:lower():find("teleporthome") and GetDistance(object) < 20 then
        self.myRecall = false
    end
end

function Orianna:OnProcessSpell(unit, spell)

    -- Validating
    if not unit or not spell or not spell.name then return end

    if unit.isMe then
        -- Orianna Q
        if spell.name:lower():find("orianaizunacommand") then
            self.ballMoving = true
            DelayAction(function(p) self.ballPos = Vector(p) end, GetDistance(spell.endPos, self.ballPos) / spells[_Q].speed - GetLatency()/1000 - 0.35, { Vector(spell.endPos) })
        -- Orianna E
        elseif spell.name:lower():find("orianaredactcommand") and (not self.ballPos.networkID or self.ballPos.networkID ~= spell.target.networkID) then
            self.ballPos = spell.target
            self.ballMoving = true
        end
    end

    -- Initiator helper
    if unit.type == player.type and unit.team == player.team then
        self.lastSpellUsed[unit.networkID] = { spellName = spell.name, time = os.clock() }
        -- Instant shield
        if _GetDistanceSqr(unit) < spells[_E].rangeSqr then
            local data = self.initiatorList[unit.charName]
            if data then
                for _, spell in ipairs(data) do
                    if spell.spellName == spell.name then
                        spells[_E]:Cast(unit)
                    end
                end
            end
        end
    end

end

function Orianna:OnCastSpell(p)

    if menu.misc.blockR then
        if Packet(p):get('spellId') == _R then
            if self:GetEnemiesHitByR() == 0 then
                p:Block()
            end
        end
    end

end

function Orianna:ApplyMenu()

    menu.combo:addParam("sep",    "",                        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("useQ",   "Use Q",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useW",   "Use W",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useE",   "Use E",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useR",   "Use R",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("sep",    "",                        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("numR",   "Use R on",                SCRIPT_PARAM_LIST, 1, { "1+ target", "2+ targets", "3+ targets", "4+ targets" , "5+ targets" })
    menu.combo:addParam("sep",    "",                        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("ignite", "Use ignite",              SCRIPT_PARAM_ONOFF, true)

    menu.harass:addParam("toggle", "Harass toggle",            SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("Z"))
    menu.harass:addParam("sep",    "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("useQ",   "Use Q",                    SCRIPT_PARAM_ONOFF, true)
    menu.harass:addParam("useW",   "Use W",                    SCRIPT_PARAM_ONOFF, false)
    menu.harass:addParam("sep",    "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("mana",   "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
    menu.harass:addParam("hp",     "Don't harass if hp < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("KS", "ks")
        menu.ks:addParam("Enable", "Smart Auto Kill",         SCRIPT_PARAM_ONOFF, true)
        menu.ks:addParam("UseQ",   "Use Q",                   SCRIPT_PARAM_ONOFF, true)
        menu.ks:addParam("UseW",   "Use W",                   SCRIPT_PARAM_ONOFF, true)
        menu.ks:addParam("UseE",   "Use E",                   SCRIPT_PARAM_ONOFF, true)
        menu.ks:addParam("UseR",   "Use R",                   SCRIPT_PARAM_ONOFF, true)
        menu.ks:addParam("numR",   "Use R on",                SCRIPT_PARAM_LIST, 1, { "1+ target", "2+ targets", "3+ targets", "4+ targets" , "5+ targets" })
        menu.ks:addParam("UseI",   "Use Ignite",              SCRIPT_PARAM_ONOFF, true)
        menu.ks:addParam("Debug",  "Debug text",              SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Misc", "misc")
        menu.misc:addSubMenu("Auto E on initiators", "autoE")
        local added = false
        for _, ally in ipairs(GetAllyHeroes()) do
            local data = self.initiatorList[ally.charName]
            if data then
                for _, spell in ipairs(data) do
                    added = true
                    menu.misc.autoE:addParam(ally.charName..spell.spellName, spell.displayName, SCRIPT_PARAM_ONOFF, true)
                end
            end
        end
        if not added then
            menu.misc.autoE:addParam("info", "No supported initiators found!", SCRIPT_PARAM_INFO, "")
        else
            menu.misc.autoE:addParam("sep",    "",       SCRIPT_PARAM_INFO, "")
            menu.misc.autoE:addParam("active", "Active", SCRIPT_PARAM_ONOFF, true)
        end
        menu.misc:addParam("autolv",    "Auto Level",                        SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("shield",    "Self Shield Use E",                 SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
        menu.misc:addParam("autoW",     "Auto W on",                         SCRIPT_PARAM_LIST, 1, { "Nope", "1+ target", "2+ targets", "3+ targets", "4+ targets", "5+ targets" })
        menu.misc:addParam("autoR",     "Auto R on",                         SCRIPT_PARAM_LIST, 1, { "Nope", "1+ target", "2+ targets", "3+ targets", "4+ targets", "5+ targets" })
        menu.misc:addParam("EQ",        "Use E + Q if tEQ < %x * tQ",        SCRIPT_PARAM_SLICE, 100, 0, 200)
        menu.misc:addParam("interrupt", "Auto interrupt important spells",   SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("blockR",    "Block R if it's will not hit(VIP)", SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Farm", "farm")
        menu.farm:addParam("freeze", "Farm Freezing",          SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
        menu.farm:addParam("lane",   "Farm LaneClear",         SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("useQ",   "Use Q",                  SCRIPT_PARAM_LIST, 4, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("useW",   "Use W",                  SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("useE",   "Use E",                  SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("mana",   "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("JungleFarm", "jfarm")
        menu.jfarm:addParam("active", "Farm!",                 SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.jfarm:addParam("sep",    "",                      SCRIPT_PARAM_INFO, "")
        menu.jfarm:addParam("useQ",   "Use Q",                 SCRIPT_PARAM_ONOFF, true)
        menu.jfarm:addParam("useW",   "Use W",                 SCRIPT_PARAM_ONOFF, true)
        menu.jfarm:addParam("useE",   "Use E",                 SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Drawing", "drawing")
        AAcircle:AddToMenu(menu.drawing,            "AA Range", false, true, true)
        circles[_Q]:AddToMenu(menu.drawing,         "Q range", true, true, true)
        self.ballCircles[2]:AddToMenu(menu.drawing, "W width", true, true, true)
        self.ballCircles[3]:AddToMenu(menu.drawing, "R width", true, true, true)
        self.ballCircles[1]:AddToMenu(menu.drawing, "Ball position", true, true, true)
        DLib:AddToMenu(menu.drawing, self.mainCombo)


    -- TickLimiter(function()  
    --     if not VIP_USER then
    --         for i = 1, player.buffCount do
    --             local tBuff = player:getBuff(i)
    --             if BuffIsValid(tBuff) then
    --                 PrintChat(tostring(tBuff.name))
    --             end
    --         end
    --         PrintChat("===================")
    --         -- if TargetHaveBuff("orianaghostself") then
    --         --     PrintChat("she has ball")
    --         --     self.ballPos = player
    --         --     self.ballMoving = false
    --         -- end
    --     end
    -- end, 1)

end  