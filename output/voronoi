import os
import bpy
import sys
import json
import bmesh
import numpy as np
import scipy.spatial as spatial
from mathutils import Vector, Matrix
import optparse
import breed_utils
sys.path.append("")
import render_utils


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
                        vert = bm.verts.new(p + offset*v)
                        verts.append(vert)
                        vertsDict[idx] = vert
                    else:
                        verts.append(vertsDict[idx])

                face = bm.faces.new(verts)
                face.material_index = material_index

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


def breed_voronoi(dad, mom, id):
    child = {}
    child['id'] = id
    child['family'] = "voronoi"
    child['density'] = breed_utils.int(dad['density'], mom['density'], 0, 100000)
    child['radius'] = breed_utils.int(dad['radius'], mom['radius'], 0, 4)
    child['palette'] = breed_utils.palette(dad['palette'], mom['palette'])
    return child


def render_voronoi(dna):

    n = dna['density']
    r = dna['radius']
    palette = dna['palette']

    print(__file__)

    # Remove all elements
    render_utils.remove_all()

    # Create camera and lamp
    render_utils.simple_scene((0, 0, 0), (5.5, 0, 0), (5, 5, 10))

    # Color palette
    # http://www.colourlovers.com/palette/1189317/Rock_Mint_Splash
    # palette = [(89, 91, 90), (20, 195, 162), (13, 229, 168), (124, 244, 154), (184, 253, 153)]

    palette = [render_utils.colorRGB_256(color) for color in palette]

    # Set background color of scene
    #bpy.context.scene.world.use_nodes = False
    #bpy.context.scene.world.color = palette[0]
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.render.image_settings.color_mode = 'RGBA'

    # Create Voronoi Sphere
    points = (np.random.random((n, 3)) - 0.5)*2*r
    bm = bmesh.new()
    VoronoiSphere(bm, points, r, num_materials=len(palette)-1)
    obj = render_utils.bmesh_to_object(bm)

    # Apply materials to object
    for color in palette[1:]:
        mat = render_utils.create_material(color)
        obj.data.materials.append(mat)

    # Render scene
    render_utils.render(
        "rocks", "rock" + str(dna['id']), 512, 512,
        render_engine='CYCLES')
