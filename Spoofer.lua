-- Configurable RBLXSCRIPTS Spoofer
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

local targetId = avatarId > 0 and avatarId or Players.LocalPlayer.UserId

local success, UserData = pcall(function()
    return game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(targetId), true)
end)

if not success then
    print("Failed to fetch user data")
    return
end

local decodedData = game:GetService("HttpService"):JSONDecode(UserData)

if spoofEveryone then
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then
            if username ~= "" then plr.Name = username end
            if displayName ~= "" then plr.DisplayName = displayName end
        end
    end
else
    local target = Players.LocalPlayer
    if username ~= "" then target.Name = username end
    if displayName ~= "" then target.DisplayName = displayName end
    target.UserId = decodedData.id
    target.CharacterAppearanceId = targetId
end

local function applyCharacter(plr)
    if not plr.Character then return end
    local char = plr.Character
    char:WaitForChild("Humanoid", 5)
    
    if username ~= "" then char.Name = username end
    if displayName ~= "" then char.Humanoid.DisplayName = displayName end

    local success, appearance = pcall(function()
        return Players:GetCharacterAppearanceAsync(targetId)
    end)
    if not success then 
        print("Failed to load appearance")
        return 
    end

    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
            v:Destroy()
        end
    end

    for _, v in pairs(appearance:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
            v.Parent = char
        elseif v:IsA("Accessory") then
            char.Humanoid:AddAccessory(v)
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        if head:FindFirstChild("face") then head.face:Destroy() end
        if appearance:FindFirstChild("face") then
            appearance.face.Parent = head
        else
            local face = Instance.new("Decal")
            face.Name = "face"
            face.Face = "Front"
            face.Texture = "rbxasset://textures/face.png"
            face.Parent = head
        end
    end

    local parent = char.Parent
    char.Parent = nil
    char.Parent = parent
end

if not spoofEveryone then
    Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyCharacter(Players.LocalPlayer)
    end)
    if Players.LocalPlayer.Character then
        applyCharacter(Players.LocalPlayer)
    end
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__index", function(self, key)
    if not spoofEveryone and self == Players.LocalPlayer then
        if key == "MembershipType" and premium then
            return Enum.MembershipType.Premium
        end
        if key == "HasVerifiedBadge" and verified then
            return true
        end
    end
    return oldNamecall(self, key)
end)
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
    print(identifyexecutor())
end
