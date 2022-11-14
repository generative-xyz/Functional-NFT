import random
import time
import math

import bpy
import bmesh

import colorsys

# with open("env.json", 'r') as file:
#     json_object = json.load(file)
#     dna = int(json_object['params'][0])
#     team = int(json_object['params'][1])
#     top = int(json_object['params'][2])
#     bottom = float(json_object['params'][3])
#     bottom = float(json_object['params'][4])
#     numbers = float(json_object['params'][5])
#     hair = float(json_object['params'][6])
#     shoes = float(json_object['params'][7])
#     tatoo = float(json_object['params'][8])
#     beard = float(json_object['params'][9])
#     tatoo = float(json_object['params'][10])
#     glasses = float(json_object['params'][11])
#     captain = float(json_object['params'][12])
#     tagline = float(json_object['params'][14])
#     rendering_path = json_object['rendering_path']

# --------------------------------------------------
# element variations
dna = 7  # 1-Male / 2-Female / 3-Robot / 4-Ape / 5-Alien / 6-Ballhead / 7-Gold
team = 'Australia'  # "Qatar", "Ecuador", "Senegal", "Netherlands",        // GA
# "England", "IR_Iran", "USA", "Wales",                // GB
# "Argentina", "Saudi_Arabia", "Mexico", "Poland",     // GC
# "France", "Australia", "Denmark", "Tunisia",         // GD
# "Spain", "Costa_Rica", "Germany", "Japan",           // GE
# "Belgium", "Canada", "Morocco", "Croatia",           // GF
# "Brazil", "Serbia", "Switzerland", "Cameroon",       // GG
# "Portugal", "Ghana", "Uruguay", "Korea_Republic"     // GH 
top = 2  # 1-T-shirt / 2-Hoodie / 3-Topless / 4-Camisole
bottom = 1  # 1-Football Shorts / 2-Jogger / 3-Shorts / 4-Skirt
numbers = 2  # 0-None / 1-26
hair = 0  # 0-None / 1-Short / 2-Long / 3-Wild / 4-Beanies / 5-Cowboy Hat / 6-Joker Hat / 7-Bird Fur Hat / 8-"Ronaldo 2002" / 9-"Balotelli"
shoes = 3  # 1-Football Boots / 2-Futuristic Boots / Gold Shoes
tatoo = 0  # 0-None / 1-Bitcoin / 2-Ethereum / 3-Soccer Ball
beard = 1  # 0-None / 1-Luxurious Beard / 2-Big Beard
glasses = 5  # 0-None / 1-3D / 2-VR / 3-AR / 4-"Edgar Davids" / 5-Gold
captain = 0  # 0-None / 1-Captain
undershirt = 0  # 0-17    

# --------------------------------------------------    
# color palette
teams = {}
teams["Qatar"] = ['af2938', 'D35057', 'ffffff', '2d2c2a']
teams["Ecuador"] = ['f2c702', '22355a', 'e51615', '080906']
teams["Senegal"] = ['F2EEED', 'edef11', 'fe5049', '029d8d']
teams["Netherlands"] = ['E26700', 'FAC752', '2C2E35', '191919']
teams["England"] = ['EBEBEB', '0964AC', '50C1DD', '222A48']
teams["IR_Iran"] = ['F3F3FF', '81DF99', '3C5D54', 'EC2B3E']
teams["USA"] = ['E2E3E5', '1A284C', 'E21333', '2B2724']
teams["Wales"] = ['E11E2C', 'F53B40', 'EBEAEF', '25775B']
teams["Argentina"] = ['9BCBE7', 'E0E3EB', '3B3F4E', 'EAE2BD']
teams["Saudi_Arabia"] = ['124139', '03A688', 'F4F6F3', '101012']
teams["Mexico"] = ['03936E', '035E58', 'F5F0F3', 'E62A2D']
teams["Poland"] = ['F4F3F9', 'C7C6CC', 'D32C37', '515152']
teams["France"] = ['242F4C', 'C0A05E', 'C7C6CC', '61A1CB']
teams["Australia"] = ['F9C555', 'F7DF85', '47B299', '6F562E']
teams["Denamrk"] = ['DA1735', 'A00E26', 'F8595F', 'FAFAFA']
teams["Tunisia"] = ['F43836', 'CB2A27', 'EEEBEB', '191919']
teams["Spain"] = ['AB132A', 'E7CB5F', '273651', '301B2D']
teams["Costa_Rica"] = ['F72040', '0169D0', 'F2ECF3', 'AE2B3B']
teams["Germany"] = ['F1F1F1', '323031', 'BD865C', '981F1E']
teams["Japan"] = ['3275C4', 'D7DCDD', '1B286C', 'B21F26']
teams["Belgium"] = ['E00F27', '2C252B', 'EDD529', 'C89560']
teams["Canada"] = ['D51932', 'F84C56', 'FEF4F9', '211B1C']
teams["Morocco"] = ['F53425', '107855', 'F7F0ED', '09D799']
teams["Crotia"] = ['E7E7E7', 'C40622', '0277BD', 'D1B269']
teams["Brazil"] = ['DBD853', '22B56C', '063E7B', '01A8D5']
teams["Serbia"] = ['DC2C41', 'D3B273', 'E8E9EB', '880A1A']
teams["Switzerland"] = ['F6342B', 'E7E5F9', '9D070E', '191919']
teams["Cameroon"] = ['EDEFEC', '37746B', 'D0B067', '0F191C']
teams["Portugal"] = ['AD1F2F', '1A523C', 'DBA237', 'ECEBEA']
teams["Ghana"] = ['EEEDF2', 'EEE757', 'E31722', '25CB5E']
teams["Uruguay"] = ['7FBAE6', 'F2F2F4', 'C5B482', 'CF503F']
teams["Korea_Republic"] = ['F44045', 'A90721', '1A1618', 'DE1C33']

(h, s, v) = (0.2, 0.4, 0.4)
(r, g, b) = colorsys.hsv_to_rgb(h, s, v)
print('RGB :', r, g, b)


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


def selectObject(nameOfObj, nameOfColl):
    for obj in bpy.data.collections[nameOfColl].all_objects:
        obj.hide_viewport = True
        obj.hide_render = True
    bpy.data.objects[nameOfObj].hide_viewport = False
    bpy.data.objects[nameOfObj].hide_render = False


def changeArmature(object):
    bpy.context.view_layer.objects.active = bpy.data.objects[object]
    if dna != 2:
        bpy.context.object.modifiers["Armature"].object = bpy.data.objects["Armature_Male"]
        bpy.context.object.parent = bpy.data.objects["Armature_Male"]
    if dna == 2:
        bpy.context.object.modifiers["Armature"].object = bpy.data.objects["Armature_Female"]
        bpy.context.object.parent = bpy.data.objects["Armature_Female"]


def selectExport():
    bpy.ops.object.select_all(action='DESELECT')
    if dna != 2:
        bpy.ops.object.select_pattern(pattern='Armature_Male')
        bpy.context.view_layer.objects.active = bpy.data.objects['Armature_Male']
    if dna == 2:
        bpy.ops.object.select_pattern(pattern='Armature_Female')
        bpy.context.view_layer.objects.active = bpy.data.objects['Armature_Female']
    bpy.ops.object.select_more()


def exportGLB(mood):
    selectObject(mood, 'Face')
    changeArmature(mood)
    selectExport()
    bpy.context.object.animation_data.action = bpy.data.actions[mood]
    bpy.ops.export_scene.gltf(filepath=filepath + filename + mood, check_existing=True, export_format='GLB',
                              use_selection=True, export_apply=True, export_animations=True, export_nla_strips=False,
                              export_anim_single_armature=True)


# --------------------------------------------------
# export settings
param = random.choice(range(1, 10001))
# filepath = rendering_path + '/result'
filepath = "./"
filename = 'Avatar' + str(param)
renderimage = 1
export = 1

# --------------------------------------------------
# bones
if dna != 2:
    selectBones = 'Armature_Male'
if dna == 2:
    selectBones = 'Armature_Female'

# DNA
if dna == 1:
    selectDNA = 'Male'
    selectHead = 'Head_Male'
if dna == 2:
    selectDNA = 'Female'
    selectHead = 'Head_Female'
if dna == 3:
    selectDNA = 'Male'
    selectHead = 'Head_Robot'
if dna == 4:
    selectDNA = 'Male'
    selectHead = 'Head_Ape'
if dna == 5:
    selectDNA = 'Male'
    selectHead = 'Head_Alien'
if dna == 6 or dna == 7:
    selectDNA = 'Male'
    selectHead = 'Head_Ballhead'
changeArmature(selectDNA)

# skin
skin_color = [0, 1, 2, 3]  # 0-None / 1-Dark / 2-Bright / 3-Yellow
if dna == 1 or dna == 2:
    skin = random.choice(range(1, 4))
if dna != 1 and dna != 2:
    skin = 0
if skin == 0:
    if dna == 3:
        bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["robot.png"]
        bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["robot_normal.png"]
    if dna == 4:
        bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["ape.png"]
        bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["ape_normal.png"]
    if dna == 5:
        bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["alien.png"]
        bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["alien_normal.png"]
    if dna == 6:
        bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["ballhead.png"]
        bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["ballhead_normal.png"]
    if dna == 7:
        bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["gold.png"]
        bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["gold_normal.png"]
if skin == 1:
    bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["dark.png"]
    bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["dark_normal.png"]
if skin == 2:
    bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["bright.png"]
    bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["bright_normal.png"]
if skin == 3:
    bpy.data.materials["skin"].node_tree.nodes["Image Texture"].image = bpy.data.images["yellow.png"]
    bpy.data.materials["skin"].node_tree.nodes["Image Texture.001"].image = bpy.data.images["yellow_normal.png"]

# hair
if hair == 0:
    selectHair = 'None_Hair'
if hair != 0:
    if hair == 1:
        if dna == 1:
            selectHair = 'Short_Male'
        if dna == 2:
            selectHair = 'Short_Female'
    if hair == 2:
        if dna == 1:
            selectHair = 'Long_Male'
        if dna == 2:
            selectHair = 'Long_Female'
    if hair == 3:
        selectHair = 'Wild'
    if hair == 4:
        selectHair = 'Beanies'
    if hair == 5:
        selectHair = 'Cowboy Hat'
    if hair == 6:
        selectHair = 'Joker Hat'
    if hair == 7:
        selectHair = 'Bird Fur Hat'
    if hair == 8:
        selectHair = 'Ronaldo 2002'
    if hair == 9:
        selectHair = 'Balotelli'
    changeArmature(selectHair)

# top
if top == 1:
    if dna != 2:
        selectTop = 'T-shirt_Male'
    if dna == 2:
        selectTop = 'T-shirt_Female'
if top == 2:
    if dna != 2:
        selectTop = 'Hoodie_Male'
        selectUnder = 'None_Undershirt'
    if dna == 2:
        selectTop = 'Hoodie_Female'
if top == 3:
    selectTop = 'Topless'
if top == 4:
    selectTop = 'Camisole'
changeArmature(selectTop)

# bottom
if bottom == 1:
    selectBottom = 'Football Shorts'
if bottom == 2:
    selectBottom = 'Jogger'
if bottom == 3:
    selectBottom = 'Shorts'
if bottom == 4:
    selectBottom = 'Skirt'
changeArmature(selectBottom)

# shoes
if shoes == 1:
    selectShoes = 'Football Boots'
if shoes == 2:
    selectShoes = 'Futuristic Boots'
if shoes == 3:
    selectShoes = 'Gold Shoes'
changeArmature(selectShoes)

# glasses                    
if glasses == 0:
    selectGlasses = 'None_Glasses'
if glasses != 0:
    if glasses == 1:
        selectGlasses = '3D'
    if glasses == 2:
        selectGlasses = 'VR'
    if glasses == 3:
        selectGlasses = 'AR'
    if glasses == 4:
        selectGlasses = 'Edgar Davids'
    if glasses == 5:
        selectGlasses = 'Gold'
    changeArmature(selectGlasses)

# captain                    
if captain == 0:
    selectCaptain = 'None_Captain'
if captain != 0:
    if captain == 1:
        selectCaptain = 'Captain'
    changeArmature(selectCaptain)

# tatoo                    
if tatoo == 0:
    selectTatoo = 'None_Tatoo'
if tatoo != 0:
    if tatoo == 1:
        selectTatoo = 'Bitcoin'
    if tatoo == 2:
        selectTatoo = 'Ethereum'
    if tatoo == 3:
        selectTatoo = 'Soccer Ball'
    changeArmature(selectTatoo)

# beard                    
if beard == 0:
    selectBeard = 'None_Beard'
if beard != 0:
    if beard == 1:
        selectBeard = 'Luxurious Beard'
    if beard == 2:
        selectBeard = 'Big Beard'
    changeArmature(selectBeard)

# undershirt
if undershirt == 0:
    selectUnder = 'None_Undershirt'
if undershirt != 0:
    selectUnder = 'Undershirt'
    bpy.data.materials["tagline"].node_tree.nodes["Image Texture"].image = bpy.data.images[str(undershirt) + ".jpg"]
    changeArmature(selectUnder)

# jersey number                    
bpy.data.materials["jersey"].node_tree.nodes["Image Texture"].image = bpy.data.images[str(numbers) + ".png"]

# --------------------------------------------------
# select objects from collection
selectObject(selectBones, 'Bones')
selectObject(selectDNA, 'DNA')
selectObject(selectHead, 'Head')
selectObject(selectHair, 'Hair')
selectObject(selectTop, 'Top')
selectObject(selectBottom, 'Bottom')
selectObject(selectShoes, 'Shoes')
selectObject(selectGlasses, 'Glasses')
selectObject(selectCaptain, 'Captain')
selectObject(selectTatoo, 'Tatoo')
selectObject(selectBeard, 'Beard')
selectObject(selectUnder, 'Undershirt')

# nations + hair color
c1 = teams[team][0];
c2 = teams[team][1];
c3 = teams[team][2];
c4 = teams[team][3]
bpy.data.materials["Material.001"].node_tree.nodes["Principled BSDF"].inputs[0].default_value = hex_color_to_rgba(c1,
                                                                                                                  alpha=1.0)
bpy.data.materials["Material.002"].node_tree.nodes["Principled BSDF"].inputs[0].default_value = hex_color_to_rgba(c2,
                                                                                                                  alpha=1.0)
bpy.data.materials["Material.003"].node_tree.nodes["Principled BSDF"].inputs[0].default_value = hex_color_to_rgba(c3,
                                                                                                                  alpha=1.0)
bpy.data.materials["Material.004"].node_tree.nodes["Principled BSDF"].inputs[0].default_value = hex_color_to_rgba(c4,
                                                                                                                  alpha=1.0)
bpy.data.materials["hair"].node_tree.nodes["Principled BSDF"].inputs[0].default_value = hex_color_to_rgba(
    random.choice(teams[team]), alpha=1.0)
bpy.data.materials["background"].node_tree.nodes["Principled BSDF"].inputs[0].default_value = hex_color_to_rgba(
    random.choice(teams[team]), alpha=1.0)

# --------------------------------------------------
# render image
changeArmature('Neutral')
selectExport()
bpy.context.object.animation_data.action = bpy.data.actions['Neutral']
selectObject('Happy', 'Face')
bpy.context.scene.render.filepath = filepath + filename
if renderimage == 1:
    bpy.ops.render.render(animation=True, write_still=True, use_viewport=False, layer='', scene='')

# export glb with animation
if export == 1:
    exportGLB('Neutral')
    exportGLB('Happy')
    exportGLB('Sad')
