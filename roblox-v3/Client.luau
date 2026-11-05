-- Readable HUD, interruptible story, guided movement, laptop simulation.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local PathfindingService=game:GetService('PathfindingService')
local player=Players.LocalPlayer
local network=RS:WaitForChild('AIBotV3')
local action=network:WaitForChild('Action')
local changed=network:WaitForChild('Changed')
local controls=require(player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule')):GetControls()
local C={bg=Color3.fromRGB(19,35,43),panel=Color3.fromRGB(28,47,55),line=Color3.fromRGB(57,78,83),cream=Color3.fromRGB(244,235,214),muted=Color3.fromRGB(170,191,190),mint=Color3.fromRGB(157,222,198),gold=Color3.fromRGB(239,196,117)}
local state,plot
local cinematic=false
local inLaptop=false
local modal=nil
local upgradeInfo=nil
local waypoint=nil
local waypointTitle=nil
local routeNodes={}
local routeIndex=1
local routeBusy=false
local routeTime=-10
local routeDestination=nil
local introStarted=false
local courseSeen=false
local skipRequested=false
local nextRequested=false
local activeTween=nil
local trainingStart=0
local lastStage=nil
local busy=false

local gui=Instance.new('ScreenGui')
gui.Name='AIBotV3UI';gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.DisplayOrder=10;gui.Parent=player:WaitForChild('PlayerGui')
local function corners(o,r) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r or 12);c.Parent=o end
local function border(o) local s=Instance.new('UIStroke');s.Color=C.line;s.Thickness=1;s.Parent=o end
local function frame(parent,name,size,pos,color)
 local f=Instance.new('Frame');f.Name=name;f.Size=size;f.Position=pos;f.BackgroundColor3=color or C.bg;f.BorderSizePixel=0;f.Parent=parent;corners(f);return f
end
local function text(parent,name,content,size,pos,fontSize,color,bold)
 local t=Instance.new('TextLabel');t.Name=name;t.Size=size;t.Position=pos;t.BackgroundTransparency=1;t.Text=content;t.TextColor3=color or C.cream;t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;t.TextSize=fontSize or 16;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;return t
end
local function button(parent,name,content,size,pos,secondary)
 local b=Instance.new('TextButton');b.Name=name;b.Size=size;b.Position=pos;b.BackgroundColor3=secondary and C.panel or C.mint;b.TextColor3=secondary and C.cream or C.bg;b.BorderSizePixel=0;b.Text=content;b.Font=Enum.Font.GothamBold;b.TextSize=16;b.TextWrapped=true;b.AutoButtonColor=true;b.Parent=parent;corners(b,9)
 if secondary then border(b) end
 return b
end
local function tween(o,duration,props)
 local t=TweenService:Create(o,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props);t:Play();return t
end
local function clampText(t,maxSize)
 t.TextScaled=true
 local c=Instance.new('UITextSizeConstraint');c.MinTextSize=11;c.MaxTextSize=maxSize;c.Parent=t
end

local hud=frame(gui,'Objective',UDim2.fromOffset(340,108),UDim2.fromOffset(20,20));border(hud)
text(hud,'Eyebrow','NOVA / BOT WORKS',UDim2.new(1,-32,0,18),UDim2.fromOffset(16,10),11,C.mint,true)
local goal=text(hud,'Goal','Loading your workshop...',UDim2.new(1,-32,0,34),UDim2.fromOffset(16,30),21,C.cream,true)
local subgoal=text(hud,'Hint','',UDim2.new(1,-32,0,33),UDim2.fromOffset(16,66),13,C.muted)
local wallet=frame(gui,'Wallet',UDim2.fromOffset(190,78),UDim2.new(1,-210,0,20));border(wallet)
local cashLabel=text(wallet,'Cash','$25',UDim2.new(1,-28,0,33),UDim2.fromOffset(14,8),27,C.cream,true)
local incomeLabel=text(wallet,'Income','Pocket money',UDim2.new(1,-28,0,22),UDim2.fromOffset(14,45),12,C.mint)
local incomeToast=text(gui,'IncomeToast','',UDim2.fromOffset(180,32),UDim2.new(1,-200,0,102),21,C.mint,true)
local toastPanel=frame(gui,'Notification',UDim2.new(.8,0,0,56),UDim2.new(.1,0,1,-76));toastPanel.Visible=false;border(toastPanel)
local toastText=text(toastPanel,'Text','',UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6),15,C.cream)
local toastSerial=0
local function toast(message)
 toastSerial=toastSerial+1;local id=toastSerial
 toastText.Text=message;toastPanel.Visible=true
 task.delay(4,function() if toastSerial==id then toastPanel.Visible=false end end)
end
local function call(name,arg)
 local ok,success,result=pcall(function() return action:InvokeServer(name,arg) end)
 if not ok then toast('Connection interrupted. Please try again.');return false end
 if not success then toast(result or 'Not available yet.') end
 return success,result
end

-- Cutscene UI stays low and does not cover the action.
local story=frame(gui,'Story',UDim2.new(.88,0,0,154),UDim2.new(.06,0,1,-176));border(story);story.Visible=false
local who=text(story,'Speaker','YOU',UDim2.new(1,-160,0,22),UDim2.fromOffset(22,16),12,C.mint,true)
local words=text(story,'Dialogue','',UDim2.new(1,-48,0,70),UDim2.fromOffset(24,43),24,C.cream,true);clampText(words,24)
local nextButton=button(story,'Next','Next  →',UDim2.fromOffset(105,30),UDim2.new(1,-123,1,-39),true)
text(story,'Hint','Space / Enter to continue',UDim2.new(1,-150,0,20),UDim2.new(0,24,1,-32),11,C.muted)
local skipButton=button(gui,'Skip','Skip story  ↗',UDim2.fromOffset(142,36),UDim2.new(1,-164,0,24),true);skipButton.Visible=false
nextButton.Activated:Connect(function() nextRequested=true end)
skipButton.Activated:Connect(function() skipRequested=true;if activeTween then activeTween:Cancel() end end)

local shade=frame(gui,'LaptopShade',UDim2.fromScale(1,1),UDim2.new());shade.BackgroundColor3=Color3.fromRGB(7,18,23);shade.BackgroundTransparency=.3;shade.Visible=false
local window=frame(shade,'Laptop',UDim2.fromScale(.88,.78),UDim2.fromScale(.5,.54));window.AnchorPoint=Vector2.new(.5,.5);border(window)
local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(850,590);limit.Parent=window
local bar=frame(window,'Titlebar',UDim2.new(1,0,0,56),UDim2.new(),C.panel)
text(bar,'Brand','NOVA  /  personal AI studio',UDim2.new(1,-100,1,0),UDim2.fromOffset(22,0),14,C.mint,true)
local close=button(bar,'Close','×',UDim2.fromOffset(36,32),UDim2.new(1,-48,0,12),true)
local scroll=Instance.new('ScrollingFrame');scroll.Name='Content';scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.Position=UDim2.fromOffset(22,70);scroll.Size=UDim2.new(1,-44,1,-90);scroll.ScrollBarThickness=4;scroll.ScrollBarImageColor3=C.mint;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=window
local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,13);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local order=0
local function item(height)
 order=order+1
 local f=frame(scroll,'Section'..order,UDim2.new(1,-6,0,height),UDim2.new(),C.bg);f.BackgroundTransparency=1;f.LayoutOrder=order;return f
end
local headingRow=item(62)
local heading=text(headingRow,'Title','Build something remarkable.',UDim2.new(1,0,0,34),UDim2.new(),28,C.cream,true);clampText(heading,28)
local description=text(headingRow,'Description','Your first bot starts with one small investment.',UDim2.new(1,0,0,25),UDim2.fromOffset(0,37),14,C.muted)
local statsRow=item(83)
local statValues={}
for i,name in ipairs({'BOT LEVEL','EARNINGS / 4 SEC','AVAILABLE CASH'}) do
 local card=frame(statsRow,name,UDim2.new(1/3,-8,1,0),UDim2.new((i-1)/3,0,0,0),C.panel)
 local label=text(card,'Name',name,UDim2.new(1,-20,0,23),UDim2.fromOffset(10,9),10,C.muted,true);clampText(label,10)
 local value=text(card,'Value','—',UDim2.new(1,-20,0,34),UDim2.fromOffset(10,35),25,C.cream,true);clampText(value,25);statValues[i]=value
end
local terminal=item(108);terminal.BackgroundTransparency=0;terminal.BackgroundColor3=Color3.fromRGB(14,29,35);border(terminal)
text(terminal,'Tag','TERMINAL / LOCAL DEVELOPMENT',UDim2.new(1,-28,0,20),UDim2.fromOffset(14,8),10,C.mint,true)
local terminalText=text(terminal,'Output','> waiting for your first training run...',UDim2.new(1,-28,1,-40),UDim2.fromOffset(14,33),14,C.muted)
terminalText.Font=Enum.Font.Code;terminalText.TextYAlignment=Enum.TextYAlignment.Top
local trainRow=item(48)
local train=button(trainRow,'Train','Invest $10 · train bot',UDim2.fromScale(1,1),UDim2.new())
local progressRow=item(7)
progressRow.BackgroundTransparency=0;progressRow.BackgroundColor3=C.panel
local fill=frame(progressRow,'Progress',UDim2.fromScale(0,1),UDim2.new(),C.mint);corners(fill,3)
local footer=item(48)
local footerText=text(footer,'Help','',UDim2.fromScale(1,1),UDim2.new(),13,C.muted)
local leaveRow=item(42)
local leave=button(leaveRow,'Leave','Leave laptop · explore your warehouse',UDim2.fromScale(1,1),UDim2.new(),true)

local mapButton=button(gui,'DistrictMap','Neighborhood map · M',UDim2.fromOffset(190,32),UDim2.new(1,-210,0,102),true)
local mapRow=item(285)
mapRow.Visible=false
mapRow.BackgroundTransparency=0
mapRow.BackgroundColor3=Color3.fromRGB(57,76,67)
local horizontal=frame(mapRow,'FoundryStreet',UDim2.new(1,0,.055,0),UDim2.fromScale(0,.35),Color3.fromRGB(116,129,115))
local vertical=frame(mapRow,'InnovationAve',UDim2.new(.045,0,1,0),UDim2.fromScale(.66,0),Color3.fromRGB(116,129,115))
local districts={
 {'HOME','MapHome',.20,.48},
 {'WAREHOUSE','MapWarehouse',.42,.49},
 {'BYTE & BREW','MapCafe',.44,.16},
 {'COMPUTER STORE','MapTech',.20,.16},
 {'SIGNAL PARK','MapPark',.76,.49},
 {'FOUNDRY YARD','MapYard',.42,.80},
}
local mapChoices={}
for _,district in ipairs(districts) do
 local b=button(mapRow,district[2],district[1],UDim2.fromScale(.19,.15),UDim2.fromScale(district[3],district[4]),true)
 b.AnchorPoint=Vector2.new(.5,.5)
 clampText(b,13)
 table.insert(mapChoices,{button=b,key=district[2],title=district[1]})
end

local function movement()
 if cinematic or inLaptop or modal then controls:Disable() else controls:Enable() end
end
local function closeWindows()
 inLaptop=false;modal=nil;shade.Visible=false;upgradeInfo=nil;mapButton.Visible=not cinematic;movement()
end
close.Activated:Connect(closeWindows);leave.Activated:Connect(closeWindows)
local refresh
local function openLaptop()
 if cinematic then return end
 inLaptop=true;modal='Laptop';upgradeInfo=nil;shade.Visible=true;movement();refresh()
end

-- A private world-space guide. No giant arrows covering your character.
local guide=Instance.new('Part');guide.Name='YourObjective';guide.Anchored=true;guide.CanCollide=false;guide.CanQuery=false;guide.CanTouch=false;guide.Shape=Enum.PartType.Cylinder;guide.Size=Vector3.new(.06,4.5,4.5);guide.Material=Enum.Material.Neon;guide.Color=C.mint;guide.Transparency=.35;guide.Parent=workspace
local marker=Instance.new('BillboardGui');marker.Size=UDim2.fromOffset(150,64);marker.StudsOffset=Vector3.new(0,4,0);marker.AlwaysOnTop=true;marker.Adornee=guide;marker.ResetOnSpawn=false;marker.Parent=player:WaitForChild('PlayerGui')
local markerText=text(marker,'Goal','↓  THIS WAY',UDim2.fromScale(1,1),UDim2.new(),19,C.cream,true);markerText.TextXAlignment=Enum.TextXAlignment.Center
local startAttachment=Instance.new('Attachment');startAttachment.Name='GuideStart'
local endAttachment=Instance.new('Attachment');endAttachment.Parent=guide
local trail=Instance.new('Beam');trail.Name='ObjectivePath';trail.Attachment0=startAttachment;trail.Attachment1=endAttachment;trail.Color=ColorSequence.new(C.mint);trail.Width0=.13;trail.Width1=.13;trail.FaceCamera=true;trail.LightEmission=.65;trail.Transparency=NumberSequence.new(.3);trail.Parent=guide
local target=nil
local function find(name) return plot and plot:FindFirstChild(name,true) end
local function chooseTarget()
 if not state or cinematic or shade.Visible then return nil end
 if state.stage=='Enter' then return find('Entrance') end
 if state.stage=='Place' or state.stage=='Course' or (state.stage=='Play' and state.level==0) then return find('LaptopSpot') end
 if state.stage=='Play' and state.level>0 and waypoint then return find(waypoint) end
 if state.stage=='Play' and state.level>=state.cap then return find(state.owned.Desk and 'ServerPad' or 'DeskPad') end
 return nil
end

refresh=function()
 if not state then return end
 hud.Visible=not cinematic;wallet.Visible=not cinematic;mapButton.Visible=not cinematic and not shade.Visible
 cashLabel.Text='$'..state.cash
 incomeLabel.Text=state.level>0 and ('+$'..state.income..' every 4 seconds') or '$25 emergency pocket money'
 local goals={
  Intro={'Your story begins',''},
  Enter={'01 / Your fresh start','Walk through the open warehouse doorway.'},
  Place={'02 / Set up your laptop','Follow the path. Use E at the workbench.'},
  Course={'03 / Learn the basics','Open your laptop. Buy the $10 course.'},
  Play={state.level==0 and '04 / Build your first bot' or 'Your AI business is live',state.level==0 and 'Open the laptop and invest $10.' or 'Earn cash. Train your bot. Upgrade the warehouse.'},
 }
 local g=goals[state.stage];goal.Text=g and g[1] or '';subgoal.Text=g and g[2] or ''
 if state.stage=='Play' and waypoint then goal.Text='Explore / '..waypointTitle;subgoal.Text='Follow the mint path. Find research notes for bonus cash.' end
 if shade.Visible then
  trainRow.Visible=true;footer.Visible=true;mapRow.Visible=false
  if modal=='Map' then
   heading.Text='Your neighborhood.';description.Text='Choose a district to set a walking waypoint.'
   statsRow.Visible=false;terminal.Visible=false;trainRow.Visible=false;progressRow.Visible=false;mapRow.Visible=true
   footerText.Text='Explore the shops and park. Three research notebooks grant $35 each. Collected: '..(state.research or 0)..' / 3'
   leave.Text='Back to the streets'
  elseif modal=='Upgrade' and upgradeInfo then
   heading.Text=upgradeInfo.title;description.Text='WAREHOUSE EXPANSION / one-time purchase'
   statsRow.Visible=false;terminal.Visible=true;terminalText.Text='> '..upgradeInfo.description..'\n> Installs a visible upgrade in your warehouse.'
   train.Text=state.owned[upgradeInfo.key] and 'Already installed' or 'Install upgrade · $'..upgradeInfo.price
   footerText.Text='Your balance: $'..state.cash..'   ·   Uses in-game cash only.'
   leave.Text='Back to warehouse';progressRow.Visible=false
  else
   local course=state.stage=='Course'
   heading.Text=course and 'Your second chance starts here.' or 'A small bot. A bigger future.'
   description.Text=course and 'FOUNDATIONS / How to build your first AI bot' or 'Train your bot and turn better answers into income.'
   statsRow.Visible=not course;terminal.Visible=true
   statValues[1].Text=state.level..' / '..state.cap
   statValues[2].Text='$'..state.income
   statValues[3].Text='$'..state.cash
   if course then
    terminalText.Text='LESSON 01  Start small. Learn the basics.\nLESSON 02  Train better answers. Earn your first customers.\nLESSON 03  Upgrade your workspace to grow.'
    train.Text='Buy beginner course · $10'
    footerText.Text='One-time purchase with in-game cash. No Robux. No real payment.'
   else
    train.Text=state.training and 'Training in progress...' or (state.level>=state.cap and 'Capacity full · upgrade your warehouse' or ('Invest $'..state.cost..' · train bot'))
    if not state.training then terminalText.Text=state.level==0 and '> model initialized\n> no training data yet\n> ready for your first investment' or ('> training runs complete: '..state.level..'\n> model deployed · earning $'..state.income..' / 4 sec\n> status: online') end
    footerText.Text=state.level>=state.cap and 'You have outgrown this setup. Leave the laptop and inspect a warehouse upgrade.' or 'Each investment adds one bot level. Earnings arrive automatically every 4 seconds.'
   end
   leave.Text='Leave laptop · explore your warehouse'
   progressRow.Visible=not course
  end
 end
 target=chooseTarget()
end

local function openMap()
 if cinematic then return end
 if not state or state.stage~='Play' or state.level==0 then toast('Launch your first bot, then explore the neighborhood.');return end
 if modal=='Map' then closeWindows();refresh();return end
 closeWindows();modal='Map';shade.Visible=true;movement();refresh()
end
mapButton.Activated:Connect(openMap)
for _,choice in ipairs(mapChoices) do
 choice.button.Activated:Connect(function()
  waypoint=choice.key;waypointTitle=choice.title;routeNodes={};routeIndex=1;routeTime=-10;routeDestination=nil
  closeWindows();refresh();toast('Walking waypoint set: '..choice.title)
 end)
end

train.Activated:Connect(function()
 if busy or not state or state.training then return end
 busy=true
 if modal=='Upgrade' and upgradeInfo then
  local success=call('Upgrade',upgradeInfo.key)
  if success then closeWindows() end
 elseif state.stage=='Course' then
  if call('BuyCourse') then toast('Course complete. Invest $10 to launch your first bot!') end
 else
  call('Train')
 end
 busy=false;refresh()
end)

local function returnCamera()
 local camera=workspace.CurrentCamera
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local root=character and character:FindFirstChild('HumanoidRootPart')
 camera.CameraType=Enum.CameraType.Custom
 if humanoid then camera.CameraSubject=humanoid end
 if root then camera.CFrame=CFrame.lookAt(root.Position-root.CFrame.LookVector*11+Vector3.new(0,6,0),root.Position+Vector3.new(0,2,0)) end
 player.CameraMinZoomDistance=6;player.CameraMaxZoomDistance=25
end
local function waitBeat(seconds)
 nextRequested=false
 local start=os.clock()
 while os.clock()-start<seconds do
  if skipRequested or nextRequested then break end
  task.wait(.04)
 end
end
local function say(speaker,content,seconds)
 if skipRequested then return end
 who.Text=speaker;words.Text=content;waitBeat(seconds or 3)
end
local function shot(position,focus,seconds)
 if skipRequested then return end
 local camera=workspace.CurrentCamera
 activeTween=tween(camera,seconds or .8,{CFrame=CFrame.lookAt(position,focus)})
 local start=os.clock()
 while os.clock()-start<(seconds or .8) and not skipRequested do task.wait(.03) end
 if skipRequested and activeTween then activeTween:Cancel() end
 activeTween=nil
end
local function startStory()
 cinematic=true;closeWindows();movement();story.Visible=true;skipButton.Visible=true;skipRequested=false;refresh()
 workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
end
local function endStory()
 cinematic=false;story.Visible=false;skipButton.Visible=false
 if activeTween then activeTween:Cancel();activeTween=nil end
 returnCamera();movement();refresh()
end
local function animateModel(model,finish,duration)
 if skipRequested then return end
 local value=Instance.new('CFrameValue');value.Value=model:GetPivot()
 local connection=value.Changed:Connect(function(cf) if model.Parent then model:PivotTo(cf) end end)
 local t=tween(value,duration,{Value=finish})
 local start=os.clock()
 while os.clock()-start<duration and not skipRequested do task.wait(.03) end
 t:Cancel();connection:Disconnect();value:Destroy()
end
local function opening()
 if introStarted then return end
 introStarted=true
 startStory()
 local ok,err=pcall(function()
  local focus=find('HomeFocus').Position
  workspace.CurrentCamera.CFrame=CFrame.lookAt(find('HomeCamera').Position,focus)
  say('YOU / THE BIG IDEA','I wish I had my own AI bot like ChatGPT or Claude.',3.8)
  shot(focus+Vector3.new(-3,2,-6),focus,.7)
  say('YOU','I will invest everything. This is going to be huge.',3)
  say('PC / DEPLOYMENT FAILED','Launch failed. All your savings are gone.',2.8)
  local mom=find('Mom')
  local initial=mom:GetPivot()
  animateModel(mom,initial+Vector3.new(-4,0,2),.8)
  local momHead=mom:FindFirstChild('Head').Position
  shot(momHead+Vector3.new(-2,1,-6),momHead,.6)
  say('MOM','WHY IS HALF OF MY MONEY GONE?',3.2)
  shot(focus+Vector3.new(1,1,-8),focus,.5)
  if not skipRequested then
   who.Text='YOU';words.Text='I... can explain?'
   local camera=workspace.CurrentCamera;local base=camera.CFrame
   local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart');local rootCF=root and root.CFrame
   local begin=os.clock()
   while os.clock()-begin<1.4 and not skipRequested do
    camera.CFrame=base*CFrame.Angles(0,0,math.sin(os.clock()*32)*.005)
    if root then root.CFrame=rootCF*CFrame.Angles(0,0,math.sin(os.clock()*40)*.03) end
    RunService.RenderStepped:Wait()
   end
   camera.CFrame=base;if root then root.CFrame=rootCF end
  end
  shot(momHead+Vector3.new(1,1,-6),momHead,.5)
  say('MOM','GET OUT OF MY HOUSE NOW!!',2.8)
  say('YOU','Fine! I am taking my laptop.',2)
  local taxi=find('Taxi')
  local carPos=taxi:GetPivot().Position
  shot(carPos+Vector3.new(13,7,-12),carPos+Vector3.new(0,1,0),.8)
  say('YOU / CALLING A TAXI','One ride. One laptop. One last chance.',2.5)
  animateModel(taxi,taxi:GetPivot()+Vector3.new(28,0,0),1.4)
  local entrance=find('Entrance').Position
  shot(entrance+Vector3.new(27,14,-27),entrance+Vector3.new(0,5,17),1)
  say('YOU','A free warehouse on Facebook Marketplace. It is not much... but it is mine.',3.5)
 end)
 if not ok then warn('AI Bot intro:',err) end
 local finished=false
 for _=1,4 do
  finished=call('FinishIntro')
  if finished then break end
  task.wait(.25)
 end
 endStory()
 if finished then toast('You are in control. Follow the mint path into the warehouse.') end
end
local function courseStory()
 if courseSeen or cinematic then return end
 courseSeen=true
 startStory()
 local ok,err=pcall(function()
  local spot=find('LaptopSpot').Position
  shot(spot+Vector3.new(4.5,4,-5.5),spot+Vector3.new(0,.6,1),.8)
  say('YOU','This time, I am going to learn before I spend everything.',2.6)
  say('LAPTOP / SEARCH RESULTS','How to build your first AI bot. Beginner course: $10.',2.8)
 end)
 if not ok then warn('AI Bot course:',err) end
 endStory();openLaptop()
end
local function receive(data)
 local wasTraining=state and state.training
 state=data
 plot=workspace:WaitForChild('AIBotPlots'):WaitForChild(state.plot)
 if state.training and not wasTraining then trainingStart=os.clock();fill.Size=UDim2.fromScale(0,1) end
 refresh()
 if state.stage=='Intro' then task.spawn(opening)
 elseif state.stage=='Course' and lastStage~='Course' and not courseSeen then task.spawn(courseStory) end
 lastStage=state.stage
end
changed.OnClientEvent:Connect(function(kind,data)
 if kind=='State' then receive(data)
 elseif kind=='Toast' then toast(data)
 elseif kind=='Laptop' then openLaptop()
 elseif kind=='Upgrade' then
  if cinematic then return end
  upgradeInfo=data;modal='Upgrade';inLaptop=false;shade.Visible=true;movement();refresh()
 elseif kind=='Trained' then
  fill.Size=UDim2.fromScale(1,1)
  toast('Bot level '..data..' deployed. Your AI is now earning more!')
 elseif kind=='Income' then
  incomeToast.Text='+$'..data;incomeToast.TextTransparency=0
  tween(incomeToast,1.5,{TextTransparency=1})
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if cinematic then
  if input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.Return then nextRequested=true end
 elseif input.KeyCode==Enum.KeyCode.M then openMap()
 elseif shade.Visible and (input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.Escape) then
  closeWindows();refresh()
 end
end)
player.CharacterAdded:Connect(function()
 closeWindows()
 task.wait(.4)
 if not cinematic then returnCamera();movement() end
end)

local function planRoute(root,goalPart)
 if routeBusy or os.clock()-routeTime<3 then return end
 routeBusy=true;routeTime=os.clock()
 local destination=waypoint
 local from=root.Position;local to=goalPart.Position
 task.spawn(function()
  local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=7})
  local ok=pcall(function() path:ComputeAsync(from,to) end)
  if ok and path.Status==Enum.PathStatus.Success and waypoint==destination then
   routeNodes=path:GetWaypoints();routeIndex=2;routeDestination=destination
  end
  routeBusy=false
 end)
end
local renderTick=0
RunService.RenderStepped:Connect(function(dt)
 renderTick=renderTick+dt
 if state and state.training then
  local progress=math.clamp((os.clock()-trainingStart)/2.5,0,.98)
  fill.Size=UDim2.fromScale(progress,1)
  if modal=='Laptop' then terminalText.Text=string.format('> preparing training data... OK\n> optimizing responses... %d%%\n> deploying next bot level...',math.floor(progress*100)) end
 end
 if renderTick<.08 then return end
 renderTick=0;target=chooseTarget()
 local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local enabled=target~=nil and root~=nil
 marker.Enabled=enabled;trail.Enabled=enabled;guide.Transparency=enabled and .4 or 1
 if enabled then
  if waypoint and target.Name==waypoint and (root.Position-target.Position).Magnitude<9 then
   toast('Arrived: '..waypointTitle);waypoint=nil;waypointTitle=nil;task.defer(refresh)
  end
  local groundY=find('Entrance').Position.Y-1.4
  local guidePosition=target.Position
  if waypoint and target.Name==waypoint then
   planRoute(root,target)
   if routeDestination==waypoint and routeNodes[routeIndex] then
    local node=routeNodes[routeIndex]
    local flatDistance=(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(node.Position.X,0,node.Position.Z)).Magnitude
    if flatDistance<4 and routeIndex<#routeNodes then routeIndex=routeIndex+1 end
    guidePosition=routeNodes[routeIndex].Position
   end
  end
  local targetZ=guidePosition.Z-(target.Name=='LaptopSpot' and 7 or 0)
  guide.CFrame=CFrame.new(guidePosition.X,groundY,targetZ)*CFrame.Angles(0,0,math.pi/2)
  if startAttachment.Parent~=root then startAttachment.Parent=root;startAttachment.Position=Vector3.new(0,-2,0) end
  local distance=(root.Position-Vector3.new(guide.Position.X,root.Position.Y,guide.Position.Z)).Magnitude
  markerText.Text=distance<3 and target.Name=='LaptopSpot' and (UIS.TouchEnabled and 'TAP THE PROMPT' or 'E / USE LAPTOP') or string.format('↓  %d studs',math.floor(distance))
 end
end)
local function responsive()
 local size=workspace.CurrentCamera.ViewportSize
 local narrow=size.X<700
 hud.Size=UDim2.fromOffset(narrow and math.min(size.X-32,340) or 340,108)
 hud.Position=UDim2.fromOffset(16,narrow and 92 or 20)
 wallet.Size=UDim2.fromOffset(narrow and 164 or 190,68)
 wallet.Position=UDim2.new(1,narrow and -180 or -210,0,16)
 mapButton.Size=UDim2.fromOffset(narrow and 164 or 190,30)
 mapButton.Position=UDim2.new(1,narrow and -180 or -210,0,narrow and 209 or 102)
 incomeToast.Position=UDim2.new(1,narrow and -180 or -210,0,narrow and 247 or 140)
 goal.TextSize=narrow and 18 or 21
 story.Size=UDim2.new(.92,0,0,narrow and 172 or 154)
 story.Position=UDim2.new(.04,0,1,narrow and -190 or -176)
end
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(responsive)
responsive()
task.spawn(function()
 for _=1,30 do
  local ok,success,data=pcall(function() return action:InvokeServer('GetState') end)
  if ok and success then receive(data);return end
  task.wait(.3)
 end
 toast('Could not load your workshop. Stop and press Play again.')
end)
