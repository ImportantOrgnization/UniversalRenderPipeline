﻿#ifndef CUSTOM_LIT_PASS_INCLUDED
#define CUSTOM_LIT_PASS_INCLUDED
#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GI.hlsl" 
#include "../ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"


//顶点函数输入结构体
struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	//表面法线
	float3 normalOS : NORMAL;
    //对象空间的切线
	float4 tangentOS : TANGENT;
	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
//片元函数输入结构体
struct Varyings 
{
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float2 baseUV : VAR_BASE_UV;
#if defined(_DETAIL_MAP)
	float2 detailUV : VAR_DETIAIL_UV;
#endif
	//世界法线
	float3 normalWS : VAR_NORMAL;
#if defined(_NORMAL_MAP)
	//世界空间的切线
	float4 tangentWS : VAR_TANGENT;
#endif
	GI_VARINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


//顶点函数
Varyings LitPassVertex(Attributes input){
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	//使UnlitPassVertex输出位置和索引,并复制索引
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input,output);
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	//计算世界空间的法线
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
#if defined(_NORMAL_MAP)
	//计算世界空间的切线
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz),input.tangentOS.w);
#endif
	//计算缩放和偏移后的UV坐标
	output.baseUV = TransformBaseUV(input.baseUV);
#if defined(_DETAIL_MAP)
	output.detailUV = TransformDetailUV(input.baseUV);
#endif
	return output;
}
//片元函数
float4 LitPassFragment(Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	
/*  观察LOD过渡因子的行为
#if defined(LOD_FADE_CROSSFADE)
    return unity_LODFade.x;
#endif
*/
    //ClipLOD(input.positionCS.xy,unity_LODFade.x);
    
    InputConfig config = GetInputConfig(input.positionCS, input.baseUV);
    //return float4(config.fragment.screenUV,0,0);
    //return config.fragment.bufferDepth.xxxx /20.0 ;   //测试片元深度
    ClipLOD(config.fragment,unity_LODFade.x);
#if defined(_DETAIL_MAP)
    config.detailUV = input.detailUV;
    config.useDetail = true;
#endif
#if defined(_MASK_MAP)
    config.useMask = true; 
#endif

	float4 base = GetBase(config);
#if defined(_CLIPPING)
	//透明度低于阈值的片元进行舍弃
	clip(base.a - GetCutoff(config));
#endif
	//定义一个surface并填充属性
	Surface surface;
	surface.position = input.positionWS;
#if defined(_NORMAL_MAP)
	surface.normal = NormalTangentToWorld(GetNormalTS(config) , input.normalWS,input.tangentWS);
	surface.interpolatedNormal = input.normalWS;
#else
    surface.normal = normalize(input.normalWS);
    surface.interpolatedNormal = surface.normal;	
#endif
	//得到视角方向
	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.color = base.rgb;
	surface.alpha = base.a;
	surface.metallic = GetMetallic(config);
	surface.smoothness = GetSmoothness(config);
	surface.fresnelStrength = GetFresnel(config);
	//计算抖动
	surface.dither = InterleavedGradientNoise(config.fragment.positionSS,0);
	surface.renderingLayerMask = asuint(unity_RenderingLayer.x);
	surface.occlusion = GetOcclusion(config);
	//通过表面属性和BRDF计算最终光照结果
#if defined(_PREMULTIPLY_ALPHA)
	BRDF brdf = GetBRDF(surface, true);
#else
	BRDF brdf = GetBRDF(surface);
#endif
    GI gi = GetGI(GI_FRAGMENT_DATA(input),surface,brdf);
	float3 color = GetLighting(surface, brdf, gi);
	color += GetEmission(config);
	return float4(color, GetFinalAlpha(surface.alpha));
}

#endif
