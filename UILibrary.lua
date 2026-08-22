local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Library = {}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Group = {}
Group.__index = Group

local Button = {}
Button.__index = Button

local Toggle = {}
Toggle.__index = Toggle

local Slider = {}
Slider.__index = Slider

local Dropdown = {}
Dropdown.__index = Dropdown

local ToggleSlider = {}
ToggleSlider.__index = ToggleSlider

function Library:validate(defaults, options)
    for k, v in pairs(defaults) do
        if options[k] == nil then
            options[k] = v
        end
    end
    return options
end

function Library:Tween(object, goal, callback)
    local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, TweenInfo, goal)
    tween.Completed:Connect(callback or function() end)
    tween:Play()
end

function Library:CreateWindow(options)
    options = Library:validate({name = "Title"}, options or {})
    
    local window = setmetatable({}, Window)
    window.CurrentTab = nil

    window.ScreenGui = Instance.new("ScreenGui", gethui())
    
    window.ImageLabel = Instance.new("ImageLabel", window.ScreenGui)
    window.ImageLabel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    window.ImageLabel.BorderColor3 = Color3.fromRGB(56, 56, 56)
    window.ImageLabel.ImageColor3 = Color3.fromRGB(36, 36, 36)
    window.ImageLabel.Image = "rbxassetid://81945815210872"
    window.ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    window.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    window.ImageLabel.Size = UDim2.new(0, 600, 0, 400)
    window.ImageLabel.ScaleType = Enum.ScaleType.Crop
    
    local Frame1 = Instance.new("Frame", window.ImageLabel)
    Frame1.Position = UDim2.new(0.5, 0, 0, 6)
    Frame1.AnchorPoint = Vector2.new(0.5, 0)
    Frame1.Size = UDim2.new(1, -12, 0, 28)
    Frame1.BackgroundTransparency = 1
    
    local UIStroke1 = Instance.new("UIStroke", Frame1)
    UIStroke1.Color = Color3.fromRGB(56, 56, 56)
    
    local TextLabel = Instance.new("TextLabel", Frame1)
    TextLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    TextLabel.TextColor3 = Color3.fromRGB(224, 224, 224)
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Position = UDim2.new(1, 0, 0, 0)
    TextLabel.AnchorPoint = Vector2.new(1, 0)
    TextLabel.Size = UDim2.new(1, -6, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = options.name
    TextLabel.TextSize = 16
    
    window.ScrollingFrame = Instance.new("ScrollingFrame", window.ImageLabel)
    window.ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    window.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    window.ScrollingFrame.Position = UDim2.new(0, 6, 0, 40)
    window.ScrollingFrame.Size = UDim2.new(0, 150, 1, -46)
    window.ScrollingFrame.BackgroundTransparency = 1
    window.ScrollingFrame.ScrollBarThickness = 0
    
    local UIStroke2 = Instance.new("UIStroke", window.ScrollingFrame)
    UIStroke2.Color = Color3.fromRGB(57, 57, 57)
    
    local UIListLayout = Instance.new("UIListLayout", window.ScrollingFrame)
    UIListLayout.Padding = UDim.new(0, 6)
    
    local UIPadding = Instance.new("UIPadding", window.ScrollingFrame)
    UIPadding.PaddingBottom = UDim.new(0, 6)
    UIPadding.PaddingRight = UDim.new(0, 6)
    UIPadding.PaddingLeft = UDim.new(0, 6)
    UIPadding.PaddingTop = UDim.new(0, 6)
    
    window.Frame2 = Instance.new("Frame", window.ImageLabel)
    window.Frame2.Position = UDim2.new(1, -6, 0, 40)
    window.Frame2.Size = UDim2.new(1, -168, 1, -46)
    window.Frame2.AnchorPoint = Vector2.new(1, 0)
    window.Frame2.BackgroundTransparency = 1
    
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        window.ImageLabel.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    Frame1.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.ImageLabel.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Frame1.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            window.ImageLabel.Visible = not window.ImageLabel.Visible
        end
    end)
    
    return window
end

function Window:CreateTab(options)
    options = Library:validate({name = "Tab"}, options or {})
    
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab.Active = false
    tab.Hover = false
    
    tab.Frame1 = Instance.new("Frame", self.ScrollingFrame)
    tab.Frame1.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    tab.Frame1.AnchorPoint = Vector2.new(1, 0)
    tab.Frame1.Size = UDim2.new(1, 0, 0, 38)
    tab.Frame1.BackgroundTransparency = 0.4
    
    local UIStroke1 = Instance.new("UIStroke", tab.Frame1)
    UIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke1.Color = Color3.fromRGB(56, 56, 56)
    
    local UIPadding1 = Instance.new("UIPadding", tab.Frame1)
    UIPadding1.PaddingLeft = UDim.new(0, 6)
    
    tab.TextLabel = Instance.new("TextLabel", tab.Frame1)
    tab.TextLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    tab.TextLabel.TextColor3 = Color3.fromRGB(102, 102, 102)
    tab.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    tab.TextLabel.Size = UDim2.new(1, 0, 1, 0)
    tab.TextLabel.BackgroundTransparency = 1
    tab.TextLabel.Text = options.name
    tab.TextLabel.TextSize = 26
    
    tab.ScrollingFrame = Instance.new("ScrollingFrame", self.Frame2)
    tab.ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tab.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    tab.ScrollingFrame.BackgroundTransparency = 1
    tab.ScrollingFrame.ScrollBarThickness = 0
    tab.ScrollingFrame.Visible = false
    
    local UIStroke2 = Instance.new("UIStroke", tab.ScrollingFrame)
    UIStroke2.Color = Color3.fromRGB(56, 56, 56)
    
    local UIListLayout = Instance.new("UIListLayout", tab.ScrollingFrame)
    UIListLayout.Padding = UDim.new(0, 6)
    
    local UIPadding2 = Instance.new("UIPadding", tab.ScrollingFrame)
    UIPadding2.PaddingBottom = UDim.new(0, 6)
    UIPadding2.PaddingRight = UDim.new(0, 6)
    UIPadding2.PaddingLeft = UDim.new(0, 6)
    UIPadding2.PaddingTop = UDim.new(0, 6)
    
    tab.Frame1.MouseEnter:Connect(function()
        tab.Hover = true
        if not tab.Active then Library:Tween(tab.TextLabel, {TextColor3 = Color3.fromRGB(164, 164, 164)}) end
    end)
    tab.Frame1.MouseLeave:Connect(function()
        tab.Hover = false
        if not tab.Active then Library:Tween(tab.TextLabel, {TextColor3 = Color3.fromRGB(102, 102, 102)}) end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and tab.Hover then
            tab:Activate()
        end
    end)
    
    if self.CurrentTab == nil then tab:Activate() end

    return tab
end

function Tab:Activate()
    if not self.Active then
        if self.Window.CurrentTab ~= nil then self.Window.CurrentTab:Deactivate() end
        self.Active = true
        Library:Tween(self.TextLabel, {TextColor3 = Color3.fromRGB(224, 224, 224)})
        self.ScrollingFrame.Visible = true
        self.Window.CurrentTab = self
    end
end

function Tab:Deactivate()
    if self.Active then
        self.Active = false
        self.Hover = false
        Library:Tween(self.TextLabel, {TextColor3 = Color3.fromRGB(102, 102, 102)})
        self.ScrollingFrame.Visible = false
    end
end

function Tab:CreateGroup(options)
    options = Library:validate({name = "Group"}, options or {})
    
    local group = setmetatable({}, Group)
    group.Tab = self
    
    group.Frame = Instance.new("Frame", self.ScrollingFrame)
    group.Frame.AutomaticSize = Enum.AutomaticSize.Y
    group.Frame.Size = UDim2.new(1, 0, 0, 0)
    group.Frame.BackgroundTransparency = 1
    
    local UIStroke = Instance.new("UIStroke", group.Frame)
    UIStroke.Color = Color3.fromRGB(56, 56, 56)
    
    local UIListLayout = Instance.new("UIListLayout", group.Frame)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 6)
    
    local UIPadding = Instance.new("UIPadding", group.Frame)
    UIPadding.PaddingBottom = UDim.new(0, 6)
    UIPadding.PaddingRight = UDim.new(0, 6)
    UIPadding.PaddingLeft = UDim.new(0, 6)
    UIPadding.PaddingTop = UDim.new(0, 6)

    local TextLabel = Instance.new("TextLabel", group.Frame)
    TextLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    TextLabel.TextColor3 = Color3.fromRGB(224, 224, 224)
    TextLabel.Size = UDim2.new(1, 0, 0, 30)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = options.name
    TextLabel.LayoutOrder = -1
    TextLabel.TextSize = 22
    
    return group
end

local function CreateButton(parent, options)
    options = Library:validate({name = "Button", callback = function() end}, options or {})
    
    local button = setmetatable({}, Button)
    button.MouseDown = false
    button.Hover = false
    
    button.Frame = Instance.new("Frame", parent)
    button.Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    button.Frame.Size = UDim2.new(1, 0, 0, 44)
    button.Frame.BackgroundTransparency = 0.4
    
    local UIStroke = Instance.new("UIStroke", button.Frame)
    UIStroke.Color = Color3.fromRGB(56, 56, 56)

    button.TextLabel = Instance.new("TextLabel", button.Frame)
    button.TextLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    button.TextLabel.TextColor3 = Color3.fromRGB(224, 224, 224)
    button.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    button.TextLabel.Position = UDim2.new(0, 4, 0, 0)
    button.TextLabel.Size = UDim2.new(1, -4, 1, 0)
    button.TextLabel.BackgroundTransparency = 1
    button.TextLabel.Text = options.name
    button.TextLabel.TextSize = 18
    
    button.Frame.MouseEnter:Connect(function()
        button.Hover = true
        Library:Tween(button.Frame, {BackgroundTransparency = 0.3})
    end)
    button.Frame.MouseLeave:Connect(function()
        button.Hover = false
        if not button.MouseDown then Library:Tween(button.Frame, {BackgroundTransparency = 0.4}) end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and button.Hover then
            button.MouseDown = true
            Library:Tween(button.Frame, {BackgroundTransparency = 0.2})
            options.callback()
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            button.MouseDown = false
            if button.Hover then
                Library:Tween(button.Frame, {BackgroundTransparency = 0.3})
            else
                Library:Tween(button.Frame, {BackgroundTransparency = 0.4})
            end
        end
    end)
    
    return button
end

local function CreateToggle(parent, options)
    options = Library:validate({
        name = "Toggle",
        default = false,
        require = nil,
        warning = nil,
        callback = function() end
    }, options or {})
    
    local toggle = setmetatable({}, Toggle)
    toggle.State = options.default
    toggle.MouseDown = false
    toggle.WarningTime = 0
    toggle.Hover = false
    
    toggle.Frame1 = Instance.new("Frame", parent)
    toggle.Frame1.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    toggle.Frame1.Size = UDim2.new(1, 0, 0, 44)
    toggle.Frame1.BackgroundTransparency = 0.4
    
    local UIStroke1 = Instance.new("UIStroke", toggle.Frame1)
    UIStroke1.Color = Color3.fromRGB(56, 56, 56)

    toggle.TextLabel = Instance.new("TextLabel", toggle.Frame1)
    toggle.TextLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    toggle.TextLabel.TextColor3 = Color3.fromRGB(224, 224, 224)
    toggle.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggle.TextLabel.Position = UDim2.new(0, 6, 0, 0)
    toggle.TextLabel.Size = UDim2.new(1, -6, 1, 0)
    toggle.TextLabel.BackgroundTransparency = 1
    toggle.TextLabel.Text = options.name
    toggle.TextLabel.TextSize = 18

    local Frame2 = Instance.new("Frame", toggle.Frame1)
    Frame2.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Frame2.Position = UDim2.new(1, -6, 0, 6)
    Frame2.AnchorPoint = Vector2.new(1, 0)
    Frame2.Size = UDim2.new(0, 32, 1, -12)
    
    local UIStroke2 = Instance.new("UIStroke", Frame2)
    UIStroke2.Color = Color3.fromRGB(56, 56, 56)

    toggle.Frame3 = Instance.new("Frame", Frame2)
    toggle.Frame3.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    toggle.Frame3.Position = UDim2.new(0.5, 0, 0.5, 0)
    toggle.Frame3.AnchorPoint = Vector2.new(0.5, 0.5)
    toggle.Frame3.BorderSizePixel = 0
    
    if toggle.State then
        toggle.Frame3.Size = UDim2.new(1, -12, 1, -12)
        toggle.Frame3.BackgroundTransparency = 0
    else
        toggle.Frame3.Size = UDim2.new(0, 0, 0, 0)
        toggle.Frame3.BackgroundTransparency = 1
    end

    toggle.Frame1.MouseEnter:Connect(function()
        toggle.Hover = true
        if not toggle.State and not toggle.MouseDown then
            Library:Tween(toggle.Frame3, {
                Size = UDim2.new(1, -12, 1, -12),
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.fromRGB(163, 163, 163)
            })
        end
    end)
    toggle.Frame1.MouseLeave:Connect(function()
        toggle.Hover = false
        if not toggle.State and not toggle.MouseDown then
            Library:Tween(toggle.Frame3, {
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            })
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and toggle.Hover then
            toggle.MouseDown = true
            Library:Tween(toggle.Frame3, {
                Size = UDim2.new(1, -12, 1, -12),
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.fromRGB(102, 102, 102)
            })
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if toggle.MouseDown then
                toggle.MouseDown = false
                
                if toggle.Hover then
                    local pass = true
                    if options.require ~= nil then
                        pass = (type(options.require) == "function") and options.require() or options.require
                    end
                    
                    if pass then
                        toggle.State = not toggle.State
                        options.callback(toggle.State)
                        
                        if toggle.State then
                            Library:Tween(toggle.Frame3, {
                                Size = UDim2.new(1, -12, 1, -12),
                                BackgroundTransparency = 0,
                                BackgroundColor3 = Color3.fromRGB(224, 224, 224)
                            })
                        else
                            Library:Tween(toggle.Frame3, {
                                Size = UDim2.new(1, -12, 1, -12),
                                BackgroundTransparency = 0,
                                BackgroundColor3 = Color3.fromRGB(163, 163, 163)
                            })
                        end
                    else
                        if toggle.State then
                            Library:Tween(toggle.Frame3, {
                                Size = UDim2.new(1, -12, 1, -12),
                                BackgroundTransparency = 0,
                                BackgroundColor3 = Color3.fromRGB(224, 224, 224)
                            })
                        else
                            Library:Tween(toggle.Frame3, {
                                Size = UDim2.new(1, -12, 1, -12),
                                BackgroundTransparency = 0,
                                BackgroundColor3 = Color3.fromRGB(163, 163, 163)
                            })
                        end
                        if options.warning then
                            local currentTick = os.clock()
                            toggle.WarningTime = currentTick
                            toggle.TextLabel.Text = options.warning
                            Library:Tween(toggle.TextLabel, {TextColor3 = Color3.fromRGB(254, 60, 48)})
                            task.delay(2, function()
                                if toggle.WarningTime == currentTick then
                                    toggle.TextLabel.Text = options.name
                                    Library:Tween(toggle.TextLabel, {TextColor3 = Color3.fromRGB(224, 224, 224)})
                                end
                            end)
                        end
                    end
                else
                    if toggle.State then
                        Library:Tween(toggle.Frame3, {
                            Size = UDim2.new(1, -12, 1, -12),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = Color3.fromRGB(224, 224, 224)
                        })
                    else
                        Library:Tween(toggle.Frame3, {
                            Size = UDim2.new(0, 0, 0, 0),
                            BackgroundTransparency = 1
                        })
                    end
                end
            end
        end
    end)
    
    return toggle
end

local function CreateSlider(parent, options)
    options = Library:validate({name = "Slider", min = 0, max = 100, default = 50, callback = function() end}, options or {})
    
    local slider = setmetatable({}, Slider)
    slider.Value = math.clamp(options.default, options.min, options.max)
    slider.Dragging = false
    slider.BarHover = false
    
    slider.Frame1 = Instance.new("Frame", parent)
    slider.Frame1.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    slider.Frame1.Size = UDim2.new(1, 0, 0, 62)
    slider.Frame1.BackgroundTransparency = 0.4
    
    local UIStroke1 = Instance.new("UIStroke", slider.Frame1)
    UIStroke1.Color = Color3.fromRGB(56, 56, 56)
    
    local TextLabel1 = Instance.new("TextLabel", slider.Frame1)
    TextLabel1.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    TextLabel1.TextColor3 = Color3.fromRGB(224, 224, 224)
    TextLabel1.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel1.Position = UDim2.new(0, 6, 0, 0)
    TextLabel1.Size = UDim2.new(1, -6, 0, 44)
    TextLabel1.BackgroundTransparency = 1
    TextLabel1.Text = options.name
    TextLabel1.TextSize = 18
    
    slider.TextLabel2 = Instance.new("TextLabel", slider.Frame1)
    slider.TextLabel2.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    slider.TextLabel2.TextColor3 = Color3.fromRGB(224, 224, 224)
    slider.TextLabel2.TextXAlignment = Enum.TextXAlignment.Right
    slider.TextLabel2.Position = UDim2.new(1, -6, 0, 0)
    slider.TextLabel2.AnchorPoint = Vector2.new(1, 0)
    slider.TextLabel2.Size = UDim2.new(1, -6, 0, 44)
    slider.TextLabel2.Text = tostring(slider.Value)
    slider.TextLabel2.BackgroundTransparency = 1
    slider.TextLabel2.TextSize = 18
    
    local Frame2 = Instance.new("Frame", slider.Frame1)
    Frame2.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Frame2.Position = UDim2.new(0, 6, 1, -6)
    Frame2.AnchorPoint = Vector2.new(0, 1)
    Frame2.Size = UDim2.new(1, -12, 0, 12)
    Frame2.BackgroundTransparency = 0.4
    
    local UIStroke2 = Instance.new("UIStroke", Frame2)
    UIStroke2.Color = Color3.fromRGB(56, 56, 56)
    
    slider.Frame3 = Instance.new("Frame", Frame2)
    slider.Frame3.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    slider.Frame3.Size = UDim2.new((slider.Value - options.min) / (options.max - options.min), 0, 1, 0)
    
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - Frame2.AbsolutePosition.X) / Frame2.AbsoluteSize.X, 0, 1)
        slider.Value = math.floor(options.min + (options.max - options.min) * pos)
        slider.TextLabel2.Text = tostring(slider.Value)
        Library:Tween(slider.Frame3, {Size = UDim2.new(pos, 0, 1, 0)})
        options.callback(slider.Value)
    end
    
    Frame2.MouseEnter:Connect(function() slider.BarHover = true end)
    Frame2.MouseLeave:Connect(function() slider.BarHover = false end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and slider.BarHover then
            slider.Dragging = true
            UpdateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then slider.Dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if slider.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input)
        end
    end)
    
    return slider
end

local function CreateDropdown(parent, options)
    options = Library:validate({
        name = "Dropdown",
        options = {},
        default = nil,
        callback = function() end
    }, options or {})
    
    local dropdown = setmetatable({}, Dropdown)
    dropdown.Selected = options.default or options.options[1] or "None"
    dropdown.HeaderHover = false
    dropdown.Open = false
    
    dropdown.Frame1 = Instance.new("Frame", parent)
    dropdown.Frame1.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    dropdown.Frame1.AutomaticSize = Enum.AutomaticSize.Y
    dropdown.Frame1.Size = UDim2.new(1, 0, 0, 44)
    dropdown.Frame1.BackgroundTransparency = 0.4
    
    local UIStroke1 = Instance.new("UIStroke", dropdown.Frame1)
    UIStroke1.Color = Color3.fromRGB(56, 56, 56)
    
    local UIPadding1 = Instance.new("UIPadding", dropdown.Frame1)
    UIPadding1.PaddingBottom = UDim.new(0, 6)
    
    local Frame2 = Instance.new("Frame", dropdown.Frame1)
    Frame2.Size = UDim2.new(1, 0, 0, 38)
    Frame2.BackgroundTransparency = 1
    
    local TextLabel1 = Instance.new("TextLabel", Frame2)
    TextLabel1.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    TextLabel1.TextColor3 = Color3.fromRGB(224, 224, 224)
    TextLabel1.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel1.Position = UDim2.new(0, 6, 0, 0)
    TextLabel1.Size = UDim2.new(1, -6, 0, 38)
    TextLabel1.BackgroundTransparency = 1
    TextLabel1.Text = options.name
    TextLabel1.TextSize = 18
    
    local UIPadding2 = Instance.new("UIPadding", TextLabel1)
    UIPadding2.PaddingTop = UDim.new(0, 6)
    
    dropdown.TextLabel2 = Instance.new("TextLabel", Frame2)
    dropdown.TextLabel2.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    dropdown.TextLabel2.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    dropdown.TextLabel2.TextColor3 = Color3.fromRGB(224, 224, 224)
    dropdown.TextLabel2.BorderColor3 = Color3.fromRGB(56, 56, 56)
    dropdown.TextLabel2.Position = UDim2.new(1, -6, 0, 6)
    dropdown.TextLabel2.AnchorPoint = Vector2.new(1, 0)
    dropdown.TextLabel2.Size = UDim2.new(0, 128, 0, 32)
    dropdown.TextLabel2.Text = dropdown.Selected
    dropdown.TextLabel2.TextSize = 16
    
    dropdown.ScrollingFrame = Instance.new("ScrollingFrame", dropdown.Frame1)
    dropdown.ScrollingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    dropdown.ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropdown.ScrollingFrame.AutomaticSize = Enum.AutomaticSize.Y
    dropdown.ScrollingFrame.Size = UDim2.new(1, -12, 0, 0)
    dropdown.ScrollingFrame.Position = UDim2.new(0, 6, 0, 44)
    dropdown.ScrollingFrame.ScrollBarThickness = 0
    dropdown.ScrollingFrame.BackgroundTransparency = 1
    dropdown.ScrollingFrame.Visible = false
    
    local UIStroke2 = Instance.new("UIStroke", dropdown.ScrollingFrame)
    UIStroke2.Color = Color3.fromRGB(56, 56, 56)
    
    local UIPadding3 = Instance.new("UIPadding", dropdown.ScrollingFrame)
    UIPadding3.PaddingBottom = UDim.new(0, 6)
    UIPadding3.PaddingRight = UDim.new(0, 6)
    UIPadding3.PaddingLeft = UDim.new(0, 6)
    UIPadding3.PaddingTop = UDim.new(0, 6)
    
    local UIGridLayout = Instance.new("UIGridLayout", dropdown.ScrollingFrame)
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    UIGridLayout.CellSize = UDim2.new(0, 128, 0, 32)
    UIGridLayout.FillDirectionMaxCells = 3
    
    Frame2.MouseEnter:Connect(function() dropdown.HeaderHover = true end)
    Frame2.MouseLeave:Connect(function() dropdown.HeaderHover = false end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdown.HeaderHover then
            dropdown.Open = not dropdown.Open
            dropdown.ScrollingFrame.Visible = dropdown.Open
        end
    end)
    
    local OptionItems = {}
    
    local function RefreshOptions()
        for optionName, item in pairs(OptionItems) do
            if optionName == dropdown.Selected then
                Library:Tween(item.Label, {TextColor3 = Color3.fromRGB(224, 224, 224)})
                item.Frame.LayoutOrder = -1 
            else
                Library:Tween(item.Label, {TextColor3 = Color3.fromRGB(102, 102, 102)})
                item.Frame.LayoutOrder = item.Index 
            end
        end
    end

    for i, option in ipairs(options.options) do
        local Frame3 = Instance.new("Frame", dropdown.ScrollingFrame)
        Frame3.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        Frame3.Size = UDim2.new(0, 124, 0, 32)
        
        local TextLabel3 = Instance.new("TextLabel", Frame3)
        TextLabel3.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
        TextLabel3.Size = UDim2.new(1, 0, 1, 0)
        TextLabel3.BackgroundTransparency = 1
        TextLabel3.Text = option
        TextLabel3.TextSize = 16
        
        local UIStroke3 = Instance.new("UIStroke", Frame3)
        UIStroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStroke3.Color = Color3.fromRGB(56, 56, 56)

        OptionItems[option] = {Frame = Frame3, Label = TextLabel3, Index = i}
        
        local optionHover = false
        Frame3.MouseEnter:Connect(function()
            optionHover = true
            if dropdown.Selected ~= option then
                Library:Tween(TextLabel3, {TextColor3 = Color3.fromRGB(163, 163, 163)})
            end
        end)
        
        Frame3.MouseLeave:Connect(function() 
            optionHover = false
            if dropdown.Selected ~= option then
                Library:Tween(TextLabel3, {TextColor3 = Color3.fromRGB(102, 102, 102)})
            end
        end)
        
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdown.Open and optionHover then
                dropdown.Selected = option
                dropdown.TextLabel2.Text = option
                dropdown.Open = false
                dropdown.ScrollingFrame.Visible = false
                
                RefreshOptions()
                
                options.callback(option)
            end
        end)
    end
    
    RefreshOptions()
    
    return dropdown
end

local function CreateToggleSlider(parent, options)
    options = Library:validate({name = "ToggleSlider", min = 0, max = 100, defaultVal = 50, defaultToggle = false, callback = function() end}, options or {})
    
    local ts = setmetatable({}, ToggleSlider)
    ts.Value = math.clamp(options.defaultVal, options.min, options.max)
    ts.State = options.defaultToggle
    ts.Dragging = false
    ts.ToggleHover = false
    ts.BarHover = false

    ts.Frame1 = Instance.new("Frame", parent)
    ts.Frame1.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    ts.Frame1.Size = UDim2.new(1, 0, 0, 62)
    ts.Frame1.BackgroundTransparency = 0.4
    
    local UIStroke1 = Instance.new("UIStroke", ts.Frame1)
    UIStroke1.Color = Color3.fromRGB(56, 56, 56)
    
    local TextLabel1 = Instance.new("TextLabel", ts.Frame1)
    TextLabel1.TextSize = 18
    TextLabel1.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel1.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    TextLabel1.TextColor3 = Color3.fromRGB(224, 224, 224)
    TextLabel1.BackgroundTransparency = 1
    TextLabel1.Size = UDim2.new(1, -6, 0, 44)
    TextLabel1.Position = UDim2.new(0, 6, 0, 0)
    TextLabel1.Text = options.name
    
    local Frame2 = Instance.new("Frame", ts.Frame1)
    Frame2.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Frame2.AnchorPoint = Vector2.new(1, 0)
    Frame2.Size = UDim2.new(0, 32, 0, 32)
    Frame2.Position = UDim2.new(1, -6, 0, 6)
    Frame2.BorderColor3 = Color3.fromRGB(56, 56, 56)
    
    ts.Frame3 = Instance.new("Frame", Frame2)
    ts.Frame3.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    ts.Frame3.Size = UDim2.new(1, -12, 1, -12)
    ts.Frame3.Position = UDim2.new(0, 6, 0, 6)
    ts.Frame3.Visible = ts.State
    
    ts.TextLabel2 = Instance.new("TextLabel", ts.Frame1)
    ts.TextLabel2.TextSize = 18
    ts.TextLabel2.TextXAlignment = Enum.TextXAlignment.Right
    ts.TextLabel2.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json")
    ts.TextLabel2.TextColor3 = Color3.fromRGB(224, 224, 224)
    ts.TextLabel2.BackgroundTransparency = 1
    ts.TextLabel2.AnchorPoint = Vector2.new(1, 0)
    ts.TextLabel2.Size = UDim2.new(1, -44, 0, 44)
    ts.TextLabel2.Position = UDim2.new(1, -44, 0, 0)
    ts.TextLabel2.Text = tostring(ts.Value)
    
    local Frame4 = Instance.new("Frame", ts.Frame1)
    Frame4.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Frame4.AnchorPoint = Vector2.new(0, 1)
    Frame4.Size = UDim2.new(1, -12, 0, 12)
    Frame4.Position = UDim2.new(0, 6, 1, -6)
    Frame4.BackgroundTransparency = 0.4
    
    local UIStroke2 = Instance.new("UIStroke", Frame4)
    UIStroke2.Color = Color3.fromRGB(56, 56, 56)
    
    ts.Frame5 = Instance.new("Frame", Frame4)
    ts.Frame5.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    ts.Frame5.Size = UDim2.new((ts.Value - options.min) / (options.max - options.min), 0, 1, 0)
    
    local function UpdateVisuals()
        if ts.State then
            Library:Tween(TextLabel1, {TextColor3 = Color3.fromRGB(224, 224, 224)})
            Library:Tween(ts.TextLabel2, {TextColor3 = Color3.fromRGB(224, 224, 224)})
            Library:Tween(ts.Frame5, {BackgroundColor3 = Color3.fromRGB(224, 224, 224)})
        else
            Library:Tween(TextLabel1, {TextColor3 = Color3.fromRGB(102, 102, 102)})
            Library:Tween(ts.TextLabel2, {TextColor3 = Color3.fromRGB(102, 102, 102)})
            Library:Tween(ts.Frame5, {BackgroundColor3 = Color3.fromRGB(102, 102, 102)})
            ts.Dragging = false
        end
    end

    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - Frame4.AbsolutePosition.X) / Frame4.AbsoluteSize.X, 0, 1)
        ts.Value = math.floor(options.min + (options.max - options.min) * pos)
        ts.TextLabel2.Text = tostring(ts.Value)
        Library:Tween(ts.Frame5, {Size = UDim2.new(pos, 0, 1, 0)})
        options.callback(ts.Value, ts.State)
    end
    
    Frame2.MouseEnter:Connect(function() ts.ToggleHover = true end)
    Frame2.MouseLeave:Connect(function() ts.ToggleHover = false end)
    Frame4.MouseEnter:Connect(function() ts.BarHover = true end)
    Frame4.MouseLeave:Connect(function() ts.BarHover = false end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if ts.ToggleHover then
                ts.State = not ts.State
                ts.Frame3.Visible = ts.State
                UpdateVisuals()
                options.callback(ts.Value, ts.State)
            elseif ts.BarHover and ts.State then
                ts.Dragging = true
                UpdateSlider(input)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then ts.Dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if ts.Dragging and ts.State and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input)
        end
    end)
    
    UpdateVisuals()
    
    return ts
end

function Tab:CreateButton(options) return CreateButton(self.ScrollingFrame, options) end
function Tab:CreateToggle(options) return CreateToggle(self.ScrollingFrame, options) end
function Tab:CreateSlider(options) return CreateSlider(self.ScrollingFrame, options) end
function Tab:CreateDropdown(options) return CreateDropdown(self.ScrollingFrame, options) end
function Tab:CreateToggleSlider(options) return CreateToggleSlider(self.ScrollingFrame, options) end

function Group:CreateButton(options) return CreateButton(self.Frame, options) end
function Group:CreateToggle(options) return CreateToggle(self.Frame, options) end
function Group:CreateSlider(options) return CreateSlider(self.Frame, options) end
function Group:CreateDropdown(options) return CreateDropdown(self.Frame, options) end
function Group:CreateToggleSlider(options) return CreateToggleSlider(self.Frame, options) end
