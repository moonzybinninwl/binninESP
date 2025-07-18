local players = game:GetService("Players")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local tween = game:GetService("TweenService")
local cam = workspace.CurrentCamera
local me = players.LocalPlayer

local cfg = {
    esp = true,
    tracers = true,
    feed = true
}

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "BinninESP_UI"
gui.ResetOnSpawn = false

local splash = Instance.new("TextLabel", gui)
splash.Size = UDim2.new(0, 400, 0, 100)
splash.Position = UDim2.new(0.5, -200, 0.4, 0)
splash.Text = "Welcome to BinninESP"
splash.TextColor3 = Color3.new(1,1,1)
splash.TextScaled = true
splash.Font = Enum.Font.GothamBold
splash.BackgroundColor3 = Color3.fromRGB(30,30,30)
splash.BorderSizePixel = 0
splash.BackgroundTransparency = 1
splash.TextTransparency = 1
Instance.new("UICorner", splash).CornerRadius = UDim.new(0,8)

tween:Create(splash, TweenInfo.new(1), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
task.wait(2)
tween:Create(splash, TweenInfo.new(1), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
task.wait(1)
splash:Destroy()

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 180)
panel.Position = UDim2.new(0, 10, 0, 200)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
panel.BorderSizePixel = 0
panel.Visible = true
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,8)

tween:Create(panel, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

local drag, dragInput, dragStart, startPos
panel.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true
        dragStart = inp.Position
        startPos = panel.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end
end)

panel.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = inp
    end
end)

uis.InputChanged:Connect(function(inp)
    if inp == dragInput and drag then
        local delta = inp.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

uis.InputBegan:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.RightShift then
        panel.Visible = not panel.Visible
    end
end)

local function makeBtn(text, y, key)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = text..": ON"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.MouseEnter:Connect(function()
        tween:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        tween:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        btn.Text = text..": "..(cfg[key] and "ON" or "OFF")
    end)
end

makeBtn("ESP", 10, "esp")
makeBtn("Tracers", 55, "tracers")
makeBtn("Killfeed", 100, "feed")

local feedFrame = Instance.new("Frame", gui)
feedFrame.Size = UDim2.new(0, 250, 0, 200)
feedFrame.Position = UDim2.new(1, -260, 0.3, 0)
feedFrame.BackgroundTransparency = 1

local function logKill(txt)
    if not cfg.feed then return end
    local lbl = Instance.new("TextLabel", feedFrame)
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.Position = UDim2.new(0,0,0,#feedFrame:GetChildren()*20 - 20)
    lbl.Text = txt
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.BackgroundTransparency = 1
    task.delay(3, function() lbl:Destroy() end)
end

local fov = Drawing.new("Circle")
fov.Thickness = 1
fov.NumSides = 50
fov.Radius = 100
fov.Color = Color3.fromRGB(255, 255, 255)
fov.Filled = false
fov.Transparency = 0.5

local plrDraws = {}
local function clear(player)
    if plrDraws[player] then
        for _,d in pairs(plrDraws[player]) do d:Remove() end
        plrDraws[player] = nil
    end
end

players.PlayerRemoving:Connect(clear)

local function barColor(healthPct)
    if healthPct > 0.5 then
        return Color3.fromRGB(0,255,0)
    elseif healthPct > 0.2 then
        return Color3.fromRGB(255,165,0)
    else
        return Color3.fromRGB(255,0,0)
    end
end

local function hookChar(p)
    p.CharacterAdded:Connect(function(c)
        local hum = c:WaitForChild("Humanoid")
        hum.Died:Connect(function()
            if not cfg.feed then return end
            if p == me then
                local killer = "Unknown"
                for _,plr in ipairs(players:GetPlayers()) do
                    if plr ~= me and plr.Character and plr.Character:FindFirstChild("Humanoid") then
                        local tag = hum:FindFirstChild("creator")
                        if tag and tag.Value == plr then
                            killer = plr.Name
                            break
                        end
                    end
                end
                logKill(killer.." killed YOU")
            else
                local tag = hum:FindFirstChild("creator")
                if tag and tag.Value == me then
                    logKill("You killed "..p.Name)
                end
            end
        end)
    end)
end

for _,p in ipairs(players:GetPlayers()) do hookChar(p) end
players.PlayerAdded:Connect(hookChar)

run.RenderStepped:Connect(function()
    fov.Position = cam.ViewportSize/2

    for _,p in ipairs(players:GetPlayers()) do
        if p ~= me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            local root = p.Character.HumanoidRootPart
            local hum = p.Character.Humanoid
            local pos, vis = cam:WorldToViewportPoint(root.Position)

            if not plrDraws[p] then
                plrDraws[p] = {
                    box = Drawing.new("Square"),
                    hp = Drawing.new("Square"),
                    line = Drawing.new("Line"),
                    name = Drawing.new("Text")
                }
            end

            for _,d in pairs(plrDraws[p]) do d.Visible = false end
            if hum.Health <= 0 then clear(p) continue end

            if vis and cfg.esp then
                local h = (cam:WorldToViewportPoint(root.Position + Vector3.new(0,3,0)).Y - cam:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y)
                local w = h/2
                local rainbow = Color3.fromHSV(tick()%5/5,1,1)

                local box = plrDraws[p].box
                box.Visible = true
                box.Size = Vector2.new(w, h)
                box.Position = Vector2.new(pos.X-w/2, pos.Y-h/2)
                box.Color = rainbow
                box.Thickness = 1
                box.Filled = false

                local hp = plrDraws[p].hp
                hp.Visible = true
                hp.Size = Vector2.new(2, -h*(hum.Health/hum.MaxHealth))
                hp.Position = Vector2.new(pos.X-w/2-4, pos.Y+h/2)
                hp.Color = barColor(hum.Health/hum.MaxHealth)
                hp.Filled = true

                local name = plrDraws[p].name
                name.Visible = true
                name.Text = p.Name
                name.Position = Vector2.new(pos.X-w/2, pos.Y-h/2-15)
                name.Color = Color3.new(1,1,1)
                name.Center = false
                name.Size = 13
                name.Outline = true

                if cfg.tracers then
                    local line = plrDraws[p].line
                    line.Visible = true
                    line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Color = Color3.new(1,1,1)
                    line.Thickness = 1
                end
            end
        else
            clear(p)
        end
    end
end)
