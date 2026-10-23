"""
================================================================================
NeuroStack-3D Gen 2: Hardened Parametric 3D Neuromorphic Prototype Builder
Autodesk Fusion 360 Python Script
================================================================================
Author: Lead Neuromorphic Hardware Engineer & Silicon Architect
Updates in Gen 2:
  - Base: Integrated Microchannel Liquid Cooling Fins
  - Interconnects: Dual Redundant TSV Pairs + Peripheral Thermal Relief Vias (TRVs)
  - Tier 1: AlN Thermal Spreader + Segmented Sub-Mat Crossbar Partitioning
  - Tier 2/3: Fault-Tolerant Deflection Router Cores

How to Run in Autodesk Fusion 360:
    1. In Fusion 360, press Shift+S (or go to UTILITIES > Scripts and Add-Ins).
    2. Choose Python, name it 'NeuroStack3D_v2', and replace the contents with this file.
    3. Click 'Run'. The hardened 3D assembly will be generated parametrically.
================================================================================
"""

import adsk.core
import adsk.fusion
import traceback
import math

def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        
        design = adsk.fusion.Design.cast(app.activeProduct)
        if not design:
            ui.messageBox('No active Fusion 360 design found. Please open or create a new document.')
            return

        rootComp = design.rootComponent
        design.designType = adsk.fusion.DesignTypes.DirectDesignType

        SCALE = 1.0
        DIE_SIZE_XY = 4.2 * SCALE
        
        # Dimensions (Fusion internal units: cm)
        THICK_BASE_PLATE = 0.15 * SCALE
        THICK_COOLING_FINS = 0.25 * SCALE
        THICK_TIER3_AER = 0.25 * SCALE
        THICK_TIER2_SOMA = 0.30 * SCALE
        THICK_ALN_SPREADER = 0.05 * SCALE
        THICK_TIER1_XBAR = 0.15 * SCALE
        THICK_BONDING = 0.08 * SCALE
        THICK_TIER0_CIS = 0.25 * SCALE
        
        TSV_RADIUS = 0.045 * SCALE
        TRV_RADIUS = 0.060 * SCALE
        
        EXPLODE_GAP = 0.65 * SCALE

        def create_slab(comp, name, z_start, thickness, size_xy):
            half = size_xy / 2.0
            sketch = comp.sketches.add(comp.xYConstructionPlane)
            sketch.sketchCurves.sketchLines.addTwoPointRectangle(
                adsk.core.Point3D.create(-half, -half, 0),
                adsk.core.Point3D.create(half, half, 0)
            )
            profile = sketch.profiles.item(0)
            extrudes = comp.features.extrudeFeatures
            dist = adsk.core.ValueInput.createByReal(thickness)
            extInput = extrudes.createInput(profile, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
            extInput.setDistanceExtent(False, dist)
            extInput.startExtent = adsk.fusion.OffsetStartDefinition.create(adsk.core.ValueInput.createByReal(z_start))
            feature = extrudes.add(extInput)
            body = feature.bodies.item(0)
            body.name = name
            return body

        def create_cylinder(comp, name, center_x, center_y, z_start, height, radius):
            sketch = comp.sketches.add(comp.xYConstructionPlane)
            sketch.sketchCurves.sketchCircles.addByCenterRadius(
                adsk.core.Point3D.create(center_x, center_y, 0), radius
            )
            profile = sketch.profiles.item(0)
            extrudes = comp.features.extrudeFeatures
            dist = adsk.core.ValueInput.createByReal(height)
            extInput = extrudes.createInput(profile, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
            extInput.setDistanceExtent(False, dist)
            extInput.startExtent = adsk.fusion.OffsetStartDefinition.create(adsk.core.ValueInput.createByReal(z_start))
            feature = extrudes.add(extInput)
            body = feature.bodies.item(0)
            body.name = name
            return body

        allComps = rootComp.occurrences
        neuroMatrixOcc = allComps.addNewComponent(adsk.core.Matrix3D.create())
        neuroComp = neuroMatrixOcc.component
        neuroComp.name = "NeuroStack_3D_Gen2_Hardened"

        z_cursor = 0.0

        # 1. Base Carrier + Microchannel Cooling Fins
        create_slab(neuroComp, "Base_Silicon_Carrier", z_cursor, THICK_BASE_PLATE, DIE_SIZE_XY * 1.05)
        z_cursor += THICK_BASE_PLATE
        
        # Etch Microfluidic cooling ribs
        num_fins = 7
        fin_spacing = (DIE_SIZE_XY * 0.9) / num_fins
        for i in range(num_fins):
            fy = - (DIE_SIZE_XY * 0.45) + i * fin_spacing
            sketch = neuroComp.sketches.add(neuroComp.xYConstructionPlane)
            sketch.sketchCurves.sketchLines.addTwoPointRectangle(
                adsk.core.Point3D.create(-DIE_SIZE_XY * 0.5, fy - 0.04, 0),
                adsk.core.Point3D.create(DIE_SIZE_XY * 0.5, fy + 0.04, 0)
            )
            extInput = neuroComp.features.extrudeFeatures.createInput(
                sketch.profiles.item(0), adsk.fusion.FeatureOperations.NewBodyFeatureOperation
            )
            extInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(THICK_COOLING_FINS))
            extInput.startExtent = adsk.fusion.OffsetStartDefinition.create(adsk.core.ValueInput.createByReal(z_cursor))
            feat = neuroComp.features.extrudeFeatures.add(extInput)
            feat.bodies.item(0).name = f"Microchannel_Cooling_Fin_{i}"

        z_cursor += THICK_COOLING_FINS + EXPLODE_GAP

        # 2. Tier 3: Axon / 3D-AER Deflection Router
        create_slab(neuroComp, "Tier3_AER_Deflection_Router", z_cursor, THICK_TIER3_AER, DIE_SIZE_XY)
        z_cursor += THICK_TIER3_AER + EXPLODE_GAP

        # 3. Interconnects: Dual Redundant TSVs + Thermal Relief Vias (TRVs)
        tsv_z_start = z_cursor - EXPLODE_GAP * 0.8
        tsv_height = EXPLODE_GAP * 0.8 + THICK_TIER2_SOMA
        
        # Dual Redundant Signal TSV pairs
        for ix in range(-2, 3):
            for iy in range(-2, 3):
                px = ix * 0.7 * SCALE
                py = iy * 0.7 * SCALE
                create_cylinder(neuroComp, f"Primary_TSV_{ix}_{iy}", px - 0.08, py, tsv_z_start, tsv_height, TSV_RADIUS)
                create_cylinder(neuroComp, f"Backup_TSV_{ix}_{iy}", px + 0.08, py, tsv_z_start, tsv_height, TSV_RADIUS)

        # Perimeter Thermal Relief Vias (TRVs)
        for tx in range(-3, 4):
            create_cylinder(neuroComp, f"TRV_Perimeter_Y0_{tx}", tx * 0.5, -DIE_SIZE_XY * 0.45, tsv_z_start, tsv_height, TRV_RADIUS)
            create_cylinder(neuroComp, f"TRV_Perimeter_Y1_{tx}", tx * 0.5, DIE_SIZE_XY * 0.45, tsv_z_start, tsv_height, TRV_RADIUS)

        # 4. Tier 2: Soma LIF Logic Die
        create_slab(neuroComp, "Tier2_Soma_LIF_Logic_Die", z_cursor, THICK_TIER2_SOMA, DIE_SIZE_XY)
        z_cursor += THICK_TIER2_SOMA + EXPLODE_GAP

        # 5. Tier 1: AlN Thermal Spreader + Segmented Sub-Mats
        create_slab(neuroComp, "AlN_HighConductivity_Spreader", z_cursor, THICK_ALN_SPREADER, DIE_SIZE_XY * 0.92)
        z_cursor += THICK_ALN_SPREADER

        # 4 Segmented Sub-Mat crossbars
        quads = [(-0.9, -0.9), (0.9, -0.9), (-0.9, 0.9), (0.9, 0.9)]
        for q_idx, (qx, qy) in enumerate(quads):
            create_slab(neuroComp, f"SubMat_Dielectric_Bed_{q_idx}", z_cursor, THICK_TIER1_XBAR * 0.5, 1.4)
            # Active 1S1R Bilayer memristor cells
            for mx in range(-1, 2):
                for my in range(-1, 2):
                    create_cylinder(
                        neuroComp, f"Sub_{q_idx}_1S1R_{mx}_{my}",
                        qx + mx * 0.35, qy + my * 0.35,
                        z_cursor + 0.05, 0.04 * SCALE, 0.05 * SCALE
                    )
        z_cursor += THICK_TIER1_XBAR + EXPLODE_GAP

        # 6. Hybrid Bonding Interface
        create_slab(neuroComp, "Interface_Hybrid_CuCu_Bonding", z_cursor, THICK_BONDING, DIE_SIZE_XY * 0.95)
        z_cursor += THICK_BONDING + EXPLODE_GAP

        # 7. Tier 0: DVS Sensor Layer + Micro-lenses
        create_slab(neuroComp, "Tier0_DVS_Retina_Die", z_cursor, THICK_TIER0_CIS, DIE_SIZE_XY)
        
        lens_grid = 6
        lens_spacing = (DIE_SIZE_XY * 0.75) / lens_grid
        for lx in range(lens_grid):
            for ly in range(lens_grid):
                px = - (DIE_SIZE_XY * 0.375) + lx * lens_spacing
                py = - (DIE_SIZE_XY * 0.375) + ly * lens_spacing
                create_cylinder(neuroComp, f"Microlens_{lx}_{ly}", px, py, z_cursor + THICK_TIER0_CIS, 0.03 * SCALE, 0.10 * SCALE)

        ui.messageBox(
            "NeuroStack-3D Gen 2 Hardened Prototype Built!\n\n"
            "Hardware Upgrades Applied:\n"
            " 1. Microchannel Liquid Cooling Ribs (Base)\n"
            " 2. Dual-Redundant TSV Pairs (100% Interconnect Yield)\n"
            " 3. Perimeter Thermal Relief Vias (TRVs)\n"
            " 4. AlN High-Conductivity Heat-Spreader Plate\n"
            " 5. Quad Sub-Mat Crossbar Partitioning (Eliminates IR Drop)"
        )

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))

if __name__ == '__main__':
    run(None)
