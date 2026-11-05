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
CFrame={lookAt=function(pos,focus) return {Position=pos} end}
Enum={KeyCode={E=1}}
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
local template=new('Model','AIBotSet',workspace)
for name,pos in pairs({Arrival={0,3,1},Entrance={0,2,17},LaptopSpot={0,4,43.8},HomeSeat={-81,2.8,30},DeskPad={-13,3,29},ServerPad={13,3,29},StudioPad={-15,3,47},ResearchCafe={8,4.8,-84},ResearchTech={-44,4.3,-71},ResearchPark={115,2.2,7}}) do
 local p=new('Part',name,template);p.Position=Vector3.new(table.unpack(pos))
 if name:find('Pad') then local g=new('SurfaceGui','Print',p);new('TextLabel','Lettering',g) end
end
for _,name in ipairs({'Laptop','WorkspaceUpgrade','ServerUpgrade','StudioUpgrade','ResearchCafeNotebook','ResearchTechNotebook','ResearchParkNotebook'}) do
 local g=new('Model',name,template);new('Part','VisiblePart',g);new('PointLight','Light',g)
end
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
local remote=services.ReplicatedStorage.AIBotV3.Action
local function invoke(action,arg)
 now=now+.2
 return remote.OnServerInvoke(p,action,arg)
end
local function state() local ok,s=invoke('GetState');assert(ok);return s end
local function travel(name)
 r.Position=workspace.AIBotPlots[tostring(p.UserId)]:FindFirstChild(name,true).Position
end
assert(state().stage=='Intro' and state().cash==25)
assert(not invoke('BuyCourse'))
assert(not invoke('Train'))
assert(invoke('FinishIntro'))
assert(state().stage=='Enter' and not r.Anchored)
assert(not invoke('FinishIntro'))
travel('Entrance');services.RunService.Heartbeat:Fire(.21)
assert(state().stage=='Place')
travel('LaptopSpot')
local plot=workspace.AIBotPlots['101']
plot.LaptopSpot:FindFirstChildOfClass('ProximityPrompt').Triggered:Fire(p)
assert(state().stage=='Course' and plot.Laptop.VisiblePart.Transparency==0)
assert(invoke('BuyCourse'));assert(state().cash==15 and state().stage=='Play')
assert(not invoke('BuyCourse'))
r.Position=Vector3.new(-100,3,-100);assert(not invoke('Train'))
travel('LaptopSpot');assert(invoke('Train'));assert(state().cash==5 and state().training)
assert(not invoke('Train'))
now=now+3
for _,job in ipairs(delayed) do if job.at<=now then job.fn() end end
delayed={}
assert(state().level==1 and state().income==3 and not state().training)
assert(not invoke('Train'))
local incomeJob=jobs[1]
local function ticks(n) for _=1,n do local ok,e=coroutine.resume(incomeJob);assert(ok,e) end end
ticks(5);assert(state().cash==20)
travel('DeskPad');assert(not invoke('Upgrade','Desk'))
ticks(20);assert(state().cash==80)
assert(invoke('Upgrade','Desk'));assert(state().cash==5 and state().cap==7)
assert(plot.WorkspaceUpgrade.VisiblePart.Transparency==0)
assert(not invoke('Upgrade','Desk'))
assert(not invoke('Upgrade','Invalid'))
ticks(110)
travel('ServerPad');assert(invoke('Upgrade','Server'));assert(state().cap==13)
travel('StudioPad');assert(invoke('Upgrade','Studio'));assert(state().income==11)
-- Research is proximity-checked, grants one reward per notebook and has visible feedback.
local beforeNotes=state().cash
plot.ResearchCafe:FindFirstChildOfClass('ProximityPrompt').Triggered:Fire(p)
assert(state().cash==beforeNotes)
for _,name in ipairs({'ResearchCafe','ResearchTech','ResearchPark'}) do
 travel(name)
 local pr=plot[name]:FindFirstChildOfClass('ProximityPrompt')
 pr.Triggered:Fire(p)
 local collected=state().cash
 pr.Triggered:Fire(p)
 assert(state().cash==collected and not pr.Enabled)
 assert(plot[name..'Notebook'].VisiblePart.Transparency==1)
end
assert(state().research==3 and state().cash==beforeNotes+105)
-- Another player's plot/prompt cannot advance or spend this player's state.
local other,otherRoot=createPlayer(202)
assert(workspace.AIBotPlots['202'].Arrival.Position.X==720)
plot.LaptopSpot:FindFirstChildOfClass('ProximityPrompt').Triggered:Fire(other)
local ok,otherState=remote.OnServerInvoke(other,'GetState');assert(ok and otherState.stage=='Intro')
players.PlayerRemoving:Fire(other);assert(not workspace.AIBotPlots:FindFirstChild('202'))
print('PASS server harness: story/tutorial, visibility, course, training, cash/income, distance, duplicate purchases, all upgrades, plot isolation and cleanup')
