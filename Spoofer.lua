-- spoof
local cfg = getgenv().Config

local spoofEveryone = cfg.spoofEveryone or false
local username = cfg.username or ""
local displayName = cfg.displayName or ""
local avatarId = tonumber(cfg.avatarId) or 0
local premium = cfg.premium or false
local verified = cfg.verified or false
local spoofExecutor = cfg.spoofExecutor or false
local fakeExecutorName = cfg.fakeExecutorName or "RBLXSCRIPTS.NET"

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local targetId = avatarId > 0 and avatarId or LocalPlayer.UserId

local success, UserData = pcall(function()
    return game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(targetId), true)
end)
if not success then return end

local decodedData = game:GetService("HttpService"):JSONDecode(UserData)

-- Name & DisplayName Spoof
if spoofEveryone then
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if username ~= "" then plr.Name = username end
            if displayName ~= "" then plr.DisplayName = displayName end
        end
    end
else
    if username ~= "" then LocalPlayer.Name = username end
    if displayName ~= "" then LocalPlayer.DisplayName = displayName end
    LocalPlayer.UserId = decodedData.id
    LocalPlayer.CharacterAppearanceId = targetId
end

-- Improved Avatar Changer
local function getDesc(id)
    local success, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(id)
    end)
    return success and desc or nil
end

local function cleanCharacter(char)
    if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("BodyColors") or
           v:IsA("CharacterMesh") or v:IsA("Shirt") or v:IsA("Pants") or
           v:IsA("ShirtGraphic") then
            v:Destroy()
        end
    end
end

local applying = false

local function applyAvatar(target_id)
    if applying then return end
    applying = true
    
    local char = LocalPlayer.Character
    if not char then 
        applying = false
        return 
    end
    
    local hum = char:WaitForChild("Humanoid", 3)
    if not hum then 
        applying = false
        return 
    end

    task.wait(0.8)
    
    local desc = getDesc(target_id)
    if not desc then 
        applying = false
        return 
    end

    cleanCharacter(char)
    
    pcall(function()
        if hum.ApplyDescriptionClientServer then
            hum:ApplyDescriptionClientServer(desc)
        else
            hum:ApplyDescription(desc)
        end
    end)

    -- Force BodyColors
    task.wait(0.3)
    local bc = char:FindFirstChildOfClass("BodyColors")
    if not bc then
        bc = Instance.new("BodyColors")
        bc.Parent = char
    end
    bc.HeadColor3 = desc.HeadColor
    bc.TorsoColor3 = desc.TorsoColor
    bc.LeftArmColor3 = desc.LeftArmColor
    bc.RightArmColor3 = desc.RightArmColor
    bc.LeftLegColor3 = desc.LeftLegColor
    bc.RightLegColor3 = desc.RightLegColor

    applying = false
end

if not spoofEveryone then
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.2)
        applyAvatar(targetId)
    end)
    
    if LocalPlayer.Character then
        task.wait(1.2)
        applyAvatar(targetId)
    end
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__index", function(self, key)
    if not spoofEveryone and self == LocalPlayer then
        if key == "MembershipType" and premium then
            return Enum.MembershipType.Premium
        end
        if key == "HasVerifiedBadge" and verified then
            return true
        end
    end
    return oldNamecall(self, key)
end)

-- Executor Spoof
if spoofExecutor then
    getgenv().FakeExecutorName = fakeExecutorName
    local oldIdentify = identifyexecutor
    identifyexecutor = function()
        return getgenv().FakeExecutorName
    end
    getexecutorname = function()
        return getgenv().FakeExecutorName
    end
    pcall(function()
        hookfunction(oldIdentify, function()
            return getgenv().FakeExecutorName
        end)
    end)
end
