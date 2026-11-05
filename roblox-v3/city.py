# Executed by build.py with its scene-building primitives.
city=model('Neighborhood',world)
# Anchored land, kerbs and long streets; no floating decorative island.
part('Boulevard',(0,.12,-26),(520,.24,21),'#50595d','Asphalt',city)
part('Innovation Avenue',(73,.14,35),(20,.24,420),'#50595d','Asphalt',city)
for x in range(-250,260,14):
    if abs(x-73)>14: part('Lane dash',(x,.26,-26),(7,.025,.18),'#e8dcb1','SmoothPlastic',city,collide=False)
for z in range(-170,245,14):
    if abs(z+26)>15: part('Avenue dash',(73,.26,z),(.18,.025,7),'#e8dcb1','SmoothPlastic',city,collide=False)
for z in [-40,-12]: part('Boulevard sidewalk',(0,.3,z),(520,.6,7),'#c0c1b3','Concrete',city)
for x in [59,87]: part('Avenue sidewalk',(x,.3,35),(7,.6,420),'#c0c1b3','Concrete',city)
for x in range(-240,260,24):
    for z in [-40,-12]:part('Expansion joint',(x,.61,z),(.04,.02,7),'#8d978d','Concrete',city,collide=False)
for z in range(-160,240,24):
    for x in [59,87]:part('Expansion joint',(x,.61,z),(7,.02,.04),'#8d978d','Concrete',city,collide=False)
# Zebra crossings at real junctions, road lettering, bollards.
for x in range(63,85,3):
    for z in [-8,-44]:part('Crosswalk',(x,.28,z),(1.3,.025,7),'#e4e2cd','SmoothPlastic',city,collide=False)
for z in range(-34,-17,3):
    for x in [52,94]:part('Crosswalk',(x,.28,z),(7,.025,1.3),'#e4e2cd','SmoothPlastic',city,collide=False)

def streetlamp(x,z):
    g=model('Streetlamp',city)
    part('Foot',(x,.5,z),(1.1,1,1.1),'#394c4e','Metal',g)
    part('Pole',(x,7,z),(.25,13,.25),'#42595a','Metal',g)
    beam((x,13,z),(x+2.5,13,z),.22,'#42595a',g)
    lamp=part('Lamp',(x+2.5,12.8,z),(2.2,.25,1.1),'#ffe8b5','Neon',g);light(lamp,'Pool','#ffe5b5',1.8,27)
for x in [-235,-175,-115,-55,25,115,185,245]:
    streetlamp(x,-41);streetlamp(x,-10)
for z in [30,95,160,220]:streetlamp(88,z)
# Clear street signs and bus shelter.
for x,z,title in [(53,-46,'FOUNDRY STREET'),(91,-10,'INNOVATION AVENUE')]:
    part('Sign pole',(x,3,z),(.18,6,.18),'#465c5c','Metal',city)
    sign(city,'Street sign',(x,5.4,z),(9,1.2,.16),title,'#315a52','#f5ebd7')
shelter=model('Bus stop',city)
part('Shelter roof',(135,8,-10),(16,.45,6),'#425c61','Metal',shelter)
for x in [128,142]:
    part('Shelter support',(x,4,-8),(.25,8,.25),'#425c61','Metal',shelter)
    part('Shelter glass',(x,4,-10),(.15,7,5),'#afcbd0','Glass',shelter,transparency=.45)
part('Shelter back',(135,4,-7.2),(14,7,.12),'#afcbd0','Glass',shelter,transparency=.4)
part('Bus bench',(135,2,-9),(11,.35,1.8),'#9f8261','Wood',shelter)
sign(shelter,'Route',(142.2,4,-10),(.12,4,2.5),'07\nCITY\nLOOP','#f0d592','#365150',face=0)

# Across-the-street shops: actual accessible floors, doors, counters and shelving.
def shop(name,x,z,width=32,color='#c3b097'):
    g=model(name,city);d=28
    part('Shop foundation',(x,.4,z),(width,.8,d),'#b3b6ac','Concrete',g)
    part('Tile floor',(x,.83,z),(width-1,.06,d-1),'#d4cfbd','Concrete',g)
    part('Back wall',(x,7,z-d/2),(width,14,1),color,'Brick',g)
    for dx in [-width/2,width/2]:part('Side wall',(x+dx,7,z),(1,14,d),color,'Brick',g)
    for dx in [-width/4-2,width/4+2]:
        part('Shop front lower',(x+dx,1.9,z+d/2),(width/2-4,3.8,.7),color,'Brick',g)
        part('Display glass',(x+dx,6.4,z+d/2),(width/2-4,5.2,.12),'#a5c8ca','Glass',g,transparency=.45)
        for edge in [-1,1]:part('Window frame',(x+dx+edge*(width/4-2),6.4,z+d/2),(.15,5.4,.25),'#405b5b','Metal',g)
    part('Front fascia',(x,11.8,z+d/2),(width,4,.8),color,'Concrete',g)
    sign(g,'Shop name',(x,11.8,z+d/2+.48),(width-3,2.6,.15),name,'#2c4f53','#f4e1bc',rot=(0,180,0))
    part('Flat roof',(x,14.2,z-4),(width+1,.5,d-7),'#717e78','Concrete',g)
    for dx in [-4,4]:part('Door jamb',(x+dx,4,z+d/2),(.2,8,.3),'#405b5b','Metal',g)
    part('Entrance mat',(x,.9,z+d/2-1),(7,.07,3),'#5b7771','Fabric',g)
    # Small awning over the open shop entrance.
    part('Awning',(x,9,z+d/2+2),(13,.25,5),'#6e8b7c','Fabric',g,rot=(8,0,0))
    return g
cafe=shop('BYTE & BREW',8,-79,34,'#c2ab87')
part('Cafe counter',(8,2.2,-86),(20,4.4,3),'#ad805d','WoodPlanks',cafe)
part('Counter top',(8,4.5,-86),(21,.22,3.3),'#ebe0c7','Concrete',cafe)
part('Espresso machine',(4,5.4,-86),(4,1.7,1.8),'#3e5459','Metal',cafe)
for x in [3,5]:part('Coffee spout',(x,5,-84.9),(.18,.4,.25),'#b6c0bb','Metal',cafe)
sign(cafe,'Menu',(8,9,-92.4),(20,4,.12),'BYTE & BREW\nCOFFEE   /   IDEAS   /   SECOND CHANCES','#264544','#e7d8b5',rot=(0,180,0))
for x in [-3,18]:
    part('Cafe table',(x,2.6,-75),(4,.2,4),'#ba9770','Wood',cafe)
    part('Table pedestal',(x,1.3,-75),(.3,2.6,.3),'#4c6060','Metal',cafe)
    for z in [-77.8,-72.2]:chair(cafe,x,z)
for x in [-3,19]:
    part('Patio table',(x,2.7,-51),(4,.25,4),'#b69a70','Wood',city)
    part('Patio pedestal',(x,1.5,-51),(.25,2.8,.25),'#45635c','Metal',city)
    for dx in [-3,3]:chair(city,x+dx,-51)
    part('Umbrella pole',(x,5,-51),(.16,9,.16),'#4b665d','Metal',city)
    for dx in [-1.5,1.5]:part('Canopy',(x+dx,9,-51),(3.2,.2,7),'#b08b5c','Fabric',city,rot=(0,0,12 if dx<0 else -12))
tech=shop('CIRCUIT / COMPUTER STORE',-44,-79,36,'#8faaa5')
for x in [-53,-35]:
    desk(tech,x,-84,y=.8,width=8,color='#aeb5ad')
    monitor(tech,x,-84.4,y=4.12)
    part('Product box',(x,2,-91),(5,2.4,2.5),'#6c8e8a','SmoothPlastic',tech)
part('Service counter',(-44,2.4,-71),(11,3.1,3),'#485f62','Wood',tech)
for z in [-86,-80,-74]:
    part('Parts shelf',(-60,4,z),(2,6,4),'#5d7472','Metal',tech)
    for y in [2,4,6]:part('Hardware box',(-59.8,y,z),(1.7,1.2,3),'#a4b0a2','SmoothPlastic',tech)
hardware=shop('FOUNDRY / HARDWARE',-100,-79,36,'#bb9277')
for x in [-111,-101,-91]:
    for y in [1.2,3.8,6.4]:
        part('Supply rack',(x,y,-87),(7,.25,4),'#536b66','Metal',hardware)
        for dx in [-2,0,2]:part('Supply carton',(x+dx,y+1,-87),(1.6,1.7,2.5),'#bca27c','WoodPlanks',hardware)
part('Hardware counter',(-100,2.5,-71),(14,3.5,3),'#797c6b','Wood',hardware)
# Residential neighborhood. Houses have foundations, porches, windows, roofs, gardens.
def house(x,z,paint,number):
    g=model('House '+str(number),city)
    part('House slab',(x,.5,z),(32,1,30),'#b6b0a0','Concrete',g)
    part('House walls',(x,6.5,z),(29,12,27),paint,'Brick',g)
    for side in [-1,1]:
        part('Roof plane',(x+side*8,14,z),(17.5,.6,31),'#586b6b','Slate',g,rot=(0,0,side*-20))
    for dx in [-8,8]:
        part('Window',(x+dx,7,z-13.6),(6,5,.15),'#95b8bd','Glass',g)
        for xx in [dx-3,dx,dx+3]:part('Window trim',(x+xx,7,z-13.72),(.15,5.3,.1),'#e6dfc8','Wood',g)
        part('Window sill',(x+dx,4.5,z-13.8),(6.6,.18,.6),'#e6dfc8','Wood',g)
    sign(g,'Front door',(x,4.3,z-13.7),(4.5,7.5,.25),str(number),'#4d6d66','#efe0ba')
    part('Door knob',(x+1.6,3.5,z-13.9),(.2,.2,.2),'#c8b17a','Metal',g,shape='Ball')
    part('Porch',(x,.7,z-17),(15,1.4,7),'#b5a48b','Concrete',g)
    part('Garden path',(x,.22,z-26),(5,.44,12),'#b4b6a5','Concrete',g)
    for dx in [-12,12]:
        part('Hedge',(x+dx,1.4,z-22),(8,2.8,3),'#6d8762','Grass',g,shape='Ball')
        plant(g,x+dx,z-17,0,.8)
    part('Mailbox post',(x-5,2,z-31),(.25,4,.25),'#566c61','Metal',g)
    part('Mailbox',(x-5,4,z-31),(1.8,1.1,1),'#667e73','Metal',g)
    part('Chimney',(x+9,16,z+7),(2,7,2),'#9c7a64','Brick',g)
for x,z,c,n in [(-145,29,'#c9bca0',12),(-208,29,'#a6b9ab',14),(-150,106,'#c6ad94',18),(-210,106,'#b7c0ad',20)]:house(x,z,c,n)
# Lanes and paths tie residential plots back to the boulevard.
part('Residential lane',(-176,.12,68),(160,.24,12),'#737d73','Asphalt',city)
part('Residential connector',(-238,.12,17),(12,.24,110),'#737d73','Asphalt',city)
part('Home footpath',(-80,.18,3),(9,.36,28),'#bab9a5','Concrete',city)
# Urban park/plaza east of the avenue.
park=model('Signal Park',city)
part('Park lawn',(151,.2,41),(112,.4,110),'#889d78','Grass',park)
part('Park walk eastwest',(151,.48,34),(112,.16,9),'#c7bd9e','Concrete',park)
part('Park walk northsouth',(147,.48,41),(9,.16,110),'#c7bd9e','Concrete',park)
# Octagonal fountain with water physically contained by coping.
part('Fountain footing',(147,.7,34),(22,1.4,22),'#b5b09b','Concrete',park)
part('Fountain basin',(147,1.5,34),(18,1.5,18),'#677f81','Concrete',park)
part('Water',(147,2.15,34),(17.5,.15,17.5),'#76b5bd','Glass',park,transparency=.2)
for x,z,s in [(137,34,(1,2,22)),(157,34,(1,2,22)),(147,24,(22,2,1)),(147,44,(22,2,1))]:part('Coping',(x,1.5,z),s,'#ddd3b4','Concrete',park)
part('Fountain column',(147,3.5,34),(2,5,2),'#b7b39b','Concrete',park)
part('Upper bowl',(147,5.5,34),(6,.6,6),'#d1c9ad','Concrete',park)
for dx,dz in [(-2,0),(2,0),(0,-2),(0,2)]:part('Falling water',(147+dx,3.7,34+dz),(.16,3.1,.16),'#a3d9db','Glass',park,transparency=.45,collide=False)
for x,z in [(115,7),(180,7),(115,69),(180,69)]:
    part('Park bench seat',(x,1.8,z),(7,.4,2),'#a58a63','WoodPlanks',park)
    part('Park bench back',(x,3,z+1),(7,2,.25),'#a58a63','WoodPlanks',park)
    for dx in [-2.4,2.4]:part('Bench leg',(x+dx,.85,z),(.3,1.7,1.7),'#49665f','Metal',park)
for x,z in [(111,53),(182,52),(115,-1),(183,-1)]:plant(park,x,z,0,1.6)
sign(park,'Park welcome',(101,4,4),(8,3,.2),'SIGNAL PARK\nTAKE A BREAK. FIND AN IDEA.','#426b5d','#efe4c7')
# Pond at the north of the park with banks and footbridge.
part('Pond bed',(152,.3,83),(37,.6,14),'#7b8c76','Ground',park,shape='Ball')
part('Pond water',(152,.62,83),(33,.12,11),'#719f9d','Glass',park,shape='Ball',transparency=.12)
for x in range(133,173,4):part('Pond edging',(x,.8,89),(4,1.6,2),'#919587','Slate',park,shape='Ball')
for z in range(76,91,2):part('Footbridge plank',(147,1.4,z),(7,.2,1.85),'#a38c67','Wood',park)
for x in [143.6,150.4]:
    for z in [77,83,89]:part('Bridge post',(x,2.5,z),(.2,2.5,.2),'#667c6b','Wood',park)
    part('Bridge handrail',(x,3.6,83),(.2,.2,13),'#667c6b','Wood',park)
# Second row of shops and taller distant buildings establish a town skyline.
for x,z,width,height,color,name in [(125,137,37,32,'#b4b4a4','NORTHSTAR OFFICES'),(180,137,38,44,'#8fa6a1','CLOUDLINE'),(233,57,35,37,'#b9a086','STACK STUDIOS'),(233,-73,33,29,'#99b1aa','LOCAL LIBRARY')]:
    g=model(name,city)
    part('Foundation',(x,.6,z),(width+3,1.2,29),'#a6aba0','Concrete',g)
    part('Building',(x,height/2+1,z),(width,height,26),color,'Concrete',g)
    part('Cornice',(x,height+1.5,z),(width+1.5,1,28),'#627e7b','Metal',g)
    for y in range(6,height-1,7):
        for dx in range(-int(width/2)+4,int(width/2)-1,6):
            part('Office window',(x+dx,y,z-13.1),(3.8,4,.15),'#587c87','Glass',g)
            part('Window ledge',(x+dx,y-2.1,z-13.2),(4.2,.15,.45),'#d1c8b3','Concrete',g)
    sign(g,'Business sign',(x,4,z-13.3),(width-3,2,.15),name,'#35535b','#f4dfb3')
    for dx in [-width/4,width/4]:part('Roof ventilation',(x+dx,height+3,z),(5,2.5,5),'#83938d','Metal',g)
# Industrial yard behind the starter warehouse: loading bays, pallets, equipment.
yard=model('Foundry Yard',city)
part('Loading apron',(-20,.12,133),(120,.24,76),'#8c9189','Concrete',yard)
part('Yard connector',(34,.12,100),(21,.24,70),'#767f77','Asphalt',yard)
for x in range(-73,28,10):part('Parking line',(x,.26,112),(.12,.025,17),'#e6ddad','SmoothPlastic',yard,collide=False)
part('Secondary depot',(-30,9,171),(92,18,25),'#8b9d95','Concrete',yard)
part('Depot roof',(-30,18.4,171),(95,.6,28),'#536d6c','Metal',yard)
for x in [-58,-30,-2]:
    part('Loading door',(x,6.2,158.3),(18,11,.2),'#63817e','Metal',yard)
    for y in range(2,12):part('Door rib',(x,y,158.1),(18,.12,.12),'#81958b','Metal',yard)
    sign(yard,'Bay number',(x,14,158),(8,1.8,.15),'LOADING / '+str((x+58)//28+1),'#35585a','#ebdfbd')
for x,z in [(-65,135),(-50,146),(6,142)]:
    for y in [1,3.2]:
        part('Pallet',(x,y-.8,z),(8,.3,6),'#9d825a','WoodPlanks',yard)
        for dx in [-2,0,2]:part('Freight carton',(x+dx,y+.3,z),(1.8,1.8,4),'#bba078','WoodPlanks',yard)
for x in [-85,-96]:
    part('Storage tank',(x,8,161),(15,7,7),'#a0b4af','Metal',yard,shape='Cylinder',rot=(0,0,90))
    for z in [158,164]:beam((x,3,z),(x,12,z),.25,'#728c81',yard)
# Small forklift with physically grounded tires.
fork=model('Forklift',yard)
part('Base',(-14,1.6,132),(6,2.2,4),'#d3a152','Metal',fork)
part('Rear housing',(-16,2.7,132),(2,2,4),'#d3a152','Metal',fork)
part('Seat',(-14,2.9,132),(1.5,.35,1.8),'#34474c','Fabric',fork)
for z in [130.3,133.7]:beam((-15,2,z),(-15,6.5,z),.18,'#3c5558',fork)
part('Safety roof',(-14,6.6,132),(4,.25,4),'#3c5558','Metal',fork)
for z in [130.5,133.5]:
    beam((-11,1,z),(-11,7,z),.25,'#3c5558',fork)
    part('Fork',(-8.7,.65,z),(5,.2,.3),'#637778','Metal',fork)
for x in [-16,-12]:
    for z in [129.8,134.2]:part('Tire',(x,.95,z),(.5,1.8,1.8),'#2c383a','SmoothPlastic',fork,shape='Cylinder',rot=(0,90,0))
# Background landforms touch the ground and conceal map edges.
for i in range(28):
    a=i*math.tau/28;x=math.cos(a)*275;z=math.sin(a)*250
    part('Grounded hill',(x,3,z),(75,30+(i%4)*8,70),'#73866d','Grass',city,shape='Ball')
    part('Hill rock',(x+8,8,z+4),(28,24,26),'#8a9384','Slate',city,rot=(i*7,i*23,12),shape='Ball')
# Tree canopies built from overlapping forms, all trunks rooted in land.
def tree(x,z,scale=1):
    g=model('Neighborhood tree',city)
    part('Trunk',(x,3.5*scale,z),(.8*scale,7*scale,.8*scale),'#7e6951','Wood',g)
    for dx,dy,dz,s in [(0,9,0,8),(-2,7,1,6),(2,8,-1,6.5)]:part('Foliage',(x+dx*scale,dy*scale,z+dz*scale),(s*scale,s*.85*scale,s*scale),'#6b8768' if dx else '#7e966d','Grass',g,shape='Ball',collide=False)
for x,z in [(-225,-54),(-190,-49),(-160,-50),(-130,-47),(-10,-108),(40,-109),(110,-98),(170,-103),(210,-130),(116,55),(180,55),(110,83),(190,83),(-120,133),(-208,152),(-157,152),(-245,105),(-245,172),(35,198),(113,196),(194,196),(242,137),(242,197)]:tree(x,z,1+(abs(x)%3)*.1)
# Exploratory notebook pickups. Interactions are added by the server.
for name,pos,word in [('ResearchCafe',(8,4.8,-84),'CUSTOMER NOTES'),('ResearchTech',(-44,4.3,-71),'HARDWARE NOTES'),('ResearchPark',(115,2.2,7),'FRESH IDEAS')]:
    g=model(name+'Notebook',city)
    part('Cover',pos,(1.3,.15,1.8),'#ccaa6b','Fabric',g)
    part('Pages',(pos[0],pos[1]+.1,pos[2]),(1.15,.1,1.6),'#efe3c6','SmoothPlastic',g)
    part(name,(pos[0],pos[1]+.4,pos[2]),(.4,.4,.4),'#ffffff','SmoothPlastic',world,collide=False,transparency=1)
for name,pos in [('MapHome',(-80,2,4)),('MapWarehouse',(0,2,10)),('MapCafe',(8,2,-58)),('MapTech',(-44,2,-58)),('MapPark',(107,2,34)),('MapYard',(-20,2,113))]:part(name,pos,(1,1,1),parent=world,collide=False,transparency=1)
# Keep play space grounded even if an engine session starts before scripts finish.
spawn=obj('SpawnLocation','SafeSpawn',world,Position=[0,1,1],Size=[8,.5,8],Color='#7e9174',Material='Grass',Rotation=[0,0,0],Shape='Block',Anchored=True,CanCollide=False,CanTouch=True,CanQuery=True,Transparency=1,TopSurface=0,BottomSurface=0,CastShadow=False,Neutral=True,Duration=0)
# The starting bedroom is now enclosed in a complete house exterior.
exterior=model('Starter House Exterior',city)
for x,width in [(-88.3,12.4),(-70.7,10.4)]:
    part('Front wall',(x,6.5,14.5),(width,13,.6),'#d4c8ad','Brick',exterior)
part('Front lintel',(-79,11.1,14.5),(6,3.8,.6),'#d4c8ad','Brick',exterior)
part('Right house wall',(-65.5,7.9,28),(.6,10.2,27),'#d4c8ad','Brick',exterior)
for side in [-1,1]:part('House roof',(-80+side*7.5,15.1,28),(16,.5,30),'#596b69','Slate',exterior,rot=(0,0,side*-20))
for x in [-88.5,-70.7]:
    part('Bedroom front window',(x,7,14.05),(5,4.5,.12),'#9abfc1','Glass',exterior)
    for dx in [-2.5,0,2.5]:part('Window trim',(x+dx,7,13.92),(.14,4.7,.12),'#f1e5c9','Wood',exterior)
    part('Window sill',(x,4.7,13.8),(5.6,.18,.5),'#f1e5c9','Wood',exterior)
part('Home porch',(-79,.6,11),(9,1.2,6),'#b8a88c','Concrete',exterior)
sign(exterior,'Home number',(-75,4.5,14.07),(1.5,1.8,.12),'10','#47675f','#eee0bc')
