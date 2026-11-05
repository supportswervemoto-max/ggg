from pathlib import Path
import ctypes, ctypes.util, json, math, re, xml.etree.ElementTree as ET, zipfile
P=Path('/workspace/artifacts'); ROOT=Path(__file__).parent
lib=ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
lib.luaL_loadbufferx.restype=ctypes.c_int
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lib.lua_tolstring.restype=ctypes.c_char_p
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p];lib.lua_pcallk.restype=ctypes.c_int
lib.lua_close.argtypes=[ctypes.c_void_p]
def check_lua(source,name,execute=False):
    state=lib.luaL_newstate()
    try:
        lib.luaL_openlibs(state)
        data=source.encode(); code=lib.luaL_loadbufferx(state,data,len(data),name.encode(),None)
        if not code and execute:code=lib.lua_pcallk(state,0,0,0,0,None)
        assert code==0, (lib.lua_tolstring(state,-1,None) or b'Lua failure').decode()
    finally:lib.lua_close(state)
for name in ['Server.luau','Client.luau','Install-AIBot-V3.luau']:
    check_lua((P/name).read_text(),name)
    print('PASS Lua 5.4-compatible syntax:',name)
scene=json.loads((P/'Scene.json').read_text())
xml=ET.parse(P/'StartYourOwnAIBot-V3.rbxlx').getroot()
items=xml.findall('.//Item'); refs=[i.attrib['referent'] for i in items]
assert len(refs)==len(set(refs))
assert len([i for i in items if i.attrib['class'] in ['Part','SpawnLocation']])==sum(n['cls'] in ['Part','SpawnLocation'] for n in scene)
assert len([i for i in items if i.attrib['class'] in ['Script','LocalScript']])==2
for i in items:
    if i.attrib['class'] in ['Part','SpawnLocation']:
        size=i.find('./Properties/Vector3[@name="size"]');assert size is not None
        assert all(float(size.find(k).text)>0 for k in ['X','Y','Z'])
        assert 0xFF000000<=int(i.find('./Properties/Color3uint8').text)<=0xFFFFFFFF
        cf=i.find('./Properties/CoordinateFrame');r=[float(cf.find('R'+str(a)+str(b)).text) for a in range(3) for b in range(3)]
        for row in range(3):assert abs(sum(v*v for v in r[row*3:row*3+3])-1)<1e-8
# Independent engine-enum regression check: the V2 export swapped Ball and Block.
api=json.load(open(ROOT/'engine-enums.json'))
engine_shapes=api['PartType']
engine_materials=api['Material']
for idx,n in enumerate(scene):
 if n['cls'] in ['Part','SpawnLocation']:
  exported=next(i for i in items if i.attrib['referent']=='N'+str(idx))
  assert int(exported.find('./Properties/token[@name="shape"]').text)==engine_shapes[n['props']['Shape']],n['name']
  mat=n['props']['Material'];mat='Concrete' if mat=='Plaster' else mat
  assert int(exported.find('./Properties/token[@name="Material"]').text)==engine_materials[mat],mat
foundation=next(i for i in items if i.find('./Properties/string[@name="Name"]').text=='Island')
assert int(foundation.find('./Properties/token[@name="shape"]').text)==1
assert foundation.find('./Properties/bool[@name="Anchored"]').text=='true'
assert foundation.find('./Properties/bool[@name="CanCollide"]').text=='true'
assert float(foundation.find('./Properties/Vector3[@name="size"]/X').text)==640
assert float(foundation.find('./Properties/CoordinateFrame/Y').text)+float(foundation.find('./Properties/Vector3[@name="size"]/Y').text)/2==0
print('PASS independent Roblox API shape/material checks and flat collidable ground regression')
names=[n['name'] for n in scene]
for name in ['Arrival','Entrance','LaptopSpot','HomeSeat','HomeCamera','HomeFocus','Mom','Taxi','Laptop','WorkspaceUpgrade','ServerUpgrade','StudioUpgrade','DeskPad','ServerPad','StudioPad','MapPark','MapTech','MapCafe','MapHome','MapYard','MapWarehouse','ResearchCafe','ResearchTech','ResearchPark']:
    assert names.count(name)==1,(name,names.count(name))
installer=(P/'Install-AIBot-V3.luau').read_text()
payload=re.search(r'JSONDecode\(\[====\[(.*?)\]====\]\)',installer,re.S).group(1)
assert json.loads(payload)==scene
for filename,scriptname in [('Server.luau','AIBotServerV3'),('Client.luau','AIBotClientV3')]:
    source=(ROOT/filename).read_text()
    assert source in installer
    embedded=next(i.find('./Properties/ProtectedString[@name="Source"]').text for i in items if i.find('./Properties/string[@name="Name"]').text==scriptname)
    assert embedded==source
assert '__SCENE_DATA__' not in installer
# Verify walking route to the front of the desk remains unobstructed at torso height.
for z in range(0,37):
    for n in scene:
        p=n['props']
        if n['cls']!='Part' or not p['CanCollide'] or p['Transparency']==1:continue
        if n['name'] in ['WorkspaceUpgrade','ServerUpgrade','StudioUpgrade']:continue
        x,y,pz=p['Position']
        import build
        rotation=build.matrix(p)
        sx,sy,sz=[sum(abs(rotation[row*3+col])*p['Size'][col] for col in range(3)) for row in range(3)]
        if abs(x)<sx/2+.8 and abs(pz-z)<sz/2+.8 and y-sy/2<5 and y+sy/2>1.1:
            raise AssertionError(f'Blocked path at z={z}: {n["name"]}')
print('PASS XML, rotations, scene references, source parity, and walking corridor')
# Execute the real server source against a minimal Roblox-service test double.
shim=(ROOT/'server_harness.lua').read_text()
check_lua(shim.replace('-- INSERT SERVER SOURCE HERE', (ROOT/'Server.luau').read_text()),'Server behavior harness',execute=True)
with zipfile.ZipFile(P/'StartYourOwnAIBot-V3.zip') as z:
    assert z.testzip() is None
    assert len(z.namelist())==5
print('PASS ZIP CRC and file membership')
