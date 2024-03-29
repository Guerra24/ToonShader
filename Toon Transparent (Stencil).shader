﻿Shader "Custom/Toon Transparent (Stencil)"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		[Toggle(_USE_DYNAMIC_DARK_COLORS)] _UseDynamicDarkColors("Use Dynamic Dark Colors", Float) = 0
		_Dark("Albedo Dark (RGB)", 2D) = "white" {}
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
		_StencilRef("Stencil Ref", Int) = 0
		//[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1.0
		[Header(Transparent hair)]
		[Toggle(_USE_TRANSPARENT_HAIR)] _UseTransparentHair("Transparent Hair", Float) = 0
		_HairMaxTransparency("Max Transparency", Range(0, 1)) = 0.5
		_HairCameraStartCutoff("Camera start cutoff", Range(-1, 1)) = 0.0
		_HairCameraEndCutoff("Camera end cutoff", Range(-1, 1)) = -0.05
		_HairDistanceStartCutoff("Distance start", Range(0, 0.1)) = 0.025
		_HairDistanceEndCutoff("Distance end", Range(0, 0.1)) = 0.03
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue"="Transparent" "ForceNoShadowCasting"="True" }
		LOD 200
		Offset -1, -1
		Cull [_CullMode]
		ZTest [_ZTest]
		//ZWrite [_ZWrite]
		Stencil {
			Ref [_StencilRef]
			Comp LEqual
			Pass Replace
		}

		CGPROGRAM
		#pragma surface surf Toon alpha:blend vertex:vert
		#pragma shader_feature _USE_TRANSPARENT_HAIR
		#pragma shader_feature _USE_DYNAMIC_DARK_COLORS
		#pragma target 4.0

		#include "./ToonLighting.cginc"

		#include "./ToonTransparentBase.cginc"

		ENDCG
	}
		FallBack "Diffuse"
}
