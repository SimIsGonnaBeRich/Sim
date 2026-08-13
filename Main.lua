local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PacketRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PacketRemote")

local Alive

getgenv().Settings = getgenv().Settings or {
    SelectedWeapon = "None",
    SilentAim = false,
    AutoFire = false,
    GunModification = false,
    AutoReadyUp = false,
    AutoUseAmmoBox = false,
    AutoMoveToAmmoBox = false,
    AutoRefillAmmoBox = false,
    AutoUpgradeAmmoBox = false,
    MaxHeadHunter = false,
    AutoPrestige = false,
    RunAndGun = false,
    ForceOpenShop = false,
    RemoveFirstNightLimit =false,
    AutoVote = "None",
}

do -- NetworkHook
    if not getgenv().NetworkHooked then
        getgenv().NetworkHooked = true
        local oldIdentity = getthreadidentity and getthreadidentity() or 8
        if setthreadidentity then setthreadidentity(2) end
        local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
        local localManager = playerScripts and playerScripts:WaitForChild("LocalManager")
        local networkManagerScript = localManager and localManager:WaitForChild("NetworkManager")
        local NetworkManager = require(networkManagerScript)
        if setthreadidentity then setthreadidentity(oldIdentity) end
        local OldPassData
        OldPassData = hookfunction(NetworkManager.PassData, function(self, action, packetData, ...)
            if action == "WeaponAttack" then
                local attackInfo = packetData and packetData[3]
                if type(attackInfo) == "table" then
                    for key in next, attackInfo do
                        if type(key) == "string" and #key == 8 and key:match("^%x+$") then
                            rawset(attackInfo, key, nil)
                        end
                    end
                end
            end
            return OldPassData(self, action, packetData, ...)
        end)
    end
end

do -- Alive
    Alive = function()
        local alive = LocalPlayer:FindFirstChild("Alive")
        return alive and alive.Value or false
    end
end

do -- TimeManager
    local TimeManager = {}
    TimeManager.CachedLabel = nil

    function TimeManager.GetTime()
        if TimeManager.CachedLabel and TimeManager.CachedLabel.Parent then
            return TimeManager.CachedLabel.Text
        end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
        local gameFrame = screenGui and screenGui:FindFirstChild("GameFrame")
        local core = gameFrame and gameFrame:FindFirstChild("Core")
        local playerFrame = core and core:FindFirstChild("PlayerFrame")
        local time = playerFrame and playerFrame:FindFirstChild("Time")
        if time then
            TimeManager.CachedLabel = time
            return time.Text
        end
        return nil
    end
    
    function TimeManager.InTime(startTime, endTime)
        local currentTime = TimeManager.GetTime()
        if not currentTime or type(currentTime) ~= "string" then return false end
        if startTime <= endTime then
            return currentTime >= startTime and currentTime <= endTime
        else
            return currentTime >= startTime or currentTime <= endTime
        end
    end

    getgenv().TimeManager = TimeManager
end

do -- AutoEquip
    if getgenv().AutoEquipConnections then
        for _, connection in pairs(getgenv().AutoEquipConnections) do 
            connection:Disconnect() 
        end
    end
    getgenv().AutoEquipConnections = {}
    
    getgenv().AutoEquipLastTick = 0
    
    getgenv().GetWeaponList = function()
        local weaponList = {"None"}
        local weaponHash = {["None"] = true}
        local parentsToSearch = {LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}
        for _, parent in ipairs(parentsToSearch) do
            if parent then
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("Tool") and not weaponHash[child.Name] then
                        weaponHash[child.Name] = true
                        table.insert(weaponList, child.Name)
                    end
                end
            end
        end
        return weaponList
    end

    getgenv().UpdateWeaponDropdown = function()
        if not getgenv().WeaponDropdown then return end
        local weaponList = getgenv().GetWeaponList()
        getgenv().WeaponDropdown:Refresh(weaponList, true)
    end

    getgenv().SelectWeapon = function(Option)
        local selectedWeapon = type(Option) == "table" and Option[1] or Option
        getgenv().Settings.SelectedWeapon = selectedWeapon
    end

    local function SetupEquipEvents(character)
        local backpack = LocalPlayer:WaitForChild("Backpack")
        if not backpack then return end
        if type(getgenv().AutoEquipConnections) ~= "table" then return end
        
        table.insert(getgenv().AutoEquipConnections, backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then getgenv().UpdateWeaponDropdown() end
        end))
        table.insert(getgenv().AutoEquipConnections, backpack.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then getgenv().UpdateWeaponDropdown() end
        end))
    end

    if LocalPlayer.Character then 
        task.spawn(SetupEquipEvents, LocalPlayer.Character) 
    end
    table.insert(getgenv().AutoEquipConnections, LocalPlayer.CharacterAdded:Connect(SetupEquipEvents))

    local function EnforceAutoEquip()
        if not Alive() then return end
        local selectedWeapon = getgenv().Settings.SelectedWeapon
        if not selectedWeapon or selectedWeapon == "None" then return end
        
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        local currentTool = character:FindFirstChildOfClass("Tool")
        if currentTool and currentTool.Name == selectedWeapon then return end
        
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local targetTool = backpack and backpack:FindFirstChild(selectedWeapon)
        
        if targetTool then
            if targetTool:FindFirstChild("OtherValues") and targetTool:FindFirstChild("CurrentValues") then
                if os.clock() - getgenv().AutoEquipLastTick > 0.25 then
                    getgenv().AutoEquipLastTick = os.clock()
                    humanoid:EquipTool(targetTool)
                end
            end
        end
    end

    table.insert(getgenv().AutoEquipConnections, RunService.Heartbeat:Connect(EnforceAutoEquip))
end

do -- TargetManager
    if getgenv().TargetManager and getgenv().TargetManager.Connection then
        getgenv().TargetManager.Connection:Disconnect()
    end

    local TargetManager = {}
    TargetManager.CurrentTarget = nil
    TargetManager.Connection = nil
    TargetManager.LastTick = 0
    
    local PRIORITY_SETTING = {
        SniperZombie = 10,
        Boss = 9,
        Hunter = 8,
        Berserker = 7,
        Destroyer = 7,
        ToxicZombie = 5,
        GuardianZombie = 2
    }

    local function Update()
        local currentTick = os.clock()
        if currentTick - TargetManager.LastTick < 0.05 then return end
        TargetManager.LastTick = currentTick
        if not Alive() or getgenv().TimeManager.InTime("06:30", "18:00") then
            TargetManager.CurrentTarget = nil
            return
        end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not humanoidRootPart then
            TargetManager.CurrentTarget = nil
            return
        end
        local ZombiesFolder = Workspace:FindFirstChild("Zombies")
        if not ZombiesFolder then
            TargetManager.CurrentTarget = nil
            return
        end
        local humanoidRootPartPosition = humanoidRootPart.Position
        local targetPriority = 0
        local targetDistance = math.huge
        local targetZombie = nil
        for _, zombie in ZombiesFolder:GetChildren() do
            local zombieHumanoid = zombie:FindFirstChildOfClass("Humanoid")
            local targetPart = zombie:FindFirstChild("Head") or zombie:FindFirstChild("HumanoidRootPart")
            if not targetPart or zombie:FindFirstChild("ForceField") or (zombieHumanoid and zombieHumanoid.Health <= 0) then 
                continue
            end
            if zombie.Name == "SwampGiant" then
                continue
            end
            local priority = PRIORITY_SETTING[zombie.Name] or 1
            local distance = (targetPart.Position - humanoidRootPartPosition).Magnitude
            if priority > targetPriority then
                targetPriority = priority
                targetDistance = distance
                targetZombie = targetPart
            elseif priority == targetPriority and distance < targetDistance then
                targetDistance = distance
                targetZombie = targetPart
            end
        end 
        TargetManager.CurrentTarget = targetZombie
    end
    
    function TargetManager.Start()
        if TargetManager.Connection then return end
        TargetManager.Connection = RunService.Heartbeat:Connect(Update)
    end
    
    function TargetManager.Stop()
        if TargetManager.Connection then
            TargetManager.Connection:Disconnect()
            TargetManager.Connection = nil
        end
        TargetManager.CurrentTarget = nil
    end

    getgenv().TargetManager = TargetManager
end

do -- SilentAim
    local SilentAim = {}
    SilentAim.IsHooked = false

    function SilentAim.Start()
        if getgenv().SilentAimHooked then return end
        getgenv().SilentAimHooked = true
        local OldNamecall
        OldNamecall = hookmetamethod(game, "__namecall", function(self, packetData, ...)
            local method = getnamecallmethod()
            if method ~= "FireServer" or self ~= PacketRemote then
                return OldNamecall(self, packetData, ...)
            end
            local settings = getgenv().Settings
            if not (settings and settings.SilentAim) or type(packetData) ~= "table" or not packetData.WeaponAttack then
                return OldNamecall(self, packetData, ...)
            end
            local attackInfo = packetData.WeaponAttack[1]
            if not (attackInfo and attackInfo[3]) then
                return OldNamecall(self, packetData, ...)
            end
            local targetManager = getgenv().TargetManager
            local targetZombie = targetManager and targetManager.CurrentTarget
            if not targetZombie or not targetZombie.Parent then
                return OldNamecall(self, packetData, ...)
            end
            if not attackInfo[2] then attackInfo[2] = {} end
            local bulletCount = math.max(1, #attackInfo[2])
            local targetPosition = targetZombie.Position
            for i = 1, bulletCount do
                attackInfo[2][i] = {targetZombie, targetPosition, true}
            end
            attackInfo[3].RayOriginPos = targetPosition
            packetData.CharPos = targetPosition
            packetData.LookPos = targetPosition
            if attackInfo[3].CriticalRolls then
                for i = 1, bulletCount do
                    attackInfo[3].CriticalRolls[i] = true
                end
            end
            if attackInfo[3].SuperCritRolls then
                for i = 1, bulletCount do
                    attackInfo[3].SuperCritRolls[i] = true
                end
            end
            return OldNamecall(self, packetData, ...)
        end)
    end
    
    getgenv().SilentAim = SilentAim
end

do -- AutoFire
    if getgenv().AutoFire then
        if getgenv().AutoFire.Connection then
            getgenv().AutoFire.Connection:Disconnect()
        end
        if getgenv().AutoFire.InputConnection then
            getgenv().AutoFire.InputConnection:Disconnect()
        end
    end

    local AutoFire = {}
    AutoFire.InputConnection = nil
    AutoFire.CachedButton = nil
    AutoFire.Connections = {Down = nil, Up = nil, Ended = nil}
    AutoFire.Connection = nil
    AutoFire.IsFiring = false
    AutoFire.LastTime = nil
    AutoFire.LastTool = nil
    AutoFire.LastTick = 0
    AutoFire.LastButtonCheckTick = 0

    local function GetAttackButton()
        local currentTick = os.clock()
        local forceRefresh = false
        
        if currentTick - AutoFire.LastButtonCheckTick >= 0.5 then
            AutoFire.LastButtonCheckTick = currentTick
            forceRefresh = true
        end

        local currentCharacter = LocalPlayer.Character
        local currentTool = currentCharacter and currentCharacter:FindFirstChildOfClass("Tool")
        
        if currentCharacter ~= AutoFire.LastCharacter or currentTool ~= AutoFire.LastTool or forceRefresh then
            AutoFire.LastCharacter = currentCharacter
            AutoFire.LastTool = currentTool
            AutoFire.CachedButton = nil
            AutoFire.Connections = { Down = nil, Up = nil, Ended = nil }
        end
        
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
        local touchControls = screenGui and screenGui:FindFirstChild("TouchControls")
        local rightSide = touchControls and touchControls:FindFirstChild("RightSide")
        local attackButton = rightSide and rightSide:FindFirstChild("AttackButton")
        
        if AutoFire.CachedButton and not AutoFire.CachedButton:IsDescendantOf(game) then
            AutoFire.CachedButton = nil
            AutoFire.Connections = {Down = nil, Up = nil, Ended = nil}
        end
        
        if attackButton and attackButton ~= AutoFire.CachedButton then
            AutoFire.CachedButton = attackButton
            local downConnections = getconnections and getconnections(attackButton.MouseButton1Down)
            if downConnections and #downConnections > 0 then
                AutoFire.CachedButton = attackButton
                AutoFire.Connections.Down = downConnections
                pcall(function()
                    AutoFire.Connections.Up = getconnections(attackButton.MouseButton1Up)
                    AutoFire.Connections.Ended = getconnections(attackButton.InputEnded)
                end)
            end
        end
        return AutoFire.CachedButton
    end

    local function SafeClick(connections)
        if type(connections) ~= "table" then return end
        for _, connection in ipairs(connections) do
            if connection.Fire then 
                pcall(function() connection:Fire() end) 
            end
        end
    end

    local function StopFiring()
        if not AutoFire.IsFiring then return end
        AutoFire.IsFiring = false
        if GetAttackButton() then
            SafeClick(AutoFire.Connections.Ended)
            SafeClick(AutoFire.Connections.Up)
        end
    end

    local function Update()
        local currentTick = os.clock()
        if currentTick - AutoFire.LastTick < 0.05 then return end
        AutoFire.LastTick = currentTick
        local currentTime = getgenv().TimeManager.GetTime()
        if currentTime == "18:00" and AutoFire.LastTime ~= "18:00" then
            AutoFire.CachedButton = nil
            AutoFire.Connections = {Down = nil, Up = nil, Ended = nil}
            AutoFire.LastTool = nil
        end
        AutoFire.LastTime = currentTime
        if not Alive() then 
            StopFiring()
            AutoFire.CachedButton = nil
            AutoFire.Connections = {Down = nil, Up = nil, Ended = nil}
            return
        end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            StopFiring()
            return
        end
        local settings = getgenv().Settings
        if not settings or not settings.AutoFire then
            StopFiring()
            return
        end
        local attackButton = GetAttackButton()
        local targetManager = getgenv().TargetManager
        local currentTarget = targetManager and targetManager.CurrentTarget
        if attackButton and currentTarget then
            if not AutoFire.IsFiring then
                AutoFire.IsFiring = true
                SafeClick(AutoFire.Connections.Down)
            end
        else
            StopFiring()
        end
    end

    function AutoFire.Start()
        if AutoFire.Connection then return end
        AutoFire.Connection = RunService.Heartbeat:Connect(Update)
        AutoFire.InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if AutoFire.IsFiring then
                    AutoFire.IsFiring = false
                end
            end
        end)
    end

    function AutoFire.Stop()
        if AutoFire.Connection then
            AutoFire.Connection:Disconnect()
            AutoFire.Connection = nil
        end
        if AutoFire.InputConnection then
            AutoFire.InputConnection:Disconnect()
            AutoFire.InputConnection = nil
        end
        
        StopFiring()
    end

    getgenv().AutoFire = AutoFire
end

do -- GunModification
    local GunModification = getgenv().GunModification
    if not GunModification then
        GunModification = {}
        GunModification.FreezeConnections = setmetatable({}, {__mode = "k"})
        GunModification.OriginalStats = setmetatable({}, {__mode = "k"})
        GunModification.ModdedGuns = setmetatable({}, {__mode = "k"})
        getgenv().GunModification = GunModification
    else
        if GunModification.CharacterConnection then GunModification.CharacterConnection:Disconnect() end
        if GunModification.ChildConnection then GunModification.ChildConnection:Disconnect() end
    end

    local function ClearFreeze(gun)
        if GunModification.FreezeConnections[gun] then
            for _, connection in ipairs(GunModification.FreezeConnections[gun]) do
                if connection then connection:Disconnect() end
            end
            GunModification.FreezeConnections[gun] = nil
        end
    end

    local function FreezeValue(gun, key, value)
        if not key then return end
        key.Value = value
        local connection = key:GetPropertyChangedSignal("Value"):Connect(function()
            if key.Value ~= value then key.Value = value end
        end)
        if not GunModification.FreezeConnections[gun] then
            GunModification.FreezeConnections[gun] = {}
        end
        table.insert(GunModification.FreezeConnections[gun], connection)
    end

    local function Modification(gun)
        if not gun then return end
        local currentValues = gun:WaitForChild("CurrentValues", 1)
        if not currentValues then return end
        local stats = { 
            zoomSpreadIncrease = currentValues:FindFirstChild("ZoomSpreadIncrease"), 
            spreadIncrease = currentValues:FindFirstChild("SpreadIncrease"), 
            fireType = currentValues:FindFirstChild("FireType") 
        }
        if not GunModification.OriginalStats[gun] then
            GunModification.OriginalStats[gun] = {}
            for key, statInstance in pairs(stats) do 
                if statInstance then
                    GunModification.OriginalStats[gun][key] = statInstance.Value 
                end 
            end
        end
        local originalStat = GunModification.OriginalStats[gun]
        local needsRefresh = false
        ClearFreeze(gun)
        if getgenv().Settings.GunModification then
            if stats.fireType then 
                if stats.fireType.Value ~= "FullAuto" then needsRefresh = true end 
                FreezeValue(gun, stats.fireType, "FullAuto") 
            end            
            for _, key in ipairs({"zoomSpreadIncrease", "spreadIncrease"}) do
                if stats[key] then 
                    if tonumber(stats[key].Value) ~= 0 then needsRefresh = true end 
                    FreezeValue(gun, stats[key], 0) 
                end
            end
        else
            if stats.fireType and originalStat.fireType ~= nil then 
                if stats.fireType.Value ~= originalStat.fireType then needsRefresh = true end 
                stats.fireType.Value = originalStat.fireType 
            end
            for _, key in ipairs({"zoomSpreadIncrease", "spreadIncrease"}) do
                if stats[key] and originalStat[key] ~= nil then 
                    if tonumber(stats[key].Value) ~= tonumber(originalStat[key]) then needsRefresh = true end 
                    stats[key].Value = originalStat[key] 
                end
            end
        end
        if needsRefresh and gun and LocalPlayer.Character and gun.Parent == LocalPlayer.Character then
            GunModification.ModdedGuns[gun] = "refreshing"
            task.spawn(function()
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:UnequipTools()
                    task.wait(0.1)
                    if character and character.Parent and humanoid and humanoid.Health > 0 and gun and gun.Parent then
                        humanoid:EquipTool(gun)
                    end
                end
                if gun then
                    GunModification.ModdedGuns[gun] = getgenv().Settings.GunModification
                end
            end)
        else
            if gun then
                GunModification.ModdedGuns[gun] = getgenv().Settings.GunModification
            end
        end
    end

    local function OnEquip(child)
        if child and child:IsA("Tool") then
            local isModded = GunModification.ModdedGuns[child]
            local needsMod = getgenv().Settings.GunModification
            if isModded ~= needsMod and isModded ~= "refreshing" then
                Modification(child)
            end
        end
    end

    local function SetupCharacter(character)
        if GunModification.ChildConnection then GunModification.ChildConnection:Disconnect() end
        GunModification.ChildConnection = character.ChildAdded:Connect(OnEquip)
    end

    GunModification.CharacterConnection = LocalPlayer.CharacterAdded:Connect(SetupCharacter)
    if LocalPlayer.Character then
        SetupCharacter(LocalPlayer.Character)
    end

    function GunModification.Update()
        if not Alive() then return end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool then
            local isModded = GunModification.ModdedGuns[tool]
            local wantModded = getgenv().Settings.GunModification
            if isModded ~= wantModded and isModded ~= "refreshing" then
                Modification(tool)
            end
        end
    end

    getgenv().GunModification = GunModification
end

do -- AutoReadyUp
    if getgenv().AutoReadyUpConnection then
        getgenv().AutoReadyUpConnection:Disconnect()
        getgenv().AutoReadyUpConnection = nil
    end

    local AutoReadyUp = {}
    AutoReadyUp.LastTick = 0
    AutoReadyUp.IsVoted = false

    local function Update()
        local currentTick = os.clock()
        if currentTick - AutoReadyUp.LastTick < 0.5 then return end
        AutoReadyUp.LastTick = currentTick
        if TimeManager.InTime("17:30", "06:29") then return end
        local settings = getgenv().Settings
        if not settings or not settings.AutoReadyUp then return end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
        local gameFrame = screenGui and screenGui:FindFirstChild("GameFrame")
        local core = gameFrame and gameFrame:FindFirstChild("Core")
        local weaponFrame = core and core:FindFirstChild("WeaponFrame")
        local voteSkip = weaponFrame and weaponFrame:FindFirstChild("VoteSkip")
        if voteSkip and voteSkip.Visible and voteSkip.Text:find("Ready Up") then
            local backgroundColor = voteSkip.BackgroundColor3
            local r = math.floor(backgroundColor.R * 255 + 0.5)
            local g = math.floor(backgroundColor.G * 255 + 0.5)
            local b = math.floor(backgroundColor.B * 255 + 0.5)
            if r == 31 and g == 31 and b == 31 and not AutoReadyUp.IsVoted then
                AutoReadyUp.IsVoted = true
                task.spawn(function()
                    pcall(function()
                        voteSkip.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
                        local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
                        local voteSkipRemote = remoteFunctions and remoteFunctions:FindFirstChild("VoteSkip")
                        if voteSkipRemote then
                            voteSkipRemote:InvokeServer()
                        end
                    end)
                    task.wait(5) 
                    AutoReadyUp.IsVoted = false
                end)
            end
        end
    end

    function AutoReadyUp.Start()
        if getgenv().AutoReadyUpConnection then return end
        AutoReadyUp.IsVoted = false
        getgenv().AutoReadyUpConnection = RunService.Heartbeat:Connect(Update)
    end

    function AutoReadyUp.Stop()
        if getgenv().AutoReadyUpConnection then
            getgenv().AutoReadyUpConnection:Disconnect()
            getgenv().AutoReadyUpConnection = nil
        end
    end

    getgenv().AutoReadyUpModule = AutoReadyUp
end

do -- AutoUseAmmoBox
    if getgenv().AutoUseAmmoBoxConnection then
        getgenv().AutoUseAmmoBoxConnection:Disconnect()
        getgenv().AutoUseAmmoBoxConnection = nil
    end
    
    local lastTick = 0
    
    local function UseAmmoBox()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.delay(0.1, function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end

    local function Update()
        local settings = getgenv().Settings
        if not settings or not settings.AutoUseAmmoBox then return end
        local currentTick = os.clock()
        if currentTick - lastTick < 1 then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not humanoidRootPart then return end
        local tool = character:FindFirstChildOfClass("Tool")
        local currentValues = tool and tool:FindFirstChild("CurrentValues")
        if currentValues and currentValues:FindFirstChild("Ammo") and currentValues:FindFirstChild("Clip") then
            if currentValues.Ammo.Value <= 0 and currentValues.Clip.Value <= 0 then
                local map = Workspace:FindFirstChild("Map")
                local upgrades = map and map:FindFirstChild("Upgrades")
                if upgrades then
                    local targetBoxes = {"AmmoBox", "RoofAmmo"}
                    for _, boxName in ipairs(targetBoxes) do
                        local ammoBox = upgrades:FindFirstChild(boxName)
                        local invisLid = ammoBox and ammoBox:FindFirstChild("InvisLid")
                        if invisLid then
                            local distance = (humanoidRootPart.Position - invisLid.Position).Magnitude
                            if distance <= 15 then
                                UseAmmoBox()
                                lastTick = currentTick
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    getgenv().AutoUseAmmoBoxConnection = RunService.Heartbeat:Connect(Update)
end

do -- AutoMoveToAmmoBox
    if getgenv().AutoMoveToAmmoBoxModule then
        getgenv().AutoMoveToAmmoBoxModule.Stop()
    end

    local AutoMoveToAmmoBox = {}
    AutoMoveToAmmoBox.autoMoveToAmmoBoxNoclipConnection = nil
    AutoMoveToAmmoBox.autoMoveToAmmoBoxConnection = nil
    AutoMoveToAmmoBox.LastMoveTick = 0
    AutoMoveToAmmoBox.IsPaused = false

    local CachedCharacter = nil
    local CachedParts = {}
    local CharDescendantConnection = nil 

    local function RefreshCache(character)
        CachedCharacter = character
        table.clear(CachedParts)
        
        if CharDescendantConnection then 
            CharDescendantConnection:Disconnect() 
            CharDescendantConnection = nil
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(CachedParts, part)
            end
        end
        
        CharDescendantConnection = character.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                table.insert(CachedParts, part)
            end
        end)
    end

    local function NoclipUpdate()
        local settings = getgenv().Settings
        if not settings or not settings.AutoMoveToAmmoBox then return end
        if TimeManager.InTime("18:00", "06:00") and not Alive() then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        if CachedCharacter ~= character then
            RefreshCache(character)
        end
        
        for i = 1, #CachedParts do
            local part = CachedParts[i]
            if part and part.Parent and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    local function MoveUpdate()
        local currentTick = os.clock()
        if currentTick - AutoMoveToAmmoBox.LastMoveTick < 0.5 then return end
        AutoMoveToAmmoBox.LastMoveTick = currentTick
        local settings = getgenv().Settings
        if not settings or not settings.AutoMoveToAmmoBox then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not humanoidRootPart or humanoid.Health <= 0 then return end
        if TimeManager.InTime("18:00", "06:00") and not Alive() then
            if not AutoMoveToAmmoBox.IsPaused then
                humanoid.WalkToPoint = humanoidRootPart.Position 
                AutoMoveToAmmoBox.IsPaused = true
            end
            return
        end
        AutoMoveToAmmoBox.IsPaused = false
        local map = Workspace:FindFirstChild("Map")
        local upgrades = map and map:FindFirstChild("Upgrades")
        local ammoBox = upgrades and upgrades:FindFirstChild("AmmoBox")
        local invisLid = ammoBox and ammoBox:FindFirstChild("InvisLid")
        if invisLid then
            local distance = (humanoidRootPart.Position - invisLid.Position).Magnitude
            if distance > 5 then
                humanoid.WalkToPoint = invisLid.Position
            end
        end
    end

    function AutoMoveToAmmoBox.Start()
        if not AutoMoveToAmmoBox.autoMoveToAmmoBoxNoclipConnection then
            AutoMoveToAmmoBox.autoMoveToAmmoBoxNoclipConnection = RunService.Stepped:Connect(NoclipUpdate)
        end
        if not AutoMoveToAmmoBox.autoMoveToAmmoBoxConnection then
            AutoMoveToAmmoBox.autoMoveToAmmoBoxConnection = RunService.Heartbeat:Connect(MoveUpdate)
        end
    end

    function AutoMoveToAmmoBox.Stop()
        if AutoMoveToAmmoBox.autoMoveToAmmoBoxConnection then
            AutoMoveToAmmoBox.autoMoveToAmmoBoxConnection:Disconnect()
            AutoMoveToAmmoBox.autoMoveToAmmoBoxConnection = nil
        end
        if AutoMoveToAmmoBox.autoMoveToAmmoBoxNoclipConnection then
            AutoMoveToAmmoBox.autoMoveToAmmoBoxNoclipConnection:Disconnect()
            AutoMoveToAmmoBox.autoMoveToAmmoBoxNoclipConnection = nil
        end
        if CharDescendantConnection then
            CharDescendantConnection:Disconnect()
            CharDescendantConnection = nil
        end
        for i = 1, #CachedParts do
            local part = CachedParts[i]
            if part and part.Parent and part:IsA("BasePart") then
                -- 팔(Arm/Hand)이거나, 무기(Tool) 파츠인지 확인
                local isArm = string.find(part.Name, "Arm") or string.find(part.Name, "Hand")
                local isWeapon = part:FindFirstAncestorOfClass("Tool")
                
                -- 팔과 무기가 아닌 경우에만 충돌(CanCollide) 복구
                if not isArm and not isWeapon then
                    part.CanCollide = true
                end
            end
        end
        table.clear(CachedParts)
        CachedCharacter = nil
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root then hum.WalkToPoint = root.Position end
        end)
    end

    getgenv().AutoMoveToAmmoBoxModule = AutoMoveToAmmoBox
end

do -- AutoRefillAmmoBox
    if getgenv().AutoRefillAmmoBoxModule then
        getgenv().AutoRefillAmmoBoxModule.Stop()
    end

    local AutoRefillAmmoBox = {}
    AutoRefillAmmoBox.Coroutine = nil

    function AutoRefillAmmoBox.Start()
        if AutoRefillAmmoBox.Coroutine then return end
        AutoRefillAmmoBox.Coroutine = task.spawn(function()
            while getgenv().Settings and getgenv().Settings.AutoRefillAmmoBox do
                if not TimeManager.InTime("18:00", "06:00") then
                    pcall(function()
                        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
                        local sellRepair = remoteEvents and remoteEvents:FindFirstChild("SellRepair")
                        if sellRepair then
                            sellRepair:FireServer("AmmoBox")
                            sellRepair:FireServer("Ladders")
                        end
                    end)
                end
                task.wait(0.5)
            end
            AutoRefillAmmoBox.Coroutine = nil
        end)
    end

    function AutoRefillAmmoBox.Stop()
        if AutoRefillAmmoBox.Coroutine then
            task.cancel(AutoRefillAmmoBox.Coroutine) 
            AutoRefillAmmoBox.Coroutine = nil
        end
    end

    getgenv().AutoRefillAmmoBoxModule = AutoRefillAmmoBox
end

do -- AutoUpgradeAmmoBox
    if getgenv().AutoUpgradeAmmoBoxModule then
        getgenv().AutoUpgradeAmmoBoxModule.Stop()
    end

    local AutoUpgradeAmmoBox = {}
    AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine = nil

    function AutoUpgradeAmmoBox.Start()
        if AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine then return end
        AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine = task.spawn(function()
            while getgenv().Settings and getgenv().Settings.AutoUpgradeAmmoBox do
                pcall(function()
                    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
                    if remoteEvents then
                        local upgradeRemote = remoteEvents:FindFirstChild("UpgradeStructurePlayer")
                        if upgradeRemote then
                            upgradeRemote:FireServer("AmmoBox", "AmmoUpgrade")
                            upgradeRemote:FireServer("AmmoBox", "AmmoRepair")
                            upgradeRemote:FireServer("AmmoBox", "AmmoSpeed")
                        end
                    end
                end)
                task.wait(1)
            end
            AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine = nil
        end)
    end

    function AutoUpgradeAmmoBox.Stop()
        if AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine then
            task.cancel(AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine)
            AutoUpgradeAmmoBox.autoUpgradeAmmoBoxCoroutine = nil
        end
    end

    getgenv().AutoUpgradeAmmoBoxModule = AutoUpgradeAmmoBox
end

do -- MaxHeadHunter
    if getgenv().MaxHeadHunterConnection then
        getgenv().MaxHeadHunterConnection:Disconnect()
        getgenv().MaxHeadHunterConnection = nil
    end
    if getgenv().MaxHeadHunter and getgenv().MaxHeadHunter.Stop then
        getgenv().MaxHeadHunter.Stop()
    end

    local MaxHeadHunter = {}
    MaxHeadHunter.Connection = nil

    function MaxHeadHunter.Start()
        if MaxHeadHunter.Connection then return end
        local playerValues = LocalPlayer:FindFirstChild("PlayerValues")
        local perkValues = playerValues and playerValues:FindFirstChild("PerkValues")
        local stackHeadshot = perkValues and perkValues:FindFirstChild("StackHeadshot")
        if stackHeadshot then
            if stackHeadshot.Value ~= 4 then
                stackHeadshot.Value = 4
            end
            MaxHeadHunter.Connection = stackHeadshot:GetPropertyChangedSignal("Value"):Connect(function()
                local settings = getgenv().Settings
                if settings and settings.MaxHeadHunter then
                    if stackHeadshot.Value ~= 4 then
                        stackHeadshot.Value = 4
                    end
                end
            end)
        end
    end

    function MaxHeadHunter.Stop()
        if MaxHeadHunter.Connection then
            MaxHeadHunter.Connection:Disconnect()
            MaxHeadHunter.Connection = nil
        end
    end

    getgenv().MaxHeadHunter = MaxHeadHunter
end

do -- AutoPrestige
    if getgenv().AutoPrestigeModule then
        getgenv().AutoPrestigeModule.Stop()
    end

    local AutoPrestige = {}
    AutoPrestige.Loop = nil

    local function GetScoreboardGui()
        local map = Workspace:FindFirstChild("Map")
        local scripted = map and map:FindFirstChild("Scripted")
        local playerBoards = scripted and scripted:FindFirstChild("PlayerBoards")
        local scoreboard = playerBoards and playerBoards:FindFirstChild("Scoreboard")
        local board = scoreboard and scoreboard:FindFirstChild("Board")
        return board and board:FindFirstChild("SurfaceGui")
    end

    local function GetOwnedPerks()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local menuGui = playerGui and playerGui:FindFirstChild("MenuGui")
        local unlocksFrame = menuGui and menuGui:FindFirstChild("UnlocksFrame")
        local unlocks = unlocksFrame and unlocksFrame:FindFirstChild("Unlocks")
        local mobileTest = unlocks and unlocks:FindFirstChild("MobileTest")
        local perksFrame = mobileTest and mobileTest:FindFirstChild("Perks")
        if not perksFrame then return {} end
        local categories = {"OffensivePerks", "DefensivePerks", "EconomyPerks", "HybridPerks", "UtilityPerks"}
        local ownedPerks = {}
        for _, category in ipairs(categories) do
            local categoryFrame = perksFrame:FindFirstChild(category)
            local perksList = categoryFrame and categoryFrame:FindFirstChild("Perks")
            if perksList then
                for _, perk in ipairs(perksList:GetChildren()) do
                    if perk:IsA("ImageButton") then
                        table.insert(ownedPerks, perk.Name)
                    end
                end
            end
        end
        return ownedPerks
    end

    function AutoPrestige.Start()
        if AutoPrestige.Loop then return end
        AutoPrestige.Loop = task.spawn(function()
            while getgenv().Settings and getgenv().Settings.AutoPrestige do
                pcall(function()
                    local surfaceGui = GetScoreboardGui()
                    if surfaceGui then
                        local myDisplayName = LocalPlayer.DisplayName
                        local targetFrame = nil
                        for _, frame in ipairs(surfaceGui:GetChildren()) do
                            if frame:IsA("Frame") and frame.Name ~= "TitleFrame" and frame.Name ~= "Overlay" then
                                local playerText = frame:FindFirstChild("Player")
                                if playerText and playerText.Text == myDisplayName then
                                    targetFrame = frame
                                    break
                                end
                            end
                        end
                        if targetFrame then
                            local levelLabel = targetFrame:FindFirstChild("Level")
                            if levelLabel then
                                local currentLevel = tonumber(string.match(levelLabel.Text, "%d+$"))
                                if currentLevel == 50 then
                                    local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
                                    local prestigeRemote = remoteFunctions and remoteFunctions:FindFirstChild("PrestigePerk")
                                    if prestigeRemote then
                                        local perksToPrestige = GetOwnedPerks()
                                        for i = 1, #perksToPrestige do
                                            local perkName = perksToPrestige[i]
                                            task.spawn(function()
                                                pcall(function()
                                                    prestigeRemote:InvokeServer(perkName)
                                                end)
                                            end)
                                            task.wait(0.025)
                                        end
                                        task.wait(5)
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(30)
            end
            AutoPrestige.Loop = nil
        end)
    end

    function AutoPrestige.Stop()
        if AutoPrestige.Loop then
            task.cancel(AutoPrestige.Loop)
            AutoPrestige.Loop = nil
        end
    end

    getgenv().AutoPrestigeModule = AutoPrestige
end

do -- RunAndGun
    if getgenv().RunAndGunModule then
        if getgenv().RunAndGunModule.Connection then
            getgenv().RunAndGunModule.Connection:Disconnect()
        end
        getgenv().RunAndGunModule.Disable()
    end

    local RunAndGun = {}
    RunAndGun.Connection = nil
    RunAndGun.IsAdded = false

    function RunAndGun.Enable()
        task.spawn(function()
            local playerPerks = LocalPlayer:WaitForChild("PlayerPerks", 5)
            if playerPerks and not playerPerks:FindFirstChild("RunGun") then
                local runGunValue = Instance.new("NumberValue")
                runGunValue.Name = "RunGun"
                runGunValue.Value = 1
                runGunValue.Parent = playerPerks
                RunAndGun.IsAdded = true
            end
        end)
    end
    function RunAndGun.Disable()
        local playerPerks = LocalPlayer:FindFirstChild("PlayerPerks")
        if playerPerks then
            local runGunValue = playerPerks:FindFirstChild("RunGun")
            if runGunValue and RunAndGun.IsAdded then
                runGunValue:Destroy()
            end
        end
        RunAndGun.IsAdded = false
    end

    function RunAndGun.Start()
        RunAndGun.Enable()
        if not RunAndGun.Connection then
            RunAndGun.Connection = LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if getgenv().Settings and getgenv().Settings.RunAndGun then 
                    RunAndGun.Enable() 
                end
            end)
        end
    end

    function RunAndGun.Stop()
        RunAndGun.Disable()
        if RunAndGun.Connection then
            RunAndGun.Connection:Disconnect()
            RunAndGun.Connection = nil
        end
    end

    getgenv().RunAndGunModule = RunAndGun
end

do -- ForceOpenShop
    if getgenv().ForceOpenShopModule then
        getgenv().ForceOpenShopModule.Stop()
    end

    local ForceOpenShop = {}
    ForceOpenShop.Loop = nil
    ForceOpenShop.AddedConnection = nil
    
    local CachedDoorsFolder = nil
    local DoorPartsCache = {}

    local function RefreshCache(doorsFolder)
        CachedDoorsFolder = doorsFolder
        table.clear(DoorPartsCache)
        for _, v in ipairs(doorsFolder:GetDescendants()) do
            if v:IsA("BasePart") then
                table.insert(DoorPartsCache, v)
            end
        end
    end
    
    function ForceOpenShop.Start()
        if ForceOpenShop.Loop then return end
        ForceOpenShop.Loop = task.spawn(function()
            while getgenv().Settings and getgenv().Settings.ForceOpenShop do
                pcall(function()
                    local map = Workspace:FindFirstChild("Map")
                    local doors = map and map:FindFirstChild("Scripted") and map.Scripted:FindFirstChild("Doors")
                    if not doors then return end
                    if CachedDoorsFolder ~= doors then
                        RefreshCache(doors)
                        if ForceOpenShop.AddedConnection then ForceOpenShop.AddedConnection:Disconnect() end
                        ForceOpenShop.AddedConnection = doors.DescendantAdded:Connect(function(v)
                            if v:IsA("BasePart") then
                                table.insert(DoorPartsCache, v)
                            end
                        end)
                    end
                    local frontDoor = doors:FindFirstChild("FrontDoor")
                    if frontDoor then
                        local doorL = frontDoor:FindFirstChild("DoorL")
                        if doorL then
                            local pivot = doorL:GetPivot()
                            if math.abs(pivot.LookVector.X - 1) > 0.01 then
                                doorL:PivotTo(CFrame.lookAt(pivot.Position, pivot.Position + Vector3.new(1, 0, 0)))
                            end
                        end
                        local doorR = frontDoor:FindFirstChild("DoorR")
                        if doorR then
                            local pivot = doorR:GetPivot()
                            if math.abs(pivot.LookVector.X - (-1)) > 0.01 then
                                doorR:PivotTo(CFrame.lookAt(pivot.Position, pivot.Position + Vector3.new(-1, 0, 0)))
                            end
                        end
                    end
                    for i = 1, #DoorPartsCache do
                        local v = DoorPartsCache[i]
                        if v.CanCollide then
                            v.CanCollide = false
                        end
                    end
                end)
                task.wait(0.5)
            end
            ForceOpenShop.Loop = nil
        end)
    end

    function ForceOpenShop.Stop()
        if ForceOpenShop.Loop then
            task.cancel(ForceOpenShop.Loop)
            ForceOpenShop.Loop = nil
        end
        if ForceOpenShop.AddedConnection then
            ForceOpenShop.AddedConnection:Disconnect()
            ForceOpenShop.AddedConnection = nil
        end
        for i = 1, #DoorPartsCache do
            local v = DoorPartsCache[i]
            if v and v.Parent and v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
        table.clear(DoorPartsCache)
        CachedDoorsFolder = nil
    end

    getgenv().ForceOpenShopModule = ForceOpenShop
end

do -- RemoveFirstNightLimit
    if getgenv().RemoveFirstNightLimitModule then
        getgenv().RemoveFirstNightLimitModule.Stop()
    end

    local RemoveFirstNightLimit = {}
    RemoveFirstNightLimit.remove1stNightUpgradeLimitConnection = nil

    function RemoveFirstNightLimit.Start()
        if RemoveFirstNightLimit.remove1stNightUpgradeLimitConnection then return end
        local firstWave = LocalPlayer:FindFirstChild("FirstWave")
        if firstWave then
            if firstWave.Value then
                firstWave.Value = false
            end
            RemoveFirstNightLimit.remove1stNightUpgradeLimitConnection = firstWave:GetPropertyChangedSignal("Value"):Connect(function()
                local settings = getgenv().Settings
                if settings and settings.RemoveFirstNightLimit then
                    if firstWave.Value ~= false then
                        firstWave.Value = false
                    end
                end
            end)
        end
    end

    function RemoveFirstNightLimit.Stop()
        if RemoveFirstNightLimit.remove1stNightUpgradeLimitConnection then
            RemoveFirstNightLimit.remove1stNightUpgradeLimitConnection:Disconnect()
            RemoveFirstNightLimit.remove1stNightUpgradeLimitConnection = nil
        end
    end

    getgenv().RemoveFirstNightLimitModule = RemoveFirstNightLimit
end

do -- AutoVote
    if getgenv().AutoVoteModule then
        getgenv().AutoVoteModule.Stop()
    end

    local AutoVote = {}
    AutoVote.autoVoteTask = nil
    
    AutoVote.MapImages = {
        ["Arctic"] = "rbxassetid://4035053244",
        ["Canyon"] = "rbxassetid://4035053244",
        ["Cityscape"] = "rbxassetid://4035053244",
        ["Excavation"] = "rbxassetid://108056030566336",
        ["Forest"] = "rbxassetid://4035053244",
        ["Lakeside"] = "rbxassetid://7019877881",
        ["Origin"] = "rbxassetid://81783035100980",
        ["Subway"] = "rbxassetid://15566565653",
        ["Swampland"] = "rbxassetid://5978539536",
        ["Underground"] = "rbxassetid://11186055774"
    }

    local function handleAutoVote()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end
        local screenGui = playerGui:WaitForChild("ScreenGui", 5)
        local mapVoting = screenGui and screenGui:WaitForChild("Overlays"):WaitForChild("MapVoting")
        local mapsContainer = mapVoting and mapVoting:WaitForChild("Container"):WaitForChild("Maps")
        local remoteMapVote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RemoteMapVote")
        if not (mapVoting and mapsContainer and remoteMapVote) then return end
        while getgenv().Settings and getgenv().Settings.AutoVote and getgenv().Settings.AutoVote ~= "None" do
            if not mapVoting.Visible then
                mapVoting:GetPropertyChangedSignal("Visible"):Wait()
            end
            if mapVoting.Visible and getgenv().Settings.AutoVote ~= "None" then
                task.wait(1)
                local selectedMapName = getgenv().Settings.AutoVote
                local targetImageId = AutoVote.MapImages[selectedMapName]
                if targetImageId then
                    for _, mapButton in ipairs(mapsContainer:GetChildren()) do
                        if mapButton:IsA("ImageButton") and mapButton.Image == targetImageId then
                            local voteCount = mapButton:FindFirstChild("VoteCount")
                            if voteCount and tonumber(voteCount.Text) and tonumber(voteCount.Text) >= 1 then
                                break 
                            end
                            local mapIndex = tonumber(mapButton.Name:match("%d+"))
                            if mapIndex then
                                pcall(function()
                                    remoteMapVote:FireServer(mapIndex)
                                end)
                            end
                            break
                        end
                    end
                end
                while mapVoting.Visible and getgenv().Settings.AutoVote ~= "None" do
                    task.wait(1)
                end
            end
        end
    end

    function AutoVote.Start()
        if AutoVote.autoVoteTask then return end
        AutoVote.autoVoteTask = task.spawn(handleAutoVote)
    end

    function AutoVote.Stop()
        if AutoVote.autoVoteTask then
            task.cancel(AutoVote.autoVoteTask)
            AutoVote.autoVoteTask = nil
        end
    end

    getgenv().AutoVoteModule = AutoVote
end

----------------------------------------------------------
getgenv().ToggleTargetManager = function()
    if getgenv().Settings.SilentAim or getgenv().Settings.AutoFire then 
        getgenv().TargetManager.Start() 
    else 
        getgenv().TargetManager.Stop() 
    end
end
-------------------------------------------------------------------------
if getgenv().RayfieldWindow then
    getgenv().RayfieldWindow:Destroy()
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
getgenv().RayfieldWindow = Rayfield
local window = Rayfield:CreateWindow({ name = "Test", subtitle = "Made by Sim" })
local tab = window:CreateTab({ name = "Test" })
getgenv().WeaponDropdown = tab:CreateDropdown({
    name = "Auto Equip", 
    options = getgenv().GetWeaponList(),
    currentValue = getgenv().Settings.SelectedWeapon or "None", 
    flag = "WeaponDropdown",
    callback = getgenv().SelectWeapon
})
tab:CreateToggle({ -- Silent Aim
    name = "Silent Aim", 
    currentValue = getgenv().Settings.SilentAim,
    callback = function(value) 
        getgenv().Settings.SilentAim = value
        getgenv().ToggleTargetManager()
        getgenv().SilentAim.Start() 
    end
})
tab:CreateToggle({ -- Auto Fire
    name = "Auto Fire", 
    currentValue = getgenv().Settings.AutoFire,
    callback = function(value) 
        getgenv().Settings.AutoFire = value
        getgenv().ToggleTargetManager()
        if value then 
            getgenv().AutoFire.Start() 
        else 
            getgenv().AutoFire.Stop() 
        end 
    end
})
tab:CreateToggle({ -- Gun Modification
    name = "Gun Modification", 
    currentValue = getgenv().Settings.GunModification,
    callback = function(value) 
        getgenv().Settings.GunModification = value
        getgenv().GunModification.Update() 
    end
})
tab:CreateToggle({ -- Auto Ready Up
    name = "Auto Ready Up",
    currentValue = getgenv().Settings.AutoReadyUp,
    callback = function(value)
        getgenv().Settings.AutoReadyUp = value
        if value then
            getgenv().AutoReadyUpModule.Start()
        else
            getgenv().AutoReadyUpModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Auto Use AmmoBox
    name = "Auto Use AmmoBox", 
    currentValue = getgenv().Settings.AutoUseAmmoBox,
    callback = function(value) 
        getgenv().Settings.AutoUseAmmoBox = value 
    end
})
tab:CreateToggle({ -- Auto Move To AmmoBox
    name = "Auto Move To AmmoBox",
    currentValue = getgenv().Settings.AutoMoveToAmmoBox,
    callback = function(value)
        getgenv().Settings.AutoMoveToAmmoBox = value
        if value then
            getgenv().AutoMoveToAmmoBoxModule.Start()
        else
            getgenv().AutoMoveToAmmoBoxModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Auto Refill AmmoBox
    name = "Auto Refill AmmoBox",
    currentValue = getgenv().Settings.AutoRefillAmmoBox,
    callback = function(value)
        getgenv().Settings.AutoRefillAmmoBox = value
        if value then
            getgenv().AutoRefillAmmoBoxModule.Start()
        else
            getgenv().AutoRefillAmmoBoxModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Auto Upgrade AmmoBox
    name = "Auto Upgrade AmmoBox",
    currentValue = getgenv().Settings.AutoUpgradeAmmoBox,
    callback = function(value)
        getgenv().Settings.AutoUpgradeAmmoBox = value
        if value then
            getgenv().AutoUpgradeAmmoBoxModule.Start()
        else
            getgenv().AutoUpgradeAmmoBoxModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Max Head Hunter
    name = "Max Head Hunter",
    currentValue = getgenv().Settings.MaxHeadHunter,
    callback = function(value)
        getgenv().Settings.MaxHeadHunter = value
        if value then
            getgenv().MaxHeadHunter.Start()
        else
            getgenv().MaxHeadHunter.Stop()
        end
    end
})
tab:CreateToggle({ -- Auto Prestige
    name = "Auto Prestige",
    currentValue = getgenv().Settings.AutoPrestige,
    callback = function(value)
        getgenv().Settings.AutoPrestige = value
        if value then
            getgenv().AutoPrestigeModule.Start()
        else
            getgenv().AutoPrestigeModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Run And Gun
    name = "Run And Gun",
    currentValue = getgenv().Settings.RunAndGun,
    callback = function(value)
        getgenv().Settings.RunAndGun = value
        if value then
            getgenv().RunAndGunModule.Start()
        else
            getgenv().RunAndGunModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Force Open Shop
    name = "Force Open Shop",
    currentValue = getgenv().Settings.ForceOpenShop,
    callback = function(value)
        getgenv().Settings.ForceOpenShop = value
        if value then
            getgenv().ForceOpenShopModule.Start()
        else
            getgenv().ForceOpenShopModule.Stop()
        end
    end
})
tab:CreateToggle({ -- Remove First Night Limit
    name = "Remove First Night Limit",
    currentValue = getgenv().Settings.RemoveFirstNightLimit,
    callback = function(value)
        getgenv().Settings.RemoveFirstNightLimit = value
        if value then
            getgenv().RemoveFirstNightLimitModule.Start()
        else
            getgenv().RemoveFirstNightLimitModule.Stop()
        end
    end
})
tab:CreateDropdown({ -- Auto Vote
    name = "Auto Vote",
    options = {"None", "Arctic", "Canyon", "Cityscape", "Excavation", "Forest", "Lakeside", "Origin", "Subway", "Swampland", "Underground"},
    currentValue = getgenv().Settings.AutoVote or "None",
    flag = "AutoVoteDropdown",
    callback = function(value)
        local selectedMap = type(value) == "table" and value[1] or value
        getgenv().Settings.AutoVote = selectedMap
        if selectedMap == "None" then
            getgenv().AutoVoteModule.Stop()
        else
            getgenv().AutoVoteModule.Start()
        end
    end
})
