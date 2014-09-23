if myHero.charName ~= "Orianna" then return end

local version = 0.18
local AUTOUPDATE = true
local scriptName = "OPOrianna"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if AUTOUPDATE then
    SourceUpdater(scriptName, version, "raw.github.com", "/wkair/OPOrianna/master/" .. scriptName .. ".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/wkair/OPOrianna/master/version.txt"):SetSilent(false):CheckUpdate()
end
-- / Lib Auto-Update Function / --
local lib_Required = {
	["SourceLib"]	= "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua",
	["SxOrbWalk"]	= "https://raw.githubusercontent.com/Superx321/BoL/master/common/SxOrbWalk.lua",
	["VPrediction"]	= "https://raw.githubusercontent.com/Hellsing/BoL/master/Common/VPrediction.lua",
	["Prodiction"]	= "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/ec830facccefb3b52212dba5696c08697c3c2854/Test/Prodiction/Prodiction.lua"
}
if not VIP_USER then
	lib_Required["Prodiction"] = nil
end
local lib_downloadNeeded, lib_downloadCount = false, 0
for lib_downloadName, lib_downloadUrl in pairs(lib_Required) do
	local lib_fileName = LIB_PATH .. lib_downloadName .. ".lua"

	if FileExist(lib_fileName) then
		require(lib_downloadName)
	else
		lib_downloadNeeded = true
		lib_downloadCount = lib_downloadCount and lib_downloadCount + 1 or 1
		DownloadFile(lib_downloadUrl, lib_fileName, function() AfterDownload() end)
	end
end

if lib_downloadNeeded then return end

function AfterDownload()
	lib_downloadCount = lib_downloadCount - 1
	if lib_downloadCount == 0 then
		lib_downloadNeeded = false
		print("<font color=\"#FF0000\">Oriana:</font> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
	end
end

-- / Lib Auto-Update Function / --



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local InitiatorsList = 
	{
	  ["Vi"] = "ViQ",--R
	  ["Vi"] = "ViR",--R
	  ["Malphite"] = "Landslide",--R UFSlash
	  ["Nocturne"] = "NocturneParanoia",--R
	  ["Zac"] = "ZacE",--E
	  ["MonkeyKing"] = "MonkeyKingNimbus",--R
	  ["MonkeyKing"] = "MonkeyKingSpinToWin",--R
	  ["MonkeyKing"] = "SummonerFlash",--Flash
	  ["Shyvana"] = "ShyvanaTransformCast",--R
	  ["Thresh"] = "threshqleap",--Q2
	  ["Aatrox"] = "AatroxQ",--Q
	  ["Renekton"] = "RenektonSliceAndDice",--E
	  ["Kennen"] = "KennenLightningRush",--E
	  ["Kennen"] = "SummonerFlash",--Flash
	  ["Olaf"] = "OlafRagnarok",--R
	  ["Udyr"] = "UdyrBearStance",--E
	  ["Volibear"] = "VolibearQ",--Q
	  ["Talon"] = "TalonCutthroat",--e?
	  ["JarvanIV"] = "JarvanIVDragonStrike",--Q
	  ["Warwick"] = "InfiniteDuress",--R
	  ["Jax"] = "JaxLeapStrike",--Q
	  ["Yasuo"] = "YasuoRKnockUpComboW",--Q
	  ["Diana"] = "DianaTeleport",
	  ["LeeSin"] = "BlindMonkQTwo",
	  ["Shen"] = "ShenShadowDash",
	  ["Alistar"] = "Headbutt",
	  ["Amumu"] = "BandageToss",
	  ["Urgot"] = "UrgotSwap2",
	  ["Rengar"] = "RengarR",
	}

local InterruptList = 
	{
		["Katarina"    ] = "KatarinaR",
		["Malzahar"    ] = "AlZaharNetherGrasp",
		["Warwick"     ] = "InfiniteDuress",
		["Velkoz"	   ] = "VelkozR",
		["Caitlyn"     ] = "CaitlynAceintheHole",
		["FiddleSticks"] = "Crowstorm",
		["FiddleSticks"] = "DrainChannel",
		["Galio"       ] = "GalioIdolOfDurand",
		["Karthus"     ] = "FallenOne",
		["Lucian"      ] = "LucianR",
		["MissFortune" ] = "MissFortuneBulletTime",
		["Nunu"        ] = "AbsoluteZero",
		["Pantheon"    ] = "Pantheon_GrandSkyfall_Jump",
		["Shen"        ] = "ShenStandUnited",
	}
	
--[[Spell data]]
local Qradius = 80
local Wradius = 255
local Eradius = 80
local Rradius = 410

local AArange = 525
local Qrange = 815
local Erange = 1095

local Qdelay = 0
local Wdelay = 0.25
local Edelay = 0.25
local Rdelay = 0.6

local BallSpeed = 1200--Q
local BallSpeedE = 1700--E

_IGNITE = nil
_AA = 142857

--[[Spell damage]]
local Qdamage = {60, 90, 120, 150, 180}
local Qscaling = 0.5
local Wdamage = {70, 115, 160, 205, 250}
local Wscaling = 0.7
local Edamage = {60, 90, 120, 150, 180}
local Escaling = 0.3
local Rdamage = {150, 225, 300}
local Rscaling = 0.7
local AAdamage = {10, 10, 10, 18, 18, 18, 26, 26, 26, 34, 34, 34, 42, 42, 42, 50, 50, 50}
local AAscaling = 0.15

local MainCombo = {_AA, _AA, _Q, _W, _R, _Q, _IGNITE}
local levelSequence = { 1,2,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3 }
local Far = 1.3

--[[Drawing Circle]]
local Circle_W
local Circle_R

--[[Ball]]
local BallPos = myHero
local BallMoving = false

--[[CDS]]
local QREADY = true
local WREADY = true
local EREADY = true
local RREADY = true
local IGNITEREADY = true
local myRecall =false

--[[VPrediction]]
local VP

local Menu = nil

local SelectedTarget = nil

local DamageToHeros = {}
local lastrefresh = 0
local lastkillcounter = 0

local ComboMode
local _ST, _TF  = 1,2

local LastChampionSpell = {}

--[[Ball location]]
function OnCreateObj(obj)
	--[[Casting Q creates this object when ball lands]]
        if obj.name:lower():find("yomu_ring_green") then
                BallPos = obj
                BallMoving = false
        end
        
        --[[When ball goes out of range it returns to Orianna and creates this object]]
        if (obj.name:lower():find("orianna_ball_flash_reverse")) then
            BallPos = myHero
			BallMoving = false
        end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name:lower():find("orianaizunacommand") then--Q
		BallMoving = true
		DelayAction(function(p) BallPos = Vector(p) end, GetDistance(spell.endPos, BallPos) / BallSpeed - GetLatency()/1000 - 0.35, {Vector(spell.endPos)})
	end

	if unit.isMe and spell.name:lower():find("orianaredactcommand") then--E
		BallMoving = true
		BallPos = spell.target
	end

	if unit.type == "obj_AI_Hero" then
		LastChampionSpell[unit.networkID] = {name = spell.name, time=os.clock()}
	end
end

function OnGainBuff(unit, buff)
	--[[When the ball reaches an ally]]
	if unit.team == myHero.team and buff.name:lower():find("orianaghostself") then
		BallMoving = false
		BallPos = unit
	end

	if unit.isMe then -- myPlayer
		if buff.name:lower():find("recall") and not myRecall then
			myRecall = true
			--PrintChat("recalling..")
		end
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe then -- myPlayer
		if buff.name:lower():find("recall") and myRecall then
			myRecall = false
			--PrintChat("recall cancled.")
		end
	end
end

--[[End of ball location]]
function OnLoad()
	if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
		_IGNITE = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
		_IGNITE = SUMMONER_2
	else
		_IGNITE = nil
	end

	Menu = scriptConfig("Orianna", "Orianna")
	--[[Combo]]

	DManager = DrawManager()
	VP = VPrediction()

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SxOrb:LoadToMenu(Menu.Orbwalking, false)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseRN", "Use R at least in", SCRIPT_PARAM_LIST, 1, { "1 target", "2 targets", "3 targets", "4 targets" , "5 targets"})
		Menu.Combo:addParam("Enabled", "Normal combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)		

	--[[Farming]]
	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 4, { "No", "Freezing", "LaneClear", "Both" })
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freezing", "LaneClear", "Both" })
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 3, { "No", "Freezing", "LaneClear", "Both" })
		Menu.Farm:addParam("ManaCheck", "Don't laneclear if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Freeze", "Farm Freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
	
	--[[Jungle farming]]
	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Enabled", "Farm jungle!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("KillSteal", "KillSteal")
		Menu.KillSteal:addParam("KsEnable", "Smart Auto Kill", SCRIPT_PARAM_ONOFF , true)
		Menu.KillSteal:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.KillSteal:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.KillSteal:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.KillSteal:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.KillSteal:addParam("UseI", "Use Ignite if Killable", SCRIPT_PARAM_ONOFF, true)	
		Menu.KillSteal:addParam("ManaCheck", "Don't AutoKill if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.KillSteal:addParam("Debug", "print chat ks(Debug)", SCRIPT_PARAM_ONOFF, false)	


	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("predType", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "Prodiction", "VPrediction" }) -- Done
		Menu.Misc:addParam("usePackets", "Use Packets to Cast Spells", SCRIPT_PARAM_ONOFF, false) -- Done
		Menu.Misc:addParam("AutoLevel", "Auto Level", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("UseW", "Auto-W if it will hit", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
		Menu.Misc:addParam("UseR", "Auto-ultimate if it will hit", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
		Menu.Misc:addParam("EQ", "Use E + Q if tEQ < %x * tQ", SCRIPT_PARAM_SLICE, 100, 1, 100)
		Menu.Misc:addParam("sheld", "self sheld", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))	
		Menu.Misc:addSubMenu("Auto-E on initiators", "AutoEInitiate")
		local added = false
		for champion, spell in pairs(InitiatorsList) do
			for i, ally in ipairs(GetAllyHeroes()) do
				if ally.charName == champion then
					added = true
					Menu.Misc.AutoEInitiate:addParam(champion..spell, champion.." ("..spell..")", SCRIPT_PARAM_ONOFF, true)
				end
			end
		end
	
		if not added then
			Menu.Misc.AutoEInitiate:addParam("info", "Info", SCRIPT_PARAM_INFO, "Not supported initiators found")
		else
			Menu.Misc.AutoEInitiate:addParam("Active", "Active", SCRIPT_PARAM_ONOFF, true)
		end
		Menu.Misc:addParam("Interrupt", "Auto interrupt important spells", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("BlockR", "Block R if it is not going to hit", SCRIPT_PARAM_ONOFF, true)

	--[[Harassing]]
	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("HpCheck", "Don't harass if Hp < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.Harass:addParam("Enabled2", "Harass (TOGGLE)!", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
		Menu.Harass:addParam("DrawAh", "Draw Auto Harass status on Hp Bar", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("DrawAhPos", "Auto Harass Drawing Position", SCRIPT_PARAM_SLICE, -50, -70, 70)
	
	--[[Drawing]]
	local tempCircle
	Menu:addSubMenu("Drawing", "Drawing")
		Menu.Drawing:addParam("DrawDamage", "Draw damage after combo in healthbars", SCRIPT_PARAM_ONOFF, true)

		DManager:CreateCircle(myHero, AArange + 50, 3, {255, 255, 255, 255}):AddToMenu(Menu.Drawing, "AA Range", true, true, true)	

		tempCircle = DManager:CreateCircle(myHero, Qrange, 3, {255, 255, 255, 255})
			tempCircle:AddToMenu(Menu.Drawing, "Q Range", true, true, true)
			tempCircle:SetDrawCondition(function() return (player:CanUseSpell(_Q) == READY) end)

		Circle_W = DManager:CreateCircle(myHero, Wradius, 3, {255, 255, 255, 255})
			Circle_W:AddToMenu(Menu.Drawing, "W Range", true, true, true)
			Circle_W:SetDrawCondition(function() return (player:CanUseSpell(_W) == READY) end)

		tempCircle = DManager:CreateCircle(myHero, Erange, 3, {255, 255, 255, 255})
			tempCircle:AddToMenu(Menu.Drawing, "E Range", true, true, true)
			tempCircle:SetDrawCondition(function() return (player:CanUseSpell(_E) == READY) end)

		Circle_R = DManager:CreateCircle(myHero, Rradius, 3, {255, 255, 255, 255})
			Circle_R:AddToMenu(Menu.Drawing, "R Range", true, true, true)
			Circle_R:SetDrawCondition(function() return (player:CanUseSpell(_R) == READY) end)
			
	EnemyMinions = minionManager(MINION_ENEMY, Qrange, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, Qrange, myHero, MINION_SORT_MAXHEALTH_DEC)
	
 	
	PrintChat("<font color=\"#81BEF7\">[Orianna] Command: Load succesfully executed!</font>")
end



function GetComboDamage(Combo, Unit)
	local totaldamage = 0
	for i, spell in ipairs(Combo) do
		totaldamage = totaldamage + GetDamage(spell, Unit)
	end
	return totaldamage
end

function GetDamage(Spell, Unit)
	local truedamage = 0
	if Spell == _Q and myHero:GetSpellData(_Q).level ~= 0 then
		truedamage = myHero:CalcMagicDamage(Unit, Qdamage[myHero:GetSpellData(_Q).level] + myHero.ap * Qscaling)
	elseif Spell == _W and myHero:GetSpellData(_W).level ~= 0 and WREADY then
		truedamage = myHero:CalcMagicDamage(Unit, Wdamage[myHero:GetSpellData(_W).level] + myHero.ap * Wscaling)
	elseif Spell == _E and myHero:GetSpellData(_E).level ~= 0 then
		truedamage = myHero:CalcMagicDamage(Unit, Edamage[myHero:GetSpellData(_E).level] + myHero.ap * Escaling)
	elseif Spell == _R and myHero:GetSpellData(_R).level ~= 0 and RREADY then
		truedamage = myHero:CalcMagicDamage(Unit, Rdamage[myHero:GetSpellData(_R).level] + myHero.ap * Rscaling)
	elseif Spell == _AA then
		truedamage = myHero:CalcDamage(Unit, myHero.totalDamage) + myHero:CalcMagicDamage(Unit, AAdamage[myHero.level] + myHero.ap * AAscaling)
	elseif Spell == _IGNITE and _IGNITE and IGNITEREADY then
		truedamage = 50 + 20 * myHero.level
	end
	return truedamage
end

function GetPredictedCastPos(unit, delay, radius, range, speed, from, collision)
	local castpos
	local hitchance
	local pos
	if Menu.Misc.predType == 1 then -- prodiction
		local cp , info = Prodiction.GetPrediction(unit, range, speed, delay, radius, from)
		castpos = cp
		hitchance = info.hitchance
		pos = info.pos
	elseif Menu.Misc.predType == 2 then --vPrediction
		local cp, hc, position = VP:GetLineCastPosition(unit, delay, radius, range, speed, from, collision)
		castpos = cp
		hitchance = hc
		pos = position
	end
	return castpos, hitchance, pos
end

function GetPredictedTargetPos(unit, delay)
	local pos = nil
	if Menu.Misc.predType == 1 then -- prodiction
		pos = Prodiction.GetPredictionTime(unit, delay)
	elseif Menu.Misc.predType == 2 then --vPrediction
		pos = VP:GetPredictedPos(unit, delay)
	end
	return pos
end

--[[Check the number of enemies hit by casting W]]
function CheckEnemiesHitByW()
	local enemieshit = {}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local position = GetPredictedTargetPos(enemy, Wdelay)
		if ValidTarget(enemy) and GetDistance(position, BallPos) <= Wradius and GetDistance(enemy.visionPos, BallPos) <= Wradius then
			table.insert(enemieshit, enemy)
		end
	end
	return #enemieshit, enemieshit
end

--[[Check the number of enemies hit by casting E]]
function CheckEnemiesHitByE(To)
	local enemieshit = {}
	local StartPoint = Vector(BallPos.x, 0, BallPos.z)
	local EndPoint = Vector(To.x, 0, To.z)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local cp, hc, position = GetPredictedCastPos(enemy, Edelay, Eradius, math.huge, BallSpeedE, StartPoint)
		if position then
			local PointInLine, tmp, isOnSegment = VectorPointProjectionOnLineSegment(StartPoint, EndPoint, position)
			if ValidTarget(enemy) and isOnSegment and GetDistance(PointInLine, position) <= (Eradius + VP:GetHitBox(enemy)) and GetDistance(PointInLine, enemy.visionPos) < (Eradius) * 2 + 30 then
				table.insert(enemieshit, enemy)
			end
		end
	end
	return #enemieshit, enemieshit
end

--[[Check number of enemies hit by casting R]]
function CheckEnemiesHitByR()
	local enemieshit = {}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local position = GetPredictedTargetPos(enemy, Rdelay)
		if ValidTarget(enemy) and GetDistance(position, BallPos) <= Rradius and GetDistance(enemy.visionPos, BallPos) <= 1.25 * Rradius  then
			table.insert(enemieshit, enemy)
		end
	end
	return #enemieshit, enemieshit
end

function CastMySpell( spell )
	if Menu.Misc.usePackets and VIP_USER then
		Packet('S_CAST', { spellId = spell }):send()
	else
		CastSpell(spell)
	end
end

function CastQ(target, fast)
	local Speed = BallSpeed * 1.5
	local CastPosition,  HitChance,  Position = GetPredictedCastPos(target, Qdelay, Qradius, math.huge, Speed, BallPos)
	local CastPoint = CastPosition

	if (HitChance < 2) then return false end

	if GetDistance(myHero.visionPos, Position) > Qrange + Wradius + VP:GetHitBox(target) then
		target2 = GetBestTarget(Qrange, target)
		if target2 then
			CastPosition,  HitChance,  Position = GetPredictedCastPos(target2, Qdelay, Qradius, math.huge, Speed, BallPos)
			CastPoint = CastPosition
		else
			do return false end
		end
	end

	if GetDistance(myHero.visionPos, Position) > (Qrange + Wradius + VP:GetHitBox(target))  then
		do return false end
	end

	if EREADY and Menu.Misc.EQ ~= 0 and BallPos ~= myHero then
		local TravelTime = GetDistance(BallPos, CastPoint) / BallSpeed
		local MinTravelTime = GetDistance(myHero, CastPoint) / BallSpeed + GetDistance(myHero, BallPos) / BallSpeedE
		local Etarget = myHero
		for i, ally in ipairs(GetAllyHeroes()) do
			if ValidTarget(ally, Erange, false) then
				local t = GetDistance(ally, CastPoint) / BallSpeed + GetDistance(ally, BallPos) / BallSpeedE
				if t < MinTravelTime then
					MinTravelTime = t
					Etarget = ally
				end
			end
		end
		if MinTravelTime < (Menu.Misc.EQ / 100) * TravelTime and (not Etarget.isMe or GetDistance(BallPos, myHero) > 100) and GetDistance(Etarget) < GetDistance(CastPoint) then
			CastE(Etarget)
			do return false end
		end
	end
	if GetDistanceSqr(myHero.visionPos, CastPoint) < Qrange * Qrange then
		CastSpell(_Q, CastPoint.x, CastPoint.z)
		return true
	else
		CastPoint = Vector(myHero.visionPos) + Qrange * (Vector(CastPoint) - Vector(myHero)):normalized()
		CastSpell(_Q, CastPoint.x, CastPoint.z)
		return true
	end
end

function CastW(enemy)
	if enemy then
		local position = GetPredictedTargetPos(enemy, Wdelay)
		if ValidTarget(enemy) and GetDistance(position, BallPos) <= Wradius and GetDistance(enemy.visionPos, BallPos) <= Wradius then
			CastMySpell( _W)
			return true
		end
	else
		local hitcount, hit = CheckEnemiesHitByW()
		if hitcount >= 1 then
			CastMySpell( _W)
			return true
		end
	end

	return false
end

function CastE(target)
	if target then
		CastSpell(_E, target)
		return true
	end
	return false
end

function CastECH(target, n)
	local hitcount, hit = CheckEnemiesHitByE(target)
	if hitcount >= n then
		CastE(target)
		return true
	end
	return false
end

function CastR(target)
	local position = GetPredictedTargetPos(target, Rdelay)
	if GetDistance(position, BallPos) < Rradius and GetDistance(target, BallPos) < Rradius then
		CastMySpell( _R)
		return true
	end
	return false
end

function CastI(target)
	if _IGNITE and GetDistanceSqr(target) <= 360000  then
		 CastSpell(_IGNITE, target)
		 return true
	end
	return false
end

function GetNMinionsHit(Pos, radius)
	local count = 0
	for i, minion in pairs(EnemyMinions.objects) do
		if GetDistance(minion, Pos) < radius then
			count = count + 1
		end
	end
	return count
end

function GetNMinionsHitE(Pos)
	local count = 0
	local StartPoint = Vector(Pos.x, 0, Pos.z)
	local EndPoint = Vector(myHero.x, 0, myHero.z)
	for i, minion in pairs(EnemyMinions.objects) do
		local position = Vector(minion.x, 0, minion.z)
		local PointInLine = VectorPointProjectionOnLineSegment(StartPoint, EndPoint, position)
		if GetDistance(PointInLine, position) < Eradius then
			count = count + 1
		end
	end
	return count
end

function Farm(Mode)
	if os.clock() <= ((SxOrb.LastAA or 0) + SxOrb:GetWindUpTime())  then return end --Cant move False

	local UseQ
	local UseW
	local UseE

	EnemyMinions:update()
	if Mode == "Freeze" then
		UseQ =  Menu.Farm.UseQ == 2
		UseW =  Menu.Farm.UseW == 2 
		UseE =  Menu.Farm.UseE == 2 
	elseif Mode == "LaneClear" then
		UseQ =  Menu.Farm.UseQ == 3
		UseW =  Menu.Farm.UseW == 3 
		UseE =  Menu.Farm.UseE == 3 
	end
	
	UseQ =  Menu.Farm.UseQ == 4 or UseQ
	UseW =  Menu.Farm.UseW == 4  or UseW
	UseE =  Menu.Farm.UseE == 4 or UseE
	
	if UseQ and QREADY then
		if UseW then
			local MaxHit = 0
			local MaxPos = 0
			for i, minion in pairs(EnemyMinions.objects) do
				if GetDistance(minion) <= Qrange then
					local MinionPos = GetPredictedTargetPos(minion, Qdelay, BallSpeed, BallPos)
					local Hit = GetNMinionsHit(minion, Wradius)
					if Hit >= MaxHit then
						MaxHit = Hit
						MaxPos = MinionPos
					end
				end
			end
			if MaxHit > 0 and MaxPos then
				CastSpell(_Q, MaxPos.x, MaxPos.z)
			end
		else
			for i, minion in pairs(EnemyMinions.objects) do
				local AAdelay = SxOrb:GetAACD() + 0.4 + SxOrb:GetAnimationTime() + SxOrb:GetLatency() + SxOrb:GetFlyTicks(minion) + SxOrb:GetWindUpTime()
				local minionPredictedHealth = VP:GetPredictedHealth(minion, AAdelay)
				if minion.health + 15 < GetDamage(_Q, minion) and ( not ValidTarget(minion, SxOrb.MyRange) or minionPredictedHealth < 20) then
					local MinionPos = GetPredictedTargetPos(minion, Qdelay, BallSpeed, BallPos)
					CastSpell(_Q, MinionPos.x, MinionPos.z)
					break
				end
			end
		end
	end

	if UseW and WREADY then
		local Hit = GetNMinionsHit(BallPos, Wradius)
		if Hit >= 3 then
			CastMySpell( _W)
		end
	end
	
	if UseE and EREADY then
		local Hit = GetNMinionsHitE(BallPos)
		if Hit >= 3 and (not WREADY or not UseW) then
			CastE(myHero)
		end
	end
end

function FarmJungle()
	JungleMinions:update()
	local UseQ = Menu.JungleFarm.UseQ 
	local UseW = Menu.JungleFarm.UseW 
	local UseE = Menu.JungleFarm.UseE 
	
	local Minion = JungleMinions.objects[1] and JungleMinions.objects[1] or nil
	
	if Minion then
		local Position = GetPredictedTargetPos(Minion, Qdelay, BallSpeed, BallPos)
		if UseQ and QREADY then
			CastSpell(_Q, Position.x, Position.z)
		end
		
		if UseW and WREADY and GetDistance(BallPos, Minion) < Wradius then
			CastMySpell( _W)
		end
		
		if UseE and (not WREADY or not UseW) and EREADY and GetDistance(Minion) < 700 then
			local starget = myHero
			local dist = GetDistanceSqr(Minion)
			for i, ally in ipairs(GetAllyHeroes()) do
				local dist2 = GetDistanceSqr(ally, Minion)
				if ValidTarget(ally, Erange, false) and dist2 < dist then
					dist = dist2
					starget = ally
				end
			end
			CastE(starget)
		end
	end
end

function FindBestLocationToQ(target)
	local points = {}
	local targets = {}
	
	local CastPosition,  HitChance,  Position = GetPredictedCastPos(target, Qdelay, Qradius, Qrange, BallSpeed, BallPos)
	table.insert(points, Position)
	table.insert(targets, target)
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Qrange + Rradius) and enemy.networkID ~= target.networkID then
			CastPosition,  HitChance,  Position = GetPredictedCastPos(enemy, Qdelay, Qradius, Qrange, BallSpeed, BallPos)
			table.insert(points, Position)
			table.insert(targets, enemy)
		end
	end
	

	for o = 1, 5 do
		local MECa = MEC(points)
		local Circle = MECa:Compute()
		
		if Circle.radius <= Rradius and #points >= 3 and RREADY then
			return Circle.center, 3
		end
	
		if Circle.radius <= Wradius and #points >= 2 and WREADY then
			return Circle.center, 2
		end
		
		if #points == 1 then
			return Circle.center, 1
		elseif Circle.radius <= (Qradius + 50) and #points >= 1 then
			return Circle.center, 2
		end
		
		local Dist = -1
		local MyPoint = points[1]
		local index = 0
		
		for i=2, #points, 1 do
			if GetDistance(points[i], MyPoint) >= Dist then
				Dist = GetDistance(points[i], MyPoint)
				index = i
			end
		end
		if index > 0 then
			table.remove(points, index)
		end
	end
end


function GetBestTarget(Range, Ignore)
	local LessToKill = 100
	local LessToKilli = 0
	local target = nil
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Range) then
			DamageToHero = myHero:CalcMagicDamage(enemy, 200)
			ToKill = enemy.health / DamageToHero
			if ((ToKill < LessToKill) or (LessToKilli == 0)) and (Ignore == nil or (Ignore.networkID ~= enemy.networkID)) then
				LessToKill = ToKill
				LessToKilli = i
				target = enemy
			end
		end
	end
	
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, Range) and (Ignore == nil or (Ignore.networkID ~= SelectedTarget.networkID)) then
		target = SelectedTarget
	end
	
	return target
end

function OnTickChecks()
	QREADY = (myHero:CanUseSpell(_Q) == READY) or ((myHero:GetSpellData(_Q).currentCd < 0.5) and (myHero:GetSpellData(_Q).level > 0))
	WREADY = (myHero:CanUseSpell(_W) == READY) or ((myHero:GetSpellData(_W).currentCd < 0.5) and (myHero:GetSpellData(_W).level > 0))
	EREADY = (myHero:CanUseSpell(_E) == READY) or ((myHero:GetSpellData(_E).currentCd < 0.5) and (myHero:GetSpellData(_E).level > 0))
	RREADY = (myHero:CanUseSpell(_R) == READY) or ((myHero:GetSpellData(_R).currentCd < 0.5) and (myHero:GetSpellData(_R).level > 0))
	IGNITEREADY = _IGNITE and ( myHero:CanUseSpell(_IGNITE) == READY or (myHero:GetSpellData(_IGNITE).currentCd < 0.5))

	if CountEnemyHeroInRange(Qrange + Rradius, myHero) == 1 then
		ComboMode = _ST
	else
		ComboMode = _TF
	end
	

	RefreshKillableTexts()

	if not VIP_USER and Menu.Misc.predType == 1 then
		Menu.Misc.predType = 2
		PrintChat("You can't use Prodiction as long as you are not a Vip User.")
		--script_Messager("You can't use Prodiction as long as you are not a Vip User.")
	end

	if not VIP_USER and Menu.Misc.usePackets then
		Menu.Misc.usePackets = false
		PrintChat("You can't activate Packet Cast as long as you are not a Vip User.")
		--script_Messager("You can't activate Packet Cast as long as you are not a Vip User.")
	end
	
	if Menu.Misc.AutoLevel then
		autoLevelSetSequence(levelSequence)
	end

	if Menu.Misc.UseW > 1 and WREADY then
		local hitcount, hit = CheckEnemiesHitByW()
		if hitcount >= (Menu.Misc.UseW -1) then
			CastMySpell( _W)
		end		
	end
	
	if Menu.Misc.UseR > 1 and RREADY then
		local hitcount, hit = CheckEnemiesHitByR()
		if (hitcount >= (Menu.Misc.UseR - 1)) and GetDistanceToClosestAlly(BallPos) < Qrange * Far then
			CastMySpell( _R)
		end		
	end
	
	if Menu.Misc.AutoEInitiate.Active and EREADY then
		for i, unit in ipairs(GetAllyHeroes()) do
			if GetDistance(unit) < Erange then
				for champion, spell in pairs(InitiatorsList) do
					if LastChampionSpell[unit.networkID] and LastChampionSpell[unit.networkID].name ~=nil and Menu.Misc.AutoEInitiate[champion.. LastChampionSpell[unit.networkID].name] and (os.clock() - LastChampionSpell[unit.networkID].time < 1.5) then
						CastE(unit)
					end
				end
			end
		end
	end
	
	if Menu.Misc.Interrupt then
		for i, unit in ipairs(GetEnemyHeroes()) do
			for champion, spell in pairs(InterruptList) do
				if GetDistance(unit) <= Qrange and LastChampionSpell[unit.networkID] and spell == LastChampionSpell[unit.networkID].name and (os.clock() - LastChampionSpell[unit.networkID].time < 1) then
					CastSpell(_Q, unit.x, unit.z)
					if GetDistance(BallPos, unit) < Rradius then
						CastMySpell( _R)
					end
				end
			end
		end
	end
end

function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local starget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= minD or starget == nil then
					minD = GetDistance(enemy, mousePos)
					starget = enemy
				end
			end
		end
		
		if starget and minD < 100 then
			if SelectedTarget and starget.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = starget
				print("<font color=\"#FF0000\">Orianna: New target selected: "..starget.charName.."</font>")
			end
		end
	end
end

function Harass(target)
	if Menu.Harass.UseQ and target then
		CastQ(target)
	end
	if Menu.Harass.UseW then
		CastW()
	end
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

function CountAllyHeroInRange(range, point)
	local n = 0
	for i, ally in ipairs(GetAllyHeroes()) do
		if ValidTarget(ally, math.huge, false) and GetDistanceSqr(point, ally) <= range * range then
			n = n + 1
		end
	end
	return n
end

function Combo(target)
	if ComboMode == _ST then--Single Target
		-- if target and ((GetDistanceSqr(target) < 300 * 300) or ((myHero.health/myHero.maxHealth <= 0.25) and (myHero.health/myHero.maxHealth < target.health/target.maxHealth))) then
		-- 	SxOrb:DisableAttacks()
		-- end

		if target and Menu.Combo.UseR and CountEnemyHeroInRange(1000, target) >= CountAllyHeroInRange(1000, target)  then
			if target and GetComboDamage(MainCombo, target) > target.health and GetDistanceToClosestAlly(BallPos) < Qrange * Far then
				local hitcount, hit = CheckEnemiesHitByR()
				if hitcount >= Menu.Combo.UseRN then
					CastR(target)
				end
			end
		end

		if Menu.Combo.UseW then
			CastW()
		end
		
		if Menu.Combo.UseQ and target and QREADY then
			CastQ(target)
		end
		
		if Menu.Combo.UseE then
			for i, ally in ipairs(GetAllyHeroes()) do
				if ValidTarget(ally, math.huge, false) and GetDistance(ally) < Erange and CountEnemyHeroInRange(400, ally) >= 1 and (target == nil or GetDistance(ally, target) < 400) then
					CastE(ally)
				end
			end
		end
		
		if Menu.Combo.UseE then
			CastECH(myHero, 1)
		end
	else
		-- for i, enemy in ipairs(GetEnemyHeroes()) do
		-- 	if ValidTarget(enemy) and (GetDistanceSqr(enemy) < 300 * 300) and (myHero.health/myHero.maxHealth <= 0.25) then
		-- 		SxOrb:DisableAttacks()
		-- 	end
		-- end
		if Menu.Combo.UseR then
			if CountEnemyHeroInRange(800, BallPos) > 1 then
				local hitcount, hit = CheckEnemiesHitByR()
				local potentialkills, kills = 0, 0
				if hitcount >= 2 then
					for i, champion in ipairs(hit) do
						if (champion.health - GetComboDamage(MainCombo, champion)) < 0.4*champion.maxHealth or (GetComboDamage(MainCombo, champion) >= 0.4*champion.maxHealth) then
							potentialkills = potentialkills + 1
						end
						if (champion.health - GetComboDamage(MainCombo, champion)) < 0 then
							kills = kills + 1
						end
					end
				end
				if (((GetDistanceToClosestAlly(BallPos) < Qrange * Far) and ((hitcount >= CountEnemyHeroInRange(800, BallPos))) or (potentialkills >= 2)) or kills >= 1) and hitcount >= Menu.Combo.UseRN then
					CastMySpell( _R)
				end
			elseif Menu.Combo.UseRN == 1 then
				if target and GetComboDamage({_Q, _W, _R}, target) > target.health and GetDistanceToClosestAlly(BallPos) < Qrange * Far then
					CastR(target)
				end
			end
		end
		
		if Menu.Combo.UseW then
			CastW()
		end

		if Menu.Combo.UseQ and target then
			local Qposition, hit = FindBestLocationToQ(target)
			
			if Qposition and hit > 1 then
				CastSpell(_Q, Qposition.x, Qposition.z)
			else
				CastQ(target)
			end
		end
		
		if Menu.Combo.UseE and EREADY then
			if CountEnemyHeroInRange(800, BallPos) <= 2 then
				CastECH(myHero, 1)
			else
				CastECH(myHero, 2)
			end
			
			
			for i, ally in ipairs(GetAllyHeroes()) do
				if ValidTarget(ally, Erange, false) and CountEnemyHeroInRange(300, ally) >= 3 and (target == nil or GetDistance(ally, target) < 300) then
					CastSpell(_E, ally)
				end
			end
		end
	end
end

function KillSteal()
	if ((os.clock() - lastkillcounter) < 0.3)then return end
	lastkillcounter = os.clock()
	for i=1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy, Qrange+Rradius/2)then
			local distance = GetDistanceSqr(enemy)
			local health = enemy.health

			if health < GetComboDamage({_Q}, enemy) and QREADY and Menu.KillSteal.UseQ then
				if CastQ(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate Q") end return end

			elseif health < GetComboDamage({_W}, enemy) and WREADY and Menu.KillSteal.UseW then
				if CastW(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate W") end return end

			elseif health < GetComboDamage({_E}, enemy) and EREADY and Menu.KillSteal.UseE then
				if CastECH(myHero, 1) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate E") end return end

			elseif health < GetComboDamage({_Q, _W}, enemy) and Menu.KillSteal.UseQ and Menu.KillSteal.UseW then
				if QREADY and WREADY then 
					if CastQ(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate Q , W") end return end
				elseif WREADY then
					if CastW(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate W , Q") end return end
				end

			elseif health < GetComboDamage({_R}, enemy) and RREADY and Menu.KillSteal.UseR then
				if CastR(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate R") end return end

			elseif health < GetComboDamage({_Q, _R}, enemy) and Menu.KillSteal.UseQ and Menu.KillSteal.UseR then
				if  QREADY and RREADY then
					if CastQ(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate Q , R") end return end
				elseif RReady then
					if CastR(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate R , Q") end return end
				end

			elseif health < GetComboDamage({_R, _W}, enemy)  and WREADY and RREADY and Menu.KillSteal.UseW and Menu.KillSteal.UseR then
				if CastR(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate R , W") end end
			
			elseif health <= GetComboDamage({_Q, _R, _W}, enemy) and Menu.KillSteal.UseQ and Menu.KillSteal.UseW and Menu.KillSteal.UseR then
				if QREADY and WREADY and RReady then
					if CastQ(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate Q , R , W") end return end
				elseif WREADY and RReady then
					if CastR(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate R , W , Q") end end
				end

			elseif health <= GetComboDamage({_Q, _R, _W, _Q}, enemy) and QREADY and WREADY and RReady and Menu.KillSteal.UseQ and Menu.KillSteal.UseW and Menu.KillSteal.UseR then
				if CastQ(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate Q , R , W , Q") end return end
			
			elseif health < GetComboDamage({_IGNITE}, enemy) and IGNITEREADY and Menu.KillSteal.UseI then
				if CastI(enemy)then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate IGNITE") end return end 
			
			elseif health < GetComboDamage({_IGNITE, _Q}, enemy) and IGNITEREADY and QREADY and Menu.KillSteal.UseI and Menu.KillSteal.UseQ then
				if CastI(enemy)then if CastQ(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate IGNITE , Q") end return end end

			elseif health < GetComboDamage({_IGNITE, _W}, enemy) and IGNITEREADY and WREADY and Menu.KillSteal.UseI and Menu.KillSteal.UseW then
				if CastW(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate IGNITE , W") end return end

			elseif health < GetComboDamage({_IGNITE, _R}, enemy) and IGNITEREADY and RREADY and Menu.KillSteal.UseI and Menu.KillSteal.UseR then
				if CastR(enemy) then if Menu.KillSteal.Debug then PrintChat(enemy.charName.. " KS activate IGNITE , R") end return end
			end

		end
	end
end

function OnTick()
	if myHero.dead then return end

	OnTickChecks()
	SxOrb:EnableAttacks()

	local target = GetBestTarget(Qrange + Qradius)
	if not target then
		target = GetBestTarget(Qrange + Qradius * 2)
	end

	if Menu.Misc.sheld then 
		CastE(myHero)
	end

	if Menu.Combo.Enabled then
		if target and SxOrb:ValidTarget(target, SxOrb.MyRange) then
			SxOrb:ForceTarget(target)
		end
		Combo(target)
	elseif (Menu.Harass.Enabled or Menu.Harass.Enabled2) and (Menu.Harass.ManaCheck <= (myHero.mana / myHero.maxMana * 100)) and (Menu.Harass.HpCheck <= (myHero.health / myHero.maxHealth * 100)) and not myRecall then
		if target and SxOrb:ValidTarget(target, SxOrb.MyRange) and Menu.Harass.Enabled then
			SxOrb:ForceTarget(target)
		end
		Harass(target)
	else

	end
	if Menu.KillSteal.KsEnable and (Menu.KillSteal.ManaCheck <= (myHero.mana / myHero.maxMana * 100)) then
		KillSteal()
	end

	if Menu.Farm.Freeze or Menu.Farm.LaneClear then
		local Mode = Menu.Farm.Freeze and "Freeze" or "LaneClear"
		if Menu.Farm.ManaCheck >= (myHero.mana / myHero.maxMana * 100) then
			Mode = "Freeze"
		end

		Farm(Mode)
	end
	
	if Menu.JungleFarm.Enabled then
		FarmJungle()
	end
end


function OnSendPacket(p)
	if Menu.Misc.BlockR and p.header == Packet.headers.S_CAST then
		local packet = Packet(p)
		if packet:get('spellId') == _R then
			local hitnumber, hit = CheckEnemiesHitByR()
			if hitnumber == 0 then
				p:Block()
			end
		end
	end
end
--[[Drawing stuff: ]]

--[[Update the bar texts]]
function RefreshKillableTexts()
	if ((os.clock() - lastrefresh) > 0.3) and Menu.Drawing.DrawDamage then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				DamageToHeros[i] =  GetComboDamage(MainCombo, enemy) 
			end
		end
		lastrefresh = os.clock()
	end
end
	
--[[	Credits to zikkah	]]

function DrawOnHPBar(enemy, damage)
    local SPos, EPos = GetEnemyHPBarPos(enemy)

    -- Validate data
    if not SPos then return end

    local barwidth = EPos.x - SPos.x
    local Position = SPos.x + math.max(0, (enemy.health - damage) / enemy.maxHealth) * barwidth

    DrawText("|", 16, math.floor(Position), math.floor(SPos.y + 8), ARGB(255,0,255,0))
    DrawText("HP: "..math.floor(enemy.health - damage), 13, math.floor(SPos.x), math.floor(SPos.y), (enemy.health - damage) > 0 and ARGB(255, 0, 255, 0) or  ARGB(255, 255, 0, 0))

end

function OnDraw()	
	if myHero.dead then return end
	if Circle_W and Circle_W.enabled then
		Circle_W.position = BallPos
	end

	if Circle_R and Circle_R.enabled then
		Circle_R.position = BallPos
	end
	if Menu.Harass.DrawAh then
		if Menu.Harass.Enabled2 then
			local pos = GetUnitHPBarPos(myHero)
			pos.x = math.floor(pos.x) - 30
			pos.y = math.floor(pos.y) + Menu.Harass.DrawAhPos

			DrawText(tostring("Auto Harass"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
			DrawText(tostring("Auto Harass"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
		end
	end
	--[[HealthBar HP tracker]]
	if Menu.Drawing.DrawDamage then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				if DamageToHeros[i] ~= nil then
					DrawOnHPBar(enemy, math.floor(DamageToHeros[i]))
				end
			end
		end
	end
end
