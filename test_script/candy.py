import math
import bpy
import bmesh
import json

# Params variable
with open("env.json", 'r') as file:
    json_object = json.load(file)
    color_list = json_object['params'][0].split(',')
    shape = int(json_object['params'][1])
    height = int(json_object['params'][2])
    surface = float(json_object['params'][3])
    rendering_path = json_object['rendering_path']


def purge_orphans():
    """
    Remove all orphan data blocks

    see this from more info:
    https://youtu.be/3rNqVPtbhzc?t=149
    """
    if bpy.app.version >= (3, 0, 0):
        # run this only for Blender versions 3.0 and higher
        bpy.ops.outliner.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)
    else:
        # run this only for Blender versions lower than 3.0
        # call purge_orphans() recursively until there are no more orphan data blocks to purge
        result = bpy.ops.outliner.orphans_purge()
        if result.pop() != "CANCELLED":
            purge_orphans()


def clean_scene():
    """
    Removing all of the objects, collection, materials, particles,
    textures, images, curves, meshes, actions, nodes, and worlds from the scene

    Checkout this video explanation with example

    "How to clean the scene with Python in Blender (with examples)"
    https://youtu.be/3rNqVPtbhzc
    """
    # make sure the active object is not in Edit Mode
    if bpy.context.active_object and bpy.context.active_object.mode == "EDIT":
        bpy.ops.object.editmode_toggle()

    # make sure non of the objects are hidden from the viewport, selection, or disabled
    for obj in bpy.data.objects:
        obj.hide_set(False)
        obj.hide_select = False
        obj.hide_viewport = False

    # select all the object and delete them (just like pressing A + X + D in the viewport)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    # find all the collections and remove them
    collection_names = [col.name for col in bpy.data.collections]
    for name in collection_names:
        bpy.data.collections.remove(bpy.data.collections[name])

    # in the case when you modify the world shader
    # delete and recreate the world object
    world_names = [world.name for world in bpy.data.worlds]
    for name in world_names:
        bpy.data.worlds.remove(bpy.data.worlds[name])
    # create a new world data block
    bpy.ops.world.new()
    bpy.context.scene.world = bpy.data.worlds["World"]

    purge_orphans()


def convert_srgb_to_linear_rgb(srgb_color_component):
    """
    Converting from sRGB to Linear RGB
    based on https://en.wikipedia.org/wiki/SRGB#From_sRGB_to_CIE_XYZ

    Video Tutorial: https://www.youtube.com/watch?v=knc1CGBhJeU
    """
    if srgb_color_component <= 0.04045:
        linear_color_component = srgb_color_component / 12.92
    else:
        linear_color_component = math.pow((srgb_color_component + 0.055) / 1.055, 2.4)

    return linear_color_component


def hex_color_to_rgb(hex_color):
    """
    Converting from a color in the form of a hex triplet string (en.wikipedia.org/wiki/Web_colors#Hex_triplet)
    to a Linear RGB

    Supports: "#RRGGBB" or "RRGGBB"

    Note: We are converting into Linear RGB since Blender uses a Linear Color Space internally
    https://docs.blender.org/manual/en/latest/render/color_management.html

    Video Tutorial: https://www.youtube.com/watch?v=knc1CGBhJeU
    """
    # remove the leading '#' symbol if present
    if hex_color.startswith("#"):
        hex_color = hex_color[1:]

    assert len(hex_color) == 6, f"RRGGBB is the supported hex color format: {hex_color}"

    # extracting the Red color component - RRxxxx
    red = int(hex_color[:2], 16)
    # dividing by 255 to get a number between 0.0 and 1.0
    srgb_red = red / 255
    linear_red = convert_srgb_to_linear_rgb(srgb_red)

    # extracting the Green color component - xxGGxx
    green = int(hex_color[2:4], 16)
    # dividing by 255 to get a number between 0.0 and 1.0
    srgb_green = green / 255
    linear_green = convert_srgb_to_linear_rgb(srgb_green)

    # extracting the Blue color component - xxxxBB
    blue = int(hex_color[4:6], 16)
    # dividing by 255 to get a number between 0.0 and 1.0
    srgb_blue = blue / 255
    linear_blue = convert_srgb_to_linear_rgb(srgb_blue)

    return tuple([linear_red, linear_green, linear_blue])


def hex_color_to_rgba(hex_color, alpha=1.0):
    """
    Converting from a color in the form of a hex triplet string (en.wikipedia.org/wiki/Web_colors#Hex_triplet)
    to a Linear RGB with an Alpha passed as a parameter

    Supports: "#RRGGBB" or "RRGGBB"

    Video Tutorial: https://www.youtube.com/watch?v=knc1CGBhJeU
    """
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


# --------------------------------------

clean_scene()

filepath = rendering_path
filename = 'model' + '_shape' + str(shape) + '_height' + str(height) + '_surface' + str(surface)
render = 1
"""
Set scene properties
"""
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

# Use the GPU to render
scene.cycles.device = 'GPU'

# Use the CPU to render
# scene.cycles.device = "CPU"

scene.cycles.samples = 50
bpy.context.scene.cycles.time_limit = 7

bpy.context.scene.view_settings.view_transform = 'Standard'

bpy.context.scene.view_settings.look = 'Medium High Contrast'

bpy.context.scene.render.resolution_x = 2000
bpy.context.scene.render.resolution_y = 2000
# --------------------------------------

# create shape 1
if shape == 1:
    # create cone without bottom
    bpy.ops.mesh.primitive_plane_add(size=30, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    CUTS = 0
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
    bpy.ops.mesh.delete(type='ONLY_FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 15 * height)})
    bpy.ops.mesh.merge(type='CENTER')

# create shape 2 - part 1
if shape == 2:
    # create cube without top and bottom
    bpy.ops.mesh.primitive_plane_add(size=20, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    CUTS = 0
    #    if CUTS >>0:
    #        bpy.ops.mesh.subdivide(number_cuts=CUTS)
    bpy.ops.mesh.select_mode(use_extend=False, use_expand=False, type='VERT')
    bpy.ops.mesh.delete(type='ONLY_FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 10 * height)})

if shape == 3:
    # create cone without bottom
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
    # create cube without top and bottom
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
    # create plane with 4 square
    bpy.ops.mesh.primitive_plane_add(size=20, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    # bpy.ops.mesh.subdivide()
    bpy.ops.mesh.subdivide(number_cuts=CUTS)

if shape == 6:
    CUTS = 0
    bpy.ops.mesh.primitive_plane_add(size=20, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
    bpy.ops.mesh.inset(thickness=5, depth=0)
    bpy.ops.mesh.delete(type='FACE')

if shape == 7:
    CUTS = 0
    depth = 10
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=10, radius2=0, depth=depth + height * 3, enter_editmode=True,
                                    align='WORLD', location=(0, 0, 0), rotation=(0, 0, 3.14 / 4), scale=(1, 1, 1))
    bpy.ops.transform.translate(value=(0, 0, (depth + height * 3) / 2))

bpy.ops.object.editmode_toggle()
bpy.ops.object.shade_smooth()

bpy.ops.object.editmode_toggle()  # enter edit mode
FACES = len(bmesh.from_edit_mesh(bpy.context.active_object.data).faces)

candy = bpy.context.active_object

# Assign Materials for each face
for i in range(FACES):
    print(i)
    material = create_reflective_material(hex_color_to_rgba(color_list[i % len(color_list)], alpha=1),
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

# create shape 2 - part 2
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

    # mirror shape
    bpy.ops.object.modifier_add(type='MIRROR')
    bpy.context.object.modifiers["Mirror"].use_axis[0] = False
    bpy.context.object.modifiers["Mirror"].use_axis[1] = False
    bpy.context.object.modifiers["Mirror"].use_axis[2] = True

    # candy shape making
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

if shape == 6:
    bpy.ops.object.editmode_toggle()  # enter
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 1)})
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 4 * height)})
    bpy.ops.object.editmode_toggle()  # exit
    bpy.ops.object.modifier_add(type='SUBSURF')
    bpy.context.object.modifiers["Subdivision"].levels = 3

if shape == 7:
    bpy.ops.object.modifier_add(type='BEVEL')
    bpy.context.object.modifiers["Bevel"].width = 1.5
    bpy.context.object.modifiers["Bevel"].segments = 8

# Apply modifier
apply_modifiers(candy)

# Delete underneath verts
if shape == 1 or shape == 2 or shape == 3 or shape == 4:
    bpy.ops.object.editmode_toggle()  # enter edit mode
    bpy.ops.mesh.select_all(action='DESELECT')
    candy_bmesh = bmesh.from_edit_mesh(candy.data)

    for vert in candy_bmesh.verts:
        if vert.co[2] < -0.1:  # if Z position < -0.1
            candy_bmesh.verts.ensure_lookup_table()
            candy_bmesh.verts[vert.index].select = True
            bmesh.update_edit_mesh(candy.data)

    bpy.ops.mesh.delete(type='VERT')

    bpy.ops.object.editmode_toggle()  # exit edit mode

bpy.ops.object.modifier_add(type='SOLIDIFY')
bpy.context.object.modifiers["Solidify"].thickness = 0.1
bpy.context.object.data.use_auto_smooth = True

##create door
if shape == 1 or shape == 2:
    bpy.ops.mesh.primitive_cube_add(size=1, enter_editmode=False, align='WORLD', location=(0, -9, 0), scale=(2, 6, 4))
if shape == 3 or shape == 4:
    bpy.ops.mesh.primitive_cube_add(size=1, enter_editmode=False, align='WORLD', location=(5, -9, 0), scale=(2, 6, 4))
if shape == 5 or shape == 6 or shape == 7:
    bpy.ops.mesh.primitive_cube_add(size=1, enter_editmode=False, align='WORLD', location=(0, -7, 0), scale=(2, 8, 6))
door = bpy.context.active_object

bpy.context.view_layer.objects.active = candy
bpy.ops.object.modifier_add(type='BOOLEAN')
bpy.context.object.modifiers["Boolean"].solver = 'FAST'

bpy.context.object.modifiers["Boolean"].object = bpy.data.objects["Cube"]

apply_modifiers(candy)

bpy.context.view_layer.objects.active = door
bpy.ops.object.delete(use_global=False)

##create room door
if CUTS == 1:
    bpy.ops.mesh.primitive_plane_add(size=8, enter_editmode=False, align='WORLD', location=(0, 0, 0.1), scale=(1, 1, 1))
    door_room = bpy.context.active_object

    bpy.ops.object.editmode_toggle()  # enter edit mode
    bpy.ops.mesh.inset(thickness=1.5, depth=0)
    bpy.ops.mesh.delete(type='FACE')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.extrude_region_move(
        MESH_OT_extrude_region={"use_normal_flip": False, "use_dissolve_ortho_edges": False, "mirror": False},
        TRANSFORM_OT_translate={"value": (0, 0, 2)})
    bpy.ops.object.editmode_toggle()  # exit edit mode

    bpy.context.view_layer.objects.active = candy
    bpy.ops.object.modifier_add(type='BOOLEAN')
    # bpy.context.object.modifiers["Boolean.001"].solver = 'FAST'

    bpy.context.object.modifiers["Boolean"].object = bpy.data.objects["Plane.001"]

    apply_modifiers(candy)

    bpy.context.view_layer.objects.active = door_room
    bpy.ops.object.delete(use_global=False)

## add ground
bpy.ops.mesh.primitive_circle_add(radius=15, enter_editmode=True, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))
bpy.ops.mesh.edge_face_add()
bpy.ops.object.editmode_toggle()  # exit
ground = bpy.context.active_object
material = create_reflective_material(hex_color_to_rgba('#C3C3C3', alpha=1.0), roughness=0.5, specular=0.5,
                                      return_nodes=False)
ground.data.materials.append(material)

# export to GLB

bpy.ops.export_scene.gltf(filepath=filepath + '/' + filename, check_existing=True, export_format='GLB')

# add light
bpy.ops.object.light_add(type='SUN', radius=1, align='WORLD', location=(0, 0, 0),
                         rotation=(0, 40 * 3.14 / 180, -40 * 3.14 / 180), scale=(1, 1, 1))
bpy.context.object.data.angle = 0.523599
bpy.context.object.visible_glossy = False
bpy.context.object.data.energy = 3

bpy.ops.object.light_add(type="AREA", radius=50, location=(0, 0, 50))
bpy.context.object.data.energy = 10000

# create camera
if shape <= 4:
    if height <= 1:
        cam_y = -45
        cam_z = 13
    if height == 2:
        cam_y = -55
        cam_z = 22
    if height >= 3:
        cam_y = -72
        cam_z = 32
if shape > 4:
    if height <= 1:
        cam_y = -45
        cam_z = 13
    if height == 2:
        cam_y = -45
        cam_z = 13
    if height >= 3:
        cam_y = -55
        cam_z = 22

bpy.ops.object.camera_add(enter_editmode=False, align='VIEW', location=(0, cam_y, cam_z),
                          rotation=(83 * 3.14 / 180, 0, 0), scale=(1, 1, 1))
bpy.context.object.data.lens = 40
bpy.context.scene.camera = bpy.context.scene.objects.get('Camera')

# create backdrop
bpy.ops.mesh.primitive_plane_add(size=300, enter_editmode=False, align='WORLD', location=(0, -80, -0.1),
                                 scale=(1, 1, 1))
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
    TRANSFORM_OT_translate={"value": (0, 0, 200)})
bpy.ops.object.editmode_toggle()  # exit
bpy.ops.object.modifier_add(type='BEVEL')
bpy.context.object.modifiers["Bevel"].width = 30
bpy.context.object.modifiers["Bevel"].segments = 10
bpy.ops.object.shade_smooth()

material = create_reflective_material(hex_color_to_rgba(color_list[0], alpha=1.0), roughness=0.5, specular=0.5,
                                      return_nodes=False)
backdrop.data.materials.append(material)

# set_1080px_square_render_res()

# render
bpy.context.scene.render.image_settings.file_format = 'JPEG'
bpy.context.scene.render.filepath = filepath + '/' + filename
if render == 1:
    bpy.ops.render.render(animation=False, write_still=True, use_viewport=False, layer='', scene='')
