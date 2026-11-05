-- AI BOT V3. Purchases, distance checks and income are server-owned.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Storage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

local template = workspace:WaitForChild('AIBotSet')
template.Name = 'AIBotTemplate'
template.Parent = Storage
workspace.FallenPartsDestroyHeight=-100
local plots = Instance.new('Folder')
plots.Name = 'AIBotPlots'
plots.Parent = workspace
local network = Instance.new('Folder')
network.Name = 'AIBotV3'
network.Parent = RS
local remote = Instance.new('RemoteFunction')
remote.Name = 'Action'
remote.Parent = network
local event = Instance.new('RemoteEvent')
event.Name = 'Changed'
event.Parent = network

local states = {}
local occupied = {}
local upgrades = {
 Desk = {price=75, model='WorkspaceUpgrade', pad='DeskPad', label='DUAL DISPLAYS', description='Capacity +4. Earnings +25%.'},
 Server = {price=200, model='ServerUpgrade', pad='ServerPad', label='SERVER RACK', description='Capacity +6. Earnings x2.'},
 Studio = {price=125, model='StudioUpgrade', pad='StudioPad', label='STUDIO LOUNGE', description='Earnings +50%.'},
}

local function capacity(s)
 return 3 + (s.owned.Desk and 4 or 0) + (s.owned.Server and 6 or 0)
end
local function income(s)
 return math.floor(s.level * 3 * (s.owned.Desk and 1.25 or 1)
  * (s.owned.Server and 2 or 1) * (s.owned.Studio and 1.5 or 1))
end
local function packet(s)
 return {stage=s.stage,cash=s.cash,level=s.level,cap=capacity(s),income=income(s),
  cost=10+s.level*8,training=s.training,owned=table.clone(s.owned),plot=s.plot.Name,research=s.researchCount}
end
local function send(p)
 local s=states[p]
 if not s then return end
 s.cashStat.Value=s.cash
 s.levelStat.Value=s.level
 event:FireClient(p,'State',packet(s))
end
local function notice(p,msg) event:FireClient(p,'Toast',msg) end
local function find(s,name) return s.plot:FindFirstChild(name,true) end
local function root(p)
 local c=p.Character
 local h=c and c:FindFirstChildOfClass('Humanoid')
 return h and h.Health>0 and c:FindFirstChild('HumanoidRootPart') or nil
end
local function near(p,position,range)
 local r=root(p)
 return r and (r.Position-position).Magnitude<=range
end
local function visible(group,show)
 for _,o in ipairs(group:GetDescendants()) do
  if o:IsA('BasePart') then
   if o:GetAttribute('OriginalTransparency')==nil then
    o:SetAttribute('OriginalTransparency',o.Transparency)
    o:SetAttribute('OriginalCollision',o.CanCollide)
    o:SetAttribute('OriginalQuery',o.CanQuery)
   end
   o.Transparency=show and o:GetAttribute('OriginalTransparency') or 1
   o.CanCollide=show and o:GetAttribute('OriginalCollision') or false
   o.CanQuery=show and o:GetAttribute('OriginalQuery') or false
  elseif o:IsA('Light') or o:IsA('SurfaceGui') then
   o.Enabled=show
  end
 end
end
local function placeCharacter(p)
 local s=states[p]
 if not s then return end
 local c=p.Character
 if not c then return end
 local r=c:WaitForChild('HumanoidRootPart',10)
 local h=c:WaitForChild('Humanoid',10)
 if not r or not h or states[p]~=s then return end
 h.Sit=false
 r.Anchored=false
 h.WalkSpeed=16
 local marker=find(s,s.stage=='Intro' and 'HomeSeat' or 'Arrival')
 local pos=marker.Position
 if s.stage~='Intro' then pos=pos+Vector3.new(0,1,0) end
 c:PivotTo(CFrame.lookAt(pos,pos+Vector3.new(0,0,10)))
 if s.stage=='Intro' then
  h.Sit=true
  r.Anchored=true
 end
end
local function makePrompt(part,action,objectText)
 local pr=Instance.new('ProximityPrompt')
 pr.ActionText=action
 pr.ObjectText=objectText
 pr.MaxActivationDistance=9
 pr.RequiresLineOfSight=false
 pr.HoldDuration=.25
 pr.KeyboardKeyCode=Enum.KeyCode.E
 pr.Parent=part
 return pr
end
local function purchase(p,key)
 local s=states[p]
 local info=upgrades[key]
 if not s or not info or s.stage~='Play' then return false,'Complete the laptop tutorial first.' end
 if not near(p,find(s,info.pad).Position,13) then return false,'Walk to this upgrade terminal first.' end
 if s.owned[key] then return false,'You already own this upgrade.' end
 if s.cash<info.price then return false,'You need $'..info.price..' for this upgrade.' end
 s.cash=s.cash-info.price
 s.owned[key]=true
 visible(find(s,info.model),true)
 local pad=find(s,info.pad)
 local pr=pad:FindFirstChildOfClass('ProximityPrompt')
 if pr then pr.Enabled=false end
 local printGui=pad:FindFirstChildOfClass('SurfaceGui')
 if printGui then printGui.Lettering.Text=info.label..'\nINSTALLED' end
 send(p)
 notice(p,info.label..' installed. '..info.description)
 return true
end

local function join(p)
 if states[p] then return end
 local slot=0
 while occupied[slot] do slot=slot+1 end
 occupied[slot]=true
 local plot=template:Clone()
 plot.Name=tostring(p.UserId)
 local offset=Vector3.new(slot*720,0,0)
 plot:PivotTo(plot:GetPivot()+offset)
 plot.Parent=plots
 local stats=Instance.new('Folder')
 stats.Name='leaderstats'
 stats.Parent=p
 local cash=Instance.new('IntValue');cash.Name='Cash';cash.Parent=stats
 local level=Instance.new('IntValue');level.Name='BotLevel';level.Parent=stats
 local s={slot=slot,plot=plot,stage='Intro',cash=25,level=0,owned={},training=false,lastAction=0,research={},researchCount=0,cashStat=cash,levelStat=level}
 states[p]=s
 visible(find(s,'Laptop'),false)
 for _,info in pairs(upgrades) do visible(find(s,info.model),false) end

 local laptopPrompt=makePrompt(find(s,'LaptopSpot'),'Place laptop','YOUR WORKBENCH')
 laptopPrompt.Triggered:Connect(function(who)
  if who~=p or not near(p,find(s,'LaptopSpot').Position,13) then return end
  if s.stage=='Place' then
   s.stage='Course'
   visible(find(s,'Laptop'),true)
   laptopPrompt.ActionText='Open laptop'
   send(p)
  elseif s.stage=='Course' or s.stage=='Play' then
   event:FireClient(p,'Laptop')
  end
 end)
 for key,info in pairs(upgrades) do
  makePrompt(find(s,info.pad),'Inspect · $'..info.price,info.label).Triggered:Connect(function(who)
   if who~=p or not near(p,find(s,info.pad).Position,13) then return end
   if s.stage~='Play' then notice(p,'Set up your laptop first.');return end
   event:FireClient(p,'Upgrade',{key=key,price=info.price,title=info.label,description=info.description})
  end)
 end
 for _,name in ipairs({'ResearchCafe','ResearchTech','ResearchPark'}) do
  local marker=find(s,name)
  if marker then
   local pr=makePrompt(marker,'Read research notes · +$35','LOCAL RESEARCH')
   pr.Triggered:Connect(function(who)
    if who~=p or not near(p,marker.Position,12) then return end
    if s.stage~='Play' or s.level==0 then notice(p,'Launch your first bot before exploring.');return end
    if s.research[name] then return end
    s.research[name]=true;s.researchCount=s.researchCount+1;s.cash=s.cash+35
    pr.Enabled=false
    local notebook=find(s,name..'Notebook')
    if notebook then visible(notebook,false) end
    send(p);notice(p,'Research collected! +$35. Notebook '..s.researchCount..' / 3.')
   end)
  end
 end
 p.CharacterAdded:Connect(function() task.wait(.15);placeCharacter(p) end)
 if p.Character then task.defer(placeCharacter,p) end
 send(p)
end

remote.OnServerInvoke=function(p,action,argument)
 local s=states[p]
 if not s then return false,'Loading your workshop...' end
 if action=='GetState' then return true,packet(s) end
 if type(action)~='string' then return false,'Invalid action.' end
 if os.clock()-s.lastAction<.15 then return false,'One moment...' end
 s.lastAction=os.clock()
 if action=='FinishIntro' and s.stage=='Intro' then
  s.stage='Enter';placeCharacter(p);send(p);return true
 end
 if action=='BuyCourse' then
  if s.stage~='Course' or not near(p,find(s,'LaptopSpot').Position,15) then return false,'Use your laptop first.' end
  if s.cash<10 then return false,'The course costs $10.' end
  s.cash=s.cash-10;s.stage='Play';send(p);return true
 end
 if action=='Train' then
  if s.stage~='Play' or not near(p,find(s,'LaptopSpot').Position,15) then return false,'Invest from your laptop.' end
  if s.training then return false,'Your bot is already training.' end
  if s.level>=capacity(s) then return false,'Capacity reached. Buy dual displays or a server rack.' end
  local cost=10+s.level*8
  if s.cash<cost then return false,'Need $'..cost..'. Your bot earns cash every 4 seconds.' end
  s.cash=s.cash-cost;s.training=true;send(p)
  task.delay(2.5,function()
   if states[p]~=s then return end
   s.level=s.level+1;s.training=false;send(p)
   event:FireClient(p,'Trained',s.level)
  end)
  return true
 end
 if action=='Upgrade' and type(argument)=='string' then return purchase(p,argument) end
 return false,'That action is not available yet.'
end

Players.PlayerAdded:Connect(join)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
Players.PlayerRemoving:Connect(function(p)
 local s=states[p]
 if s then occupied[s.slot]=nil;s.plot:Destroy() end
 states[p]=nil
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed=elapsed+dt
 if elapsed<.2 then return end
 elapsed=0
 for p,s in pairs(states) do
  if s.stage=='Enter' then
   local entry=find(s,'Entrance')
   local r=root(p)
   if r and math.abs(r.Position.X-entry.Position.X)<12 and r.Position.Z>entry.Position.Z-1
    and r.Position.Z<entry.Position.Z+9 then
    s.stage='Place';send(p)
   end
  end
 end
end)
task.spawn(function()
 while true do
  task.wait(4)
  for p,s in pairs(states) do
   if s.stage=='Play' and s.level>0 then
    local reward=income(s)
    s.cash=s.cash+reward;send(p);event:FireClient(p,'Income',reward)
   end
  end
 end
end)
