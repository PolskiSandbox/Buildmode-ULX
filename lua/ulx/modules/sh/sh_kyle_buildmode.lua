local function _kyle_Buildmode_Enable(z)
    z:SendLua("GAMEMODE:AddNotify(\"Włączono tryb budowania (masz goda i nie możesz zabijać), !pvp aby wyłączyć.\",NOTIFY_GENERIC, 8)")
	if z:Alive() then
		ULib.getSpawnInfo( z )
		if _Kyle_Buildmode["restrictweapons"]=="1" then
			z:StripWeapons()
			for x,y in pairs(_Kyle_Buildmode["buildloadout"]) do
				z:Give(y)
			end
		end
	end
	z.buildmode = true
	z:SetNWBool("_Kyle_Buildmode",true)
	z:SetNWBool("_Kyle_BuildmodeOnSpawn",z:GetNWBool("_kyle_died"))
end

local function _kyle_Buildmode_Disable(z)
	if z:Alive() then
		local pos = z:GetPos()

		if _Kyle_Buildmode["killonpvp"]=="1" and z:InVehicle() then
			z:ExitVehicle()
		end

		if _Kyle_Buildmode["restrictweapons"]=="1" and not z:GetNWBool("_Kyle_BuildmodeOnSpawn") then
			ULib.spawn( z, true ) --Returns the player to spawn with the weapons they had before entering buildmode
		end

		if _Kyle_Buildmode["killonpvp"]=="1" then
			ULib.spawn( z, false)  --Returns the player to spawn
		end

		if _Kyle_Buildmode["restrictweapons"]=="1" and z:GetNWBool("_Kyle_BuildmodeOnSpawn") then
			z:ConCommand("kylebuildmode defaultloadout") --called when buildmode is disabled after spawning with it enabled
		end

		if _Kyle_Buildmode["killonpvp"]=="0" then
			z:SetPos( pos ) --Returns the player to where they where when they disabled buildmode
		end

		if 	z:GetNWBool("kylenocliped") then
			z:ConCommand( "noclip" ) --called when the player had noclip while in buildmode
		end
	end

	z.buildmode = false
	z:SendLua("GAMEMODE:AddNotify(\"Włączono tryb PVP (możesz strzelać się z innymi graczami w PVP), !build aby wyłączyć.\",NOTIFY_GENERIC, 5)")
	z:SetNWBool("_Kyle_Buildmode",false)
end

hook.Add("HUDPaint", "KyleBuildmodehalos", function()


		for y,z in pairs(player.GetAll()) do
			z.buildmode = z:GetNWBool("_Kyle_Buildmode",false)
		end
    LocalPlayer().buildmode = LocalPlayer():GetNWBool("_Kyle_Buildmode",false)
end)

function DrawNameTitle(players,texter,col)
	local textalign = 1
	local distancemulti = 2
	local vStart = LocalPlayer():GetPos()
	local vEnd
	for k, v in pairs(players) do

		if v:Alive() then

			local vStart = LocalPlayer():GetPos()
			local vEnd = v:GetPos() + Vector(0,0,40)
			local trace = util.TraceLine( {
				start = vStart,
				endpos = vEnd,
				filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
			} )
			if trace.Entity != NULL then
				--Do nothing!
			else
				local mepos = LocalPlayer():GetPos()
				local tpos = v:GetPos()
				local tdist = mepos:Distance(tpos)

				if tdist <= 1000 then
					local zadj = 0.03334 * tdist
					local pos = v:GetPos() + Vector(0,0,v:OBBMaxs().z + 5 + zadj)
					pos = pos:ToScreen()

					local alphavalue = (600 * distancemulti) - (tdist/1.5)
					alphavalue = math.Clamp(alphavalue, 0, 255)

					local outlinealpha = (450 * distancemulti) - (tdist/2)
					outlinealpha = math.Clamp(outlinealpha, 0, 255)


					local playercolour = Color(255,255,255)
					titlefont = "Coolvetica20"
					if v!=LocalPlayer() then
						draw.SimpleTextOutlined(texter, titlefont, pos.x, pos.y + 6, col,textalign,1,1,Color(0,0,0,outlinealpha))
					end
				end
			end
		end
	end
end

--VERY EXPERIMENTAL ANTI-PROPMINGE CODE BELOW
--IF USED, EXPECT BUGS AND CRASHES
--[[
hook.Add("PhysgunPickup", "KylebuildmodePropKill", function(y,z)
	if IsValid(z) and (not z:IsPlayer()) and y.buildmode and _Kyle_Buildmode["antipropkill"]=="1" then
		z:SetNWInt("RenderMode", z:GetRenderMode())
		z:SetNWInt("Alpha", z:GetColor()["a"])
		z:SetColor( Color( z:GetColor()["r"], z:GetColor()["g"], z:GetColor()["b"], 200 ) )
		z:SetRenderMode(1)
		z:SetCustomCollisionCheck(true)
		z:SetNWBool("NoCollide", true)
	end
end)

local function UnNoclip(z)
	z:SetNWBool("Colliding", false)
	timer.Simple( 0.1, function()
		if not z:GetNWBool("Colliding") and z:IsValid() then
			z:SetNWBool("NoCollide", false)
			z:SetColor( Color( z:GetColor()["r"], z:GetColor()["g"], z:GetColor()["b"], z:GetNWInt("Alpha") ) )
			z:SetRenderMode(z:GetNWInt("RenderMode"))
		elseif z:IsValid() then
			UnNoclip(z)
		end
	end )
end

hook.Add("PhysgunDrop", "KylebuildmodePropKill", function(y,z)
	if IsValid(z) and (not z:IsPlayer()) and y.buildmode and _Kyle_Buildmode["antipropkill"]=="1" then
		z:SetPos(z:GetPos())
		UnNoclip(z)
	end
end)

hook.Add("ShouldCollide", "Kylebuildmodetrycollide", function(y, z)
	print(y, y:GetNWBool("_Kyle_Buildmode"))
	print(z, z:GetNWBool("_kyle_Buildmode"))

	if (y:IsPlayer() or z:IsPlayer()) and _Kyle_Buildmode["antipropkill"]=="1" then

		if y:IsPlayer() then
			z:SetNWBool("Colliding", true)
			if z:IsVehicle() then
							print("a")

				if y.buildmode  or z:GetDriver().buildmode  then
					return false
				end
			end
		else
			y:SetNWBool("Colliding", true)
			if y:IsVehicle() then
				print("a")
				if z.buildmode  then
					return false
				end
			end
		end

		if (y:GetNWBool("NoCollide") or z:GetNWBool("NoCollide")) then
			return false
		end
	end
end)
]]

hook.Add("PlayerNoClip", "KylebuildmodeNoclip", function(y,z)
	if _Kyle_Buildmode["allownoclip"]=="1" then
		y:SetNWBool("kylenocliped", z)
    if  z == false or y.buildmode then else
      if SERVER then
      y:SendLua([[notification.AddLegacy("Nie mozesz uzywac noclipa w trybie PVP (wpisz !build aby zmienic)",0,4)]])
    end
    end
		return z == false or y.buildmode
	end
end )

hook.Add("PlayerSpawn", "kyleBuildmodePlayerSpawn",  function(z)
	if (_Kyle_Buildmode["spawnwithbuildmode"]=="1" or z:GetNWBool("_Kyle_Buildmode")) and z:GetNWBool("_kyle_died") then
		_kyle_Buildmode_Enable(z)
	end
	z:SetNWBool("_kyle_died", false)
end )

hook.Add("PlayerInitialSpawn", "kyleBuildmodePlayerInitilaSpawn", function (z)
	if _Kyle_Buildmode["spawnwithbuildmode"]=="1" then
		_kyle_Buildmode_Enable(z)
	end
end )

hook.Add("PostPlayerDeath", "kyleBuildmodePostPlayerDeath",  function(z)
	z:SetNWBool("_kyle_died", true)
end )

hook.Add("PlayerGiveSWEP", "kyleBuildmodeTrySWEPGive", function(y,z)
     if y.buildmode and _Kyle_Buildmode["restrictweapons"]=="1" and not table.HasValue( _Kyle_Buildmode["buildloadout"], z ) then
        y:SendLua("GAMEMODE:AddNotify(\"You cannot give yourself weapons while in Buildmode.\",NOTIFY_GENERIC, 5)")
	  return false
    end
end)

hook.Add("PlayerSpawnSWEP", "kyleBuildmodeTrySWEPSpawn", function(y,z)
    if y.buildmode and _Kyle_Buildmode["restrictweapons"]=="1" and not table.HasValue( _Kyle_Buildmode["buildloadout"], z ) then
        y:SendLua("GAMEMODE:AddNotify(\"You cannot spawn weapons while in Buildmode.\",NOTIFY_GENERIC, 5)")
		return false
    end
end)

hook.Add("EntityTakeDamage", "kyleBuildmodeTryTakeDamage", function(y,z)
  local att = z:GetAttacker()
  --print(att)
  local shoulddmg =  y.buildmode or att.buildmode
  if y:IsPlayer() and att:IsPlayer() then
  if att != v and att != nil and att:IsPlayer() and y.buildmode == true then
att:SendLua([[
  if LocalPlayer().buildmode == true then
  --GAMEMODE:AddNotify("Nie możesz zabijać graczy będąc w trybie Budowania.",NOTIFY_GENERIC, 5)
else
  GAMEMODE:AddNotify("Nie możesz zabijać graczy będących w trybie Budowania.",NOTIFY_GENERIC, 5)
end
  ]])
end
end
  if not att.buildmode and y.buildmode then att:TakeDamage(z:GetDamage(),nil,nil) end
  return shoulddmg
end)

hook.Add("PlayerCanPickupWeapon", "kyleBuildmodeTrySWEPPickup", function(y,z)
    if y.buildmode and _Kyle_Buildmode["restrictweapons"]=="1" and not table.HasValue( _Kyle_Buildmode["buildloadout"], string.Split(string.Split(tostring(z),"][", true)[2],"]", true)[1]) then
        if y:GetNWBool("_kyle_buildNotify")then
			y:SetNWBool("_kyle_buildNotify", true)
            y:SendLua("GAMEMODE:AddNotify(\"You cannot pick up weapons while in Build Mode.\",NOTIFY_GENERIC, 5)")
            timer.Create( "_kyle_NotifyBuildmode", 5, 1, function()
                y:SetNWBool("_kyle_buildNotify", false)
            end)
	   end
	   return false
    end
end)

local CATEGORY_NAME = "_Kyle_1"
local buildmode = ulx.command( "_Kyle_1", "ulx build", function( calling_ply, target_plys, should_revoke )
    local affected_plys = {}
	for y,z in pairs(target_plys) do
        if not z.buildmode and not should_revoke then
			_kyle_Buildmode_Enable(z)
        elseif z.buildmode and should_revoke then
            _kyle_Buildmode_Disable(z)
        end
        table.insert( affected_plys, z )
	end

	if should_revoke then
		ulx.fancyLogAdmin( calling_ply, "#A revoked Buildmode from #T", affected_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A granted Buildmode upon #T", affected_plys )
	end
end, "!build" )
buildmode:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional}
buildmode:defaultAccess( ULib.ACCESS_ALL )
buildmode:addParam{ type=ULib.cmds.BoolArg, invisible=true }
buildmode:help( "Grants Buildmode to target(s)." )
buildmode:setOpposite( "ulx pvp", {_, _, true}, "!pvp" )
