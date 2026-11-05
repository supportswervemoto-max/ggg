-- Start Your Own Clothing Company V4
-- Tutorial, company HUD, website setup, build/hire/ads menus and day results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local network = ReplicatedStorage:WaitForChild("ClothingCompanyV4")
local action = network:WaitForChild("Action")
local changed = network:WaitForChild("Changed")
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local COLORS = {
	ink = Color3.fromRGB(26, 27, 30),
	panel = Color3.fromRGB(35, 37, 42),
	panel2 = Color3.fromRGB(49, 51, 57),
	line = Color3.fromRGB(75, 77, 84),
	cream = Color3.fromRGB(246, 239, 222),
	muted = Color3.fromRGB(174, 177, 181),
	green = Color3.fromRGB(105, 208, 149),
	gold = Color3.fromRGB(232, 187, 96),
	red = Color3.fromRGB(229, 108, 103),
}

local state, plot
local activeMenu = nil
local busy = false
local toastSerial = 0
local websiteStartedAt = 0
local lastMenuRender = 0

local gui = Instance.new("ScreenGui")
gui.Name = "ClothingCompanyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(object, radius)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius or 12)
	ui.Parent = object
end

local function stroke(object, color)
	local ui = Instance.new("UIStroke")
	ui.Color = color or COLORS.line
	ui.Thickness = 1
	ui.Parent = object
end

local function frame(parent, name, size, position, color)
	local object = Instance.new("Frame")
	object.Name = name
	object.Size = size
	object.Position = position
	object.BackgroundColor3 = color or COLORS.panel
	object.BorderSizePixel = 0
	object.Parent = parent
	corner(object)
	return object
end

local function label(parent, name, content, size, position, textSize, color, bold)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.Text = content
	object.Size = size
	object.Position = position
	object.BackgroundTransparency = 1
	object.TextColor3 = color or COLORS.cream
	object.TextSize = textSize or 16
	object.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	object.TextWrapped = true
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Parent = parent
	return object
end

local function button(parent, name, content, size, position, secondary)
	local object = Instance.new("TextButton")
	object.Name = name
	object.Text = content
	object.Size = size
	object.Position = position
	object.BackgroundColor3 = secondary and COLORS.panel2 or COLORS.cream
	object.TextColor3 = secondary and COLORS.cream or COLORS.ink
	object.TextSize = 15
	object.TextWrapped = true
	object.Font = Enum.Font.GothamBold
	object.BorderSizePixel = 0
	object.AutoButtonColor = true
	object.Parent = parent
	corner(object, 9)
	if secondary then stroke(object) end
	return object
end

local function formatMoney(amount)
	amount = math.floor(tonumber(amount) or 0)
	local text = tostring(amount)
	while true do
		local changedText, replacements = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		text = changedText
		if replacements == 0 then break end
	end
	return "$" .. text
end

local function call(name, argument)
	local ok, success, result = pcall(function() return action:InvokeServer(name, argument) end)
	if not ok then return false, "Connection interrupted. Try again." end
	return success, result
end

-- Top-left tutorial card.
local tutorial = frame(gui, "Tutorial", UDim2.fromOffset(365, 112), UDim2.fromOffset(20, 20), COLORS.panel)
stroke(tutorial)
label(tutorial, "Step", "TUTORIAL", UDim2.new(1, -32, 0, 17), UDim2.fromOffset(16, 11), 11, COLORS.gold, true)
local tutorialTitle = label(tutorial, "Title", "Loading your company...", UDim2.new(1, -32, 0, 31), UDim2.fromOffset(16, 32), 20, COLORS.cream, true)
local tutorialHint = label(tutorial, "Hint", "", UDim2.new(1, -32, 0, 38), UDim2.fromOffset(16, 67), 13, COLORS.muted)

-- Required top-right company card.
local companyCard = frame(gui, "CompanyCard", UDim2.fromOffset(270, 104), UDim2.new(1, -290, 0, 20), COLORS.panel)
stroke(companyCard, COLORS.gold)
label(companyCard, "Caption", "YOUR COMPANY", UDim2.new(1, -28, 0, 16), UDim2.fromOffset(14, 10), 10, COLORS.gold, true)
local companyName = label(companyCard, "CompanyName", "Company", UDim2.new(1, -28, 0, 27), UDim2.fromOffset(14, 28), 17, COLORS.cream, true)
local companyCash = label(companyCard, "Cash", "$0", UDim2.new(1, -28, 0, 35), UDim2.fromOffset(14, 58), 27, COLORS.green, true)
companyCash.TextXAlignment = Enum.TextXAlignment.Right

local dayCard = frame(gui, "DayCard", UDim2.fromOffset(270, 66), UDim2.new(1, -290, 0, 133), COLORS.ink)
stroke(dayCard)
local dayLabel = label(dayCard, "Day", "DAY 1 · NOT STARTED", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 9), 13, COLORS.cream, true)
local dayProgressBackground = frame(dayCard, "Progress", UDim2.new(1, -28, 0, 8), UDim2.fromOffset(14, 44), COLORS.panel2)
corner(dayProgressBackground, 4)
local dayProgress = frame(dayProgressBackground, "Fill", UDim2.fromScale(0, 1), UDim2.new(), COLORS.green)
corner(dayProgress, 4)

-- Toasts and money feedback.
local toastPanel = frame(gui, "Toast", UDim2.new(.76, 0, 0, 54), UDim2.new(.12, 0, 1, -140), COLORS.panel)
toastPanel.Visible = false
stroke(toastPanel)
local toastText = label(toastPanel, "Text", "", UDim2.new(1, -24, 1, -12), UDim2.fromOffset(12, 6), 14, COLORS.cream, true)
toastText.TextXAlignment = Enum.TextXAlignment.Center
local saleText = label(gui, "Sale", "", UDim2.fromOffset(210, 36), UDim2.new(1, -230, 0, 208), 22, COLORS.green, true)
saleText.TextXAlignment = Enum.TextXAlignment.Right

local function toast(message, color)
	toastSerial = toastSerial + 1
	local serial = toastSerial
	toastText.Text = message
	toastText.TextColor3 = color or COLORS.cream
	toastPanel.Visible = true
	task.delay(4, function()
		if toastSerial == serial then toastPanel.Visible = false end
	end)
end

-- Bottom navigation contains the tutorial's Build and Hire buttons.
local nav = frame(gui, "Navigation", UDim2.fromOffset(610, 64), UDim2.new(.5, -305, 1, -78), COLORS.panel)
stroke(nav)
local computerButton = button(nav, "Computer", "COMPUTER", UDim2.fromOffset(135, 42), UDim2.fromOffset(11, 11), true)
local buildButton = button(nav, "Build", "BUILD", UDim2.fromOffset(135, 42), UDim2.fromOffset(157, 11), true)
local hireButton = button(nav, "Hire", "HIRE", UDim2.fromOffset(135, 42), UDim2.fromOffset(303, 11), true)
local startDayButton = button(nav, "StartDay", "START DAY", UDim2.fromOffset(150, 42), UDim2.fromOffset(449, 11), false)

-- Modal window used by the computer, build catalogue and hiring screen.
local shade = frame(gui, "Shade", UDim2.fromScale(1, 1), UDim2.new(), Color3.fromRGB(8, 9, 11))
shade.BackgroundTransparency = .25
shade.Visible = false
shade.ZIndex = 20
local window = frame(shade, "Window", UDim2.fromScale(.82, .78), UDim2.fromScale(.5, .5), COLORS.panel)
window.AnchorPoint = Vector2.new(.5, .5)
window.ZIndex = 21
stroke(window, COLORS.gold)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(880, 650)
sizeLimit.MinSize = Vector2.new(420, 380)
sizeLimit.Parent = window
local windowTitle = label(window, "Title", "", UDim2.new(1, -90, 0, 42), UDim2.fromOffset(24, 15), 25, COLORS.cream, true)
windowTitle.ZIndex = 22
local closeButton = button(window, "Close", "×", UDim2.fromOffset(38, 34), UDim2.new(1, -54, 0, 14), true)
closeButton.ZIndex = 22
local windowSubtitle = label(window, "Subtitle", "", UDim2.new(1, -48, 0, 45), UDim2.fromOffset(24, 59), 14, COLORS.muted)
windowSubtitle.ZIndex = 22
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Position = UDim2.fromOffset(22, 112)
content.Size = UDim2.new(1, -44, 1, -134)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = COLORS.gold
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.ZIndex = 22
content.Parent = window
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 12)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

local dynamicConnections = {}
local function clearContent()
	for _, connection in ipairs(dynamicConnections) do connection:Disconnect() end
	table.clear(dynamicConnections)
	for _, child in ipairs(content:GetChildren()) do
		if child ~= contentLayout then child:Destroy() end
	end
end

local function menuCard(title, description, price, actionText, callback, disabled)
	local card = frame(content, title:gsub("%W", ""), UDim2.new(1, -8, 0, 112), UDim2.new(), COLORS.panel2)
	card.ZIndex = 23
	stroke(card)
	local titleLabel = label(card, "Name", title, UDim2.new(1, -190, 0, 28), UDim2.fromOffset(16, 13), 17, COLORS.cream, true)
	titleLabel.ZIndex = 24
	local descriptionLabel = label(card, "Description", description, UDim2.new(1, -190, 0, 54), UDim2.fromOffset(16, 45), 13, COLORS.muted)
	descriptionLabel.ZIndex = 24
	local buy = button(card, "Action", actionText .. (price and (" · " .. formatMoney(price)) or ""), UDim2.fromOffset(160, 62), UDim2.new(1, -176, .5, -31), disabled)
	buy.ZIndex = 24
	buy.Active = not disabled
	buy.AutoButtonColor = not disabled
	if disabled then buy.TextColor3 = COLORS.muted end
	if not disabled then table.insert(dynamicConnections, buy.Activated:Connect(callback)) end
	return card
end

local BUILD_ITEMS = {
	{"SortingDesk", "Clothing sorting desk", "Unpack, inspect and sort designer-inspired clothing. Required first.", 100},
	{"PackingStation", "Packing station", "Adds room for packers and more orders per day.", 350},
	{"ClothingRack", "Designer clothing racks", "Display fictional premium labels and increase order capacity.", 650},
	{"PhotoStudio", "Product photo studio", "Unlock photographers and stronger product listings.", 1800},
	{"Showroom", "Luxury showroom", "Your flagship warehouse upgrade. Unlocks managers.", 6000},
}

local WORKER_ITEMS = {
	{"Sorter", "Clothing sorter", "Sorts incoming clothes and prepares online orders.", 75, "SortingDesk"},
	{"Packer", "Order packer", "Boxes and ships orders faster. Requires packing station.", 250, "PackingStation"},
	{"Photographer", "Product photographer", "Creates product photos. Requires photo studio.", 700, "PhotoStudio"},
	{"Manager", "Warehouse manager", "Manages a much larger operation. Requires showroom.", 2500, "Showroom"},
}

local ADS = {
	{"Local social post", 100, "1.5× traffic"},
	{"Influencer package", 750, "2.2× traffic"},
	{"City campaign", 3500, "3.4× traffic"},
	{"National campaign", 18000, "5.5× traffic"},
	{"Global fashion campaign", 90000, "9× traffic"},
}

local function movement()
	if shade.Visible then controls:Disable() else controls:Enable() end
end

local function closeMenu()
	activeMenu = nil
	shade.Visible = false
	movement()
end

local renderMenu
local function openMenu(name)
	if not state then return end
	activeMenu = name
	shade.Visible = true
	movement()
	renderMenu()
end

renderMenu = function()
	if not state or not activeMenu then return end
	clearContent()
	if activeMenu == "Computer" then
		windowTitle.Text = state.companyName .. " / OFFICE COMPUTER"
		windowSubtitle.Text = "Create your store, advertise it and watch your online business grow."
		if not state.websiteReady then
			if state.websiteProgress > 0 then
				menuCard("Creating your online store...", "Your website is being designed. This takes 15 seconds.", nil,
					math.floor(state.websiteProgress * 100) .. "% complete", function() end, true)
			else
				menuCard("Start a website", "Create a clean online store for your clothing company. Build time: 15 seconds.", nil,
					"CREATE WEBSITE", function()
						local success, message = call("StartWebsite")
						if success then websiteStartedAt = os.clock(); toast("Website construction started — 15 seconds.", COLORS.gold) else toast(message, COLORS.red) end
					end, false)
			end
		else
			menuCard("Website online", "Your store is live and ready for customers.", nil, "ONLINE", function() end, true)
			local nextAd = state.adLevel + 1
			local ad = ADS[nextAd]
			if ad then
				menuCard(ad[1], "Permanent marketing upgrade: " .. ad[3] .. ".", ad[2], "BUY ADS", function()
					local success, message = call("BuyAd", nextAd)
					if success then toast("Ad campaign purchased! Traffic increased.", COLORS.green) else toast(message, COLORS.red) end
				end, false)
			else
				menuCard("Global brand reach", "Every campaign has been purchased. Your brand has maximum traffic.", nil, "MAXED", function() end, true)
			end
			menuCard("Live store stats", "Today's revenue: " .. formatMoney(state.todayRevenue) .. "\nExpected sale batch: " .. formatMoney(state.salePerTick) .. " every 3 seconds.", nil,
				"DAY " .. state.day, function() end, true)
		end
	elseif activeMenu == "Build" then
		windowTitle.Text = "BUILD / WAREHOUSE"
		windowSubtitle.Text = "Buy real work areas for your clothing operation. They appear inside the warehouse."
		for _, item in ipairs(BUILD_ITEMS) do
			local key, title, description, price = item[1], item[2], item[3], item[4]
			local owned = state.buildings[key]
			local locked = key ~= "SortingDesk" and not state.buildings.SortingDesk
			menuCard(title, description, price, owned and "BUILT" or (locked and "LOCKED" or "BUILD"), function()
				local success, message = call("Build", key)
				if success then toast(title .. " built.", COLORS.green) else toast(message, COLORS.red) end
			end, owned or locked)
		end
	elseif activeMenu == "Hire" then
		windowTitle.Text = "HIRE / TEAM"
		windowSubtitle.Text = "Employees sort clothes, pack orders and ship them. Wages are paid after each day."
		for _, item in ipairs(WORKER_ITEMS) do
			local key, title, description, price, requirement = item[1], item[2], item[3], item[4], item[5]
			local locked = not state.buildings[requirement]
			local count = state.workers[key] or 0
			menuCard(title .. " · hired " .. count, description, price, locked and "NEEDS WORKSTATION" or "HIRE", function()
				local success, message = call("Hire", key)
				if success then toast(title .. " hired.", COLORS.green) else toast(message, COLORS.red) end
			end, locked)
		end
	end
end

closeButton.Activated:Connect(closeMenu)
computerButton.Activated:Connect(function() openMenu("Computer") end)
buildButton.Activated:Connect(function()
	if not state or not state.websiteReady then toast("Create your website first.", COLORS.red); return end
	openMenu("Build")
end)
hireButton.Activated:Connect(function()
	if not state or not state.buildings.SortingDesk then toast("Build a clothing sorting desk first.", COLORS.red); return end
	openMenu("Hire")
end)
startDayButton.Activated:Connect(function()
	if not state then return end
	local success, message = call("StartDay")
	if not success then toast(message, COLORS.red) end
end)

-- Day completion popup.
local results = frame(gui, "DayResults", UDim2.fromOffset(470, 390), UDim2.fromScale(.5, .5), COLORS.panel)
results.AnchorPoint = Vector2.new(.5, .5)
results.Visible = false
results.ZIndex = 40
stroke(results, COLORS.gold)
local resultsTitle = label(results, "Title", "DAY 1 COMPLETED", UDim2.new(1, -40, 0, 46), UDim2.fromOffset(20, 24), 27, COLORS.gold, true)
resultsTitle.TextXAlignment = Enum.TextXAlignment.Center
local resultsSummary = label(results, "Summary", "", UDim2.new(1, -60, 0, 205), UDim2.fromOffset(30, 88), 18, COLORS.cream)
resultsSummary.TextXAlignment = Enum.TextXAlignment.Center
local resultsButton = button(results, "Continue", "CONTINUE BUILDING", UDim2.new(1, -60, 0, 52), UDim2.new(0, 30, 1, -78), false)
resultsButton.ZIndex = 41
resultsButton.Activated:Connect(function() results.Visible = false; movement() end)

-- World marker points to the computer during the tutorial.
local markerPart = Instance.new("Part")
markerPart.Name = "PersonalTutorialMarker"
markerPart.Anchored = true
markerPart.CanCollide = false
markerPart.CanQuery = false
markerPart.CanTouch = false
markerPart.Transparency = 1
markerPart.Parent = workspace
local marker = Instance.new("BillboardGui")
marker.Name = "TutorialMarker"
marker.Size = UDim2.fromOffset(180, 80)
marker.StudsOffset = Vector3.new(0, 4, 0)
marker.AlwaysOnTop = true
marker.Adornee = markerPart
marker.Parent = player:WaitForChild("PlayerGui")
local markerText = label(marker, "Text", "▼ USE COMPUTER", UDim2.fromScale(1, 1), UDim2.new(), 18, COLORS.gold, true)
markerText.TextXAlignment = Enum.TextXAlignment.Center

local function refresh()
	if not state then return end
	companyName.Text = state.companyName
	companyCash.Text = formatMoney(state.cash)
	local objectives = {
		CreateWebsite = {"01 / CREATE YOUR STORE", "Use the computer and click Start a website. It takes 15 seconds."},
		BuildDesk = {"02 / BUILD A WORKSPACE", "Click BUILD, then buy a clothing sorting desk for $100."},
		HireWorker = {"03 / HIRE YOUR FIRST EMPLOYEE", "Click HIRE and employ a clothing sorter for $75."},
		BuyAds = {"04 / FIND CUSTOMERS", "Use the computer again and buy your first $100 ad campaign."},
		RunBusiness = {"GROW TO $1,000,000", "Build, hire and advertise. Complete days until your company becomes a millionaire."},
	}
	local objective = objectives[state.stage]
	tutorialTitle.Text, tutorialHint.Text = objective[1], objective[2]
	buildButton.BackgroundColor3 = state.stage == "BuildDesk" and COLORS.gold or COLORS.panel2
	hireButton.BackgroundColor3 = state.stage == "HireWorker" and COLORS.gold or COLORS.panel2
	computerButton.BackgroundColor3 = (state.stage == "CreateWebsite" or state.stage == "BuyAds") and COLORS.gold or COLORS.panel2
	startDayButton.Visible = state.stage == "RunBusiness" and not state.dayRunning
	if state.dayRunning then
		local seconds = math.max(0, math.ceil(state.dayTimeLeft))
		dayLabel.Text = "DAY " .. state.day .. " · " .. seconds .. "s · SALES " .. formatMoney(state.todayRevenue)
		dayProgress.Size = UDim2.fromScale(math.clamp(1 - state.dayTimeLeft / 60, 0, 1), 1)
	else
		dayLabel.Text = "DAY " .. state.day .. " · READY"
		dayProgress.Size = UDim2.fromScale(0, 1)
	end
	marker.Enabled = state.stage == "CreateWebsite" or state.stage == "BuyAds"
	if marker.Enabled and plot then
		local target = plot:FindFirstChild("CompanyComputer", true) or plot:FindFirstChild("LaptopSpot", true)
		if target then markerPart.CFrame = target.CFrame end
	end
end

local function receive(data)
	state = data
	plot = workspace:WaitForChild("ClothingCompanyPlots"):WaitForChild(state.plot)
	if state.websiteProgress > 0 and websiteStartedAt == 0 then websiteStartedAt = os.clock() - state.websiteProgress * 15 end
	refresh()
	if activeMenu then renderMenu() end
end

changed.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then
		receive(data)
	elseif kind == "OpenComputer" then
		openMenu("Computer")
	elseif kind == "Toast" then
		toast(data)
	elseif kind == "WebsiteReady" then
		toast("Your website is LIVE! Now click BUILD and buy a clothing sorting desk.", COLORS.green)
		if activeMenu == "Computer" then closeMenu() end
	elseif kind == "Built" then
		toast(data.name .. " added to your warehouse.", COLORS.green)
		if activeMenu == "Build" then renderMenu() end
	elseif kind == "Hired" then
		toast(data.name .. " joined your company.", COLORS.green)
		if activeMenu == "Hire" then renderMenu() end
	elseif kind == "AdBought" then
		toast(data.name .. " purchased — traffic is now " .. data.multiplier .. "×.", COLORS.green)
		closeMenu()
	elseif kind == "Sale" then
		saleText.Text = "+" .. formatMoney(data) .. " orders"
		saleText.TextTransparency = 0
		task.spawn(function()
			local serial = os.clock()
			task.wait(1.3)
			if saleText.Text ~= "" and os.clock() >= serial then saleText.TextTransparency = 1 end
		end)
	elseif kind == "DayStarted" then
		toast("Day " .. data .. " started. Your team is processing orders!", COLORS.gold)
	elseif kind == "DayComplete" then
		closeMenu()
		results.Visible = true
		movement()
		resultsTitle.Text = data.millionaire and "YOU BUILT A MILLION-DOLLAR COMPANY!" or ("DAY " .. data.day .. " COMPLETED")
		resultsSummary.Text = "Revenue  " .. formatMoney(data.revenue) .. "\nWages  -" .. formatMoney(data.wages)
			.. "\n\nDay profit  " .. formatMoney(data.profit) .. "\nCompany cash  " .. formatMoney(data.cash)
			.. "\nCompany value  " .. formatMoney(data.companyValue)
		resultsButton.Text = data.millionaire and "KEEP BUILDING THE EMPIRE" or "CONTINUE TO DAY " .. (data.day + 1)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape and shade.Visible then closeMenu() end
	if input.KeyCode == Enum.KeyCode.B then openMenu("Build") end
	if input.KeyCode == Enum.KeyCode.H then openMenu("Hire") end
	if input.KeyCode == Enum.KeyCode.C then openMenu("Computer") end
end)

player.CharacterAdded:Connect(function()
	closeMenu()
	task.wait(.3)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then workspace.CurrentCamera.CameraSubject = humanoid end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if not state then return end
	if state.dayRunning then
		state.dayTimeLeft = math.max(0, state.dayTimeLeft - deltaTime)
	end
	if state.websiteProgress > 0 and state.websiteProgress < 1 and websiteStartedAt > 0 then
		state.websiteProgress = math.clamp((os.clock() - websiteStartedAt) / 15, 0, 1)
	end
	if activeMenu == "Computer" and state.websiteProgress > 0 and state.websiteProgress < 1 and os.clock() - lastMenuRender > .25 then
		lastMenuRender = os.clock()
		renderMenu()
	end
	refresh()
end)

local function responsive()
	local viewport = workspace.CurrentCamera.ViewportSize
	local narrow = viewport.X < 760
	companyCard.Size = UDim2.fromOffset(narrow and 220 or 270, 104)
	companyCard.Position = UDim2.new(1, narrow and -236 or -290, 0, 16)
	dayCard.Size = UDim2.fromOffset(narrow and 220 or 270, 66)
	dayCard.Position = UDim2.new(1, narrow and -236 or -290, 0, 128)
	tutorial.Size = UDim2.fromOffset(math.min(narrow and viewport.X - 32 or 365, 365), 112)
	tutorial.Position = UDim2.fromOffset(16, narrow and 208 or 20)
	nav.Size = UDim2.new(narrow and 1 or 0, narrow and -24 or 610, 0, narrow and 118 or 64)
	nav.Position = narrow and UDim2.new(0, 12, 1, -130) or UDim2.new(.5, -305, 1, -78)
	if narrow then
		local buttons = {computerButton, buildButton, hireButton, startDayButton}
		for index, object in ipairs(buttons) do
			object.Size = UDim2.new(.5, -17, 0, 42)
			object.Position = UDim2.new((index - 1) % 2 * .5, ((index - 1) % 2) * 6 + 11, math.floor((index - 1) / 2) * .5, 10)
		end
	else
		computerButton.Size, computerButton.Position = UDim2.fromOffset(135,42), UDim2.fromOffset(11,11)
		buildButton.Size, buildButton.Position = UDim2.fromOffset(135,42), UDim2.fromOffset(157,11)
		hireButton.Size, hireButton.Position = UDim2.fromOffset(135,42), UDim2.fromOffset(303,11)
		startDayButton.Size, startDayButton.Position = UDim2.fromOffset(150,42), UDim2.fromOffset(449,11)
	end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(responsive)
responsive()

task.spawn(function()
	for _ = 1, 30 do
		local ok, success, data = pcall(function() return action:InvokeServer("GetState") end)
		if ok and success then receive(data); return end
		task.wait(.3)
	end
	toast("The company could not load. Stop and press Play again.", COLORS.red)
end)
