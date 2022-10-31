AH='BEVEL'
AG='Subdivision.001'
AF='SIMPLE_DEFORM'
AE='MIRROR'
AD='Background'
AC='World'
AB=print
AA=tuple
y='DESELECT'
x='CENTER'
w=range
m='Bevel'
l='Subdivision'
k='ONLY_FACE'
j=''
i=None
h='params'
Z='VERT'
Y=len
X='SUBSURF'
W='Mirror'
V='SELECT'
U=int
P='SimpleDeform'
O='value'
N='mirror'
M='use_dissolve_ortho_edges'
L='use_normal_flip'
G='WORLD'
D=True
B=False
import json
with open('env.json','r')as z:S=json.load(z);A0=U(S[h][0]);C=U(S[h][1]);F=U(S[h][2]);A1=float(S[h][3]);A2=S['rendering_path']
import math,bpy as A,bmesh as H
def n():
    if A.app.version>=(3,0,0):A.ops.outliner.orphans_purge(do_local_ids=D,do_linked_ids=D,do_recursive=D)
    else:
        B=A.ops.outliner.orphans_purge()
        if B.pop()!='CANCELLED':n()
def A3():
    if A.context.active_object and A.context.active_object.mode=='EDIT':A.ops.object.editmode_toggle()
    for C in A.data.objects:C.hide_set(B);C.hide_select=B;C.hide_viewport=B
    A.ops.object.select_all(action=V);A.ops.object.delete();E=[B.name for B in A.data.collections]
    for D in E:A.data.collections.remove(A.data.collections[D])
    F=[B.name for B in A.data.worlds]
    for D in F:A.data.worlds.remove(A.data.worlds[D])
    A.ops.world.new();A.context.scene.world=A.data.worlds[AC];n()
def a(srgb_color_component):
    A=srgb_color_component
    if A<=0.04045:B=A/12.92
    else:B=math.pow((A+0.055)/1.055,2.4)
    return B
def A4(hex_color):
    A=hex_color
    if A.startswith('#'):A=A[1:]
    assert Y(A)==6,f"RRGGBB is the supported hex color format: {A}";B=U(A[:2],16);C=B/255;D=a(C);E=U(A[2:4],16);F=E/255;G=a(F);H=U(A[4:6],16);I=H/255;J=a(I);return AA([D,G,J])
def o(hex_color,alpha=1.0):A,B,C=A4(hex_color);return AA([A,B,C,alpha])
def p(color,name=i,roughness=0.1,specular=0.5,return_nodes=B):
    E='Principled BSDF';C=name
    if C is i:C=j
    B=A.data.materials.new(name=f"material.reflective.{C}");B.use_nodes=D;B.node_tree.nodes[E].inputs['Base Color'].default_value=color;B.node_tree.nodes[E].inputs['Roughness'].default_value=roughness;B.node_tree.nodes[E].inputs['Specular'].default_value=specular
    if return_nodes:return B,B.node_tree.nodes
    else:return B
def A5(obj):
    B=obj;D=A.context.copy();D['object']=B
    for (E,C) in enumerate(B.modifiers):
        try:D['modifier']=C;A.ops.object.modifier_apply(D,modifier=C.name)
        except RuntimeError:AB(f"Error applying {C.name} to {B.name}, removing it instead.");B.modifiers.remove(C)
    for C in B.modifiers:B.modifiers.remove(C)
A3()
b=['#E7434F','#E7973D','#E7DC4E','#5CE75D','#2981E7','#5D21E7','#E777E4','#E7E7E7','#312624','#E7969F','#E7B277','#E7DD8F','#8CE7C3','#87B2E7','#A082E7','#E4B7E7']
AI=j
A6=4
Q=i
q=0
for r in w(2**Y(b)):
    if bin(r).count('1')==A6:
        if q==A0:
            Q=[]
            for I in w(Y(b)):
                if r>>I&1>0:Q.append(b[I])
            break
        else:q+=1
if Q==i:raise Exception('error when find color palette')
s=A2+'/result'
t=1
A7=1
A8=t*A7
J=A.context.scene
J.frame_end=A8
u=A.data.worlds[AC]
if AD in u.node_tree.nodes:u.node_tree.nodes[AD].inputs[0].default_value=0,0,0,1
J.render.fps=t
J.frame_current=1
J.frame_start=1
J.render.engine='CYCLES'
J.cycles.device='GPU'
J.cycles.samples=50
A.context.scene.cycles.time_limit=5
A.context.scene.view_settings.view_transform='Standard'
A.context.scene.view_settings.look='None'
A.context.scene.render.resolution_x=2000
A.context.scene.render.resolution_y=2000
if C<4:c=-0.8;d=0.1
if C==4:c=-1.4;d=0.17
if C>4:c=-0.8;d=0.2
if C==1:A.ops.mesh.primitive_plane_add(size=30,enter_editmode=D,align=G,location=(0,0,0),scale=(1,1,1));E=0;A.ops.mesh.select_mode(use_extend=B,use_expand=B,type=Z);A.ops.mesh.delete(type=k);A.ops.mesh.select_all(action=V);A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,15*F)});A.ops.mesh.merge(type=x)
if C==2:A.ops.mesh.primitive_plane_add(size=20,enter_editmode=D,align=G,location=(0,0,0),scale=(1,1,1));E=0;A.ops.mesh.select_mode(use_extend=B,use_expand=B,type=Z);A.ops.mesh.delete(type=k);A.ops.mesh.select_all(action=V);A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,10+F*3)})
if C==3:A.ops.mesh.primitive_plane_add(size=30,enter_editmode=D,align=G,location=(0,0,0),scale=(1,1,1));E=1;A.ops.mesh.subdivide(number_cuts=E);A.ops.mesh.select_mode(use_extend=B,use_expand=B,type=Z);A.ops.mesh.delete(type=k);A.ops.mesh.select_all(action=V);A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,10*F)});A.ops.mesh.merge(type=x)
if C==4:A.ops.mesh.primitive_plane_add(size=20,enter_editmode=D,align=G,location=(0,0,0),scale=(1,1,1));E=1;A.ops.mesh.subdivide(number_cuts=E);A.ops.mesh.select_mode(use_extend=B,use_expand=B,type=Z);A.ops.mesh.delete(type=k);A.ops.mesh.select_all(action=V);A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,15*F)})
if C==5:E=0;A.ops.mesh.primitive_plane_add(size=20,enter_editmode=D,align=G,location=(0,0,0),scale=(1,1,1));A.ops.mesh.subdivide(number_cuts=E)
if C==6:E=0;A.ops.mesh.primitive_plane_add(size=30,enter_editmode=D,align=G,location=(0,0,0),scale=(1,1,1));A.ops.mesh.inset(thickness=10,depth=0);A.ops.mesh.delete(type='FACE')
if C==7:E=0;v=10;A.ops.mesh.primitive_cone_add(vertices=4,radius1=20,radius2=0,depth=v+F*10,enter_editmode=D,align=G,location=(0,0,0),rotation=(0,0,3.14/4),scale=(1,1,1));A.ops.transform.translate(value=(0,0,(v+F*3)/2));A.context.object.rotation_euler[2]=0.349066
A.ops.object.editmode_toggle()
A.ops.object.shade_smooth()
A.ops.object.editmode_toggle()
A9=Y(H.from_edit_mesh(A.context.active_object.data).faces)
K=A.context.active_object
for I in w(A9):AB(I);e=p(o(Q[I%Y(Q)],alpha=1),roughness=A1,specular=0.5,return_nodes=B);K.data.materials.append(e);K.active_material_index=I;A.ops.mesh.select_all(action=y);R=H.from_edit_mesh(K.data);R.faces.ensure_lookup_table();R.faces[I].select=D;H.update_edit_mesh(K.data);A.ops.object.material_slot_assign()
A.ops.object.editmode_toggle()
if C==2 or C==4:
    A.ops.object.editmode_toggle();A.ops.mesh.select_all(action=y);R=H.from_edit_mesh(K.data)
    for T in R.verts:
        if T.co[2]>=0.1:R.verts.ensure_lookup_table();R.verts[T.index].select=D;H.update_edit_mesh(K.data)
    A.ops.object.editmode_toggle();A.ops.object.editmode_toggle();A.ops.mesh.select_mode(use_extend=B,use_expand=B,type='EDGE');A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,5)});A.ops.mesh.merge(type=x);A.ops.object.editmode_toggle()
if C==2:A.ops.object.modifier_add(type=AE);A.context.object.modifiers[W].use_axis[0]=B;A.context.object.modifiers[W].use_axis[1]=B;A.context.object.modifiers[W].use_axis[2]=D;A.ops.object.modifier_add(type=X);A.context.object.modifiers[l].levels=2;A.ops.object.modifier_add(type=AF);A.context.object.modifiers[P].deform_method='BEND';A.context.object.modifiers[P].deform_axis='Y';A.context.object.modifiers[P].angle=1.5708;A.ops.object.modifier_add(type=X);A.context.object.modifiers[AG].levels=2
if C==1 or C==3 or C==4:
    A.ops.object.modifier_add(type=AE);A.context.object.modifiers[W].use_axis[0]=B;A.context.object.modifiers[W].use_axis[1]=B;A.context.object.modifiers[W].use_axis[2]=D;A.ops.object.modifier_add(type=X);A.context.object.modifiers[l].levels=2;A.ops.object.modifier_add(type=AF);A.context.object.modifiers[P].deform_axis='Z'
    if C==1:A.context.object.modifiers[P].angle=6.28319*0
    if C==3:A.context.object.modifiers[P].angle=6.28319*0.2
    if C==2:A.context.object.modifiers[P].angle=6.28319*0
    if C==4:A.context.object.modifiers[P].angle=6.28319*1
    A.ops.object.modifier_add(type=X);A.context.object.modifiers[AG].levels=2
if C==5:A.ops.object.modifier_add(type='SOLIDIFY');A.context.object.modifiers['Solidify'].thickness=-10*F;A.ops.object.modifier_add(type=X);A.context.object.modifiers[l].levels=3;A.context.object.rotation_euler[0]=0.785398
if C==6:A.ops.object.editmode_toggle();A.ops.mesh.select_all(action=V);A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,1)});A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,6*F)});A.ops.object.editmode_toggle();A.ops.object.modifier_add(type=X);A.context.object.modifiers[l].levels=3;A.context.object.rotation_euler[0]=0.785398
if C==7:A.ops.object.modifier_add(type=AH);A.context.object.modifiers[m].width=1.5;A.context.object.modifiers[m].segments=8
A5(K)
A.ops.transform.resize(value=(0.01,0.01,0.01))
A.ops.object.transform_apply(location=B,rotation=B,scale=D)
A.ops.export_scene.gltf(filepath=s,check_existing=D,export_format='GLB')
A.ops.object.light_add(type='SUN',radius=1,align=G,location=(0,0,0),rotation=(0,40*3.14/180,-40*3.14/180),scale=(1,1,1))
A.context.object.data.angle=0.523599
A.context.object.data.energy=3
A.ops.object.light_add(type='AREA',radius=50,location=(0,0,50))
A.context.object.data.energy=10000
A.ops.object.camera_add(enter_editmode=B,align='VIEW',location=(0,c,d),rotation=(83*3.14/180,0,0),scale=(1,1,1))
A.context.object.data.lens=40
A.context.scene.camera=A.context.scene.objects.get('Camera')
A.ops.mesh.primitive_plane_add(size=3,enter_editmode=B,align=G,location=(0,0,-0.5),scale=(1,1,1))
f=A.context.active_object
A.ops.object.editmode_toggle()
A.ops.mesh.select_mode(use_extend=B,use_expand=B,type=Z)
A.ops.mesh.select_all(action=y)
g=H.from_edit_mesh(f.data)
for T in g.verts:
    if T.co[1]>=0.1:g.verts.ensure_lookup_table();g.verts[T.index].select=D;H.update_edit_mesh(f.data)
A.ops.object.editmode_toggle()
A.ops.object.editmode_toggle()
A.ops.mesh.extrude_region_move(MESH_OT_extrude_region={L:B,M:B,N:B},TRANSFORM_OT_translate={O:(0,0,2)})
A.ops.object.editmode_toggle()
A.ops.object.modifier_add(type=AH)
A.context.object.modifiers[m].width=1
A.context.object.modifiers[m].segments=10
A.ops.object.shade_smooth()
e=p(o(Q[0],alpha=1.0),roughness=0.5,specular=0.5,return_nodes=B)
f.data.materials.append(e)
A.context.scene.render.filepath=s
A.context.scene.render.image_settings.file_format='JPEG'
A.ops.render.render(animation=B,write_still=D,use_viewport=B,layer=j,scene=j)