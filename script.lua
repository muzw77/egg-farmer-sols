-- ⏳ Wait for game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 🔄 Global control (for reloading)
_G.EggFarmerRunning = true

-- ⏳ Wait for player + character
local player = game.Players.LocalPlayer
while not player do
    game.Players.PlayerAdded:Wait()
    player = game.Players.LocalPlayer
end

local character = player.Character or player.CharacterAdded:Wait()
repeat task.wait() until character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")

local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

local TRY_TIME = 6
local WALK_TIMEOUT = 40

-- 🥇 Egg Priority
local eggPriority = {
    ["dreamer_egg"] = 1,
    ["egg_v2_0"] = 2,
    ["the_egg_of_the_sky"] = 3,
    ["forest_egg"] = 4,
    ["blooming_egg"] = 5,
    ["angelic_egg"] = 6,
    ["andromeda_egg"] = 7,
    ["royal_egg"] = 8,
    ["hatch_egg"] = 9,
    ["point_egg_6"] = 10,
    ["point_egg_5"] = 11,
    ["point_egg_4"] = 12,
    ["point_egg_3"] = 13,
    ["point_egg_2"] = 14,
    ["point_egg_1"] = 15,
    ["random_potion_egg_2"] = 16,
    ["random_potion_egg_1"] = 17
}

-- 🖥️ UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggStatusUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 320, 0, 50)
statusLabel.Position = UDim2.new(0.5, -160, 0, 20)
statusLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
statusLabel.TextColor3 = Color3.fromRGB(255,255,255)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "Starting..."
statusLabel.Parent = screenGui

Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 12)

-- 🔄 Reload Button
local reloadButton = Instance.new("TextButton")
reloadButton.Size = UDim2.new(0, 50, 0, 50)
reloadButton.Position = UDim2.new(0.5, 170, 0, 20)
reloadButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
reloadButton.TextColor3 = Color3.fromRGB(255,255,255)
reloadButton.TextScaled = true
reloadButton.Font = Enum.Font.SourceSansBold
reloadButton.Text = "⟳"
reloadButton.Parent = screenGui

Instance.new("UICorner", reloadButton).CornerRadius = UDim.new(0, 12)

local function setStatus(text)
    statusLabel.Text = text
end

-- 🔄 Reload Logic (LOCAL SAFE VERSION)
reloadButton.MouseButton1Click:Connect(function()
    setStatus("🔄 Reloading...")

    _G.EggFarmerRunning = false -- stop loops

    task.wait(0.5)
    screenGui:Destroy()

    -- restart script (re-executes itself)
    task.spawn(function()
        loadstring(game:HttpGet("https://pastebin.com/raw/YOUR_LINK_HERE"))()
    end)
end)

-- ✅ Get eggs
local function getValidEggs()
    local eggs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if eggPriority[name] then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if part and prompt then
                    table.insert(eggs, {model=obj, part=part, prompt=prompt})
                end
            end
        end
    end
    return eggs
end

-- 🎯 Best egg
local function getBestEgg(blacklist)
    local best, score = nil, math.huge
    for _, data in ipairs(getValidEggs()) do
        if not blacklist[data.model] then
            local p = eggPriority[data.model.Name:lower()] or 999
            local d = (rootPart.Position - data.part.Position).Magnitude
            local s = p * 10000 + d
            if s < score then
                score = s
                best = data
            end
        end
    end
    return best
end

-- 🚶 Move
local function moveTo(pos)
    local startTime = tick()

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    path:ComputeAsync(rootPart.Position, pos)
    if path.Status ~= Enum.PathStatus.Success then return false end

    for _, wp in ipairs(path:GetWaypoints()) do
        humanoid:MoveTo(wp.Position)

        local reached = false
        local conn = humanoid.MoveToFinished:Connect(function()
            reached = true
        end)

        while not reached do
            if tick() - startTime > WALK_TIMEOUT then
                conn:Disconnect()
                return false
            end
            task.wait(0.2)
        end

        conn:Disconnect()
    end

    return true
end

-- 🖐️ Pickup
local function tryPickup(data)
    setStatus("Picking up " .. data.model.Name)

    local start = tick()
    while tick() - start < TRY_TIME do
        if not data.model.Parent then return true end

        fireproximityprompt(data.prompt)
        humanoid:MoveTo(data.part.Position)

        task.wait(0.2)
    end

    return false
end

-- 🕹️ Anti-AFK
task.spawn(function()
    while _G.EggFarmerRunning do
        task.wait(60)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- 🔁 MAIN LOOP
local blacklist = {}

while _G.EggFarmerRunning do
    local egg = getBestEgg(blacklist)

    if egg then
        setStatus("Walking to " .. egg.model.Name)

        if moveTo(egg.part.Position) then
            if not tryPickup(egg) then
                blacklist[egg.model] = true
            end
        else
            blacklist[egg.model] = true
        end
    else
        setStatus("Waiting for eggs...")
        blacklist = {}
        task.wait(2)
    end

    task.wait(0.3)
end
