# Run using blender --background --python render.py. This previews exported geometry, not the Roblox engine.
import bpy, math, xml.etree.ElementTree as ET
from mathutils import Matrix, Vector
from pathlib import Path
P=Path('/workspace/artifacts')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
root=ET.parse(P/'StartYourOwnClothingCompany-V4.rbxlx').getroot()
materials={}
def material(packed):
    if packed in materials:return materials[packed]
    rgb=[((packed>>s)&255)/255 for s in [16,8,0]]
    rgb=[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb]
    m=bpy.data.materials.new(str(packed));m.diffuse_color=(*rgb,1);m.use_nodes=True
    bsdf=m.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*rgb,1);bsdf.inputs['Roughness'].default_value=.7
    materials[packed]=m;return m
bpy.ops.mesh.primitive_cube_add(size=2);cube=bpy.context.object.data;bpy.data.objects.remove(bpy.context.object,do_unlink=True)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10);ball=bpy.context.object.data;bpy.data.objects.remove(bpy.context.object,do_unlink=True)
for f in ball.polygons:f.use_smooth=True
bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=1,depth=2);cyl=bpy.context.object.data;bpy.data.objects.remove(bpy.context.object,do_unlink=True)
for v in cyl.vertices:v.co=Vector((v.co.z,v.co.x,v.co.y))
for mesh in [cube,ball,cyl]:mesh.materials.append(material(0xffcccccc))
T=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
count=0
for item in root.findall('.//Item'):
    if item.get('class') not in ['Part','SpawnLocation']:continue
    p=item.find('Properties');trans=float(p.find('./float[@name="Transparency"]').text)
    if trans>=.99:continue
    name=p.find('./string[@name="Name"]').text
    cf=p.find('CoordinateFrame');size=p.find('./Vector3[@name="size"]')
    sz=[float(size.find(k).text) for k in ['X','Y','Z']]
    m=Matrix([[float(cf.find('R'+str(i)+str(j)).text) for j in range(3)]+[float(cf.find(['X','Y','Z'][i]).text)] for i in range(3)]+[[0,0,0,1]])
    shape=int(p.find('./token[@name="shape"]').text)
    o=bpy.data.objects.new(name,{0:ball,1:cube,2:cyl}[shape]);bpy.context.collection.objects.link(o)
    o.matrix_world=T@m@Matrix.Diagonal(Vector((sz[0]/2,sz[1]/2,sz[2]/2,1)))
    o.material_slots[0].link='OBJECT';o.material_slots[0].material=material(int(p.find('Color3uint8').text))
    count+=1
world=bpy.context.scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.75,.82,1);world.node_tree.nodes['Background'].inputs[1].default_value=.65
bpy.ops.object.light_add(type='SUN',location=(100,-100,200));sun=bpy.context.object;sun.rotation_euler=(math.radians(25),math.radians(-20),math.radians(-28));sun.data.energy=2.8;sun.data.angle=.12
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False
scene.render.resolution_x=1500;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera
camera.data.type='ORTHO';camera.data.ortho_scale=610
camera.location=(T@Vector((320,300,-350,1))).to_3d();target=T@Vector((0,0,10,1));camera.rotation_euler=(target.to_3d()-camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(P/'City-Geometry-Preview.png');bpy.ops.render.render(write_still=True)
camera.data.type='PERSP';camera.data.lens=25
camera.location=(T@Vector((14,12,7,1))).to_3d();target=(T@Vector((0,5,48,1))).to_3d();camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1280;scene.render.resolution_y=850;scene.render.filepath=str(P/'Warehouse-Geometry-Preview.png');bpy.ops.render.render(write_still=True)
print('Previewed',count,'exported parts with corrected Roblox shape values')
