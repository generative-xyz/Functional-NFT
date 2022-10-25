import bpy
import bmesh
import numpy as np
import scipy.spatial as spatial
from mathutils import Vector, Matrix
# import utils
import os

from dotenv import load_dotenv
from pathlib import Path

dotenv_path = Path('.env')
load_dotenv(dotenv_path=dotenv_path)

RENDER_FOLDER = os.getenv('RENDER_FOLDER')
R = int(os.getenv('PARAM_0'))
N = int(os.getenv('PARAM_1'))


def remove_object(obj):
    if obj.type == 'MESH':
        if obj.data.name in bpy.data.meshes:
            bpy.data.meshes.remove(obj.data)
        if obj.name in bpy.context.scene.objects:
            bpy.context.scene.objects.unlink(obj)
        bpy.data.objects.remove(obj)
    else:
        raise NotImplementedError('Other types not implemented yet besides \'MESH\'')


def track_to_constraint(obj, target):
    constraint = obj.constraints.new('TRACK_TO')
    constraint.target = target
    constraint.track_axis = 'TRACK_NEGATIVE_Z'
    # constraint.track_axis = 'TRACK_Z'
    constraint.up_axis = 'UP_Y'
    # constraint.owner_space = 'LOCAL'
    # constraint.target_space = 'LOCAL'

    return constraint


def create_target(origin=(0, 0, 0)):
    target = bpy.data.objects.new('Target', None)
    bpy.context.collection.objects.link(target)
    target.location = origin
    return target


def create_camera(origin, target=None, lens=35, clip_start=0.1, clip_end=200, type='PERSP', ortho_scale=6):
    # Create object and camera
    camera = bpy.data.cameras.new("Camera")
    camera.lens = lens
    camera.clip_start = clip_start
    camera.clip_end = clip_end
    camera.type = type  # 'PERSP', 'ORTHO', 'PANO'
    if type == 'ORTHO':
        camera.ortho_scale = ortho_scale

    # Link object to scene
    obj = bpy.data.objects.new("CameraObj", camera)
    obj.location = origin
    bpy.context.collection.objects.link(obj)
    bpy.context.scene.camera = obj  # Make this the current camera

    if target:
        track_to_constraint(obj, target)
    return obj


def create_light(origin, type='POINT', energy=1, color=(1, 1, 1), target=None):
    # Light types: 'POINT', 'SUN', 'SPOT', 'HEMI', 'AREA'
    bpy.ops.object.add(type='LIGHT', location=origin)
    obj = bpy.context.object
    obj.data.type = type
    obj.data.energy = energy
    obj.data.color = color

    if target:
        track_to_constraint(obj, target)
    return obj


def simple_scene(target_coords, camera_coords, sun_coords, lens=35):
    target = create_target(target_coords)
    camera = create_camera(camera_coords, target, lens)
    sun = create_light(sun_coords, 'SUN', target=target)

    return target, camera, sun


def set_smooth(obj, level=None, smooth=True):
    if level:
        # Add subsurf modifier
        modifier = obj.modifiers.new('Subsurf', 'SUBSURF')
        modifier.levels = level
        modifier.render_levels = level

    # Smooth surface
    mesh = obj.data
    for p in mesh.polygons:
        p.use_smooth = smooth


def rainbow_lights(r=5, n=100, freq=2, energy=0.1):
    for i in range(n):
        t = float(i) / float(n)
        pos = (r * sin(TAU * t), r * cos(TAU * t), r * sin(freq * TAU * t))

        # Create lamp
        bpy.ops.object.add(type='LIGHT', location=pos)
        obj = bpy.context.object
        obj.data.type = 'POINT'

        # Apply gamma correction for Blender
        color = tuple(pow(c, 2.2) for c in colorsys.hsv_to_rgb(t, 0.6, 1))

        # Set HSV color and lamp energy
        obj.data.color = color
        obj.data.energy = energy


def remove_all(type=None):
    # Possible type:
    # "MESH", "CURVE", "SURFACE", "META", "FONT", "ARMATURE",
    # "LATTICE", "EMPTY", "CAMERA", "LIGHT"
    if type:
        bpy.ops.object.select_all(action='DESELECT')
        bpy.ops.object.select_by_type(type=type)
        bpy.ops.object.delete()
    else:
        # Remove all elements in scene
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)


def create_material(base_color=(1, 1, 1, 1), metalic=0.0, roughness=0.5):
    mat = bpy.data.materials.new('Material')

    if len(base_color) == 3:
        base_color = list(base_color)
        base_color.append(1)

    mat.use_nodes = True
    node = mat.node_tree.nodes[0]
    node.inputs[0].default_value = base_color
    node.inputs[4].default_value = metalic
    node.inputs[7].default_value = roughness

    return mat


def colorRGB_256(color):
    return tuple(pow(float(c) / 255.0, 2.2) for c in color)


def render(
        render_folder='rendering',
        render_name='render',
        resolution_x=800,
        resolution_y=800,
        resolution_percentage=100,
        animation=False,
        frame_end=None,
        render_engine='CYCLES'
):
    render_folder = os.getenv('RENDERING_PATH')
    scene = bpy.context.scene
    scene.render.resolution_x = resolution_x
    scene.render.resolution_y = resolution_y
    scene.render.resolution_percentage = resolution_percentage
    scene.render.engine = render_engine
    if frame_end:
        scene.frame_end = frame_end

    # Check if script is executed inside Blender
    if bpy.context.space_data is None:
        # Specify folder to save rendering and check if it exists
        render_folder = os.path.join(os.getcwd(), render_folder)
        if (not os.path.exists(render_folder)):
            os.mkdir(render_folder)

        if animation:
            # Render animation
            scene.render.filepath = os.path.join(
                render_folder,
                render_name)
            bpy.ops.render.render(animation=True)
        else:
            # Render still frame
            scene.render.filepath = os.path.join(
                render_folder,
                render_name + '.png')
            bpy.ops.render.render(write_still=True)


def bmesh_to_object(bm, name='Object'):
    mesh = bpy.data.meshes.new(name + 'Mesh')
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    return obj


def VoronoiSphere(bm, points, r=2, offset=0.02, num_materials=1):
    # Calculate 3D Voronoi diagram
    vor = spatial.Voronoi(points)

    faces_dict = {}
    for (idx_p0, idx_p1), ridge_vertices in zip(vor.ridge_points, vor.ridge_vertices):
        if -1 in ridge_vertices: continue
        if idx_p0 not in faces_dict:
            faces_dict[idx_p0] = []
        if idx_p1 not in faces_dict:
            faces_dict[idx_p1] = []

        faces_dict[idx_p0].append(ridge_vertices)
        faces_dict[idx_p1].append(ridge_vertices)

    for idx_point in faces_dict:
        region = faces_dict[idx_point]
        center = Vector(vor.points[idx_point])
        if len(region) <= 1: continue

        # Skip all Voronoi regions outside of radius r
        skip = False
        for faces in region:
            for idx in faces:
                p = vor.vertices[idx]
                if np.linalg.norm(p) > r:
                    skip = True
                    break

        if not skip:
            vertsDict = {}
            material_index = np.random.randint(num_materials)

            for faces in region:
                verts = []
                for idx in faces:
                    p = Vector(vor.vertices[idx])
                    if idx not in vertsDict:
                        v = center - p
                        v.normalize()
                        vert = bm.verts.new(p + offset * v)
                        verts.append(vert)
                        vertsDict[idx] = vert
                    else:
                        verts.append(vertsDict[idx])

                face = bm.faces.new(verts)
                face.material_index = material_index

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


if __name__ == '__main__':
    print(__file__)

    # Remove all elements
    remove_all()

    # Create camera and lamp
    simple_scene((0, 0, 0), (5.5, 0, 0), (-5, 5, 10))

    # Color palette
    # http://www.colourlovers.com/palette/1189317/Rock_Mint_Splash
    palette = [(89, 91, 90), (20, 100, 162), (13, 229, 168),
               (124, 244, 154), (100, 253, 153)]
    palette = [colorRGB_256(color) for color in palette]

    # Set background color of scene
    bpy.context.scene.world.use_nodes = False
    bpy.context.scene.world.color = palette[0]

    # Create Voronoi Sphere
    n, r = N, R
    points = (np.random.random((n, 3)) - 0.5) * 2 * r
    bm = bmesh.new()
    VoronoiSphere(bm, points, r, num_materials=len(palette) - 1)
    obj = bmesh_to_object(bm)

    # Apply materials to object
    for color in palette[1:]:
        mat = create_material(color)
        obj.data.materials.append(mat)

    # Render scene
    render(
        'rendering', 'voronoi_sphere', 512, 512,
        render_engine='CYCLES')

# set filename
outpath = os.path.join(os.getenv('RENDERING_PATH'), "voronoi_sphere" + '.glb')

# export it
# many other parameters can be added here

bpy.ops.export_scene.gltf(
    filepath=outpath, export_format="GLB", export_tangents=False, export_image_format="JPEG", export_cameras=True,
    export_lights=True
)
