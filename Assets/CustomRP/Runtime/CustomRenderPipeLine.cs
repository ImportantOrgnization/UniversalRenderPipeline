﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 自定义渲染管线实例
/// </summary>
public partial class CustomRenderPipeline : RenderPipeline
{
    CameraRenderer renderer = new CameraRenderer();
    bool useDynamicBatching, useGPUInstancing;
    private ShadowSettings shadowSettings;
    public CustomRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher , ShadowSettings shadowSettings)
    {
        this.shadowSettings = shadowSettings;
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        //灯光使用线性强度
        GraphicsSettings.lightsUseLinearIntensity = true;
        InitializeForEditor();
    }
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        //遍历所有相机单独渲染
        foreach (Camera camera in cameras)
        {
            renderer.Render(context, camera, useDynamicBatching, useGPUInstancing,shadowSettings);
        }
    }
}
