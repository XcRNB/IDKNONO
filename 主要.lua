
if not getgenv().shared then
    getgenv().shared = {}
end

if not getgenv().voidware_loaded then
    getgenv().voidware_loaded = true
else
    local suc = pcall(function()
        shared.Voidware_InkGame_Library:Unload()
    end)
    if not suc then
        return 
    end
end

local isNew = false
pcall(function()
    if not isfolder("voidware_linoria") then makefolder("voidware_linoria"); isNew = true; end
    for _, v in pairs({"voidware_linoria/ink_game", "voidware_linoria/themes"}) do
        if not isfolder(v) then makefolder(v); isNew = true; end
    end
    for _, v in pairs({"voidware_linoria/ink_game/settings", "voidware_linoria/ink_game/themes"}) do
        if not isfolder(v) then makefolder(v); isNew = true; end
    end

    if isNew then
        writefile("voidware_linoria/themes/default.txt", "Jester")
        local suc = pcall(function()
            writefile("voidware_linoria/ink_game/settings/default.json", game:HttpGet("https://raw.githubusercontent.com/Erchobg/VoidwareProfiles/refs/heads/main/InkGame/ink_game/settings/default.json", true))
        end)
        if suc then
            writefile("voidware_linoria/ink_game/settings/autoload.txt", "default")
        end
    end
end)

task.spawn(function()
    pcall(function()
        if not isfile("Local_VW_Update_Log.json") then
            shared.UpdateLogBypass = true
        end
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VWExtra/main/VWUpdateLog.lua", true))()
        shared.UpdateLogBypass = nil
    end)
end)

--// Library \\--
local repo = "https://raw.githubusercontent.com/XcRNB/Obsidian-CNHK/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
	Title = "地岩 - Ink Game",
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = true,
	TabPadding = 2,
	MenuFadeTime = 0
})

local Tabs = {
	Main = Window:AddTab("主要"),
    Visuals = Window:AddTab("绘制"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({Tasks = {}}, Maid)
end

function Maid:Add(task)
    if typeof(task) == "RBXScriptConnection" or (typeof(task) == "Instance" and task.Destroy) or typeof(task) == "function" then
        table.insert(self.Tasks, task)
    end
    return task
end

function Maid:Clean()
    for _, task in ipairs(self.Tasks) do
		pcall(function()
			if typeof(task) == "RBXScriptConnection" then
				task:Disconnect()
			elseif typeof(task) == "Instance" then
				task:Destroy()
			elseif typeof(task) == "function" then
				task()
			end
		end)
    end
	table.clear(self.Tasks)
    self.Tasks = {}
end

local Services = setmetatable({}, {
	__index = function(self, key)
		local suc, service = pcall(game.GetService, game, key)
		if suc and service then
			self[key] = service
			return service
		else
			warn(`[Services] Warning: "{key}" is not a valid Roblox service.`)
			return nil
		end
	end
})

local Players = Services.Players
local RunService = Services.RunService
local HttpService = Services.HttpService
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage

local lplr = Players.LocalPlayer
local localPlayer = lplr

local camera = workspace.CurrentCamera

type ESP = {
    Color: Color3,
    IsEntity: boolean,
    Object: Instance,
    Offset: Vector3,
    Text: string,
    TextParent: Instance,
    Type: string,
}

local Script = {
    GameStateChanged = Instance.new("BindableEvent"),
    GameState = "unknown",
    Services = Services,
    Maid = Maid.new(),
    Connections = {},
    Functions = {},
    ESPTable = {
        Player = {},
        Seeker = {},
        Hider = {},
        Guard = {},
        Door = {},
        None = {},
        Key = {},
    },
    Temp = {}
}

function Script.Functions.Alert(message: string, time_obj: number)
    Library:Notify(message, time_obj or 5)

    --if TogglesNotifySound..Value then
        local sound = Instance.new("Sound", workspace) do
            sound.SoundId = "rbxassetid://4590662766"
            sound.Volume = 2
            sound.PlayOnRemove = true
            sound:Destroy()
        end
    --end
end

function Script.Functions.Warn(message: string)
    warn("WARN - voidware:", message)
end

function Script.Functions.ESP(args: ESP)
    if not args.Object then return Script.Functions.Warn("ESP Object is nil") end

    local ESPManager = {
        Object = args.Object,
        Text = args.Text or "No Text",
        TextParent = args.TextParent,
        Color = args.Color or Color3.new(),
        Offset = args.Offset or Vector3.zero,
        IsEntity = args.IsEntity or false,
        Type = args.Type or "None",

        Highlights = {},
        Humanoid = nil,
        RSConnection = nil,

        Connections = {}
    }

    local tableIndex = #Script.ESPTable[ESPManager.Type] + 1

    if ESPManager.IsEntity and ESPManager.Object.PrimaryPart.Transparency == 1 then
        ESPManager.Object:SetAttribute("Transparency", ESPManager.Object.PrimaryPart.Transparency)
        ESPManager.Humanoid = Instance.new("Humanoid", ESPManager.Object)
        ESPManager.Object.PrimaryPart.Transparency = 0.99
    end

    local highlight = Instance.new("Highlight") do
        highlight.Adornee = ESPManager.Object
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = ESPManager.Color
        highlight.FillTransparency = Options.ESPFillTransparency.Value
        highlight.OutlineColor = ESPManager.Color
        highlight.OutlineTransparency = Options.ESPOutlineTransparency.Value
        highlight.Enabled = Toggles.ESPHighlight.Value
        highlight.Parent = ESPManager.Object
    end

    table.insert(ESPManager.Highlights, highlight)
    

    local billboardGui = Instance.new("BillboardGui") do
        billboardGui.Adornee = ESPManager.TextParent or ESPManager.Object
		billboardGui.AlwaysOnTop = true
		billboardGui.ClipsDescendants = false
		billboardGui.Size = UDim2.new(0, 1, 0, 1)
		billboardGui.StudsOffset = ESPManager.Offset
        billboardGui.Parent = ESPManager.TextParent or ESPManager.Object
	end

    local textLabel = Instance.new("TextLabel") do
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.Oswald
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.Text = ESPManager.Text
		textLabel.TextColor3 = ESPManager.Color
		textLabel.TextSize = Options.ESPTextSize.Value
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0.75
        textLabel.Parent = billboardGui
	end

    function ESPManager.SetColor(newColor: Color3)
        ESPManager.Color = newColor

        for _, highlight in pairs(ESPManager.Highlights) do
            highlight.FillColor = newColor
            highlight.OutlineColor = newColor
        end

        textLabel.TextColor3 = newColor
    end

    function ESPManager.Destroy()
        if ESPManager.RSConnection then
            ESPManager.RSConnection:Disconnect()
        end

        if ESPManager.IsEntity and ESPManager.Object then
            if ESPManager.Object.PrimaryPart then
                ESPManager.Object.PrimaryPart.Transparency = ESPManager.Object.PrimaryPart:GetAttribute("Transparency")
            end
            if ESPManager.Humanoid then
                ESPManager.Humanoid:Destroy()
            end
        end

        for _, highlight in pairs(ESPManager.Highlights) do
            highlight:Destroy()
        end
        if billboardGui then billboardGui:Destroy() end

        if Script.ESPTable[ESPManager.Type][tableIndex] then
            Script.ESPTable[ESPManager.Type][tableIndex] = nil
        end

        for _, conn in pairs(ESPManager.Connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        ESPManager.Connections = {}
    end

    ESPManager.RSConnection = RunService.RenderStepped:Connect(function()
        if not ESPManager.Object or not ESPManager.Object:IsDescendantOf(workspace) then
            ESPManager.Destroy()
            return
        end

        for _, highlight in pairs(ESPManager.Highlights) do
            highlight.Enabled = Toggles.ESPHighlight.Value
            highlight.FillTransparency = Options.ESPFillTransparency.Value
            highlight.OutlineTransparency = Options.ESPOutlineTransparency.Value
        end
        textLabel.TextSize = Options.ESPTextSize.Value

        if Toggles.ESPDistance.Value then
            textLabel.Text = string.format("%s\n[%s]", ESPManager.Text, math.floor(Script.Functions.DistanceFromCharacter(ESPManager.Object)))
        else
            textLabel.Text = ESPManager.Text
        end
    end)

    function ESPManager.GiveSignal(signal)
        table.insert(ESPManager.Connections, signal)
    end

    Script.ESPTable[ESPManager.Type][tableIndex] = ESPManager
    return ESPManager
end

function Script.Functions.SeekerESP(player : Player)
    if not player:GetAttribute("IsHider") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local esp = Script.Functions.ESP({
            Object = player.Character,
            Text = player.Name .. " (Seeker)",
            Color = Options.SeekerEspColor.Value,
            Offset = Vector3.new(0, 3, 0),
            Type = "Seeker"
        })
    end
end

function Script.Functions.HiderESP(player : Player)
    if player:GetAttribute("IsHider") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local esp = Script.Functions.ESP({
            Object = player.Character,
            Text = player.Name .. " (Hider)",
            Color = Options.HiderEspColor.Value,
            Offset = Vector3.new(0, 3, 0),
            Type = "Hider"
        })
        player:GetAttributeChangedSignal("IsHider"):Once(function()
            if not player:GetAttribute("IsHider") then
                esp.Destroy()
            end
        end)
    end
end

function Script.Functions.KeyESP(key)
    if key:IsA("Model") and key.PrimaryPart then
        local esp = Script.Functions.ESP({
            Object = key,
            Text = key.Name .. " (Key)",
            Color = Options.KeyEspColor.Value,
            Offset = Vector3.new(0, 1, 0),
            Type = "Key",
            IsEntity = true
        })
    end
end

function Script.Functions.DoorESP(door)
    if door:IsA("Model") and door.Name == "FullDoorAnimated" and door.PrimaryPart then
        local keyNeeded = door:GetAttribute("KeyNeeded") or "None"
        local esp = Script.Functions.ESP({
            Object = door,
            Text = "Door (Key: " .. keyNeeded .. ")",
            Color = Options.DoorEspColor.Value,
            Offset = Vector3.new(0, 2, 0),
            Type = "Door",
            IsEntity = true
        })
    end
end

function Script.Functions.GuardESP(character)
    if character and character:FindFirstChild("HumanoidRootPart") then
        local esp = Script.Functions.ESP({
            Object = character,
            Text = "Guard",
            Color = Options.GuardEspColor.Value,
            Offset = Vector3.new(0, 3, 0),
            Type = "Guard"
        })
    end
end

function Script.Functions.PlayerESP(player: Player)
    if not (player.Character and player.Character.PrimaryPart and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0) then return end

    local playerEsp = Script.Functions.ESP({
        Type = "Player",
        Object = player.Character,
        Text = string.format("%s [%s]", player.DisplayName, player.Character.Humanoid.Health),
        TextParent = player.Character.PrimaryPart,
        Color = Options.PlayerEspColor.Value
    })

    playerEsp.GiveSignal(player.Character.Humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth > 0 then
            playerEsp.Text = string.format("%s [%s]", player.DisplayName, newHealth)
        else
            playerEsp.Destroy()
        end
    end))
end

Script.Functions.SafeRequire = function(module)
    local suc, err = pcall(function()
        return require(module)
    end)
    if not suc then
        warn("[SafeRequire]: Failure loading "..tostring(module).." ("..tostring(err)..")")
    end
    return suc and err
end

Script.Functions.ExecuteClick = function()
    local args = {
        "Clicked"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Replication"):WaitForChild("Event"):FireServer(unpack(args))    
end

Script.Functions.CompleteDalgonaGame = function()
    Script.Functions.ExecuteClick()
    local args = {
        {
            Completed = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DALGONATEMPREMPTE"):FireServer(unpack(args))
end

Script.Functions.PullRope = function(perfect)
    local args = {
        {
            PerfectQTE = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TemporaryReachedBindable"):FireServer(unpack(args))
end

Script.Functions.RevealGlassBridge = function()
    local Effects = Script.Functions.SafeRequire(ReplicatedStorage.Modules.Effects) or {
        AnnouncementTween = function(args)
            Script.Functions.Alert(args.AnnouncementDisplayText, args.DisplayTime)
        end
    }

    local glassHolder = workspace:FindFirstChild("GlassBridge") and workspace.GlassBridge:FindFirstChild("GlassHolder")
    if not glassHolder then
        warn("GlassHolder not found in workspace.GlassBridge")
        return
    end

    for _, tilePair in pairs(glassHolder:GetChildren()) do
        for _, tileModel in pairs(tilePair:GetChildren()) do
            if tileModel:IsA("Model") and tileModel.PrimaryPart then
                local primaryPart = tileModel.PrimaryPart
                local isBreakable = primaryPart:GetAttribute("exploitingisevil") == true

                local targetColor = isBreakable and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                local transparency = 0.5

                for _, part in pairs(tileModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
                            Transparency = transparency,
                            Color = targetColor
                        }):Play()
                    end
                end

                local highlight = Instance.new("Highlight")
                highlight.FillColor = targetColor
                highlight.FillTransparency = 0.7
                highlight.OutlineTransparency = 0.5
                highlight.Parent = tileModel
            end
        end
    end

    Effects.AnnouncementTween({
        AnnouncementOneLine = true,
        FasterTween = true,
        DisplayTime = 10,
        AnnouncementDisplayText = "[Voidware]: Safe tiles are green, breakable tiles are red!"
    })
end

Script.Functions.OnLoad = function()
    local Effects = Script.Functions.SafeRequire(ReplicatedStorage.Modules.Effects) or {
        AnnouncementTween = function(args)
            Script.Functions.Alert(args.AnnouncementDisplayText, args.DisplayTime)
        end
    }

    Effects.AnnouncementTween({
        AnnouncementOneLine = true,
        FasterTween = true,
        DisplayTime = 5,
        AnnouncementDisplayText = "Voidware - Ink Game loaded!"
    })

    Effects.AnnouncementTween({
        AnnouncementOneLine = true,
        FasterTween = true,
        DisplayTime = 5,
        AnnouncementDisplayText = "Join discord.gg/voidware for updates :)"
    })
end

Script.Functions.BypassRagdoll = function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SharedFunctions = Script.Functions.SafeRequire(ReplicatedStorage.Modules.SharedFunctions)

    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Torso = Character:FindFirstChild("Torso")
    if not (Humanoid and HumanoidRootPart and Torso) then return end

    local function restoreHumanoidStates()
        Humanoid.PlatformStand = false
        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        for _, state in pairs({
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.Swimming,
            Enum.HumanoidStateType.Flying,
            Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Ragdoll
        }) do
            Humanoid:SetStateEnabled(state, false)
        end
    end

    local function cleanupRagdoll()
        for _, obj in pairs(HumanoidRootPart:GetChildren()) do
            if obj:IsA("BallSocketConstraint") or obj.Name:match("^CacheAttachment") then
                obj:Destroy()
            end
        end

        local joints = {"Left Hip", "Left Shoulder", "Neck", "Right Hip", "Right Shoulder"}
        for _, jointName in pairs(joints) do
            local motor = Torso:FindFirstChild(jointName)
            if motor and motor:IsA("Motor6D") and not motor.Part0 then
                motor.Part0 = Torso
            end
        end

        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") and part:FindFirstChild("BoneCustom") then
                part.BoneCustom:Destroy()
            end
        end

        for _, folderName in pairs({"Ragdoll", "Stun", "RotateDisabled", "RagdollWakeupImmunity"}) do
            local folder = Character:FindFirstChild(folderName)
            if folder then
                folder:Destroy()
            end
        end

        local LocalRagdolls = workspace.Effects:FindFirstChild("LocalRagdolls")
        if LocalRagdolls then
            local ragdollModel = LocalRagdolls:FindFirstChild(LocalPlayer.Name)
            if ragdollModel then
                ragdollModel:Destroy()
            end
        end
    end

    restoreHumanoidStates()
    cleanupRagdoll()

    --[[local connection
    connection = Character.ChildAdded:Connect(function(child)
        if child.Name == "Ragdoll" or child.Name == "Stun" or child.Name == "RotateDisabled" or child.Name == "Waiting" then
            task.defer(function()
                child:Destroy()
                restoreHumanoidStates()
                cleanupRagdoll()
            end)
        end
    end)

    return function()
        if connection then
            connection:Disconnect()
        end
    end--]]
end

Script.Functions.BypassDalgonaGame = function()
    local SharedFunctions = Script.Functions.SafeRequire(ReplicatedStorage.Modules.SharedFunctions)

    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character and Character:FindFirstChild("Humanoid")
    local PlayerGui = LocalPlayer.PlayerGui
    local DebrisBD = LocalPlayer:WaitForChild("DebrisBD")
    local CurrentCamera = workspace.CurrentCamera
    local EffectsFolder = workspace:FindFirstChild("Effects")
    local ImpactFrames = PlayerGui:FindFirstChild("ImpactFrames")

    local shapeModel, outlineModel, pickModel, redDotModel
    if EffectsFolder then
        for _, obj in pairs(EffectsFolder:GetChildren()) do
            if obj:IsA("Model") and obj.Name:match("Outline$") then
                outlineModel = obj
            elseif obj:IsA("Model") and not obj.Name:match("Outline$") and obj.Name ~= "Pick" and obj.Name ~= "RedDot" then
                shapeModel = obj
            elseif obj.Name == "Pick" then
                pickModel = obj
            elseif obj.Name == "RedDot" then
                redDotModel = obj
            end
        end
    end

    local progressBar = ImpactFrames and ImpactFrames:FindFirstChild("ProgressBar")

    local pickViewportModel
    if ImpactFrames then
        for _, obj in pairs(ImpactFrames:GetChildren()) do
            if obj:IsA("ViewportFrame") and obj:FindFirstChild("PickModel") then
                pickViewportModel = obj.PickModel
                break
            end
        end
    end

    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local DalgonaRemote = Remotes:WaitForChild("DALGONATEMPREMPTE")
    
    task.spawn(function()
        SharedFunctions.CreateFolder(LocalPlayer, "RecentGameStartedMessage", 0.01)

        if shapeModel and shapeModel:FindFirstChild("shape") then
            TweenService:Create(shapeModel.shape, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                Position = shapeModel.shape.Position + Vector3.new(0, 0.5, 0)
            }):Play()
        end

        if shapeModel then
            for _, part in pairs(shapeModel:GetChildren()) do
                if part.Name == "DalgonaClickPart" and part:IsA("BasePart") then
                    TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                        Transparency = 1
                    }):Play()
                end
            end
        end

        if pickModel and pickModel.Parent then
            TweenService:Create(pickModel, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                Transparency = 1
            }):Play()
        end
        if redDotModel and redDotModel.Parent then
            TweenService:Create(redDotModel, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                Transparency = 1
            }):Play()
        end

        if pickViewportModel then
            for _, part in pairs(pickViewportModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                        Transparency = 1
                    }):Play()
                end
            end
        end

        if HumanoidRootPart then
            TweenService:Create(CurrentCamera, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                CFrame = HumanoidRootPart.CFrame * CFrame.new(0.0841674805, 8.45438766, 6.69675446, 0.999918401, -0.00898250192, 0.00907994807, 3.31699681e-08, 0.710912943, 0.703280032, -0.0127722733, -0.703222632, 0.710854948)
            }):Play()
        end

        SharedFunctions.Invisible(Character, 0, true)

        DalgonaRemote:FireServer({
            Success = true
        })

        task.wait(2)
        for _, obj in pairs({shapeModel, outlineModel, pickModel, redDotModel, progressBar}) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end

        UserInputService.MouseIconEnabled = true
        if PlayerGui:FindFirstChild("Hotbar") and PlayerGui.Hotbar:FindFirstChild("Backpack") then
            TweenService:Create(PlayerGui.Hotbar.Backpack, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
        end
        if progressBar then
            DebrisBD:Fire(progressBar, 2)
            TweenService:Create(progressBar, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
                Position = UDim2.new(progressBar.Position.X.Scale, 0, progressBar.Position.Y.Scale + 1, 0)
            }):Play()
        end

        -- Forcefully reset camera
        CurrentCamera.CameraType = Enum.CameraType.Custom
        if Humanoid then
            CurrentCamera.CameraSubject = Humanoid
        end

        local cameraConnection
        local startTime = tick()
        cameraConnection = RunService.RenderStepped:Connect(function()
            if tick() - startTime >= 5 then
                cameraConnection:Disconnect()
                return
            end
            if CurrentCamera.CameraType ~= Enum.CameraType.Custom or CurrentCamera.CameraSubject ~= Humanoid then
                CurrentCamera.CameraType = Enum.CameraType.Custom
                if Humanoid then
                    CurrentCamera.CameraSubject = Humanoid
                end
            end
        end)
    end)

    return function()
        for _, obj in pairs({shapeModel, outlineModel, pickModel, redDotModel, progressBar}) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
        UserInputService.MouseIconEnabled = true
        CurrentCamera.CameraType = Enum.CameraType.Custom
        if Humanoid then
            CurrentCamera.CameraSubject = Humanoid
        end
    end
end

Script.Functions.GetRootPart = function()
    if not lplr.Character then return end
    local rp = lplr.Character:WaitForChild("HumanoidRootPart", 10)
    return rp
end

Script.Functions.GetHumanoid = function()
    if not lplr.Character then return end
    local rp = lplr.Character:WaitForChild("Humanoid", 10)
    return rp
end

Script.Functions.JoinDiscordServer = function()
    local sInvite = "感谢你的支持"
    
    local function getInviteCode(sInvite)
        for i = #sInvite, 1, -1 do
            local char = sInvite:sub(i, i)
            if char == "/" then
                return sInvite:sub(i + 1, #sInvite)
            end
        end
        return sInvite
    end
    
    local function getInviteData(sInvite)
        local success, result = pcall(function()
            return HttpService:JSONDecode(request({
                Url = "https://ptb.discord.com/api/invites/".. getInviteCode(sInvite),
                Method = "GET"
            }).Body)
        end)
        if not success then
            warn("Failed to get invite data:\n".. result)
            return
        end
        return success, result
    end

    local success, result = getInviteData(sInvite)
	if success and result then
        request({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = {
                    code = result.code
                },
                nonce = HttpService:GenerateGUID(false)
            })
        })
	end
    pcall(function()
        setclipboard("discord.gg/voidware")
    end)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Voidware Discord - discord.gg/voidware",
        Text = "Copied to clipboard (discord.gg/voidware)",
        Duration = 10,
    })
end

function Script.Functions.DistanceFromCharacter(position: Instance | Vector3)
    if typeof(position) == "Instance" then
        position = position:GetPivot().Position
    end

    if not alive then
        return (camera.CFrame.Position - position).Magnitude
    end

    return (rootPart.Position - position).Magnitude
end

Script.Functions.FixCamera = function()
    if workspace.CurrentCamera then
        pcall(function()
            workspace.CurrentCamera:Destroy()
        end)
    end
    local new = Instance.new("Camera")
    new.Parent = workspace
    workspace.CurrentCamera = new
    new.CameraType = Enum.CameraType.Custom
    new.CameraSubject = lplr.Character.Humanoid
end

function Script.Functions.SetupOtherPlayerConnection(player: Player)
    if player.Character then
        if Toggles.PlayerESP.Value then
            Script.Functions.PlayerESP(player)
        end
    end

    Library:GiveSignal(player.CharacterAdded:Connect(function(newCharacter)
        task.delay(0.1, function()
            if Toggles.PlayerESP.Value then
                Script.Functions.PlayerESP(player)
            end
        end)
    end))
end

local MAIN_ESP_META = {
    {
        metaName = "PlayerESP",
        text = "玩家",
        default = false,
        color = {
            metaName = "PlayerEspColor",
            default = Color3.fromRGB(255, 255, 255)
        },
        func = function()
            for _, player in pairs(Players:GetPlayers()) do
                if player == localPlayer then continue end
                Script.Functions.PlayerESP(player)
            end
        end
    },
    {
        metaName = "GuardESP",
        text = "警卫",
        default = false,
        color = {
            metaName = "GuardEspColor",
            default = Color3.fromRGB(200, 100, 200)
        },
        func = function()
            local live = workspace:FindFirstChild("Live")
            if not live then return end
            for _, descendant in pairs(live:GetChildren()) do
                if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Live" and descendant:FindFirstChild("TypeOfGuard") then
                    if string.find(descendant.Name, "Guard") then
                        Script.Functions.GuardESP(descendant)
                    end
                end
            end
        end,
        descendantcheck = function(descendant)
            if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Live" and descendant:FindFirstChild("TypeOfGuard") then
                if string.find(descendant.Name, "Guard") then
                    Script.Functions.GuardESP(descendant)
                end
            end
        end
    }
}

local MainESPGroup = Tabs.Visuals:AddLeftGroupbox("绘制1") do
    for _, meta in pairs(MAIN_ESP_META) do
        MainESPGroup:AddToggle(meta.metaName, {
            Text = meta.text,
            Default = meta.default
        }):AddColorPicker(meta.color.metaName, {
            Default = meta.color.default
        })

        Toggles[meta.metaName]:OnChanged(function(call)
            if call then
                if meta.func then
                    meta.func(call)
                end
            else
                for _, esp in pairs(Script.ESPTable[meta.text]) do
                    esp.Destroy()
                end
            end
        end)

        if meta.descendantcheck then
            Library:GiveSignal(workspace.DescendantAdded:Connect(function(descendant)
                if not Toggles[meta.metaName].Value then return end
                meta.descendantcheck(descendant)
            end))
        end
    end
end

local ESP_META = {
    {
        metaName = "HiderESP",
        text = "隐藏者",
        default = false,
        color = {
            metaName = "HiderEspColor",
            default = Color3.fromRGB(0, 255, 0)
        },
        checkType = "player"
    },
    {
        metaName = "SeekerESP",
        text = "寻找者",
        default = false,
        color = {
            metaName = "SeekerEspColor",
            default = Color3.fromRGB(255, 0, 0)
        },
        checktype = "player"
    },
    {
        metaName = "KeyESP",
        text = "钥匙",
        default = false,
        color = {
            metaName = "KeyEspColor",
            default = Color3.fromRGB(255, 255, 0)
        },
        checktype = "key",
        descendantcheck = function(descendant)
            local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
            if not hideAndSeekMap then return end
            if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "KEYS" and descendant.Parent.Parent == hideAndSeekMap then
                Script.Functions.KeyESP(descendant)
            end
        end
    },
    {
        metaName = "DoorESP",
        text = "门",
        default = false,
        color = {
            metaName = "DoorEspColor",
            default = Color3.fromRGB(0, 128, 255)
        },
        checktype = "door",
        descendantcheck = function(descendant)
            local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
            if not hideAndSeekMap then return end
            if descendant:IsA("Model") and descendant.Name == "FullDoorAnimated" and descendant.Parent and descendant.Parent.Parent and descendant.Parent.Parent.Name == "NEWFIXEDDOORS" then
                Script.Functions.DoorESP(descendant)
            end
        end
    }
}

local ESPGroupBox = Tabs.Visuals:AddLeftGroupbox("捉迷藏绘制") do
    for _, meta in pairs(ESP_META) do
        ESPGroupBox:AddToggle(meta.metaName, {
            Text = meta.text,
            Default = meta.default
        }):AddColorPicker(meta.color.metaName, {
            Default = meta.color.default
        })

        Toggles[meta.metaName]:OnChanged(function(call)
            if call then
                if not string.find(Script.GameState, "HideAndSeek") then return end
                if meta.checktype == "player" then
                    for _, player in pairs(Players:GetPlayers()) do
                        Script.Functions[meta.metaName](player)
                    end
                elseif meta.checktype == "key" then
                    local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
                    if hideAndSeekMap then
                        local keysFolder = hideAndSeekMap:FindFirstChild("KEYS")
                        if keysFolder then
                            for _, key in pairs(keysFolder:GetChildren()) do
                                Script.Functions.KeyESP(key)
                            end
                        end
                    end
                elseif meta.checktype == "door" then
                    local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
                    if hideAndSeekMap then
                        local newFixedDoors = hideAndSeekMap:FindFirstChild("NEWFIXEDDOORS")
                        if newFixedDoors then
                            for _, floor in pairs(newFixedDoors:GetChildren()) do
                                if floor.Name:match("^Floor") then
                                    for _, door in pairs(floor:GetChildren()) do
                                        Script.Functions.DoorESP(door)
                                    end
                                end
                            end
                        end
                    end
                end
            else
                for _, esp in pairs(Script.ESPTable[meta.text]) do
                    esp.Destroy()
                end
            end
        end)

        Options[meta.color.metaName]:OnChanged(function(value)
            for _, esp in pairs(Script.ESPTable[meta.text]) do
                esp.SetColor(value)
            end
        end)

        if meta.descendantcheck then
            Library:GiveSignal(workspace.DescendantAdded:Connect(function(descendant)
                if not string.find(Script.GameState, "HideAndSeek") then return end
                if not Toggles[meta.metaName].Value then return end
                meta.descendantcheck(descendant)
            end))
        end
    end
end

local ESPSettingsGroupBox = Tabs.Visuals:AddRightGroupbox("绘制设置") do
    ESPSettingsGroupBox:AddToggle("ESPHighlight", {
        Text = "开启高亮",
        Default = true,
    })

    ESPSettingsGroupBox:AddToggle("ESPDistance", {
        Text = "显示距离",
        Default = true,
    })

    ESPSettingsGroupBox:AddSlider("ESPFillTransparency", {
        Text = "透明度",
        Default = 0.75,
        Min = 0,
        Max = 1,
        Rounding = 2
    })

    ESPSettingsGroupBox:AddSlider("ESPOutlineTransparency", {
        Text = "轮框透明度",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2
    })

    ESPSettingsGroupBox:AddSlider("ESPTextSize", {
        Text = "文字大小",
        Default = 22,
        Min = 16,
        Max = 26,
        Rounding = 0
    })
end

local SelfGroupBox = Tabs.Visuals:AddRightGroupbox("自身") do
    SelfGroupBox:AddToggle("FOVToggle", {
        Text = "视角开启",
        Default = false
    })
    SelfGroupBox:AddSlider("FOVSlider", {
        Text = "视角大小",
        Default = 60, 
        Min = 10,
        Max = 120,
        Rounding = 1
    })
end

local GreenLightRedLightGroup = Tabs.Main:AddLeftGroupbox("红绿灯") do
    GreenLightRedLightGroup:AddButton("通关红绿灯", function()
        if not game.Workspace:FindFirstChild("RedLightGreenLight") then
            Script.Functions.Alert("游戏还未开启")
            return
        end
        lplr.Character:PivotTo(CFrame.new(Vector3.new(-100.8, 1030, 115)))
    end)
    GreenLightRedLightGroup:AddButton("移除受伤", function()
        Script.Functions.Alert("开启", 3)
    end)
end

local DangolaGameGroup = Tabs.Main:AddLeftGroupbox("扣糖饼") do
    DangolaGameGroup:AddButton("通关扣糖饼", function()
        if not game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):FindFirstChild("DALGONATEMPREMPTE") then
            Script.Functions.Alert("游戏还未开启")
            return
        end
        Script.Functions.CompleteDalgonaGame()
        Script.Functions.BypassDalgonaGame()
        Script.Functions.FixCamera()
        Script.Functions.Alert("通关扣糖并成功", 2)
        Script.Functions.Alert("请你使用修复视角", 3)
    end)
end

local TugOfWarGroup = Tabs.Main:AddLeftGroupbox("拔河") do
    TugOfWarGroup:AddToggle("AutoPull", {
        Text = "自动拔河",
        Default = false
    })
    TugOfWarGroup:AddToggle("PerfectPull", {
        Text = "百分百完美拔河",
        Default = true
    })
end

local GlassBridgeGroup = Tabs.Main:AddLeftGroupbox("玻璃墙") do
    GlassBridgeGroup:AddButton("通关玻璃桥", function()
        Script.Functions.Alert("")
        --lplr.Character:PivotTo(workspace.GlassBridge.End:GetPrimaryPartCFrame())
    end)
    GlassBridgeGroup:AddButton("显示玻璃桥", function()
        if not workspace:FindFirstChild("GlassBridge") then
            Script.Functions.Alert("游戏还未开启")
            return
        end
        Script.Functions.RevealGlassBridge()
    end)
end

local InformationGroup = Tabs.Main:AddRightGroupbox("信息") do
    InformationGroup:AddLabel("欢迎你使用我的脚本")
    InformationGroup:AddLabel("请你加入我的QQ群接收每天的定期更新")
    InformationGroup:AddButton("加入我的QQ群", Script.Functions.JoinDiscordServer)
    InformationGroup:AddButton("关闭", function() Library:Unload() end)
end

local MiscGroup = Tabs.Main:AddRightGroupbox("我也不知道起到什么用") do
    MiscGroup:AddToggle("AntiRagdoll", {
        Text = "无视布娃娃与减速",
        Default = false
    })
    MiscGroup:AddButton("移除布娃娃", Script.Functions.BypassRagdoll)
    MiscGroup:AddDivider()
    MiscGroup:AddButton("修复视角", Script.Functions.FixCamera)
end

Toggles.AntiRagdoll:OnChanged(function()
    if call then
        Script.Functions.Alert("无视布娃娃与减速开启", 3)
        Script.Functions.BypassRagdoll()
        task.spawn(function()
            repeat
                task.wait()
                Script.Functions.BypassRagdoll()
            until not Toggles.AntiRagdoll.Value or Library.Unloaded
        end)
    else
        Script.Functions.Alert("无视布娃娃加减速取消", 3)
    end
end)

Library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        camera = workspace.CurrentCamera
    end
end))

Toggles.FOVToggle:OnChanged(function(call)
    if call then
        Script.Temp.OldFOV = camera and camera.FieldOfView or 60
        task.spawn(function()
            repeat 
                if camera then
                    camera.FieldOfView = Options.FOVSlider.Value
                end
                task.wait()
            until not Toggles.FOVToggle.Value or Library.Unloaded
        end)
    end
end)

local PlayerGroupBox = Tabs.Main:AddRightGroupbox("玩家") do
    PlayerGroupBox:AddSlider("SpeedSlider", {
        Text = "移动速度",
        Default = 30,
        Min = 0,
        Max = 100,
        Rounding = 1
    })
    
    PlayerGroupBox:AddToggle("SpeedToggle", {
        Text = "开启速度",
        Default = false
    }):AddKeyPicker("SpeedKey", {
        Mode = "Toggle",
        Default = "C",
        Text = "速度",
        SyncToggleState = true
    })

    PlayerGroupBox:AddToggle("Noclip", {
        Text = "穿墙",
        Default = false
    }):AddKeyPicker("NoclipKey", {
        Mode = "Toggle",
        Default = "N",
        Text = "穿墙",
        SyncToggleState = true
    })

    PlayerGroupBox:AddToggle("InfiniteJump", {
        Text = "无限跳跃",
        Default = false
    })

    PlayerGroupBox:AddToggle("Fly", {
        Text = "飞行 (不稳定)",
        Default = false
    })--[[:AddKeyPicker("FlyKey", {
        Mode = "Toggle",
        Default = "F",
        Text = "飞行",
        SyncToggleState = true
    })--]]
    
    PlayerGroupBox:AddSlider("FlySpeed", {
        Text = "飞行速度",
        Default = 40,
        Min = 10,
        Max = 100,
        Rounding = 1,
        Compact = true,
    })
end

Toggles.Fly:SetVisible(false)
Options.FlySpeed:SetVisible(false)

Toggles.Noclip:OnChanged(function(call)
    if call then
        local function NoclipLoop()
            if lplr.Character ~= nil then
                for _, child in pairs(lplr.Character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide == true then
                        child.CanCollide = false
                    end
                end
            end
        end
        task.spawn(function()
            repeat 
                RunService.Heartbeat:Wait()
                NoclipLoop()
            until not Toggles.Noclip.Value or Library.Unloaded
        end)
    else
    if lplr.Character ~= nil then
            for _, child in pairs(lplr.Character:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide == false then
                    child.CanCollide = true
                end
            end
        end
    end
end)

Options.SpeedSlider:OnChanged(function(val)
    if not Toggles.SpeedToggle.Value then return end
    if not lplr.Character then return end
    if not lplr.Character:FindFirstChild("Humanoid") then return end
    lplr.Character.Humanoid.WalkSpeed = Options.SpeedSlider.Value
end)

Toggles.SpeedToggle:OnChanged(function(call)
    if call then
        task.spawn(function()
            repeat
                task.wait(0.5)
                if not lplr.Character then return end
                if not lplr.Character:FindFirstChild("Humanoid") then return end
                if call then
                    Script.Temp.OldSpeed = lplr.Character.Humanoid.WalkSpeed
                    lplr.Character.Humanoid.WalkSpeed = Options.SpeedSlider.Value
                else
                    lplr.Character.Humanoid.WalkSpeed = Script.Temp.OldSpeed or 23
                end
            until not Toggles.SpeedToggle.Value or Library.Unloaded
        end)
    else
    end
end)    

local controlModule

Toggles.Fly:OnChanged(function(value)
    local rootPart = Script.Functions.GetRootPart()
    if not rootPart then return end

    local humanoid = Script.Functions.GetHumanoid()
    if humanoid then
        humanoid.PlatformStand = value
    end

    local flyBody = Script.Temp.FlyBody or Instance.new("BodyVelocity")
    flyBody.Velocity = Vector3.zero
    flyBody.MaxForce = Vector3.one * 9e9
    Script.Temp.FlyBody = flyBody

    Script.Temp.FlyBody.Parent = value and rootPart or nil

    if value then
        controlModule = controlModule or Script.Functions.SafeRequire(lplr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        Script.Connections["Fly"] = RunService.RenderStepped:Connect(function()
            local moveVector = controlModule:GetMoveVector()
            local velocity = -((camera.CFrame.LookVector * moveVector.Z) - (camera.CFrame.RightVector * moveVector.X)) * Options.FlySpeed.Value

            Script.Temp.FlyBody.Velocity = velocity
        end)
    else
        if Script.Connections["Fly"] then
            Script.Connections["Fly"]:Disconnect()
        end
    end
end)

Library:GiveSignal(lplr.CharacterAdded:Connect(function(char)
    if not Toggles.SpeedToggle.Value then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    hum.WalkSpeed = Options.SpeedSlider.Value
end))

Library:GiveSignal(lplr:GetAttributeChangedSignal("CurrentLighting"):Connect(function()
    Script.GameState = lplr:GetAttribute("CurrentLighting")
    Script.GameStateChanged:Fire(Script.GameState)

    if not Script.GameState then return end
    Script.GameState = tostring(Script.GameState)
    if string.find(Script.GameState, "HideAndSeek") then
        for _, meta in pairs(ESP_META) do
            if not Toggles[meta.metaName] then continue end
            if Toggles[meta.metaName].Value then
                Toggles[meta.metaName]:SetValue(false)
                Toggles[meta.metaName]:SetValue(true)
            end
        end
    end
end))

Toggles.AutoPull:OnChanged(function(call)
    if call then
        task.spawn(function()
            repeat
                Script.Functions.PullRope(Toggles.PerfectPull.Value)
                task.wait()
            until not Toggles.AutoPull.Value or Library.Unloaded
        end)
    end
end)

Library:GiveSignal(UserInputService.JumpRequest:Connect(function()
    if Toggles.InfiniteJump.Value then
        if not lplr.Character then return end
        if not lplr.Character:FindFirstChild("Humanoid") then return end
        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

for _, player in pairs(Players:GetPlayers()) do
    if player == localPlayer then continue end
    Script.Functions.SetupOtherPlayerConnection(player)
end

Library:GiveSignal(Players.PlayerAdded:Connect(function(player)
    if player == localPlayer then return end
    Script.Functions.SetupOtherPlayerConnection(player)
end))

task.spawn(function() pcall(Script.Functions.OnLoad) end)

Library:OnUnload(function()
    pcall(function()
        Script.Maid:Clean()
    end)
    for _, conn in pairs(Script.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    SaveManager:Save()
    Library.Unloaded = true
    getgenv().voidware_loaded = false
    shared.Voidware_InkGame_Library = nil
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
local CreditsGroup = Tabs["UI Settings"]:AddRightGroupbox("Credits")

MenuGroup:AddToggle("KeybindMenuOpen", { Default = false, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddToggle("ShowCustomCursor", {Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = false, Text = "Menu keybind" })
MenuGroup:AddButton("Join Discord Server", Script.Functions.JoinDiscordServer)
MenuGroup:AddButton("Unload", function() Library:Unload() end)

CreditsGroup:AddLabel("erchodev#0 - script dev")
CreditsGroup:AddLabel("linoria - ui library")
CreditsGroup:AddLabel("mspaint v2")
CreditsGroup:AddLabel("Inf Yield")
CreditsGroup:AddLabel("Please notify me if you need \n credits (erchodev#0 on discord)")

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({  })
-- "MenuKeybind"

ThemeManager:SetFolder("voidware_linoria")
SaveManager:SetFolder("voidware_linoria/ink_game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])

ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
