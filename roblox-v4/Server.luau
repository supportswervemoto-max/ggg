-- Start Your Own Clothing Company V4
-- Server-authoritative economy, tutorial, building, hiring, ads, days and millionaire goal.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local template = workspace:WaitForChild("ClothingCompanySet")
template.Name = "ClothingCompanyTemplate"
template.Parent = ServerStorage
workspace.FallenPartsDestroyHeight = -100

local plots = Instance.new("Folder")
plots.Name = "ClothingCompanyPlots"
plots.Parent = workspace

local network = Instance.new("Folder")
network.Name = "ClothingCompanyV4"
network.Parent = ReplicatedStorage
local action = Instance.new("RemoteFunction")
action.Name = "Action"
action.Parent = network
local changed = Instance.new("RemoteEvent")
changed.Name = "Changed"
changed.Parent = network

local DAY_SECONDS = 60
local SALE_INTERVAL = 3
local STARTING_CASH = 500
local states = {}
local occupiedSlots = {}

local BUILDINGS = {
	SortingDesk = {name = "Clothing sorting desk", price = 100, model = "SortingDeskBuild", capacity = 18},
	PackingStation = {name = "Packing station", price = 350, model = "PackingStationBuild", capacity = 30},
	ClothingRack = {name = "Designer clothing racks", price = 650, model = "ClothingRackBuild", capacity = 55},
	PhotoStudio = {name = "Product photo studio", price = 1800, model = "PhotoStudioBuild", capacity = 90},
	Showroom = {name = "Luxury showroom", price = 6000, model = "ShowroomBuild", capacity = 180},
}

local WORKERS = {
	Sorter = {name = "Clothing sorter", price = 75, wage = 18, speed = 1},
	Packer = {name = "Order packer", price = 250, wage = 45, speed = 2, requires = "PackingStation"},
	Photographer = {name = "Product photographer", price = 700, wage = 110, speed = 3, requires = "PhotoStudio"},
	Manager = {name = "Warehouse manager", price = 2500, wage = 350, speed = 7, requires = "Showroom"},
}

local ADS = {
	[1] = {name = "Local social post", price = 100, multiplier = 1.5},
	[2] = {name = "Influencer package", price = 750, multiplier = 2.2},
	[3] = {name = "City campaign", price = 3500, multiplier = 3.4},
	[4] = {name = "National campaign", price = 18000, multiplier = 5.5},
	[5] = {name = "Global fashion campaign", price = 90000, multiplier = 9},
}

local function find(state, name)
	return state.plot:FindFirstChild(name, true)
end

local function setVisible(group, visible)
	if not group then return end
	for _, object in ipairs(group:GetDescendants()) do
		if object:IsA("BasePart") then
			if object:GetAttribute("OriginalTransparency") == nil then
				object:SetAttribute("OriginalTransparency", object.Transparency)
				object:SetAttribute("OriginalCollision", object.CanCollide)
				object:SetAttribute("OriginalQuery", object.CanQuery)
			end
			object.Transparency = visible and object:GetAttribute("OriginalTransparency") or 1
			object.CanCollide = visible and object:GetAttribute("OriginalCollision") or false
			object.CanQuery = visible and object:GetAttribute("OriginalQuery") or false
		elseif object:IsA("SurfaceGui") or object:IsA("BillboardGui") or object:IsA("Light") then
			object.Enabled = visible
		end
	end
end

local function root(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	return character:FindFirstChild("HumanoidRootPart")
end

local function near(player, part, distance)
	local playerRoot = root(player)
	return playerRoot and part and (playerRoot.Position - part.Position).Magnitude <= distance
end

local function workerPower(state)
	local power = 0
	for workerKey, amount in pairs(state.workers) do power = power + WORKERS[workerKey].speed * amount end
	return power
end

local function orderCapacity(state)
	local capacity = 0
	for buildingKey in pairs(state.buildings) do capacity = capacity + BUILDINGS[buildingKey].capacity end
	return capacity
end

local function adMultiplier(state)
	local info = ADS[state.adLevel]
	return info and info.multiplier or 1
end

local function wageBill(state)
	local wages = 0
	for workerKey, amount in pairs(state.workers) do wages = wages + WORKERS[workerKey].wage * amount end
	return wages
end

local function saleValue(state)
	local capacity = math.max(1, orderCapacity(state))
	local labor = math.max(1, workerPower(state))
	local brandGrowth = 1 + math.min(state.day - 1, 40) * 0.08
	local orders = math.min(capacity, labor * 4)
	return math.max(0, math.floor(orders * 4 * adMultiplier(state) * brandGrowth))
end

local function companyValue(state)
	local assetValue = 0
	for buildingKey in pairs(state.buildings) do assetValue = assetValue + BUILDINGS[buildingKey].price end
	for workerKey, amount in pairs(state.workers) do assetValue = assetValue + WORKERS[workerKey].price * amount end
	return state.cash + assetValue + state.totalRevenue
end

local function packet(state)
	local workersCopy, buildingsCopy = {}, {}
	for key, value in pairs(state.workers) do workersCopy[key] = value end
	for key, value in pairs(state.buildings) do buildingsCopy[key] = value end
	return {
		stage = state.stage, companyName = state.companyName, cash = state.cash, day = state.day,
		dayRunning = state.dayRunning,
		dayTimeLeft = state.dayRunning and math.max(0, DAY_SECONDS - (os.clock() - state.dayStarted)) or DAY_SECONDS,
		websiteProgress = state.websiteBuilding and math.clamp((os.clock() - state.websiteStarted) / 15, 0, 1) or (state.websiteReady and 1 or 0),
		websiteReady = state.websiteReady, workers = workersCopy, workerPower = workerPower(state),
		buildings = buildingsCopy, capacity = orderCapacity(state), adLevel = state.adLevel,
		adMultiplier = adMultiplier(state), wages = wageBill(state), todayRevenue = state.todayRevenue,
		totalRevenue = state.totalRevenue, companyValue = companyValue(state), salePerTick = saleValue(state),
		plot = state.plot.Name,
	}
end

local function send(player)
	local state = states[player]
	if not state then return end
	state.cashStat.Value = state.cash
	state.dayStat.Value = state.day
	changed:FireClient(player, "State", packet(state))
end

local function toast(player, message) changed:FireClient(player, "Toast", message) end

local function prompt(part, actionText, objectText)
	local interaction = Instance.new("ProximityPrompt")
	interaction.ActionText = actionText
	interaction.ObjectText = objectText
	interaction.KeyboardKeyCode = Enum.KeyCode.E
	interaction.MaxActivationDistance = 11
	interaction.HoldDuration = 0.2
	interaction.RequiresLineOfSight = false
	interaction.Parent = part
	return interaction
end

local function updateCompanySigns(state)
	for _, object in ipairs(state.plot:GetDescendants()) do
		if object.Name == "CompanyNameText" and object:IsA("TextLabel") then object.Text = string.upper(state.companyName) end
	end
end

local function placeCharacter(player)
	local state, character = states[player], player.Character
	if not state or not character then return end
	local playerRoot = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not playerRoot or not humanoid or states[player] ~= state then return end
	humanoid.Sit = false
	playerRoot.Anchored = false
	local spawnMarker = find(state, "CompanySpawn") or find(state, "Arrival")
	character:PivotTo(CFrame.lookAt(spawnMarker.Position + Vector3.new(0, 2, 0), spawnMarker.Position + Vector3.new(0, 2, 12)))
end

local function createWorkerModel(state, workerKey, index)
	local spawn = find(state, "WorkerSpawn") or find(state, "LaptopSpot")
	if not spawn then return end
	local model = Instance.new("Model")
	model.Name = workerKey .. "Worker" .. index
	model:SetAttribute("CompanyWorker", true)
	local colors = {Sorter = Color3.fromRGB(91,126,145), Packer = Color3.fromRGB(158,111,75), Photographer = Color3.fromRGB(116,91,145), Manager = Color3.fromRGB(51,66,77)}
	local function bodyPart(name, size, offset, color)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = name, size, color
		part.Material, part.Anchored, part.CanCollide = Enum.Material.SmoothPlastic, true, false
		part.CFrame = CFrame.new(spawn.Position + offset + Vector3.new((index - 1) * 2.4, 0, 0))
		part.Parent = model
		return part
	end
	bodyPart("Torso", Vector3.new(2,2.4,1), Vector3.new(0,3.4,0), colors[workerKey])
	bodyPart("Head", Vector3.new(1.5,1.5,1.5), Vector3.new(0,5.35,0), Color3.fromRGB(221,174,135)).Shape = Enum.PartType.Ball
	bodyPart("LeftLeg", Vector3.new(.8,2,.8), Vector3.new(-.5,1.2,0), Color3.fromRGB(43,51,58))
	bodyPart("RightLeg", Vector3.new(.8,2,.8), Vector3.new(.5,1.2,0), Color3.fromRGB(43,51,58))
	bodyPart("Package", Vector3.new(1.6,1.2,1.4), Vector3.new(0,3.1,-1.2), Color3.fromRGB(190,155,103)).Material = Enum.Material.WoodPlanks
	model.Parent = state.plot
end

local function finishDay(player, state)
	if states[player] ~= state or not state.dayRunning then return end
	state.dayRunning = false
	local wages = wageBill(state)
	state.cash = math.max(0, state.cash - wages)
	local completedDay = state.day
	state.day = state.day + 1
	state.totalRevenue = state.totalRevenue + state.todayRevenue
	local results = {day = completedDay, revenue = state.todayRevenue, wages = wages, profit = state.todayRevenue - wages,
		cash = state.cash, companyValue = companyValue(state), millionaire = state.cash >= 1000000 or companyValue(state) >= 1000000}
	state.todayRevenue = 0
	send(player)
	changed:FireClient(player, "DayComplete", results)
end

local function startDay(player, state)
	if state.dayRunning or state.stage ~= "RunBusiness" then return false, "Complete the tutorial first." end
	state.dayRunning, state.dayStarted, state.todayRevenue = true, os.clock(), 0
	send(player)
	changed:FireClient(player, "DayStarted", state.day)
	task.delay(DAY_SECONDS, function() finishDay(player, state) end)
	return true
end

local function join(player)
	if states[player] then return end
	local slot = 0
	while occupiedSlots[slot] do slot = slot + 1 end
	occupiedSlots[slot] = true
	local plot = template:Clone()
	plot.Name = tostring(player.UserId)
	plot:PivotTo(plot:GetPivot() + Vector3.new(slot * 720, 0, 0))
	plot.Parent = plots

	local leaderstats = Instance.new("Folder")
	leaderstats.Name, leaderstats.Parent = "leaderstats", player
	local cashStat = Instance.new("IntValue")
	cashStat.Name, cashStat.Parent = "CompanyCash", leaderstats
	local dayStat = Instance.new("IntValue")
	dayStat.Name, dayStat.Parent = "Day", leaderstats
	local state = {slot=slot, plot=plot, companyName=player.Name.."'s Company", stage="CreateWebsite", cash=STARTING_CASH,
		day=1, dayRunning=false, dayStarted=0, websiteBuilding=false, websiteStarted=0, websiteReady=false,
		buildings={}, workers={}, adLevel=0, todayRevenue=0, totalRevenue=0, lastAction=0, cashStat=cashStat, dayStat=dayStat}
	states[player] = state
	updateCompanySigns(state)
	for _, info in pairs(BUILDINGS) do setVisible(find(state, info.model), false) end
	for _, oldModel in ipairs({"WorkspaceUpgrade", "ServerUpgrade", "StudioUpgrade"}) do setVisible(find(state, oldModel), false) end

	local computer = find(state, "CompanyComputer") or find(state, "LaptopSpot")
	prompt(computer, "Use computer", state.companyName).Triggered:Connect(function(who)
		if who == player and near(player, computer, 14) then changed:FireClient(player, "OpenComputer") end
	end)
	player.CharacterAdded:Connect(function() task.wait(.2); placeCharacter(player) end)
	if player.Character then task.defer(placeCharacter, player) end
	send(player)
end

action.OnServerInvoke = function(player, actionName, argument)
	local state = states[player]
	if not state then return false, "Loading your company..." end
	if actionName == "GetState" then return true, packet(state) end
	if type(actionName) ~= "string" then return false, "Invalid action." end
	if os.clock() - state.lastAction < .12 then return false, "One moment..." end
	state.lastAction = os.clock()

	if actionName == "StartWebsite" then
		if state.stage ~= "CreateWebsite" or state.websiteBuilding then return false, "Your website is already being handled." end
		local computer = find(state, "CompanyComputer") or find(state, "LaptopSpot")
		if not near(player, computer, 15) then return false, "Use your company computer first." end
		state.websiteBuilding, state.websiteStarted = true, os.clock()
		send(player)
		task.delay(15, function()
			if states[player] ~= state or not state.websiteBuilding then return end
			state.websiteBuilding, state.websiteReady, state.stage = false, true, "BuildDesk"
			send(player)
			changed:FireClient(player, "WebsiteReady")
		end)
		return true
	end

	if actionName == "Build" and type(argument) == "string" then
		local info = BUILDINGS[argument]
		if not info then return false, "That build item does not exist." end
		if not state.websiteReady then return false, "Create your website first." end
		if state.buildings[argument] then return false, "You already own this build item." end
		if argument ~= "SortingDesk" and not state.buildings.SortingDesk then return false, "Build the clothing sorting desk first." end
		if state.cash < info.price then return false, "You need $" .. info.price .. "." end
		state.cash = state.cash - info.price
		state.buildings[argument] = true
		setVisible(find(state, info.model), true)
		if state.stage == "BuildDesk" and argument == "SortingDesk" then state.stage = "HireWorker" end
		send(player)
		changed:FireClient(player, "Built", {key=argument, name=info.name})
		return true
	end

	if actionName == "Hire" and type(argument) == "string" then
		local info = WORKERS[argument]
		if not info then return false, "That worker role does not exist." end
		if not state.buildings.SortingDesk then return false, "Build a sorting desk first." end
		if info.requires and not state.buildings[info.requires] then return false, "Build the required workstation first." end
		if state.cash < info.price then return false, "You need $" .. info.price .. " to hire this worker." end
		state.cash = state.cash - info.price
		state.workers[argument] = (state.workers[argument] or 0) + 1
		createWorkerModel(state, argument, state.workers[argument])
		if state.stage == "HireWorker" then state.stage = "BuyAds" end
		send(player)
		changed:FireClient(player, "Hired", {name=info.name})
		return true
	end

	if actionName == "BuyAd" and type(argument) == "number" then
		if state.stage ~= "BuyAds" and state.stage ~= "RunBusiness" then
			return false, "Finish the website, desk, and first hire before buying ads."
		end
		local nextLevel = state.adLevel + 1
		local info = ADS[nextLevel]
		if not info or argument ~= nextLevel then return false, "Buy the next available campaign." end
		if state.stage == "BuyAds" then
			local computer = find(state, "CompanyComputer") or find(state, "LaptopSpot")
			if not near(player, computer, 15) then return false, "Buy your first ad from the company computer." end
		end
		if state.cash < info.price then return false, "You need $" .. info.price .. " for this campaign." end
		state.cash = state.cash - info.price
		state.adLevel = nextLevel
		if state.stage == "BuyAds" then state.stage = "RunBusiness" end
		send(player)
		changed:FireClient(player, "AdBought", {name=info.name, multiplier=info.multiplier})
		if not state.dayRunning then startDay(player, state) end
		return true
	end

	if actionName == "StartDay" then return startDay(player, state) end
	return false, "That action is not available yet."
end

Players.PlayerAdded:Connect(join)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(join, player) end
Players.PlayerRemoving:Connect(function(player)
	local state = states[player]
	if state then occupiedSlots[state.slot] = nil; state.plot:Destroy() end
	states[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(SALE_INTERVAL)
		for player, state in pairs(states) do
			if state.dayRunning then
				local revenue = saleValue(state)
				state.cash = state.cash + revenue
				state.todayRevenue = state.todayRevenue + revenue
				send(player)
				changed:FireClient(player, "Sale", revenue)
			end
		end
	end
end)
