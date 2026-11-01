"""Editable first Oathkeeper model study; run with Blender 4.5+, not system Python.

This is a visual-review source, not an approved final model or game replacement.
Weapons/shields remain separate objects attached to reusable hand sockets.
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

PROJECT = Path(__file__).resolve().parents[2]
OUT = PROJECT / "assets/models/oathkeeper"
OUT.mkdir(parents=True, exist_ok=True)
args = argparse.ArgumentParser()
args.add_argument("--quick", action="store_true")
args.add_argument("--no-render", action="store_true")
options = args.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0


def collection(name, parent=None):
    col = bpy.data.collections.new(name)
    (parent.children if parent else scene.collection.children).link(col)
    return col


source = collection("Oathkeeper_Source")
body = collection("Body", source)
frame = collection("Mechanical_Frame", body)
armor = collection("Armor", body)
rig = collection("Rig_Attachments", source)
sword_col = collection("Equipment_Sword", source)
shield_col = collection("Equipment_Shield", source)
stage = collection("Render_Setup")
references = collection("Reference", source)


def material(name, color, metallic, roughness, weather=True):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if weather:
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 110
        noise.inputs["Detail"].default_value = 3
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].position = .36
        ramp.color_ramp.elements[0].color = (*(v * .58 for v in color), 1)
        ramp.color_ramp.elements[1].position = .63
        ramp.color_ramp.elements[1].color = (*color, 1)
        links.new(noise.outputs["Fac"], ramp.inputs[0])
        links.new(ramp.outputs[0], bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = .12
        bump.inputs["Distance"].default_value = .008
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs[0], bsdf.inputs["Normal"])
    return mat


ivory = material("Ivory_Weathered_Armor", (.72, .695, .625), .38, .42)
navy = material("Navy_Armor_Panels", (.045, .072, .115), .5, .43)
dark = material("Dark_Mechanical_Steel", (.035, .043, .048), .8, .38)
steel = material("Machined_Steel", (.22, .25, .26), .88, .3)
brass = material("Worn_Brass_Fittings", (.40, .265, .115), .8, .33)
blade_mat = material("Sword_Steel", (.48, .52, .52), .9, .27)
grip_mat = material("Dark_Grip", (.035, .029, .023), .18, .65)
floor_mat = material("Neutral_Studio_Surface", (.52, .49, .44), 0, .82, False)


def assign(obj, col, mat=None, bone=None, bevel=.02):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    col.objects.link(obj)
    if mat:
        obj.data.materials.append(mat)
    if bone:
        obj["future_rig_bone"] = bone
    if bevel and obj.type == "MESH":
        mod = obj.modifiers.new("Machined_Edge_Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        normal = obj.modifiers.new("Weighted_Surface_Normals", "WEIGHTED_NORMAL")
        normal.keep_sharp = True
    return obj


def mesh(name, vertices, faces, mat, col=armor, bone=None, bevel=.02):
    data = bpy.data.meshes.new(name + "_Mesh")
    data.from_pydata(vertices, [], faces)
    normals = bmesh.new()
    normals.from_mesh(data)
    bmesh.ops.recalc_face_normals(normals, faces=list(normals.faces))
    normals.to_mesh(data)
    normals.free()
    data.update()
    obj = bpy.data.objects.new(name, data)
    return assign(obj, col, mat, bone, bevel)


def box(name, center, size, mat, col=armor, bone=None, bevel=.025):
    x, y, z = center
    a, b, c = (v / 2 for v in size)
    verts = [(x + i*a, y + j*b, z + k*c) for i, j, k in
             [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name, verts, [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], mat, col, bone, bevel)


def loft(name, sections, mat, col=armor, location=(0,0,0), bone=None):
    # Section: height, half-width, half-depth, fore/aft center. Chamfered octagons.
    verts = []
    for z, w, d, cy in sections:
        verts += [(w*x, cy+d*y, z) for x,y in
                  [(-.65,-1),(.65,-1),(1,-.65),(1,.65),(.65,1),(-.65,1),(-1,.65),(-1,-.65)]]
    faces = [tuple(range(7,-1,-1))]
    for ring in range(len(sections)-1):
        for i in range(8):
            a = ring*8+i
            b = ring*8+(i+1)%8
            faces.append((a,b,b+8,a+8))
    faces.append(tuple(range((len(sections)-1)*8, len(sections)*8)))
    obj = mesh(name, verts, faces, mat, col, bone)
    obj.location = location
    return obj


def plate(name, outline, y, depth, mat, col=armor, crown=.04, bone=None):
    n = len(outline)
    verts = [(x,y,z) for x,z in outline] + [(x,y+depth,z) for x,z in outline]
    verts.append((sum(p[0] for p in outline)/n, y-crown, sum(p[1] for p in outline)/n))
    faces = [(n*2,i,(i+1)%n) for i in range(n)]
    faces += [tuple(range(n*2-1,n-1,-1))]
    faces += [(i,n+i,n+(i+1)%n,(i+1)%n) for i in range(n)]
    return mesh(name, verts, faces, mat, col, bone, .012)


def rod(name, a, b, radius, mat=steel, col=frame, bone=None, vertices=16):
    a,b = Vector(a),Vector(b)
    axis = b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=axis.length,
                                       end_fill_type="NGON", location=(a+b)*.5)
    obj=bpy.context.object
    obj.name=name
    obj.rotation_euler=axis.to_track_quat("Z","Y").to_euler()
    return assign(obj,col,mat,bone,.008)


def ball(name, at, size, mat=dark, bone=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1, location=at)
    obj=bpy.context.object
    obj.name=name
    obj.scale=size
    for face in obj.data.polygons:
        face.use_smooth=True
    return assign(obj,frame,mat,bone,0)


def joint(name, at, radius, depth, sign, bone):
    x,y,z=at
    rod(name+"_Housing",(x-depth/2,y,z),(x+depth/2,y,z),radius,dark,bone=bone,vertices=24)
    outside=x+sign*(depth/2+.015)
    rod(name+"_Brass_Rim",(outside-sign*.035,y,z),(outside+sign*.025,y,z),radius*.9,brass,bone=bone,vertices=24)
    rod(name+"_Steel_Center",(outside+sign*.027,y,z),(outside+sign*.045,y,z),radius*.60,steel,bone=bone,vertices=24)
    for i in range(6):
        t=i*math.tau/6
        yy,zz=y+math.cos(t)*radius*.74,z+math.sin(t)*radius*.74
        rod(name+"_Bolt_%d"%i,(outside,yy,zz),(outside+sign*.05,yy,zz),.023,dark,bone=bone,vertices=6)


def limb_shell(name, bottom, top, sections, mat, bone):
    a,b=Vector(bottom),Vector(top)
    obj=loft(name,[(p*(b-a).length,w,d,cy) for p,w,d,cy in sections],mat,bone=bone)
    obj.location=a
    obj.rotation_euler=(b-a).to_track_quat("Z","Y").to_euler()
    return obj


def empty(name, at=(0,0,0), col=rig):
    obj=bpy.data.objects.new(name,None)
    col.objects.link(obj)
    obj.location=at
    obj.empty_display_type="ARROWS"
    obj.empty_display_size=.20
    return obj


root=empty("Oathkeeper_Root")
root["asset_status"]="FIRST_MODEL_STUDY_NOT_APPROVED"
root["source_reference"]="assets/art/mechs/concepts/oathkeeper.png"
root["equipment_is_interchangeable"]=True
root["runtime_target"]="Offline rendered 2D sprites, not runtime 3D"

# Pelvis, spine and independent layered breastplate.
loft("Pelvis_Frame",[(3.78,.56,.35,0),(4.12,.70,.39,0),(4.32,.52,.34,0)],dark,frame,bone="pelvis")
rod("Spinal_Core",(0,.06,4.05),(0,.06,5.10),.22,dark,bone="spine")
for z in [4.30,4.47,4.64,4.81]:
    rod("Spinal_Collar",(0,.06,z-.035),(0,.06,z+.035),.245,steel,bone="spine")
for sign in [-1,1]:
    rod("Abdomen_Piston",(sign*.35,-.24,4.13),(sign*.47,-.28,5.12),.065,steel,bone="spine")
    rod("Abdomen_Sleeve",(sign*.35,-.24,4.13),(sign*.41,-.26,4.65),.105,dark,bone="spine")
    plate("Hip_Front_Armor",[(sign*.07,4.27),(sign*.65,4.24),(sign*.80,3.80),(sign*.37,3.46),(sign*.13,3.83)],-.43,.18,ivory,bone="pelvis")
    plate("Hip_Navy_Edge",[(sign*.65,4.20),(sign*.89,4.06),(sign*.97,3.57),(sign*.77,3.76)],-.25,.12,navy,bone="pelvis")
    joint("Hip",(sign*.55,0,3.94),.21,.38,sign,"pelvis")
loft("Thorax_Chassis",[(4.87,.47,.35,0),(5.46,.83,.46,0),(6.08,.95,.40,0)],dark,frame,bone="chest")
plate("Breastplate_Main",[(-.94,6.03),(-.48,6.20),(.48,6.20),(.94,6.03),(.68,5.55),(0,5.20),(-.68,5.55)],-.55,.30,ivory,crown=.20,bone="chest")
plate("Breastplate_Central_Facet",[(-.53,6.01),(0,6.12),(.53,6.01),(.33,5.55),(0,5.31),(-.33,5.55)],-.76,.065,ivory,crown=.11,bone="chest")
for sign in [-1,1]:
    plate("Thorax_Navy_Flank",[(sign*.15,5.34),(sign*.68,5.60),(sign*.86,5.40),(sign*.47,4.96),(sign*.18,4.91)],-.51,.18,navy,bone="chest")
    plate("Chest_Outer_Shell",[(sign*.78,5.62),(sign*1.03,5.95),(sign*1.13,5.72),(sign*.90,5.15),(sign*.59,5.04)],-.36,.20,ivory,bone="chest")
    for i in range(3):
        box("Chest_Recess_Vent",(sign*.78,-.58,5.79-i*.075),(.25,.035,.028),dark,bone="chest",bevel=.003)
    rod("Collar_Strut",(sign*.15,-.11,6.18),(sign*.83,.03,6.22),.10,steel,bone="chest")
loft("Back_Armor",[(5.02,.48,.13,.43),(5.55,.83,.21,.43),(6.10,.78,.16,.43)],ivory,bone="chest")
for x in [-.35,.35]:
    rod("Rear_Exhaust",(x,.55,5.75),(x,.67,6.35),.11,dark,bone="chest")
    rod("Rear_Exhaust_Rim",(x,.66,6.30),(x,.68,6.38),.135,brass,bone="chest")

# Legs are planted humanoid chains, with separate upper/lower armor and boots.
for sign,side in [(-1,"r"),(1,"l")]:
    hip=(sign*.55,.02,3.94)
    knee=(sign*.69,-.10,2.28)
    ankle=(sign*.83,.04,.55)
    rod("Thigh_Frame_"+side,hip,knee,.18,dark,bone="thigh_"+side)
    rod("Shin_Frame_"+side,knee,ankle,.16,dark,bone="shin_"+side)
    joint("Knee_"+side,knee,.235,.55,sign,"shin_"+side)
    joint("Ankle_"+side,ankle,.15,.40,sign,"foot_"+side)
    limb_shell("Thigh_Ivory_"+side,Vector(knee)+Vector((0,0,.16)),Vector(hip)-Vector((0,0,.11)),
               [(0,.22,.25,-.02),(.20,.26,.29,-.04),(.82,.36,.34,-.02),(1,.32,.27,0)],ivory,"thigh_"+side)
    limb_shell("Thigh_Navy_Outer_"+side,Vector(knee)+Vector((sign*.24,.12,.28)),Vector(hip)+Vector((sign*.23,.12,-.2)),
               [(0,.09,.18,0),(.6,.14,.22,0),(1,.08,.17,0)],navy,"thigh_"+side)
    limb_shell("Shin_Ivory_"+side,Vector(ankle)+Vector((0,-.03,.05)),Vector(knee)-Vector((0,0,.13)),
               [(0,.23,.25,-.04),(.22,.25,.27,-.08),(.78,.30,.32,-.10),(1,.31,.28,-.08)],ivory,"shin_"+side)
    limb_shell("Shin_Navy_Inset_"+side,Vector(ankle)+Vector((sign*.23,.11,.18)),Vector(knee)+Vector((sign*.23,.12,-.28)),
               [(0,.08,.15,0),(.7,.10,.19,0),(1,.06,.13,0)],navy,"shin_"+side)
    rod("Calf_Hydraulic_"+side,(sign*.80,.34,.72),(sign*.72,.32,2.04),.07,steel,bone="shin_"+side)
    foot_y=-.03 if side=="r" else .10
    loft("Boot_Sole_"+side,[(.07,.39,.64,foot_y-.27),(.19,.40,.65,foot_y-.27),(.24,.34,.55,foot_y-.25)],dark,location=(sign*.83,0,0),bone="foot_"+side)
    loft("Boot_Ivory_"+side,[(.19,.35,.58,foot_y-.25),(.38,.34,.48,foot_y-.27),(.66,.25,.25,foot_y+.01)],ivory,location=(sign*.83,0,0),bone="foot_"+side)
    for i in range(2):
        box("Toe_Recess_"+side,(sign*.83,foot_y-.73,.30+i*.09),(.38,.035,.022),dark,bone="foot_"+side,bevel=.003)
    # Layered front plates supply the reference's long, pointed armor silhouette.
    plate("Thigh_Navy_Underlay_"+side,[(sign*.36,3.69),(sign*.80,3.74),(sign*.97,3.35),(sign*.87,2.54),(sign*.65,2.35),(sign*.42,2.82)],-.35,.06,navy,bone="thigh_"+side)
    plate("Thigh_Front_Plate_"+side,[(sign*.40,3.72),(sign*.74,3.70),(sign*.88,3.37),(sign*.78,2.64),(sign*.62,2.40),(sign*.49,2.91)],-.415,.075,ivory,crown=.085,bone="thigh_"+side)
    plate("Kneecap_"+side,[(sign*.48,2.36),(sign*.70,2.50),(sign*.91,2.34),(sign*.83,2.13),(sign*.70,2.02),(sign*.53,2.15)],-.34,.13,ivory,crown=.085,bone="shin_"+side)
    plate("Shin_Navy_Underlay_"+side,[(sign*.53,2.08),(sign*.88,2.12),(sign*1.01,1.70),(sign*.97,.75),(sign*.83,.49),(sign*.67,.80)],-.35,.06,navy,bone="shin_"+side)
    plate("Shin_Ridged_Plate_"+side,[(sign*.58,2.09),(sign*.81,2.13),(sign*.92,1.80),(sign*.88,1.07),(sign*.82,.69),(sign*.72,1.04),(sign*.64,1.68)],-.425,.065,ivory,crown=.085,bone="shin_"+side)
    for z in [1.20,1.28]:
        box("Shin_Service_Vent_"+side,(sign*.78,-.49,z),(.15,.02,.024),dark,bone="shin_"+side,bevel=.002)
    plate("Ankle_Guard_"+side,[(sign*.59,.66),(sign*.83,.84),(sign*1.07,.64),(sign*1.01,.36),(sign*.68,.35)],-.22,.13,ivory,bone="foot_"+side)

# Neck and faceted helmet. Crests are armor fins, not oversized ears.
rod("Neck",(0,0,6.13),(0,0,6.50),.16,steel,bone="head")
loft("Helmet_Shell",[(6.40,.21,.23,-.01),(6.72,.37,.32,-.01),(7.04,.29,.26,.01),(7.16,.13,.17,.02)],ivory,bone="head")
plate("Helmet_Navy_Visor_Recess",[(-.30,6.85),(.30,6.85),(.23,6.48),(0,6.36),(-.23,6.48)],-.333,.065,navy,bone="head")
plate("Helmet_Brow",[(-.34,6.94),(0,7.09),(.34,6.94),(.27,6.80),(0,6.72),(-.27,6.80)],-.37,.075,ivory,crown=.045,bone="head")
rod("Visor_Left",(-.27,-.425,6.77),(0,-.445,6.66),.021,brass,armor,"head")
rod("Visor_Right",(0,-.445,6.66),(.27,-.425,6.77),.021,brass,armor,"head")
plate("Helmet_Chin",[(-.075,6.65),(.075,6.65),(.09,6.43),(0,6.36),(-.09,6.43)],-.418,.065,ivory,bone="head")
for sign in [-1,1]:
    rod("Helmet_Temple",(sign*.32,-.01,6.71),(sign*.40,-.01,6.71),.12,brass,armor,"head",24)
    verts=[(sign*.23,-.035,6.97),(sign*.36,.055,6.99),(sign*.48,.07,7.91),(sign*.42,-.005,7.77),
           (sign*.23,.035,6.97),(sign*.36,.125,6.99),(sign*.48,.14,7.91),(sign*.42,.065,7.77)]
    mesh("Helmet_Crest",verts,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],ivory,bone="head",bevel=.008)

# Arms with separate pauldron shells and consistent anatomical handedness.
hands={}
for sign,side in [(-1,"r"),(1,"l")]:
    shoulder=(sign*1.20,.02,5.99)
    elbow=(sign*1.49,-.01,4.87)
    wrist=(sign*1.67,-.11,3.91)
    hand=(sign*1.69,-.16,3.69)
    hands[side]=Vector(hand)
    ball("Shoulder_Bearing_"+side,shoulder,(.30,.30,.30),bone="upper_arm_"+side)
    rod("Upper_Arm_Frame_"+side,shoulder,elbow,.16,dark,bone="upper_arm_"+side)
    joint("Elbow_"+side,elbow,.20,.43,sign,"forearm_"+side)
    rod("Forearm_Frame_"+side,elbow,wrist,.15,dark,bone="forearm_"+side)
    limb_shell("Upper_Arm_Shell_"+side,Vector(elbow)+Vector((0,-.06,.18)),Vector(shoulder)+Vector((0,-.03,-.14)),
               [(0,.18,.20,0),(.6,.24,.22,0),(1,.21,.18,0)],ivory,"upper_arm_"+side)
    limb_shell("Forearm_Ivory_"+side,wrist,Vector(elbow)+Vector((0,-.02,-.12)),
               [(0,.20,.21,-.03),(.40,.31,.29,-.03),(.85,.27,.25,-.02),(1,.20,.20,0)],ivory,"forearm_"+side)
    limb_shell("Forearm_Navy_"+side,Vector(wrist)+Vector((sign*.18,.08,.07)),Vector(elbow)+Vector((sign*.18,.08,-.23)),
               [(0,.075,.11,0),(.7,.12,.17,0),(1,.07,.11,0)],navy,"forearm_"+side)
    pauldron=[(sign*.94,6.26),(sign*1.16,6.55),(sign*1.76,6.47),(sign*2.02,6.11),(sign*1.91,5.70),(sign*1.60,5.58),(sign*1.18,5.89)]
    plate("Pauldron_Ivory_"+side,pauldron,-.34,.76,ivory,crown=.13,bone="upper_arm_"+side)
    plate("Pauldron_Navy_"+side,[(sign*1.72,6.41),(sign*1.98,6.10),(sign*1.88,5.74),(sign*1.64,5.92)],-.49,.08,navy,bone="upper_arm_"+side)
    plate("Pauldron_Upper_Layer_"+side,[(sign*.98,6.28),(sign*1.20,6.57),(sign*1.69,6.49),(sign*1.53,6.26),(sign*1.16,6.15)],-.47,.055,ivory,crown=.035,bone="upper_arm_"+side)
    plate("Pauldron_Lower_Segment_"+side,[(sign*1.24,6.14),(sign*1.62,6.10),(sign*1.79,5.85),(sign*1.61,5.57),(sign*1.37,5.76)],-.49,.07,ivory,bone="upper_arm_"+side)
    rod("Shoulder_Front_Bearing_"+side,(sign*1.20,-.44,6.05),(sign*1.20,-.53,6.05),.145,brass,armor,"upper_arm_"+side,24)
    rod("Shoulder_Front_Axle_"+side,(sign*1.20,-.535,6.05),(sign*1.20,-.56,6.05),.08,dark,armor,"upper_arm_"+side,24)
    for z in [6.39,5.83]:
        rod("Pauldron_Fastener_"+side,(sign*1.65,-.52,z),(sign*1.65,-.545,z),.028,brass,armor,"upper_arm_"+side,8)
    joint("Shoulder_Hub_"+side,(sign*1.44,.00,6.10),.23,.72,sign,"upper_arm_"+side)
    plate("Forearm_Face_"+side,[(sign*1.30,4.62),(sign*1.57,4.70),(sign*1.83,4.38),(sign*1.80,4.01),(sign*1.63,3.89),(sign*1.42,4.18)],-.40,.08,ivory,crown=.065,bone="forearm_"+side)
    rod("Wrist_Bearing_"+side,(sign*1.67,-.20,3.97),(sign*1.67,-.30,3.97),.105,brass,armor,"hand_"+side,24)
    box("Hand_Palm_"+side,hand,(.32,.32,.41),dark,bone="hand_"+side,bevel=.045)
    box("Hand_Backplate_"+side,(hand[0],hand[1]+.07,hand[2]+.04),(.33,.19,.29),ivory,bone="hand_"+side,bevel=.035)
    for i in range(4):
        box("Finger_"+side,(hand[0]-.12+i*.078,hand[1]-.12,hand[2]-.07),(.064,.16,.23),steel,bone="hand_"+side,bevel=.022)

# Independent equipment sockets. Gear is authored in socket-local coordinates.
right_axis=Vector((-.43,-.035,-.902)).normalized()
hand_r=empty("hand_r",hands["r"]+right_axis*.15)
# Fix the blade plane explicitly: its broad face must face forward rather than
# inherit an arbitrary roll from a track quaternion, which made it edge-on.
grip_y=Vector((0,1,0))
grip_y=(grip_y-right_axis*grip_y.dot(right_axis)).normalized()
grip_x=grip_y.cross(right_axis).normalized()
hand_r.rotation_euler=Matrix((grip_x,grip_y,right_axis)).transposed().to_euler()
hand_r["attachment_type"]="grip"
hand_r["supported_source_equipment"]="weapon,shield; item supplies its grip/mount offset"
hand_r["anatomical_hand"]="right"
hand_r["future_rig_bone"]="hand_r"
hand_l=empty("hand_l",hands["l"]+Vector((.08,-.26,.05)))
hand_l.rotation_euler.z=math.radians(13)
hand_l["attachment_type"]="shield_or_offhand_mount"
hand_l["supported_source_equipment"]="weapon,shield; item supplies its grip/mount offset"
hand_l["anatomical_hand"]="left"
hand_l["future_rig_bone"]="hand_l"

loft("Sword_Blade",[(.05,.18,.045,0),(.30,.20,.045,0),(2.95,.12,.035,0),(3.67,.006,.008,0)],blade_mat,sword_col)
loft("Sword_Fuller",[(.30,.045,.008,-.048),(2.80,.027,.008,-.040),(3.12,.004,.005,-.030)],dark,sword_col)
rod("Sword_Grip",(0,0,-.42),(0,0,.02),.065,grip_mat,sword_col)
for z in [-.36,-.28,-.20,-.12]:
    rod("Sword_Grip_Ring",(0,0,z-.012),(0,0,z+.012),.071,brass,sword_col)
box("Sword_Crossguard",(0,0,.045),(.68,.16,.11),brass,sword_col,bevel=.035)
loft("Sword_Pommel",[(-.52,.07,.07,0),(-.44,.10,.10,0),(-.39,.07,.07,0)],brass,sword_col)
for obj in sword_col.objects:
    obj.parent=hand_r
    obj["equipment_id"]="oathkeeper_starting_sword"
    obj["socket"]="hand_r"

shield_outline=[(-.44,1.50),(.38,1.40),(.64,.76),(.49,-.57),(0,-1.60),(-.49,-.57),(-.62,.73)]
plate("Shield_Ivory_Rim",shield_outline,-.13,.20,ivory,shield_col,crown=.06)
plate("Shield_Navy_Inset",[(x*.84,z*.92) for x,z in shield_outline],-.205,.07,navy,shield_col,crown=.055)
plate("Shield_Ivory_Quarter",[(-.36,1.29),(-.055,1.21),(-.055,.45),(-.48,.69)],-.275,.04,ivory,shield_col,crown=.01)
rod("Shield_Central_Rib",(0,-.305,-1.38),(0,-.305,1.31),.025,brass,shield_col)
rod("Shield_Cross_Rib",(-.46,-.31,.45),(.47,-.31,.45),.023,brass,shield_col)
rod("Shield_Boss",(0,-.30,.45),(0,-.39,.45),.125,brass,shield_col,vertices=24)
rod("Shield_Mount",(-.20,.13,.2),(.20,.13,.2),.08,dark,shield_col)
for obj in shield_col.objects:
    obj.parent=hand_l
    obj["equipment_id"]="oathkeeper_starting_kite_shield"
    obj["socket"]="hand_l"

# Pack the exact reference into the editable source, without rendering it as a model.
reference=bpy.data.images.load(str(PROJECT/"assets/art/mechs/concepts/oathkeeper.png"))
reference.pack()
ref=empty("Original_Approved_Concept",(-6,2,4),references)
ref.empty_display_type="IMAGE"
ref.data=reference
ref.empty_display_size=7.5
ref.hide_render=True

# Neutral proof lighting. No animation or gameplay replacement is done at this gate.
box("Studio_Floor",(0,0,-.08),(200,200,.12),floor_mat,stage,bevel=0)
world=bpy.data.worlds.new("Studio_World")
world.use_nodes=True
world.node_tree.nodes["Background"].inputs[0].default_value=(.68,.65,.59,1)
world.node_tree.nodes["Background"].inputs[1].default_value=.45
scene.world=world


def light(name, at, energy, size, color):
    data=bpy.data.lights.new(name,"AREA")
    data.energy=energy
    data.shape="DISK"
    data.size=size
    data.color=color
    obj=bpy.data.objects.new(name,data)
    stage.objects.link(obj)
    obj.location=at
    obj.rotation_euler=(Vector((0,0,4))-obj.location).to_track_quat("-Z","Y").to_euler()


light("Key_Upper_Left",(-5,-8,12),2000,6,(1.0,.92,.80))
light("Soft_Fill",(7,-4,7),950,5,(.82,.90,1.0))
light("Rim",(-3,5,10),1700,5,(1.0,.94,.82))
camera_data=bpy.data.cameras.new("Reference_Proof_Camera")
camera=bpy.data.objects.new("Reference_Proof_Camera",camera_data)
stage.objects.link(camera)
camera.location=(8,-20,9)
camera.rotation_euler=(Vector((-.25,0,3.90))-camera.location).to_track_quat("-Z","Y").to_euler()
camera_data.type="ORTHO"
camera_data.ortho_scale=8.7
scene.camera=camera
scene.render.engine="CYCLES"
scene.cycles.samples=48 if options.quick else 128
scene.cycles.use_denoising=True
scene.render.resolution_x=768 if options.quick else 1024
scene.render.resolution_y=960 if options.quick else 1280
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.image_settings.color_mode="RGBA"
scene.render.film_transparent=False
scene.render.fps=24
scene.view_settings.view_transform="AgX"
scene.view_settings.look="AgX - Medium High Contrast"
scene.render.filepath=str(OUT/"oathkeeper-model-study.png")

# Equipment contract: toggling/removing/replacing attachments cannot mutate body.
body_objects=[obj for obj in body.all_objects if obj.type=="MESH"]
signature=[(obj.name,len(obj.data.vertices),tuple(obj.matrix_world)) for obj in body_objects]
for col in [sword_col,shield_col]:
    col.hide_render=True
for col in [sword_col,shield_col]:
    col.hide_render=False
assert signature==[(obj.name,len(obj.data.vertices),tuple(obj.matrix_world)) for obj in body_objects]
assert set(sword_col.objects).isdisjoint(set(body.all_objects))
assert set(shield_col.objects).isdisjoint(set(body.all_objects))
assert all(obj.parent==hand_r for obj in sword_col.objects)
assert all(obj.parent==hand_l for obj in shield_col.objects)
body_data={obj.data for obj in body_objects}
assert all(obj.data not in body_data for obj in list(sword_col.objects)+list(shield_col.objects))
# Exercise an actual alternative attachment, without retaining an invented item.
template=next(obj for obj in sword_col.objects if obj.name=="Sword_Blade")
probe=template.copy()
probe.data=template.data.copy()
sword_col.objects.link(probe)
probe.parent=hand_l
probe.matrix_parent_inverse=Matrix.Identity(4)
bpy.context.view_layer.update()
before=probe.matrix_world.translation.copy()
hand_l.location.x+=.1
bpy.context.view_layer.update()
assert abs((probe.matrix_world.translation-before).x-.1)<1e-5
hand_l.location.x-=.1
bpy.context.view_layer.update()
assert signature==[(obj.name,len(obj.data.vertices),tuple(obj.matrix_world)) for obj in body_objects]
probe_data=probe.data
bpy.data.objects.remove(probe,do_unlink=True)
bpy.data.meshes.remove(probe_data)
for obj in body.all_objects:
    if obj.parent is None:
        obj.parent=root
for obj in [hand_r,hand_l]:
    obj.parent=root
references.hide_viewport=True
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=="VIEW_3D":
            area.spaces.active.region_3d.view_perspective="CAMERA"
            area.spaces.active.shading.color_type="MATERIAL"
bpy.ops.object.select_all(action="DESELECT")
root.select_set(True)
bpy.context.view_layer.objects.active=root
manifest={
    "status":"first_model_study_not_approved", "units":"meters", "blender":bpy.app.version_string,
    "reference":"assets/art/mechs/concepts/oathkeeper.png", "body_meshes":len(body_objects),
    "equipment":{"sword":{"socket":"hand_r","meshes":len(sword_col.objects)},
                 "shield":{"socket":"hand_l","meshes":len(shield_col.objects)}},
    "checks":{"equipment_separate_from_body":True,"body_unchanged_when_gear_hidden":True,
              "anatomical_hand_attachments":True,"equipment_mesh_data_independent":True,
              "replacement_probe_attaches_to_other_hand_without_body_changes":True},
    "rig_status":"rigid parts tagged for future bones; animation deferred until still review",
    "runtime_integration":False}
(OUT/"model-study.json").write_text(json.dumps(manifest,indent=2)+"\n")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"oathkeeper-study.blend"))
print("OATHKEEPER_MODEL_STUDY",json.dumps(manifest))
if not options.no_render:
    bpy.ops.render.render(write_still=True)
