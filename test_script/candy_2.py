import json

with open("env.json", 'r') as file:
    json_object = json.load(file)
    color_palette_id = int(json_object['params'][0])
    shape = int(json_object['params'][1])
    height = int(json_object['params'][2])
    surface = float(json_object['params'][3])
    rendering_path = json_object['rendering_path']

import math

import bpy
import bmesh


def purge_orphans():
    if bpy.app.version >= (3, 0, 0):
        bpy.ops.outliner.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)
    else:
        result = bpy.ops.outliner.orphans_purge()
        if result.pop() != "CANCELLED":
            purge_orphans()


def clean_scene():
    if bpy.context.active_object and bpy.context.active_object.mode == "EDIT":
        bpy.ops.object.editmode_toggle()

    for obj in bpy.data.objects:
        obj.hide_set(False)
        obj.hide_select = False
        obj.hide_viewport = False

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    collection_names = [col.name for col in bpy.data.collections]
    for name in collection_names:
        bpy.data.collections.remove(bpy.data.collections[name])

    world_names = [world.name for world in bpy.data.worlds]
    for name in world_names:
        bpy.data.worlds.remove(bpy.data.worlds[name])
    bpy.ops.world.new()
    bpy.context.scene.world = bpy.data.worlds["World"]

    purge_orphans()


def convert_srgb_to_linear_rgb(srgb_color_component):
    if srgb_color_component <= 0.04045:
        linear_color_component = srgb_color_component / 12.92
    else:
        linear_color_component = math.pow((srgb_color_component + 0.055) / 1.055, 2.4)

    return linear_color_component


def hex_color_to_rgb(hex_color):
    if hex_color.startswith("#"):
        hex_color = hex_color[1:]

    assert len(hex_color) == 6, f"RRGGBB is the supported hex color format: {hex_color}"

    red = int(hex_color[:2], 16)
    srgb_red = red / 255
    linear_red = convert_srgb_to_linear_rgb(srgb_red)

    green = int(hex_color[2:4], 16)
    srgb_green = green / 255
    linear_green = convert_srgb_to_linear_rgb(srgb_green)

    blue = int(hex_color[4:6], 16)
    srgb_blue = blue / 255
    linear_blue = convert_srgb_to_linear_rgb(srgb_blue)

    return tuple([linear_red, linear_green, linear_blue])


def hex_color_to_rgba(hex_color, alpha=1.0):
    linear_red, linear_green, linear_blue = hex_color_to_rgb(hex_color)
    return tuple([linear_red, linear_green, linear_blue, alpha])


def create_reflective_material(color, name=None, roughness=0.1, specular=0.5, return_nodes=False):
    if name is None:
        name = ""

    material = bpy.data.materials.new(name=f"material.reflective.{name}")
    material.use_nodes = True

    material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
    material.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = roughness
    material.node_tree.nodes["Principled BSDF"].inputs["Specular"].default_value = specular

    if return_nodes:
        return material, material.node_tree.nodes
    else:
        return material


def apply_modifiers(obj):
    ctx = bpy.context.copy()
    ctx['object'] = obj
    for _, m in enumerate(obj.modifiers):
        try:
            ctx['modifier'] = m
            bpy.ops.object.modifier_apply(ctx, modifier=m.name)
        except RuntimeError:
            print(f"Error applying {m.name} to {obj.name}, removing it instead.")
            obj.modifiers.remove(m)

    for m in obj.modifiers:
        obj.modifiers.remove(m)


clean_scene()

color_list = ["#E7434F", "#E7973D", "#E7DC4E", "#5CE75D", "#2981E7", "#5D21E7", "#E777E4", "#E7E7E7", "#312624"]
color_name = ''
color_palette_length = 4
color_palette = None
count = 0
for mask in range(2 ** len(color_list)):
    if bin(mask).count("1") == color_palette_length:
        if count == color_palette_id:
            color_palette = []
            for i in range(len(color_list)):
                if (mask >> i) & 1 > 0:
                    color_palette.append(color_list[i])
            break
        else:
            count += 1
if color_palette == None:
    raise Exception("error when find color palette")

file_path = rendering_path + '/result'

fps = 1
loop_seconds = 1
frame_count = fps * loop_seconds
scene = bpy.context.scene
scene.frame_end = frame_count

# set the world background to black
world = bpy.data.worlds["World"]
if "Background" in world.node_tree.nodes:
    world.node_tree.nodes["Background"].inputs[0].default_value = (0, 0, 0, 1)

scene.render.fps = fps

scene.frame_current = 1
scene.frame_start = 1

scene.render.engine = "CYCLES"

scene.cycles.device = 'GPU'

scene.cycles.samples = 50
bpy.context.scene.cycles.time_limit = 5

bpy.context.scene.view_settings.view_transform = 'Standard'

bpy.context.scene.view_settings.look = 'None'

bpy.context.scene.render.resolution_x = 2000
bpy.context.scene.render.resolution_y = 2000

if shape < 4:
    cam_y = -0.8
    cam_z = 0.1
if shape == 4:
    cam_y = -1.4
    cam_z = 0.17
if shape > 4:
    cam_y = -0.8
    cam_z = 0.2

if shape == 1:
    bpy.ops.mesh.primitive_plane_add(size=30, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    CUTS = 0
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
    bpy.ops.mesh.delete(type='ONLY_FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 15 * height)})
    bpy.ops.mesh.merge(type='CENTER')

if shape == 2:
    bpy.ops.mesh.primitive_plane_add(size=20, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    CUTS = 0
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
    bpy.ops.mesh.delete(type='ONLY_FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 10 + height * 3)})

if shape == 3:
    bpy.ops.mesh.primitive_plane_add(size=30, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    CUTS = 1
    bpy.ops.mesh.subdivide(number_cuts=CUTS)
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
    bpy.ops.mesh.delete(type='ONLY_FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 10 * height)})
    bpy.ops.mesh.merge(type='CENTER')

if shape == 4:
    bpy.ops.mesh.primitive_plane_add(size=20, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    CUTS = 1
    bpy.ops.mesh.subdivide(number_cuts=CUTS)
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
    bpy.ops.mesh.delete(type='ONLY_FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 15 * height)})

if shape == 5:
    CUTS = 0
    bpy.ops.mesh.primitive_plane_add(size=20, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    # bpy.ops.mesh.subdivide()
    bpy.ops.mesh.subdivide(number_cuts=CUTS)

if shape == 6:
    CUTS = 0
    bpy.ops.mesh.primitive_plane_add(size=30, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    bpy.ops.mesh.inset(thickness=10, depth=0)
    bpy.ops.mesh.delete(type='FACE')

if shape == 7:
    CUTS = 0
    depth = 10
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=20, radius2=0, depth=depth + height * 10, enter_editmode=True,
                                    align='WORLD', location=(0, 0, 0), rotation=(0, 0, 3.14 / 4), scale=(1, 1, 1))
    bpy.ops.transform.translate(value=(0, 0, (depth + height * 3) / 2))
    bpy.context.object.rotation_euler[2] = 0.349066

bpy.ops.object.editmode_toggle()
bpy.ops.object.shade_smooth()

bpy.ops.object.editmode_toggle()  # enter edit mode
FACES = len(bmesh.from_edit_mesh(bpy.context.active_object.data).faces)

candy = bpy.context.active_object

for i in range(FACES):
    print(i)
    material = create_reflective_material(hex_color_to_rgba(color_palette[i % len(color_palette)], alpha=1),
                                          roughness=surface, specular=0.5, return_nodes=False)
    candy.data.materials.append(material)
    candy.active_material_index = i
    # bpy.ops.object.editmode_toggle()
    bpy.ops.mesh.select_all(action='DESELECT')

    candy_bmesh = bmesh.from_edit_mesh(candy.data)
    candy_bmesh.faces.ensure_lookup_table()
    candy_bmesh.faces[i].select = True
    bmesh.update_edit_mesh(candy.data)
    bpy.ops.object.material_slot_assign()

bpy.ops.object.editmode_toggle()  # exit edit mode

if shape == 2 or shape == 4:
    # Select top vertex

    bpy.ops.object.editmode_toggle()
    bpy.ops.mesh.select_all(action='DESELECT')
    candy_bmesh = bmesh.from_edit_mesh(candy.data)

    for vert in candy_bmesh.verts:
        if vert.co[2] >= 0.1:  # if Z position >= 0.1
            candy_bmesh.verts.ensure_lookup_table()
            candy_bmesh.verts[vert.index].select = True
            bmesh.update_edit_mesh(candy.data)

    # Convert selected vertex to selected edge        
    bpy.ops.object.editmode_toggle()
    bpy.ops.object.editmode_toggle()
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='EDGE')
    # Extrude edges and merge at center
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 5)})
    bpy.ops.mesh.merge(type='CENTER')
    bpy.ops.object.editmode_toggle()

if shape == 2:
    bpy.ops.object.modifier_add(type='MIRROR')
    bpy.context.object.modifiers["Mirror"].use_axis[0] = False
    bpy.context.object.modifiers["Mirror"].use_axis[1] = False
    bpy.context.object.modifiers["Mirror"].use_axis[2] = True
    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_add(type='SIMPLE_DEFORM')
    bpy.context.object.modifiers["SimpleDeform"].deform_method = 'BEND'
    bpy.context.object.modifiers["SimpleDeform"].deform_axis = 'Y'
    bpy.context.object.modifiers["SimpleDeform"].angle = 1.5708
    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision.001"].levels = 2

if shape == 1 or shape == 3 or shape == 4:
    bpy.ops.object.modifier_add(type='MIRROR')
    bpy.context.object.modifiers["Mirror"].use_axis[0] = False
    bpy.context.object.modifiers["Mirror"].use_axis[1] = False
    bpy.context.object.modifiers["Mirror"].use_axis[2] = True

    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision"].levels = 2

    bpy.ops.object.modifier_add(type='SIMPLE_DEFORM')
    bpy.context.object.modifiers["SimpleDeform"].deform_axis = 'Z'
    if shape == 1:
        bpy.context.object.modifiers["SimpleDeform"].angle = 6.28319 * 0
    if shape == 3:
        bpy.context.object.modifiers["SimpleDeform"].angle = 6.28319 * 0.2
    if shape == 2:
        bpy.context.object.modifiers["SimpleDeform"].angle = 6.28319 * 0
    if shape == 4:
        bpy.context.object.modifiers["SimpleDeform"].angle = 6.28319 * 1

    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision.001"].levels = 2

if shape == 5:
    bpy.ops.object.modifier_add(type='SOLIDIFY')
    bpy.context.object.modifiers["Solidify"].thickness = -10 * height
    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision"].levels = 3
    bpy.context.object.rotation_euler[0] = 0.785398

if shape == 6:
    bpy.ops.object.editmode_toggle()  # enter
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 1)})
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 6 * height)})
    bpy.ops.object.editmode_toggle()  # exit
    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision"].levels = 3
    bpy.context.object.rotation_euler[0] = 0.785398

if shape == 7:
    bpy.ops.object.modifier_add(type='BEVEL')
    bpy.context.object.modifiers["Bevel"].width = 1.5
    bpy.context.object.modifiers["Bevel"].segments = 8

apply_modifiers(candy)

bpy.ops.transform.resize(value=(0.01, 0.01, 0.01))
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

bpy.ops.export_scene.gltf(filepath=file_path, check_existing=True, export_format='GLB')

bpy.ops.object.light_add(type='SUN', radius=1, align='WORLD', location=(0, 0, 0),
                         rotation=(0, 40 * 3.14 / 180, -40 * 3.14 / 180), scale=(1, 1, 1))
bpy.context.object.data.angle = 0.523599
bpy.context.object.data.energy = 3

bpy.ops.object.light_add(type="AREA", radius=50, location=(0, 0, 50))
bpy.context.object.data.energy = 10000

bpy.ops.object.camera_add(enter_editmode=False, align='VIEW', location=(0, cam_y, cam_z),
                          rotation=(83 * 3.14 / 180, 0, 0), scale=(1, 1, 1))
bpy.context.object.data.lens = 40
bpy.context.scene.camera = bpy.context.scene.objects.get('Camera')

bpy.ops.mesh.primitive_plane_add(size=3, enter_editmode=False, align='WORLD', location=(0, 0, -0.5), scale=(1, 1, 1))
backdrop = bpy.context.active_object

bpy.ops.object.editmode_toggle()  # enter
bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
bpy.ops.mesh.select_all(action='DESELECT')
backdrop_bmesh = bmesh.from_edit_mesh(backdrop.data)

for vert in backdrop_bmesh.verts:
    if vert.co[1] >= 0.1:  # if Z position >= 0.1
        backdrop_bmesh.verts.ensure_lookup_table()
        backdrop_bmesh.verts[vert.index].select = True
        bmesh.update_edit_mesh(backdrop.data)

bpy.ops.object.editmode_toggle()  # exit
bpy.ops.object.editmode_toggle()  # enter    
# bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='EDGE')
bpy.ops.mesh.extrude_region_move(
    MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
    TRANSFORM_OT_translate={"value": (0, 0, 2)})
bpy.ops.object.editmode_toggle()  # exit
bpy.ops.object.modifier_add(type='BEVEL')
bpy.context.object.modifiers["Bevel"].width = 1
bpy.context.object.modifiers["Bevel"].segments = 10
bpy.ops.object.shade_smooth()

material = create_reflective_material(hex_color_to_rgba(color_palette[0], alpha=1.0), roughness=0.5, specular=0.5,
                                      return_nodes=False)
backdrop.data.materials.append(material)

bpy.context.scene.render.filepath = file_path

bpy.context.scene.render.image_settings.file_format = 'JPEG'

bpy.ops.render.render(animation=False, write_still=True, use_viewport=False, layer='', scene='')
