local lib = syn.request({ Url = "https://raw.githubusercontent.com/sv3softworks/RWLibrary/main/main.lua" }).Body
local Library = loadstring(lib)()

local Window = Library:new({Size = Vector2.new(600,400)})
if getgenv().Window then
    table.clear(getgenv().Window)
end
getgenv().Window = Window

local ColorOptions = {
    'Text',
    'TextDisabled',
    'WindowBg',
    'ChildBg',
    'PopupBg',
    'Border',
    'BorderShadow',
    'FrameBg',
    'FrameBgHovered',
    'FrameBgActive',
    'TitleBg',
    'TitleBgActive',
    'TitleBgCollapsed',
    'MenuBarBg',
    'ScrollbarBg',
    'ScrollbarGrab',
    'ScrollbarGrabHovered',
    'ScrollbarGrabActive',
    'CheckMark',
    'SliderGrab',
    'SliderGrabActive',
    'Button',
    'ButtonHovered',
    'ButtonActive',
    'Header',
    'HeaderHovered',
    'HeaderActive',
    'Separator',
    'SeparatorHovered',
    'SeparatorActive',
    'ResizeGrip',
    'ResizeGripHovered',
    'ResizeGripActive',
    'Tab',
    'TabHovered',
    'TabActive',
    'TabUnfocused',
    'TabUnfocusedActive',
    'DockingPreview',
    'DockingEmptyBg',
    'PlotLines',
    'PlotLinesHovered',
    'PlotHistogram',
    'PlotHistogramHovered',
    'TableHeaderBg',
    'TableBorderStrong',
    'TableBorderLight',
    'TableRowBg',
    'TableRowBgAlt',
    'TextSelectedBg',
    'DragDropTarget',
    'NavHighlight',
    'NavWindowingHighlight',
    'NavWindowingDimBg',
    'ModalWindowDimBg',
}

local MousePoint = PointMouse.new()
local FOVCircle = CircleDynamic.new(MousePoint)
FOVCircle.Color = Color3.fromRGB(1,1,0)
local CurrentMode = "Linear"
local TargetPart = "Head"
local WTVP = workspace.CurrentCamera.WorldToViewportPoint
local UserInputService = game.UserInputService
local WorldToScreen = function(...) return WTVP(workspace.CurrentCamera, ...) end
local PlayerPoints = {}
local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ESPPoints = {}
local Drawings = {}

local function getMouseLocation()
    return (workspace.CurrentCamera.ViewportSize/2)
end

function beziercurve(p0, p1, p2, alpha)
    local l1 = p0:Lerp(p1, alpha)
    local l2 = p1:Lerp(p2, alpha)

    return l1:Lerp(l2, alpha)
end

local BoxSettings = {
    Thickness = 1,
    Filled = false,
    Opacity = .5
}
function characterAdded(Character)
    local points = {}
    if Drawings[Character.Name] then
        Drawings[Character.Name][3]:Destroy()
        table.clear(Drawings[Character.Name])
        table.clear(ESPPoints[Character.Name])
        table.clear(PlayerPoints[Character.Name])
    end
    Character:WaitForChild("Head")
    for i,v in Character:GetChildren() do
        if v:IsA("BasePart") then
            points[v.Name] = PointInstance.new(v)
            points[v.Name].RotationType = CFrameRotationType.Ignore
            --local circle = CircleDynamic.new(points[v.Name])
            --circle.Radius = 1
            --task.delay(30, function()
            --    circle = nil
            --end)
        end
    end
    local Head = Character:FindFirstChild("FakeHead") or Character:FindFirstChild("Head")
    local esppoints = {
        TopLeft = PointInstance.new(Character.Head, CFrame.new(-2, .5, 0));
        BottomRight = PointInstance.new(Character.Head, CFrame.new(2, -4.5,0));
        Front = PointInstance.new(Head, CFrame.new(0,0,-2))
    }

    esppoints.Front.RotationType = CFrameRotationType.TargetRelative
    ESPPoints[Character.Name] = esppoints
    PlayerPoints[Character.Name] = points

    local Box = RectDynamic.new(esppoints.TopLeft)
    Box.BottomRight = esppoints.BottomRight
    Box.Visible = false
    Box.Outlined = true
    Box.OutlineThickness = 1
    for i,v in pairs(BoxSettings) do
        Box[i] = v
    end
    local Line = LineDynamic.new(points.Head, esppoints.Front)
    Line.Visible = false
    Line.Thickness = 2
    local Highlight = Instance.new('Highlight')
    Highlight.Enabled = false
    Highlight.Parent = game.CoreGui
    Highlight.Adornee = Character
    Drawings[Character.Name] = {Box, Line,  Highlight}

    return points
end

local function closestPart(Character)
    local dot = -2
    local part
    for i,v in Character:GetChildren() do
        if v:IsA('BasePart') then
            local pos = WorldToScreen(v.Position)
            pos = Vector2.new(pos.X, pos.Y)
            local LV = Vector2.new(Mouse.Origin.LookVector.X, Mouse.Origin.LookVector.Y)
            --print(pos, getMouseLocation(), LV)
            local Dot = LV:Dot((pos-getMouseLocation()).Unit)
            --print(Dot)
            if Dot > dot then
                dot = Dot
                part = v
            end
        end
    end

    return part or Character:FindFirstChild("Head")
end

function findClosestCharacter(range)
    local closest


    for i,v in game.Players:GetPlayers() do
        local Character = v.Character
        if Character and v ~= LocalPlayer then
            if v.Character:FindFirstChild("Humanoid") 
            and v.Character:FindFirstChild("Humanoid").Health <= 0 then
                continue
            end
            local pos = v.Character:GetPivot().Position
            local closestpart = closestPart(v.Character)
            --print(closestpart, worldtoscreen({closestpart}))
            if closestpart then
                pos,vis = WorldToScreen(closestpart.Position)
                if pos and vis then
                    pos = Vector2.new(pos.X, pos.Y)
                    local dist = (pos-getMouseLocation()).Magnitude
                    if dist < range then
                        range = dist
                        closest = v.Character
                    end
                end
            end
        end
    end

    return closest
end

function findClosestPoint(fov)
    local Character = findClosestCharacter(fov)

    if not Character then return end
    local Points = PlayerPoints[Character.Name]
    local closest
    local fov = math.huge
    if Points then
        for i,v in Points do
            local dist = (v.ScreenPos-getMouseLocation()).Magnitude
            if dist < fov then
                fov = dist
                closest = v
            end
        end

        return closest
    end
end

task.spawn(function()
    for i,v in game.Players:GetPlayers() do
        if v == LocalPlayer then continue end
        if v.Character then
            characterAdded(v.Character)
        end
        local c; c = v.CharacterAdded:Connect(characterAdded)
        task.spawn(function()
            repeat task.wait() until Window ~= getgenv().Window
            c:Disconnect()
        end)
    end
end)

game.Players.PlayerAdded:Connect(function(Player)
    if Player == LocalPlayer then return end
    if Player.Character then
        characterAdded(Player.Character)
    end
    local c; c = Player.CharacterAdded:Connect(characterAdded)
    task.spawn(function()
        repeat task.wait() until Window ~= getgenv().Window
        c:Disconnect()
    end)
end)

function divideVector2(v2, div)
    return Vector2.new(v2.X/div, v2.Y/div)
end
local function getCharacterFromPart(Part)
    local isEnemy
    for i,v in game.Players:GetPlayers() do
        if v ~= LocalPlayer and v.Character 
        and Part:IsDescendantOf(v.Character)
        and (v.TeamColor ~= LocalPlayer.TeamColor or Window.flags.IgnoreTeams) then
            isEnemy = v.Character
        end
    end

    return isEnemy
end

local Tabs = {
    {Legit = function(Library)
        Library:Child({Size = Vector2.new(100,4)})
        Library.With(Library:SameLine({}), function(Library)
        local Preset = {Size = Vector2.new(210,180)}
            Library:Child({Size = Vector2.new(1,10)})

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Aimbot"})
                Library:Separator({})
                Library:CheckBox({tag = "AimbotEnabled", Label = "Enabled"})
                Library:CheckBox({tag = "IgnoreTeams", Label = "Ignore Teams"})
                Library:CheckBox({tag = "AlwaysOn", Label = "Always On"})
                Library:IntSlider({tag = "AimbotFOV", Label = "FOV", Max = 12, Min = 1, Value = 2})
                Library:IntSlider({tag = "Smoothing", Label = "Smoothing", Max = 100, Min = 0, Value = 34})
                Library:IntSlider({tag = "Sens", Label = "Sens", Max = 8, Min = 0, Value = 2})
                Library:IntSlider({tag = "BezierX", Label = "Curve X", Max = 100, Min = 0, Value = 23})
                Library:IntSlider({tag = "BezierY", Label = "Curve Y", Max = 100, Min = 0, Value = 10})
                Library:Label({title = "Hitboxes"})
                Library:Separator({})
                Library:Combo({title = "Hitboxes", Items = {"Head", "Torso", "Closest"}, SelectedItem = 3})
                Library:Label({title = "Walls"})
                Library:Separator({})
                Library:CheckBox({Label = "Respect Walls"})
                Library:IntSlider({tag = "MaxWalls", Label = "Max Walls", Max = 5, Min = 0})
            end)

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Triggerbot"})
                Library:Separator({})
                Library:CheckBox({tag = "TriggerEnabled", Label = "Enabled"})
                Library:CheckBox({tag = "TriggerCheck", Label = "Presence Check"})
                Library:IntSlider({tag = "TriggerDelay", Label = "Delay", Max = 1000, Min = 0, Value = 244})
            end)
        end)
        Library:Child({Size = Vector2.new(1,1)})
        Library.With(Library:SameLine({}), function(Library)
        local Preset = {Size = Vector2.new(210,190)}
            Library:Child({Size = Vector2.new(1,10)})

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Danger Zone"})
                Library:Separator({})
                Library:CheckBox({Label = "Enabled"})
                Library:CheckBox({Label = "Use same fov as aimbot"})
                Library:IntSlider({tag = "DangerFOV", Label = "FOV", Max = 12, Min = 1, Value = 1})
            end)

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Backtrack"})
                Library:Separator({})
                Library:CheckBox({Label = "Enabled"})
                Library:IntSlider({tag = "BacktrackDelay", Label = "Delay", Max = 1000, Min = 0, Value = 150})
            end)
        end)
        if Library.con then return end
        Library.con = true
        local mousedown = false
        local TimeElapsed = 0
        local CurrentMouseTarget
        local con; con = game.RunService.Heartbeat:Connect(function(dt)
            if Window ~= getgenv().Window then FOVCircle = nil con:Disconnect() return end
            local MouseLoc = UserInputService:GetMouseLocation()
            if iskeydown(0x01) then
                mousedown = false
            end

            if Window.flags.AimbotEnabled and (Window.flags.AlwaysOn or iskeydown(0x01)) then
                local fov = Window.flags.AimbotFOV*50
                FOVCircle.Radius = fov

                local Point = findClosestPoint(fov)
                if Point then
                    Point = Point.ScreenPos
                    local Smoothness = Window.flags.Smoothing*0.5
                    Smoothness = math.random(Smoothness-10, Smoothness+10)
                    local Sens = Window.flags.Sens*5

                    if CurrentMode == "Linear" then
                        local goalPos = (Point-getMouseLocation())
                        goalPos = Vector2.new((goalPos.X/Smoothness)*Sens, (goalPos.Y/Smoothness)*Sens)
                        --print(goalPos.X*dt, goalPos.Y*dt)
                        goalPos = goalPos*dt
                        if goalPos.Magnitude < 10 then
                            mousemoverel(goalPos.X, goalPos.Y, true)
                        end
                    elseif CurrentMode == "Legit" then
                        local DotY = math.clamp(Vector2.new(0,1):Dot(Point), -1, 1)
                        local DotX = math.clamp(Vector2.new(1,0):Dot(Point), -1, 1)
                        local MidPoint = divideVector2(getMouseLocation()+Point, 2)+Vector2.new(DotX,DotY)
                        goalPos = beziercurve(getMouseLocation(), MidPoint, Point, .1)
                        goalPos = Vector2.new((goalPos.X/Smoothness)*Sens, (goalPos.Y/Smoothness)*Sens)
                        mousemoverel(goalPos.X*dt, goalPos.Y*dt, true)
                    end
                end
            else
                FOVCircle.Radius = 0
            end
            if Window.flags.TriggerEnabled then
                local origin = Mouse.Origin.Position
                local goal = Mouse.Hit.Position
                local cast = workspace:Raycast(origin, goal-origin)
                local Target = cast and cast.Instance
                if Target then
                    local isEnemy = getCharacterFromPart(Target)
                    if isEnemy == CurrentMouseTarget then
                        if isEnemy then
                            mouse1press()
                            mousedown = true
                        end
                        return
                    else
                        if mousedown then
                            mousedown = false
                            mouse1release()
                        end
                    end
                    if isEnemy then
                        if TimeElapsed == 0 then
                            TimeElapsed = tick()
                        elseif tick()-TimeElapsed >= Window.flags.TriggerDelay/1000 then
                            TimeElapsed = 0
                            if not Window.flags.TriggerCheck or Target == Mouse.Target then
                                mousedown = true
                                mouse1press()
                                CurrentMouseTarget = isEnemy
                            end
                        end
                    else
                        if mousedown then
                            mouse1release()
                        end
                        TimeElapsed = 0
                    end
                end
            end
        end)
    end},
    {Rage = function(Library)
        Library:Child({Size = Vector2.new(100,4)})
        Library.With(Library:SameLine({}), function(Library)
        local Preset = {Size = Vector2.new(210,180)}
            Library:Child({Size = Vector2.new(1,10)})

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "ESP"})
                Library:Separator({})
                Library:CheckBox({tag = "ESPEnabled", Label = "Enabled"})
                Library:CheckBox({tag = "IgnoreTeams", Label = "Ignore Teams"})
                Library:CheckBox({tag = "ThroughWalls", Label = "See through walls", Value = true})
                Library:CheckBox({tag = "ShowTeam", Label = "Show Teammates", Value = true})
                Library:CheckBox({tag = "Boxes", Label = "Boxes", Value = true})
                Library:CheckBox({tag = "HeadLine", Label = "HeadLine", Value = true})
            end)

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Anti Aim"})
                Library:Separator({})
                Library:CheckBox({tag = "SpinEnabled", Label = "Enabled"})
                Library:IntSlider({tag = "SpinSpeed", Label = "Offset", Max = 180, Min = -180})
                Library:CheckBox({tag = "AntiHeadshot", Label = "Remove Head", Value = true})
            end)
        end)
        Library:Child({Size = Vector2.new(1,1)})
        Library.With(Library:SameLine({}), function(Library)
        local Preset = {Size = Vector2.new(210,190)}
            Library:Child({Size = Vector2.new(1,10)})

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library.styles.IndentSpacing = 5
                Library:Label({title = "ESP Customization"})
                Library:Separator({})
                Library:CheckBox({tag = "Filled", Label = "Filled",
                OnUpdated = function(self, val)
                    for i,v in Drawings do
                        v[2].Filled = val
                    end
                    BoxSettings.Filled = val
                end})
                Library:IntSlider({tag = "ESPThick", Label = "Thickness", Max = 10, Min = 1, Value = 1,
                OnUpdated = function(self, val)
                    if val > 1 or val < 0 then return end
                    for i,v in Drawings do
                        v[2].Thickness = val
                    end
                    BoxSettings.Thickness = val
                end})
                Library:Slider({tag = "ESPOpacity", Label = "Opacity", Max = 1, Min = 0, Value = .5,
                OnUpdated = function(self, val)
                    if val > 1 or val < 0 then return end
                    for i,v in Drawings do
                        v[2].Opacity = val
                    end
                    BoxSettings.Opacity = val
                end})
            end)

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Extras (EXPERIMENTAL)"})
                Library:Separator({})
                Library:CheckBox({Label = 'Tracers'})
            end)
        end)
        if Library.con3 then return end
        Library.con3 = true
        local remotecd = tick()
        local oldchar
        local hrp
        local con; con = game.RunService.Stepped:Connect(function(dt)
            if Window ~= getgenv().Window then 
                con:Disconnect()
                return 
            end 
            if Window.flags.SpinEnabled then
                if Window.flags.AntiHeadshot then
                    local number1 = -3.485
                    local boolean1 = false

                    local remote = game:GetService("ReplicatedStorage").Events.ControlTurn
                    if tick()-remotecd > .05 then
                        remote:FireServer(number1, boolean1)
                    end
                end
                if LocalPlayer.Character and oldchar ~= LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    oldchar = LocalPlayer.Character
                    hrp = oldchar:FindFirstChild("HumanoidRootPart")
                end
                if hrp then
                    local character
                    local closest = math.huge
                    for i,v in game.Players:GetPlayers() do
                        local isEnemy = Window.flags.IgnoreTeams or v.TeamColor ~= LocalPlayer.TeamColor
                        if v ~= LocalPlayer and v.Character and isEnemy then
                            local dist = LocalPlayer:DistanceFromCharacter(v.Character:GetPivot().Position)
                            if dist < closest then
                                closest = dist
                                character = v.Character
                            end
                        end
                    end
                    if character then
                        local pivot = character:GetPivot()
                        hrp.CFrame = CFrame.new(hrp.Position, pivot.Position) * CFrame.Angles(0, math.rad(Window.flags.SpinSpeed), 0)
                    end
                end
            end
        end)
    end},
    {Visuals = function(Library)
        Library:Child({Size = Vector2.new(100,4)})
        Library.With(Library:SameLine({}), function(Library)
        local Preset = {Size = Vector2.new(210,180)}
            Library:Child({Size = Vector2.new(1,10)})

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "ESP"})
                Library:Separator({})
                Library:CheckBox({tag = "ESPEnabled", Label = "Enabled"})
                Library:CheckBox({tag = "IgnoreTeams", Label = "Ignore Teams"})
                Library:CheckBox({tag = "ThroughWalls", Label = "See through walls", Value = true})
                Library:CheckBox({tag = "ShowTeam", Label = "Show Teammates", Value = true})
                Library:CheckBox({tag = "Boxes", Label = "Boxes", Value = true})
                Library:CheckBox({tag = "HeadLine", Label = "HeadLine", Value = true})
            end)

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Chams"})
                Library:Separator({})
                Library:CheckBox({tag = "ChamsEnabled", Label = "Enabled"})
                Library:CheckBox({tag = "ChamsAOT", Label = "Always On Top"})
                Library:CheckBox({tag = "ShowTeam", Label = "Show Teammates", Value = true})
                Library:Slider({tag = "ChamsFOpacity", Label = "Fill Opacity", Max = 1, Min = 0, Value = .5})
                Library:Slider({tag = "ChamsOOpacity", Label = "Outline Opacity", Max = 1, Min = 0, Value = .5})
                Library:ColorPicker({tag = "ChamsColor", Label = "FillColor"})
                Library:ColorPicker({tag = "OutlineColor", Label = "OutlineColor"})
            end)
        end)
        Library:Child({Size = Vector2.new(1,1)})
        Library.With(Library:SameLine({}), function(Library)
        local Preset = {Size = Vector2.new(210,190)}
            Library:Child({Size = Vector2.new(1,10)})

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library.styles.IndentSpacing = 5
                Library:Label({title = "ESP Customization"})
                Library:Separator({})
                Library:Label({title = "Box"})
                local BoxPresets = {
                    OnUpdated = function(self, val)
                        for i,v in Drawings do
                            v[2][self.Label] = val
                        end
                        BoxSettings[self.Label] = val
                    end
                }
                Library:CheckBox({tag = "Filled", Label = "Filled"}, BoxPresets)
                Library:IntSlider({tag = "ESPThick", Label = "Thickness", Max = 10, Min = 1, Value = 1}, BoxPresets)
                Library:Slider({tag = "ESPOpacity", Label = "Opacity", Max = 1, Min = 0, Value = .5}, BoxPresets)
                Library:Label({title = "Box"})
                local BoxPresets = {
                    OnUpdated = function(self, val)
                        for i,v in Drawings do
                            v[2][self.Label] = val
                        end
                        BoxSettings[self.Label] = val
                    end
                }
                Library:CheckBox({tag = "Filled", Label = "Filled"}, BoxPresets)
                Library:IntSlider({tag = "ESPThick", Label = "Thickness", Max = 10, Min = 1, Value = 1}, BoxPresets)
                Library:Slider({tag = "ESPOpacity", Label = "Opacity", Max = 1, Min = 0, Value = .5}, BoxPresets)
            end)

            Library.With(Library:Child(Preset), function(Library)
                Library.colors.ChildBg = Window.colors.WindowBg
                Library:Label({title = "Extras (EXPERIMENTAL)"})
                Library:Separator({})
                Library:CheckBox({Label = 'Tracers'})
            end)
        end)
        if Library.con2 then return end
        Library.con2 = true
        local con; con = game.RunService.Heartbeat:Connect(function(dt)
            if Window ~= getgenv().Window then 
                con:Disconnect() 
                for i,v in pairs(Drawings) do
                    v[3]:Destroy()
                end
                table.clear(Drawings)
                table.clear(ESPPoints)
                table.clear(PlayerPoints)
                return 
            end
            for i,v in Drawings do
                local Player = game.Players:FindFirstChild(i)
                if not Player or not v[1] then
                    Drawings[i] = nil
                    continue
                end
                local Visible = Window.flags.ESPEnabled
                local TeamColor = Player.TeamColor.Color
                local isTeammate = false
                if Window.flags.IgnoreTeams then
                    TeamColor = Color3.fromRGB(255,0,0)
                end
                if not Window.flags.ShowTeam then
                    if LocalPlayer.TeamColor.Color == TeamColor then
                        Visible = false
                        isTeammate = true
                    end
                end
                if not Window.flags.ThroughWalls then
                    local origin = Mouse.Origin.Position
                    local goal = PlayerPoints[i].Head.WorldPos
                    local cast = workspace:Raycast(origin, goal-origin)
                    if LocalPlayer.Character and Player.Character 
                    and cast 
                    and not (cast.Instance:IsDescendantOf(LocalPlayer.Character)
                    or cast.Instance:IsDescendantOf(Player.Character)) then
                        Visible = false
                    end
                end
                Visible = Visible or false
                v[1].Color = TeamColor
                v[1].OutlineColor = TeamColor
                v[1].Visible = Visible
                v[2].Visible = Visible
                --Highlight specifics
                local FillColor = Window.flags.ChamsColor or {TeamColor.R, TeamColor.G, TeamColor.B}
                local OutlineColor = Window.flags.ChamsColor or {TeamColor.R, TeamColor.G, TeamColor.B}
                v[3].Enabled = Window.flags.ChamsEnabled and not isTeammate
                v[3].DepthMode = Window.flags.ChamsAOT and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                v[3].OutlineColor = Color3.fromRGB(OutlineColor[1], OutlineColor[2], OutlineColor[3])
                v[3].FillColor = Color3.fromRGB(FillColor[1], FillColor[2], FillColor[3])
                v[3].FillTransparency = Window.flags.ChamsFOpacity
                v[3].OutlineTransparency = Window.flags.ChamsOOpacity
            end
        end)
    end},
    {Theming = function(Library)
        Library:Label({title = "Colors"})
        Library:Separator({})
        for i,v in pairs(ColorOptions) do
            Library.With(Library:SameLine({}), function(Library)
                Library.With(Library:Collapsable({title = v}), function(Library)
                    Library:ColorPicker({Size = Vector2.new(100,100), OnUpdated = function(self, r,g,b,a)
                        Window.colors[v] = {Color3.fromRGB(r,g,b), a}
                    end})
                end)
            end)
        end
    end},
}

Library.With(Window, function(Library)
    --print(Library.__super and Library.__super.properties.title)
    Library.styles.WindowMinSize = Vector2.new(600,490)
    Library.styles.ScrollbarSize = 0
    Library.styles.ChildBorderSize = 3
    Library.styles.GrabMinSize = 0
    --Library.colors.Border = {Color3.fromRGB(255,255,0), 1}
    Library.colors.WindowBg = {Color3.fromRGB(43,43,43), 1}
    Library.With(Library:Child({Size = Vector2.new(550,50)}), function(Library)
        
    end)
    Library.With(Library:SameLine({Size = Vector3.new(600, 100)}), function(Library)
        Library.styles.ChildBorderSize = 3
        Library.styles.WindowBorderSize = 3
        local CheatWindow
        Library.With(Library:Child({Size = Vector2.new(130,410)}), function(Library)
            Library.styles.ScrollbarSize = 0
            Library.colors.ChildBg = Window.colors.WindowBg
            Library.With(Library:Child({Size = Vector2.new(200,280)}), function(Library)
                local Preset = {Size = Vector2.new(181,26), Toggles = true}
                for i,v in pairs(Tabs) do
                    local i,v = next(v)
                    Library:Selectable({Label=i, OnUpdated = function(self, Val)
                    if Val then
                        for i,v in pairs(Library.Children) do
                            if v ~= self then
                                v.Value = false
                            end
                        end
                    end
                    CheatWindow:Clear()
                    v(CheatWindow) 
                end}, Preset)
                end
            end)
            Library.With(Library:Child({Size = Vector2.new(200,40)}), function(Library)
                Library:Label({title='defconhax', Size = Library.properties.Size})
            end)
        end)
        CheatWindow = Library.With(Library:Child({}), function(Library)
            Library.colors.ChildBg = {Color3.fromRGB(55,55,55), 1}
            Library.styles.ChildBorderSize = 3
        end)
        Tabs[1].Legit(CheatWindow)
    end)
end)
