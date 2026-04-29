local nextHallucination = 0
local horrorActive = true
local sanity = 100
local heartBeatSound = nil


hook.Add("RenderScreenspaceEffects", "HorrorAtmosphere", function()
    if not horrorActive then return end

    local sanityRatio = (100 - sanity) / 100
    local tab = {
        [ "$pp_colour_addr" ] = 0,
        [ "$pp_colour_addg" ] = 0,
        [ "$pp_colour_addb" ] = 0,
        [ "$pp_colour_brightness" ] = -0.15 - (sanityRatio * 0.1), 
        [ "$pp_colour_contrast" ] = 1.1 + (sanityRatio * 0.5),
        [ "$pp_colour_colour" ] = 0.4 - (sanityRatio * 0.3),
        [ "$pp_colour_mulr" ] = 0,
        [ "$pp_colour_mulg" ] = 0,
        [ "$pp_colour_mulb" ] = 0
    }
    DrawColorModify(tab)
    

    if sanity < 50 then
        DrawMotionBlur(0.1, 0.5 * sanityRatio, 0.05)
        DrawSharpen(1.2 * sanityRatio, 0.5)
    end
end)


hook.Add("Think", "ShadowStalker", function()
    if CurTime() < nextHallucination then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local lightLevel = render.GetLightColor(ply:GetPos()):Length()


    if lightLevel < 0.05 then
        sanity = math.Clamp(sanity - 0.05, 0, 100)
    else
        sanity = math.Clamp(sanity + 0.02, 0, 100)
    end

    if lightLevel < 0.1 and math.random(1, 500) == 1 then
        local angle = ply:EyeAngles()
        angle.y = angle.y + math.random(140, 220)
        local spawnPos = ply:GetPos() + angle:Forward() * 300
        
        local ghost = ClientsideModel("models/combine_monitors/monitors_wrecked04.mdl")
        ghost:SetPos(spawnPos + Vector(0, 0, 10))
        ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
        ghost:SetColor(Color(0, 0, 0, 255))
        ghost:SetModelScale(1.5, 0)
        

        timer.Create("GhostTwitch"..ghost:EntIndex(), 0.05, 10, function()
            if IsValid(ghost) then ghost:SetPos(ghost:GetPos() + Vector(0,0, math.sin(CurTime()*10))) end
        end)

        timer.Simple(0.8, function() 
            if IsValid(ghost) then 
                ghost:Remove() 

                sound.Play("ambient/voices/faint_fly.wav", spawnPos, 75, 70, 0.6)
            end 
        end)

        nextHallucination = CurTime() + (sanity * 0.2)
    end
end)


timer.Create("HorrorSounds", 12, 0, function()
    local ply = LocalPlayer()
    local sounds = {
        "ambient/creatures/town_child_scream1.wav",
        "npc/stalker/breathing3.wav",
        "ambient/voices/whisper1.wav",
        "ambient/voices/whisper6.wav",
        "ambient/materials/footstep_slate_01.wav",
        "npc/zombie/zombie_voice_idle7.wav"
    }
    

    local pos = ply:GetPos() - (ply:GetForward() * 50) + (ply:GetRight() * math.random(-50, 50))
    sound.Play(table.Random(sounds), pos, 60, math.random(80, 110), 0.5)
end)


hook.Add("Think", "HeartbeatLogic", function()
    if sanity < 40 then
        if not heartBeatSound then
            heartBeatSound = CreateSound(LocalPlayer(), "player/heartbeat1.wav")
            heartBeatSound:Play()
        end
        heartBeatSound:ChangePitch(math.Clamp(140 - sanity, 100, 150), 0.1)
        heartBeatSound:ChangeVolume(math.Clamp(1 - (sanity/40), 0, 1), 0.1)
    elseif heartBeatSound then
        heartBeatSound:Stop()
        heartBeatSound = nil
    end
end)


timer.Create("Poltergeist", 15, 0, function()
    local ply = LocalPlayer()
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
        if ent:GetClass() == "prop_physics" and math.random(1, 3) == 1 then
            ent:EmitSound("physics/wood/wood_box_impact_soft1.wav", 60, 90)
            -- Visual twitch only (clientside)
            ent:SetRenderAngles(ent:GetRenderAngles() + Angle(2, 2, 2))
        end
    end
    

    render.RedownloadAllLightmaps(true)
end)


hook.Add("Think", "VoidStare", function()
    local ply = LocalPlayer()
    local tr = ply:GetEyeTrace()
    
    if tr.HitNoWorld and tr.Fraction < 0.1 then
         if math.random(1, 1000) == 666 then
            util.ScreenShake(ply:GetPos(), 5, 5, 0.5, 500)
            ply:EmitSound("npc/stalker/go_alert2.wav", 100, 80)
         end
    end
end)