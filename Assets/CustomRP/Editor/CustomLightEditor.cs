﻿using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CanEditMultipleObjects]
[CustomEditorForRenderPipeline(typeof(Light),typeof(CustomRenderPipelineAsset))]
public class CustomLightEditor : LightEditor
{
    //重新灯光Inspector面板
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (!settings.lightType.hasMultipleDifferentValues && (LightType)settings.lightType.enumValueIndex == LightType.Spot)
        {
            settings.DrawInnerAndOuterSpotAngle();
            settings.ApplyModifiedProperties();            
        }
    }
}