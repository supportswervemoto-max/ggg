from pathlib import Path
import json, math, xml.etree.ElementTree as ET, zipfile
ROOT=Path(__file__).parent
OUT=Path('/workspace/artifacts'); OUT.mkdir(exist_ok=True)
nodes=[]
def obj(cls,name,parent=None,**props):
    i=len(nodes); nodes.append(dict(cls=cls,name=name,parent=parent,props=props)); return i
def model(name,parent=None): return obj('Model',name,parent)
def part(name,pos,size,color='#cccccc',material='SmoothPlastic',parent=None,rot=(0,0,0),shape='Block',collide=True,transparency=0):
    return obj('Part',name,parent,Position=list(pos),Size=list(size),Color=color,Material=material,Rotation=list(rot),Shape=shape,Anchored=True,CanCollide=collide,CanTouch=False,CanQuery=True,Transparency=transparency,TopSurface=0,BottomSurface=0,CastShadow=transparency<1)
def beam(a,b,width,color,parent,material='Metal',name='Beam'):
    d=[b[i]-a[i] for i in range(3)]; length=math.sqrt(sum(x*x for x in d)); mid=[(a[i]+b[i])/2 for i in range(3)]
    # Local Y follows the beam, Z chosen perpendicular.
    y=[v/length for v in d]; seed=[0,0,1] if abs(y[2])<.9 else [1,0,0]
    x=[y[1]*seed[2]-y[2]*seed[1],y[2]*seed[0]-y[0]*seed[2],y[0]*seed[1]-y[1]*seed[0]]; norm=math.sqrt(sum(v*v for v in x)); x=[v/norm for v in x]
    z=[x[1]*y[2]-x[2]*y[1],x[2]*y[0]-x[0]*y[2],x[0]*y[1]-x[1]*y[0]]
    i=part(name,mid,(width,length,width),color,material,parent); nodes[i]['props']['Matrix']=[x[0],y[0],z[0],x[1],y[1],z[1],x[2],y[2],z[2]]; return i
def sign(parent,name,pos,size,words,bg='#17242c',fg='#f5eee2',face=5,rot=(0,0,0)):
    p=part(name,pos,size,bg,'SmoothPlastic',parent,rot=rot)
    gui=obj('SurfaceGui','Print',p,Face=face,CanvasSize=[900,350],AlwaysOnTop=False,LightInfluence=0)
    obj('TextLabel','Lettering',gui,Size=[1,0,1,0],Position=[0,0,0,0],BackgroundTransparency=1,Text=words,TextColor3=fg,TextScaled=True,Font=46,TextWrapped=True)
    return p
def light(parent,name,color='#fff1ce',brightness=1.3,range_=20):
    obj('PointLight',name,parent,Color=color,Brightness=brightness,Range=range_,Shadows=False)
def plant(parent,x,z,y=0,scale=1):
    g=model('Plant',parent)
    part('Clay pot',(x,y+.6*scale,z),(1.2*scale,1.6*scale,1.6*scale),'#b87853','SmoothPlastic',g,shape='Cylinder',rot=(0,0,90))
    part('Soil',(x,y+1.23*scale,z),(1.2*scale,.1*scale,1.2*scale),'#413328','Ground',g)
    beam((x,y+1.2*scale,z),(x,y+3.8*scale,z),.14*scale,'#516d3f',g)
    for j in range(7):
        a=j*2.4; h=1.8+j*.32
        part('Leaf',(x+math.sin(a)*.65*scale,y+h*scale,z+math.cos(a)*.65*scale),(.6*scale,1.65*scale,.22*scale),'#66845b' if j%2 else '#809767','SmoothPlastic',g,rot=(20*math.cos(a),j*45,35*math.sin(a)),shape='Ball',collide=False)
    return g
def desk(parent,x,z,y=0,width=9,name='Workbench',color='#b68b62'):
    g=model(name,parent)
    part('Top',(x,y+3.1,z),(width,.42,4.6),color,'Wood',g)
    for dx in [-width/2+.6,width/2-.6]:
        for dz in [-1.6,1.6]: part('Leg',(x+dx,y+1.5,z+dz),(.35,3,.35),'#344048','Metal',g)
    part('Cable tray',(x,y+2.45,z+1.4),(width-1,.3,.5),'#344048','Metal',g)
    return g
def monitor(parent,x,z,y=3.32,name='Monitor',w=4):
    g=model(name,parent)
    part('Foot',(x,y+.06,z),(1.7,.12,1.1),'#28323a','Metal',g)
    part('Stem',(x,y+.8,z),(.25,1.5,.25),'#28323a','Metal',g)
    sign(g,'Screen',(x,y+2.1,z),(w,2.5,.22),'BOT / OS\n> build something remarkable','#172f3a','#93dfc9')
    part('Power LED',(x+w/2-.25,y+.95,z-.13),(.06,.06,.02),'#97e5bd','Neon',g,collide=False)
    return g
def chair(parent,x,z,y=0,rot=0,name='Chair'):
    g=model(name,parent)
    part('Seat',(x,y+1.8,z),(2.5,.5,2.5),'#465d5b','Fabric',g)
    part('Back',(x,y+3,z-1),(2.5,2.4,.4),'#465d5b','Fabric',g,rot=(-8,0,0))
    for dx in [-1.1,1.1]: part('Arm',(x+dx,y+2.4,z),(.18,.2,1.9),'#25363a','Metal',g)
    part('Support',(x,y+.85,z),(.3,1.4,.3),'#25363a','Metal',g)
    for a in [0,60,120]: part('Wheelbase',(x,y+.22,z),(2.8,.15,.18),'#25363a','Metal',g,rot=(0,a,0))
    return g

world=model('AIBotSet')
# Landscape and arrival court
part('Island',(0,-8,0),(640,16,600),'#7e9174','Grass',world)
part('Street',(-5,.06,-26),(210,.18,20),'#4e555a','Asphalt',world)
for x in range(-100,100,16): part('Road marking',(x,.17,-26),(8,.02,.2),'#ede2b6','SmoothPlastic',world)
part('Sidewalk',(0,.2,-12),(70,.4,7),'#bdc0b7','Concrete',world)
part('Court',(0,.15,2),(65,.3,25),'#aaa99c','Cobblestone',world)
for x in range(-28,30,4): part('Paving joint',(x,.32,2),(.025,.025,24),'#8d9087','Concrete',world,collide=False)
for x in [-29,29]:
    part('Planter',(x,1,9),(5,2,7),'#827d70','Concrete',world)
    plant(world,x,9,2,1.1)
    p=part('Path light',(x,2.7,-5),(.4,5.4,.4),'#29373b','Metal',world)
    cap=part('Light',(x,5.5,-5),(1,.5,1),'#fbe4b6','Neon',world); light(cap,'Warm pool',range_=18)
# Warehouse open front; roof deliberately partial for daylight/camera.
w=model('Warehouse',world)
part('Slab',(0,.25,40),(48,.5,52),'#999e9c','Concrete',w)
for x in [-24,24]:
    part('Brick dado',(x,3,40),(1,6,52),'#8b7767','Brick',w)
    part('Upper wall',(x,12,40),(1,12,52),'#b7b9ad','Concrete',w)
    for z in range(16,67,8): part('Wall rib',(x- (.55 if x>0 else -.55),11,z),(.22,14,.28),'#8d9a96','Metal',w)
    # Low side windows with dark framing.
    for z in [26,42,58]:
        sign(w,'Industrial window',(x-.58*(1 if x>0 else -1),11,z),(.12,5,9),'','#8cbbc2',face=0 if x<0 else 3)
        for dz in [-4.5,0,4.5]: part('Window mullion',(x-.7*(1 if x>0 else -1),11,z+dz),(.18,5,.16),'#405b61','Metal',w)
        part('Window rail',(x-.7*(1 if x>0 else -1),11,z),(.18,.14,9),'#405b61','Metal',w)
part('Back wall',(0,9,66),(48,18,1),'#b2b4a8','Concrete',w)
part('Back brick',(0,3,65.4),(47,6,.15),'#8b7767','Brick',w)
for x in [-23,23]:
    part('Entrance pier',(x,9,14),(2,18,2),'#384a4e','Metal',w)
for x in [-19,19]: part('Front wing',(x,7,14),(8,14,1),'#8b7767','Brick',w)
part('Front header',(0,16,14),(48,4,1),'#384a4e','Metal',w)
sign(w,'Warehouse identity',(0,16.1,13.3),(28,2.6,.18),'N O V A  /  B O T   W O R K S','#253b40','#f6ead1')
sign(w,'Unit plate',(-13,6,13.3),(3,1.5,.1),'UNIT 01','#ddd8c7','#344f50')
part('Roller shutter',(0,17.1,14),(29,1.1,1.3),'#798f8d','Metal',w,shape='Cylinder',rot=(0,0,0))
for z in [18,40,63]:
    beam((-23,17,z),(23,17,z),.45,'#405557',w)
    beam((-23,17,z),(0,20,z),.3,'#405557',w)
    beam((0,20,z),(23,17,z),.3,'#405557',w)
    for x in [-12,12]:
        beam((x,17,z),(x,15.2,z),.07,'#283c41',w)
        lamp=part('Pendant',(x,15,z),(4,.25,1.2),'#ffedcb','Neon',w); light(lamp,'Work light',brightness=1.7,range_=25)
# Rear canopy only, not camera-blocking full roof.
part('Rear roof',(0,20.2,61),(49,.45,11),'#536564','Metal',w)
# Work zone, paths, interior decoration
part('Workspace rug',(0,.56,43),(15,.08,12),'#6f8176','Fabric',w)
for x in [-6.8,6.8]: part('Rug border',(x,.61,43),(.08,.02,11),'#c7c2aa','Fabric',w,collide=False)
desk(w,0,44,width=10,name='StarterDesk')
chair(w,0,40)
# Laptop is hidden until placed by server.
laptop=model('Laptop',world)
part('Aluminum base',(0,3.42,43.8),(3.6,.18,2.5),'#bcc4c5','Metal',laptop)
part('Keyboard inset',(0,3.53,44.03),(3.1,.025,1.25),'#253239','SmoothPlastic',laptop)
for row in range(4):
    for col in range(10): part('Key',(-1.37+col*.3,3.55,43.57+row*.29),(.23,.025,.19),'#536168','SmoothPlastic',laptop,collide=False)
part('Trackpad',(0,3.54,43.05),(1.05,.02,.5),'#8f9ea1','Metal',laptop)
sign(laptop,'Display',(0,4.6,45),(3.6,2.25,.14),'NOVA\nYOUR NEXT BIG IDEA','#122d39','#a8e8d6',rot=(-10,0,0))
# Buyable upgrade geometry
up=model('WorkspaceUpgrade',world)
monitor(up,-3.5,45.2,w=3.8,name='LeftDisplay')
monitor(up,3.5,45.2,w=3.8,name='RightDisplay')
part('Desk strip',(0,3.18,41.7),(9.7,.08,.08),'#b0eadb','Neon',up,collide=False)
servergroup=model('ServerUpgrade',world)
for x in [15.5,20]:
    part('Cabinet',(x,4.5,58),(3.5,8,4),'#263a40','Metal',servergroup)
    for y in range(2,8):
        part('Server blade',(x,y,55.92),(3,.58,.2),'#4e6268','Metal',servergroup)
        for dx in [-1,-.6]: part('Status lamp',(x+dx,y,55.78),(.12,.12,.06),'#8fefcb','Neon',servergroup,collide=False)
        for dx in [.2,.5,.8,1.1]: part('Vent',(x+dx,y,55.78),(.08,.32,.03),'#17252a','SmoothPlastic',servergroup,collide=False)
    light(part('Rack glow',(x,.65,58),(3,.1,3),'#86d9cd','Neon',servergroup),'Rack light','#7edbcc',.4,10)
decor=model('StudioUpgrade',world)
part('Sofa base',(-15,1,52),(9,1.4,3.5),'#425e60','Fabric',decor)
part('Sofa back',(-15,2.6,53.7),(9,2,.65),'#425e60','Fabric',decor)
for x in [-19.3,-10.7]: part('Sofa arm',(x,2,52),(.6,2,3.7),'#425e60','Fabric',decor)
for x in [-17.7,-15,-12.3]: part('Cushion',(x,1.9,51.9),(2.5,.5,3),'#6c8681','Fabric',decor)
plant(decor,-20,57,0,1.2)
sign(decor,'Art',(-15,9,65.25),(11,5,.2),'SMALL START.\nBIG IDEAS.','#ddc4a1','#2d5657')
# Visible workshop props
plant(w,-20,20,0,1.1); plant(w,20,20,0,1.1)
for x in [-17,-13]:
    part('Packing crate',(x,1.3,60),(3,2.6,3),'#b49067','WoodPlanks',w)
    for dx in [-1.1,1.1]: part('Crate brace',(x+dx,1.3,58.45),(.2,2.5,.12),'#80674f','Wood',w)
# Tool pegboard
part('Pegboard',(-23.3,7,43),(.18,5,11),'#bca47c','Wood',w)
for z in range(39,48):
    for y in [5.5,6.5,7.5,8.5]: part('Peg',(-23.15,y,z),(.12,.08,.08),'#685e4e','Metal',w,collide=False)
for z in [40,42,45]:
    beam((-22.9,6,z),(-22.9,8,z),.18,'#46545b',w)
    part('Tool grip',(-22.9,6.3,z),(.3,.7,.3),'#ba7b48','SmoothPlastic',w)
# Goal/action markers (invisible)
for name,pos in [('Arrival',(0,3,1)),('Entrance',(0,2,17)),('LaptopSpot',(0,4,43.8)),('HomeSeat',(-81,2.8,30)),('HomeCamera',(-73,7,24)),('HomeFocus',(-81,4,33)),('MomDoor',(-68,3,25))]:
    part(name,pos,(1,1,1),parent=world,collide=False,transparency=1)
# Physical upgrade terminals
for name,x,z,cost,subtitle in [('DeskPad',-13,29,75,'DUAL DISPLAY / +CAPACITY'),('ServerPad',13,29,200,'SERVER RACK / +INCOME'),('StudioPad',-15,47,125,'STUDIO LOUNGE / +50%')]:
    g=model(name+'Model',w)
    part('Pedestal',(x,1.3,z),(2.2,2.6,1.4),'#344b50','Metal',g)
    pad=sign(g,name,(x,3,z),(3.4,1.8,.2),f'{subtitle}\n${cost}  /  INTERACT','#1b3540','#d8e9df')
    part('Accent',(x,2.05,z-.12),(3.2,.06,.06),'#9ad8c4','Neon',g,collide=False)
# Home detail
h=model('Home',world)
part('Foundation',(-80,.2,28),(29,.4,27),'#d3c9b7','Concrete',h)
for x in range(-94,-66,2): part('Oak floor',(x,.44,28),(1.96,.08,26),'#b08b62' if x%4 else '#bf9a70','Wood',h)
part('Rear wall',(-80,6.5,41.5),(29,13,.6),'#d8d6c6','Plaster',h)
part('Left wall',(-94.5,6.5,28),(.6,13,27),'#b3beb5','Plaster',h)
# Right wall is cut away for camera.
part('Right lower wall',(-65.5,1.4,28),(.6,2.8,27),'#d8d6c6','Plaster',h)
for pos,size in [((-80,1,41.1),(29,.25,.15)),((-94.1,1,28),(.15,.25,27))]: part('Skirting',pos,size,'#f4eedf','Wood',h)
part('Woven rug',(-80,.53,29),(15,.08,11),'#657b7b','Fabric',h)
for z in [24,34]: part('Rug hem',(-80,.58,z),(14,.02,.1),'#dfd4b6','Fabric',h,collide=False)
desk(h,-81,35,width=10,name='HomeDesk')
monitor(h,-81,36.2,w=5)
chair(h,-81,30)
part('Keyboard',(-81,3.4,34.1),(3,.1,.9),'#303c43','SmoothPlastic',h)
part('Mouse mat',(-78,3.35,34),(1.8,.04,1.8),'#4f6c70','Fabric',h)
part('Mouse',(-78,3.5,34),(.5,.3,.8),'#d0d5cc','SmoothPlastic',h,shape='Ball')
# Mug
part('Coffee',(-84,3.65,34),(.6,.65,.6),'#e1d1af','SmoothPlastic',h,shape='Cylinder',rot=(0,0,90))
# Bed
part('Bed frame',(-90,1,32),(6.5,1.4,11),'#6e5947','Wood',h)
part('Mattress',(-90,1.85,32),(6.2,.6,10.7),'#f4e8d2','Fabric',h)
part('Duvet',(-90,2.25,30.9),(6.3,.45,8),'#b97852','Fabric',h)
part('Duvet fold',(-90,2.52,34.2),(6.3,.16,1.4),'#d8a078','Fabric',h)
for x in [-91.5,-88.5]: part('Pillow',(x,2.4,36),(2.65,.6,1.7),'#eee1c8','Fabric',h,shape='Ball')
part('Headboard',(-90,2.5,37.7),(6.8,4,.5),'#806951','Wood',h)
# Bookshelf
part('Bookshelf back',(-69,4.1,39),(5.5,7.2,.4),'#866d50','Wood',h)
for y in [1,3.2,5.4,7.6]: part('Shelf',(-69,y,38.1),(5.5,.2,2),'#a58c67','Wood',h)
for y in [2,4.2,6.4]:
    for i in range(7): part('Book',(-71+i*.57,y,38),(.4,1.6,1.4),['#6c8a87','#c79a60','#ab6d55','#e0cfad'][i%4],'Fabric',h,rot=(0,0,(i%3-1)*4))
# Window / curtains / wall art
sign(h,'Window',(-94.1,8,28),(.12,6,9),'','#a9cbd0',face=0)
for z in [23.3,28,32.7]: part('Window frame',(-93.9,8,z),(.3,6,.2),'#f2ebda','Wood',h)
part('Window crossbar',(-93.9,8,28),(.3,.2,9.5),'#f2ebda','Wood',h)
for z in [22.5,33.5]: part('Curtain',(-93.6,8,z),(.5,7,1.6),'#7e948b','Fabric',h)
sign(h,'Bedroom poster',(-78,8,41.1),(6,4,.16),'MAKE\nSOMETHING.','#e4ca97','#476867')
plant(h,-68,19,0,.9)
part('Bedside table',(-85.2,1.5,36),(2.2,3,2.2),'#b5926a','Wood',h)
part('Lamp stem',(-85.2,3.8,36),(.15,1.3,.15),'#8c704e','Metal',h)
lamp=part('Linen shade',(-85.2,4.6,36),(1.3,1.6,1.6),'#f9e8be','Fabric',h,shape='Cylinder',rot=(0,0,90)); light(lamp,'Bedside glow',range_=14)
# Styled articulated placeholder Mom; no downloaded assets.
mom=model('Mom',world)
mx,my,mz=-68,0,25
part('Torso',(mx,3.8,mz),(2.1,2.4,1.25),'#bd7765','Fabric',mom,shape='Ball')
part('Skirt',(mx,2.55,mz),(2.4,1.5,1.6),'#4c6570','Fabric',mom,shape='Ball')
part('Apron',(mx,3.5,mz-.64),(1.3,1.8,.15),'#e9ddc4','Fabric',mom)
part('Head',(mx,5.6,mz),(1.7,1.9,1.5),'#e5b68f','SmoothPlastic',mom,shape='Ball')
part('Hair crown',(mx,6.2,mz+.15),(1.85,1.1,1.6),'#4b352c','SmoothPlastic',mom,shape='Ball')
part('Hair bun',(mx,6.4,mz+.75),(1.1,1.1,1.1),'#4b352c','SmoothPlastic',mom,shape='Ball')
for dx in [-.82,.82]: part('Hair side',(mx+dx,5.8,mz+.18),(.3,1.3,1.2),'#4b352c','SmoothPlastic',mom,shape='Ball')
for dx in [-.32,.32]:
    part('Eye white',(mx+dx,5.68,mz-.7),(.3,.32,.1),'#fff6e4','SmoothPlastic',mom,shape='Ball',collide=False)
    part('Pupil',(mx+dx,5.68,mz-.76),(.12,.18,.06),'#252b2b','SmoothPlastic',mom,shape='Ball',collide=False)
    part('Eyebrow',(mx+dx,5.98,mz-.73),(.38,.09,.07),'#4b352c','SmoothPlastic',mom,rot=(0,0,15 if dx>0 else -15),collide=False)
part('Mouth',(mx,5.17,mz-.65),(.38,.12,.08),'#995a4c','SmoothPlastic',mom,collide=False)
for dx in [-1.35,1.35]:
    part('Sleeve',(mx+dx,4,mz),(.7,1.3,.8),'#bd7765','Fabric',mom,shape='Ball')
    part('Forearm',(mx+dx,3.2,mz-.18),(.5,1.1,.5),'#e5b68f','SmoothPlastic',mom,shape='Ball')
    part('Hand',(mx+dx,2.65,mz-.25),(.55,.6,.45),'#e5b68f','SmoothPlastic',mom,shape='Ball')
for dx in [-.58,.58]:
    part('Leg',(mx+dx,1.5,mz),(.65,1.8,.65),'#e5b68f','SmoothPlastic',mom,shape='Ball')
    part('Shoe',(mx+dx,.53,mz-.18),(.8,.5,1.3),'#38434a','SmoothPlastic',mom,shape='Ball')
# Detailed taxi exterior
car=model('Taxi',world)
part('Chassis',(-31,1.35,-26),(11.5,1.2,5.4),'#bd8c24','Metal',car)
part('Body',(-31,2.15,-26),(11.8,1.5,5.5),'#ebbd49','SmoothPlastic',car)
part('Cabin',(-31,3.25,-26),(6.7,1.5,4.7),'#e5ad34','SmoothPlastic',car)
for z in [-28.4,-23.6]:
    for x in [-33,-30]: part('Window',(x,3.5,z),(2.55,1.05,.08),'#416472','Glass',car)
    part('Door seam',(-31.5,2.5,z),(.04,1.5,.06),'#a47a24','SmoothPlastic',car)
    for x in [-33,-30]: part('Handle',(x,2.7,z),(.6,.1,.1),'#e0dcca','Metal',car)
for x in [-36.4,-25.6]:
    part('Bumper',(x,1.4,-26),(.35,.45,5.7),'#d0d1c9','Metal',car)
    for z in [-27.8,-24.2]:
        part('Lamp',(x,2.1,z),(.22,.65,.9),'#fff2c8' if x>-30 else '#b44e3f','Neon',car)
for x in [-34.5,-27.5]:
    for z in [-28.7,-23.3]:
        part('Tire',(x,1.1,z),(.55,2.2,2.2),'#283032','SmoothPlastic',car,shape='Cylinder',rot=(0,90,0))
        part('Hub',(x,1.1,z+(-.3 if z<-26 else .3)),(.08,1.25,1.25),'#afb5b0','Metal',car,shape='Cylinder',rot=(0,90,0))
sign(car,'Taxi roof sign',(-31,4.3,-26),(2.3,.7,.8),'TAXI','#f9edc5','#263b40')
# Trees silhouette / fence / crates improve the site without blocking paths.
for x,z in [(-50,55),(43,60),(45,10),(-45,-9)]:
    g=model('Tree',world)
    part('Trunk',(x,4,z),(1.2,8,1.2),'#77624c','Wood',g)
    for dx,dy,dz,s in [(0,10,0,10),(-3,8,1,7),(3,9,-1,8)]: part('Canopy',(x+dx,dy,z+dz),(s,s*.8,s),'#6b856c','Grass',g,shape='Ball',collide=False)
for x in range(-27,30,4):
    part('Fence post',(x,2,76),(.3,4,.3),'#596b64','Wood',world)
for y in [1.2,3]: part('Fence rail',(0,y,76),(58,.2,.2),'#596b64','Wood',world)

exec((ROOT/'city.py').read_text())

# All geometry remains available to both the XML place and Studio installer.
MATERIALS={'Plastic':256,'SmoothPlastic':272,'Neon':288,'Wood':512,'WoodPlanks':528,'Slate':800,'Concrete':816,'Brick':848,'Cobblestone':880,'Metal':1088,'Grass':1280,'Fabric':1312,'Asphalt':1376,'Ground':1360,'Glass':1568,'Plaster':816}
SHAPES={'Block':1,'Ball':0,'Cylinder':2}
def rgb(h): return tuple(int(h[i:i+2],16)/255 for i in (1,3,5))
def matrix(p):
    if 'Matrix' in p:return p['Matrix']
    x,y,z=[math.radians(v) for v in p.get('Rotation',[0,0,0])]
    cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return [cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy]
def prop(parent,name,tag,value):
    e=ET.SubElement(parent,tag,{'name':name})
    if tag in ('Vector3','Vector2','Color3'):
        for key,v in zip({'Vector3':['X','Y','Z'],'Vector2':['X','Y'],'Color3':['R','G','B']}[tag],value):ET.SubElement(e,key).text=str(v)
    elif tag=='UDim2':
        for key,v in zip(['XS','XO','YS','YO'],value):ET.SubElement(e,key).text=str(v)
    elif tag=='CoordinateFrame':
        for key,v in zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],value):ET.SubElement(e,key).text=str(v)
    else:e.text=str(value).lower() if isinstance(value,bool) else str(value)
def xml_node(parent,n,ref):
    item=ET.SubElement(parent,'Item',{'class':n['cls'],'referent':ref}); props=ET.SubElement(item,'Properties'); prop(props,'Name','string',n['name'])
    p=n['props']
    if n['cls'] in ('Part','SpawnLocation'):
        prop(props,'CFrame','CoordinateFrame',p['Position']+matrix(p)); prop(props,'size','Vector3',p['Size']); r,g,b=rgb(p['Color']); prop(props,'Color3uint8','Color3uint8',(255<<24)+(round(r*255)<<16)+(round(g*255)<<8)+round(b*255));prop(props,'Material','token',MATERIALS[p['Material']]); prop(props,'shape','token',SHAPES[p['Shape']])
    for k,v in p.items():
        if n['cls'] in ('Part','SpawnLocation') and k in ['Position','Rotation','Matrix','Size','Color','Material','Shape']:continue
        if isinstance(v,bool):prop(props,k,'bool',v)
        elif isinstance(v,str):prop(props,k,'Color3' if v.startswith('#') and len(v)==7 else ('ProtectedString' if k=='Source' else 'string'),rgb(v) if v.startswith('#') and len(v)==7 else v)
        elif k in ['Size','Position'] and isinstance(v,list):prop(props,k,'UDim2',v)
        elif k=='CanvasSize':prop(props,k,'Vector2',v)
        elif k in ['Face','Font','TopSurface','BottomSurface']:prop(props,k,'token',v)
        else:prop(props,k,'float',v)
    return item

def build():
    root=ET.Element('roblox',{'version':'4'}); ET.SubElement(root,'External').text='null'; ET.SubElement(root,'External').text='nil'
    ws=xml_node(root,dict(cls='Workspace',name='Workspace',props={}), 'Workspace')
    camera=xml_node(ws,dict(cls='Camera',name='Camera',props={}), 'EditorCamera')
    eye=[205,148,-220]; focus=[0,4,20]
    back=[eye[i]-focus[i] for i in range(3)]; norm=math.sqrt(sum(v*v for v in back)); back=[v/norm for v in back]
    right=[back[2],0,-back[0]]; norm=math.sqrt(sum(v*v for v in right)); right=[v/norm for v in right]
    up=[back[1]*right[2]-back[2]*right[1],back[2]*right[0]-back[0]*right[2],back[0]*right[1]-back[1]*right[0]]
    prop(camera.find('Properties'),'CFrame','CoordinateFrame',eye+[right[0],up[0],back[0],right[1],up[1],back[1],right[2],up[2],back[2]])
    prop(camera.find('Properties'),'FieldOfView','float',65)
    prop(ws.find('Properties'),'CurrentCamera','Ref','EditorCamera')
    refs=[]
    for i,n in enumerate(nodes):refs.append(xml_node(ws if n['parent'] is None else refs[n['parent']],n,'N'+str(i)))
    lighting=xml_node(root,dict(cls='Lighting',name='Lighting',props={'ClockTime':14.5,'Brightness':2.5,'Ambient':'#9aafa9','OutdoorAmbient':'#b2c4c4','GlobalShadows':True,'ExposureCompensation':0.15}), 'Lighting')
    xml_node(lighting,dict(cls='Atmosphere',name='Afternoon',props={'Density':.22,'Offset':.2,'Color':'#d2dfdf','Decay':'#afbdc7','Haze':1,'Glare':.1}),'Atmosphere')
    xml_node(lighting,dict(cls='BloomEffect',name='SubtleBloom',props={'Intensity':.12,'Size':20,'Threshold':1.5}),'Bloom')
    xml_node(lighting,dict(cls='ColorCorrectionEffect',name='WarmFinish',props={'Brightness':.01,'Contrast':.06,'Saturation':-.06,'TintColor':'#fff5e8'}),'Grade')
    sss=xml_node(root,dict(cls='ServerScriptService',name='ServerScriptService',props={}), 'SSS')
    xml_node(sss,dict(cls='Script',name='AIBotServerV3',props={'Source':(ROOT/'Server.luau').read_text()}),'Server')
    sp=xml_node(root,dict(cls='StarterPlayer',name='StarterPlayer',props={'CameraMaxZoomDistance':26,'CameraMinZoomDistance':6}), 'SP')
    sps=xml_node(sp,dict(cls='StarterPlayerScripts',name='StarterPlayerScripts',props={}), 'SPS')
    xml_node(sps,dict(cls='LocalScript',name='AIBotClientV3',props={'Source':(ROOT/'Client.luau').read_text()}),'Client')
    ET.indent(root)
    ET.ElementTree(root).write(OUT/'StartYourOwnAIBot-V3.rbxlx',encoding='utf-8',xml_declaration=True)
    data=json.dumps(nodes,separators=(',',':'))
    installer='''-- START YOUR OWN AI BOT V3 / Studio Command Bar installer\nassert(not game:GetService("RunService"):IsRunning(), "Stop Play mode before installing.")\nlocal function remove(parent,name) local o=parent:FindFirstChild(name); if o then o:Destroy() end end\nlocal SSS=game:GetService("ServerScriptService")\nlocal SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")\nfor _,name in ipairs({"AIBotServer","AIBotServerV2","AIBotServerV3"}) do remove(SSS,name) end\nfor _,name in ipairs({"AIBotClient","AIBotClientV2","AIBotClientV3"}) do remove(SPS,name) end\nfor _,name in ipairs({"AIBotSet","AIBotWorld","AIBotPlots"}) do remove(workspace,name) end\nfor _,name in ipairs({"StartYourOwnAIBot","AIBotV2","AIBotV3"}) do remove(game:GetService("ReplicatedStorage"),name) end\nremove(game:GetService("ServerStorage"),"AIBotTemplate")\nlocal data=game:GetService("HttpService"):JSONDecode([====[__SCENE_DATA__]====])\nlocal built={}\nlocal function color(hex) return Color3.fromRGB(tonumber(hex:sub(2,3),16),tonumber(hex:sub(4,5),16),tonumber(hex:sub(6,7),16)) end\nfor i,n in ipairs(data) do\n local o=Instance.new(n.cls); o.Name=n.name; local p=n.props\n if n.cls=="Part" or n.cls=="SpawnLocation" then\n  o.Size=Vector3.new(table.unpack(p.Size)); o.Color=color(p.Color)\n  o.Material=Enum.Material[p.Material=="Plaster" and "Concrete" or p.Material]; o.Shape=Enum.PartType[p.Shape]\n  if p.Matrix then o.CFrame=CFrame.new(table.unpack(p.Position))*CFrame.new(0,0,0,table.unpack(p.Matrix))\n  else o.CFrame=CFrame.new(table.unpack(p.Position))*CFrame.Angles(math.rad(p.Rotation[1]),math.rad(p.Rotation[2]),math.rad(p.Rotation[3])) end\n end\n for k,v in pairs(p) do\n  if (n.cls=="Part" or n.cls=="SpawnLocation") and ({Position=true,Size=true,Color=true,Material=true,Shape=true,Rotation=true,Matrix=true})[k] then\n  elseif type(v)=="string" and v:sub(1,1)=="#" and #v==7 then o[k]=color(v)\n  elseif k=="Size" or k=="Position" then o[k]=UDim2.new(table.unpack(v))\n  elseif k=="CanvasSize" then o[k]=Vector2.new(table.unpack(v))\n  else o[k]=v end\n end\n o.Parent=n.parent~=nil and built[n.parent+1] or workspace; built[i]=o\nend\nlocal L=game:GetService("Lighting"); L.ClockTime=14.5; L.Brightness=2.5; L.Ambient=color("#9aafa9"); L.OutdoorAmbient=color("#b2c4c4"); L.GlobalShadows=true; L.ExposureCompensation=.15\nfor _,n in ipairs({"Afternoon","SubtleBloom","WarmFinish"}) do remove(L,n) end\nlocal a=Instance.new("Atmosphere"); a.Name="Afternoon";a.Density=.22;a.Haze=1;a.Color=color("#d2dfdf");a.Parent=L\nlocal bloom=Instance.new("BloomEffect");bloom.Name="SubtleBloom";bloom.Intensity=.12;bloom.Size=20;bloom.Threshold=1.5;bloom.Parent=L\nlocal grade=Instance.new("ColorCorrectionEffect");grade.Name="WarmFinish";grade.Contrast=.06;grade.Saturation=-.06;grade.TintColor=color("#fff5e8");grade.Parent=L\nlocal s=Instance.new("Script");s.Name="AIBotServerV3";s.Source=[====[__SERVER_SOURCE__]====];s.Parent=SSS\nlocal c=Instance.new("LocalScript");c.Name="AIBotClientV3";c.Source=[====[__CLIENT_SOURCE__]====];c.Parent=SPS\ngame:GetService("StarterPlayer").CameraMinZoomDistance=6;game:GetService("StarterPlayer").CameraMaxZoomDistance=26\nworkspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(205,148,-220),Vector3.new(0,4,20))\nprint("Installed AI Bot V3. Press Play. Only the named prototype objects were replaced.")\n'''
    installer=installer.replace('__SERVER_SOURCE__',(ROOT/'Server.luau').read_text()).replace('__CLIENT_SOURCE__',(ROOT/'Client.luau').read_text()).replace('__SCENE_DATA__',data)
    (OUT/'Install-AIBot-V3.luau').write_text(installer)
    (OUT/'Scene.json').write_text(json.dumps(nodes))
    for name in ['Server.luau','Client.luau','README.md']:(OUT/name).write_text((ROOT/name).read_text())
    with zipfile.ZipFile(OUT/'StartYourOwnAIBot-V3.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['StartYourOwnAIBot-V3.rbxlx','Install-AIBot-V3.luau','Server.luau','Client.luau','README.md']:z.write(OUT/name,'StartYourOwnAIBot-V3/'+name)
    print(f'{len(nodes)} scene objects; {sum(n["cls"]=="Part" for n in nodes)} parts; place and installer generated')
if __name__=='__main__':build()
