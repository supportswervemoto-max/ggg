# Clothing-company warehouse set dressing and purchasable build groups.
# Executed by build.py with its scene helpers in scope.

fashion = model('FashionCompanyInterior', world)

# Dynamic company sign. The server replaces CompanyNameText for each player's plot.
company_sign = part('CompanySign', (0, 12.5, 13.25), (32, 4.6, .35), '#20252a', 'SmoothPlastic', fashion)
company_gui = obj('SurfaceGui', 'CompanySignGui', company_sign, Face=5, CanvasSize=[1200, 360], AlwaysOnTop=False, LightInfluence=0)
obj('TextLabel', 'CompanyNameText', company_gui, Size=[1, 0, .67, 0], Position=[0, 0, 0, 0], BackgroundTransparency=1,
    Text="YOUR COMPANY", TextColor3='#f5e7ca', TextScaled=True, Font=46, TextWrapped=True)
obj('TextLabel', 'CompanySubtitleText', company_gui, Size=[1, 0, .25, 0], Position=[0, 0, .7, 0], BackgroundTransparency=1,
    Text='ONLINE FASHION / FULFILMENT', TextColor3='#85c5a2', TextScaled=True, Font=46, TextWrapped=True)

# Computer desk where the player begins and manages the website/ads.
office = model('CompanyOffice', fashion)
desk(office, -8, 42, width=11, name='CompanyOfficeDesk', color='#9a7655')
monitor(office, -8, 43.4, w=5.5, name='CompanyMonitor')
part('CompanyComputer', (-8, 4.5, 43.2), (5.8, 3.5, .55), '#182c32', 'SmoothPlastic', office, collide=False, transparency=1)
chair(office, -8, 38.8, name='FounderChair')
sign(office, 'Founder board', (-13, 8.5, 65.25), (10, 4.6, .18), 'START SMALL.\nSHIP THE FIRST ORDER.', '#d3b47d', '#273a3c')

# Spawn and employee display positions.
part('CompanySpawn', (-8, 1, 36), (1, 1, 1), parent=world, collide=False, transparency=1)
part('WorkerSpawn', (4, 0, 50), (1, 1, 1), parent=world, collide=False, transparency=1)

def folded_stack(parent, x, y, z, color, count=4, width=2.4):
    for index in range(count):
        part('Folded garment', (x, y + index * .28, z), (width, .22, 1.6), color if index % 2 == 0 else '#e7deca', 'Fabric', parent)

def cardboard_box(parent, x, y, z, label_text='ORDER'):
    box = model('Shipping box', parent)
    part('Carton', (x, y, z), (3.2, 2.2, 2.8), '#b58d5e', 'WoodPlanks', box)
    part('Packing tape', (x, y + 1.12, z), (.45, .05, 2.8), '#e6d0a0', 'SmoothPlastic', box, collide=False)
    sign(box, 'Shipping label', (x, y, z - 1.42), (1.8, 1, .04), label_text, '#efe8d5', '#283336')

# First required sorting desk.
sorting = model('SortingDeskBuild', fashion)
part('Sorting table', (3, 3.1, 43), (12, .55, 6), '#b8946a', 'Wood', sorting)
for dx in [-5.2, 5.2]:
    for dz in [-2.2, 2.2]: part('Table leg', (3 + dx, 1.5, 43 + dz), (.35, 3, .35), '#33444a', 'Metal', sorting)
for x, color in [(-1, '#657f9b'), (2, '#a56f61'), (5, '#6d8464')]: folded_stack(sorting, x, 3.55, 43, color, 5)
for x, title in [(-1, 'NEW'), (2, 'CHECK'), (5, 'READY')]:
    sign(sorting, 'Sort tray label', (x, 4.7, 40.05), (2.5, .75, .08), title, '#24343a', '#f1e4ca')
part('Quality lamp', (8, 7, 43), (.18, 7.5, .18), '#405458', 'Metal', sorting)
lamp = part('Inspection light', (6.7, 8.7, 43), (3, .3, 1.4), '#ffe7ad', 'Neon', sorting)
light(lamp, 'Inspection glow', '#ffe9bd', 1.8, 18)

# Packing station and shipping queue.
packing = model('PackingStationBuild', fashion)
part('Packing worktop', (13, 3, 52), (10, .5, 5), '#9b7956', 'WoodPlanks', packing)
for dx in [-4.2, 4.2]:
    for dz in [-1.8, 1.8]: part('Packing leg', (13 + dx, 1.45, 52 + dz), (.3, 2.9, .3), '#34494c', 'Metal', packing)
cardboard_box(packing, 11, 4.35, 52, 'SHIP')
for x in [16, 18.5, 21]: cardboard_box(packing, x, 1.25, 57, 'ORDER')
part('Tape dispenser', (15.5, 3.6, 51), (1, .7, .7), '#5f7e78', 'SmoothPlastic', packing)
part('Label printer', (16.8, 4, 52.6), (2.2, 1.5, 1.8), '#39494e', 'SmoothPlastic', packing)

# Designer-inspired inventory uses original fictional labels.
racks = model('ClothingRackBuild', fashion)
for rack_x, brand, accent in [(-17, 'CREST & ROW', '#6f7f9e'), (-11, 'NORTHLINE POLO', '#9b6c59'), (-5, 'ATELIER 16', '#72876c')]:
    part('Rack base', (rack_x, .75, 55), (5, .35, 2.4), '#3c4d50', 'Metal', racks)
    for dx in [-2.2, 2.2]: part('Rack post', (rack_x + dx, 4, 55), (.2, 6.5, .2), '#3c4d50', 'Metal', racks)
    part('Rack rail', (rack_x, 6.7, 55), (5, .2, .2), '#3c4d50', 'Metal', racks)
    sign(racks, 'Brand plate', (rack_x, 8, 55), (5.2, 1.1, .16), brand, '#243a3d', '#f1e4c7')
    for index in range(7):
        gx = rack_x - 1.8 + index * .6
        part('Hanger hook', (gx, 6.3, 55), (.08, .6, .08), '#c3b794', 'Metal', racks, shape='Cylinder')
        part('Designer shirt', (gx, 4.9, 55), (.48, 2.1, 1.4), accent if index % 2 == 0 else '#e3dac5', 'Fabric', racks)

# Product photography corner.
studio = model('PhotoStudioBuild', fashion)
part('Backdrop', (-16, 7, 25), (15, 13, .4), '#e8e1d3', 'Fabric', studio)
part('Backdrop floor', (-16, .75, 29), (15, .25, 8), '#e8e1d3', 'Fabric', studio)
for x in [-22, -10]:
    part('Tripod pole', (x, 3.6, 32), (.15, 6.5, .15), '#303d42', 'Metal', studio)
    for dx in [-1, 0, 1]: beam((x, .5, 32), (x + dx, 0, 32 + 1), .1, '#303d42', studio)
    softbox = part('Softbox', (x, 7, 31), (3.5, 3, .5), '#f6e8c6', 'Neon', studio, rot=(-12, 0, 0))
    light(softbox, 'Studio light', '#fff1cf', 2.2, 22)
part('Camera tripod', (-16, 3, 35), (.2, 5, .2), '#303d42', 'Metal', studio)
part('Camera', (-16, 5.8, 34.7), (2.2, 1.3, 1.5), '#202a2e', 'SmoothPlastic', studio)
part('Product pedestal', (-16, 2, 27), (4, 4, 4), '#d2c7af', 'Concrete', studio)
folded_stack(studio, -16, 4.2, 27, '#647f9b', 3, 3)

# Luxury showroom appears as a late-game warehouse transformation.
showroom = model('ShowroomBuild', fashion)
part('Showroom floor', (0, .7, 31), (35, .18, 12), '#d6ccb6', 'WoodPlanks', showroom)
for x in [-13, 0, 13]:
    part('Display plinth', (x, 1.5, 31), (5, 2.5, 5), '#eee5d1', 'Concrete', showroom)
    part('Display mannequin torso', (x, 5, 31), (2.2, 3.4, 1.2), ['#647f9b', '#9a6659', '#657d68'][int((x + 13) / 13)], 'Fabric', showroom, shape='Ball')
    part('Display mannequin head', (x, 7.2, 31), (1.5, 1.5, 1.5), '#d2b08c', 'SmoothPlastic', showroom, shape='Ball')
sign(showroom, 'Showroom title', (0, 10, 25), (24, 2.2, .18), 'THE FLAGSHIP COLLECTION', '#25383b', '#f4e5c7')

# Keep old AI-themed signs from showing in the clothing-company edition.
for hidden_name, pos in [('OldWarehouseIdentityCover', (0, 16.1, 13.0)), ('OldLaptopCover', (0, 4.6, 44.8))]:
    part(hidden_name, pos, (30, 3.2, .2) if 'Warehouse' in hidden_name else (4, 2.7, .25), '#20252a', 'SmoothPlastic', fashion)
