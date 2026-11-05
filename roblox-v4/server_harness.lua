-- Offline behavior checks: this is not a substitute for a Studio playtest.
local now=10
os.clock=function() return now end
table.clone=function(t) local r={};for k,v in pairs(t) do r[k]=v end;return r end
local V={}
local vm={}
vm.__index=function(t,k)
 if k=='Magnitude' then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
 return V[k]
end
vm.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm) end}
CFrame={new=function(value) return {Position=value} end,lookAt=function(pos,focus) return {Position=pos} end}
Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
Enum={KeyCode={E=1},Material={SmoothPlastic=1,WoodPlanks=2},PartType={Ball=0}}
math.clamp=function(value,minimum,maximum) return math.max(minimum,math.min(maximum,value)) end
local function signal()
 local s={callbacks={}}
 function s:Connect(fn) table.insert(self.callbacks,fn) end
 function s:Fire(...) for _,fn in ipairs(self.callbacks) do fn(...) end end
 return s
end
local methods={}
local meta={}
meta.__index=function(t,k)
 if methods[k] then return methods[k] end
 if t.props[k]~=nil then return t.props[k] end
 for _,c in ipairs(t.children) do if c.Name==k then return c end end
end
meta.__newindex=function(t,k,v)
 if k=='Parent' then
  local old=t.props.Parent
  if old then for i,c in ipairs(old.children) do if c==t then table.remove(old.children,i);break end end end
  t.props.Parent=v
  if v then table.insert(v.children,t) end
 elseif k=='CFrame' then t.props.CFrame=v;t.props.Position=v.Position
 else t.props[k]=v end
end
local function new(class,name,parent)
 local t=setmetatable({props={ClassName=class,Name=name or class,Position=Vector3.new(),Transparency=0,CanCollide=true,CanQuery=true},children={},attributes={}},meta)
 if class=='ProximityPrompt' then t.Triggered=signal() end
 if class=='RemoteEvent' then t.calls={};t.FireClient=function(self,p,kind,data) table.insert(self.calls,{p,kind,data}) end end
 t.Parent=parent
 return t
end
function methods:IsA(c) return c==self.ClassName or (c=='BasePart' and self.ClassName=='Part') or (c=='Light' and self.ClassName=='PointLight') end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:SetAttribute(k,v) self.attributes[k]=v end
function methods:FindFirstChild(name,recursive)
 for _,c in ipairs(self.children) do if c.Name==name then return c end end
 if recursive then for _,c in ipairs(self.children) do local f=c:FindFirstChild(name,true);if f then return f end end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),'Missing '..name) end
function methods:FindFirstChildOfClass(class) for _,c in ipairs(self.children) do if c.ClassName==class then return c end end end
function methods:GetDescendants()
 local r={};for _,c in ipairs(self.children) do table.insert(r,c);for _,d in ipairs(c:GetDescendants()) do table.insert(r,d) end end;return r
end
function methods:Clone()
 local t=new(self.ClassName,self.Name)
 for k,v in pairs(self.props) do if k~='Parent' then t.props[k]=v end end
 for _,c in ipairs(self.children) do c:Clone().Parent=t end
 return t
end
function methods:GetPivot() return self.pivot or Vector3.new() end
function methods:PivotTo(cf)
 local pos=cf.Position or cf
 local old=self.pivot or Vector3.new();local delta=pos-old;self.pivot=pos
 for _,c in ipairs(self:GetDescendants()) do if c:IsA('BasePart') then c.Position=c.Position+delta end end
end
function methods:Destroy() self.Parent=nil end
Instance={new=function(class) return new(class) end}
local services={}
for _,name in ipairs({'Players','ReplicatedStorage','ServerStorage','RunService','Workspace'}) do services[name]=new(name,name) end
workspace=services.Workspace
game={GetService=function(self,name) return assert(services[name],name) end}
local players=services.Players
players.PlayerAdded=signal();players.PlayerRemoving=signal();players.GetPlayers=function() return {} end
services.RunService.Heartbeat=signal()
local jobs={}
local delayed={}
task={}
task.spawn=function(fn,...) local co=coroutine.create(fn);local ok,err=coroutine.resume(co,...);assert(ok,err);table.insert(jobs,co) end
task.defer=function(fn,...) fn(...) end
task.delay=function(seconds,fn) table.insert(delayed,{at=now+seconds,fn=fn}) end
task.wait=function(seconds) return coroutine.yield(seconds) end
local template=new('Model','ClothingCompanySet',workspace)
for name,pos in pairs({Arrival={0,3,1},CompanySpawn={-8,1,36},LaptopSpot={0,4,43.8},CompanyComputer={-8,4.5,43.2},WorkerSpawn={4,0,50}}) do
 local p=new('Part',name,template);p.Position=Vector3.new(table.unpack(pos))
end
for _,name in ipairs({'SortingDeskBuild','PackingStationBuild','ClothingRackBuild','PhotoStudioBuild','ShowroomBuild','WorkspaceUpgrade','ServerUpgrade','StudioUpgrade'}) do
 local g=new('Model',name,template);new('Part','VisiblePart',g);new('PointLight','Light',g)
end
local companySign=new('SurfaceGui','CompanySignGui',template)
new('TextLabel','CompanyNameText',companySign)
-- INSERT SERVER SOURCE HERE
local function createPlayer(id)
 local p=new('Player','TestPlayer'..id);p.UserId=id;p.CharacterAdded=signal()
 local char=new('Model','Character');p.Character=char
 local r=new('Part','HumanoidRootPart',char)
 local h=new('Humanoid','Humanoid',char);h.Health=100
 players.PlayerAdded:Fire(p)
 return p,r
end
local p,r=createPlayer(101)
local remote=services.ReplicatedStorage.ClothingCompanyV4.Action
local function invoke(actionName,argument)
 now=now+.2
 return remote.OnServerInvoke(p,actionName,argument)
end
local function state() local ok,s=invoke('GetState');assert(ok);return s end
local function travel(name)
 r.Position=workspace.ClothingCompanyPlots[tostring(p.UserId)]:FindFirstChild(name,true).Position
end
local function runDelayed(seconds)
 now=now+seconds
 local remaining={}
 for _,job in ipairs(delayed) do
  if job.at<=now then job.fn() else table.insert(remaining,job) end
 end
 delayed=remaining
end

local plot=workspace.ClothingCompanyPlots['101']
local initial=state()
assert(initial.stage=='CreateWebsite' and initial.cash==500 and initial.companyName=="TestPlayer101's Company")
assert(plot:FindFirstChild('CompanyNameText',true).Text=="TESTPLAYER101'S COMPANY")
assert(plot.SortingDeskBuild.VisiblePart.Transparency==1)
assert(not invoke('Build','SortingDesk'))
assert(not invoke('Hire','Sorter'))
assert(not invoke('BuyAd',1))

-- Website creation is proximity checked and requires the full 15-second delay.
r.Position=Vector3.new(-200,3,-200)
assert(not invoke('StartWebsite'))
travel('CompanyComputer')
assert(invoke('StartWebsite'))
assert(not invoke('StartWebsite'))
runDelayed(14)
assert(state().stage=='CreateWebsite' and state().websiteProgress<1)
runDelayed(1)
assert(state().stage=='BuildDesk' and state().websiteReady)

-- Build, hire and ads must occur in tutorial order.
assert(invoke('Build','SortingDesk'))
assert(state().stage=='HireWorker' and state().cash==400)
assert(plot.SortingDeskBuild.VisiblePart.Transparency==0)
assert(not invoke('Build','SortingDesk'))
assert(not invoke('Hire','Packer'))
assert(invoke('Hire','Sorter'))
assert(state().stage=='BuyAds' and state().cash==325 and state().workers.Sorter==1)
assert(plot:FindFirstChild('SorterWorker1',true))
r.Position=Vector3.new(-200,3,-200)
assert(not invoke('BuyAd',1))
travel('CompanyComputer')
assert(invoke('BuyAd',1))
assert(state().stage=='RunBusiness' and state().cash==225 and state().dayRunning and state().adLevel==1)
assert(not invoke('BuyAd',3))
assert(not invoke('StartDay'))

-- Twenty three-second sale cycles complete a 60-second day.
local salesJob=jobs[1]
for _=1,20 do
 now=now+3
 local ok,errorMessage=coroutine.resume(salesJob)
 assert(ok,errorMessage)
 runDelayed(0)
end
local dayTwo=state()
assert(dayTwo.day==2 and not dayTwo.dayRunning)
assert(dayTwo.totalRevenue==480 and dayTwo.cash==687)
local sawDayComplete=false
for _,event in ipairs(services.ReplicatedStorage.ClothingCompanyV4.Changed.calls) do
 if event[2]=='DayComplete' and event[3].day==1 and event[3].revenue==480 and event[3].wages==18 then sawDayComplete=true end
end
assert(sawDayComplete)

-- Expansion unlocks roles and changes the economy.
assert(invoke('Build','PackingStation'))
assert(state().cash==337 and plot.PackingStationBuild.VisiblePart.Transparency==0)
assert(invoke('Hire','Packer'))
assert(state().cash==87 and state().workers.Packer==1 and state().wages==63)
assert(invoke('StartDay'))
for _=1,20 do
 now=now+3
 local ok,errorMessage=coroutine.resume(salesJob)
 assert(ok,errorMessage)
 runDelayed(0)
end
assert(state().day==3 and state().cash>1000 and state().companyValue>state().cash)
assert(invoke('BuyAd',2))
assert(state().adLevel==2 and state().dayRunning)

-- Invalid keys and another player's prompts cannot mutate this company.
assert(not invoke('Build','Invalid'))
assert(not invoke('Hire','Invalid'))
local other,otherRoot=createPlayer(202)
assert(workspace.ClothingCompanyPlots['202'].CompanySpawn.Position.X==712)
plot.CompanyComputer:FindFirstChildOfClass('ProximityPrompt').Triggered:Fire(other)
local ok,otherState=remote.OnServerInvoke(other,'GetState')
assert(ok and otherState.stage=='CreateWebsite' and otherState.cash==500)
players.PlayerRemoving:Fire(other)
assert(not workspace.ClothingCompanyPlots:FindFirstChild('202'))
print('PASS clothing-company server harness: username company, 15-second website, build/hire/ad tutorial, sales, wages, day completion, expansion, validation, plot isolation and cleanup')
