Shader "Guerra24/Toon Transparent"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Dark("Albedo Dark (RGB)", 2D) = "white" {}
		[Header(Lighting)]
		_Sharpness("Sharpness", Range(0, 1)) = 0.1
		_IndirectSharpness("Indirect sharpness", Range(0, 0.5)) = 0.05
		[Toggle(_USE_NEW_SHADING)] _UseNewShading("Use new shading", Float) = 0
		_ShadowColor("Shadow color", Color) = (1.0, 1.0, 1.0, 0.0)
		[Toggle(_USE_AMBIENT)] _UseAmbient("Use ambient", Float) = 0
		[Header(Transparent hair)]
		[Toggle(_USE_TRANSPARENT_HAIR)] _UseTransparentHair("Transparent Hair", Float) = 0
		_HairMaxTransparency("Max Transparency", Range(0, 1)) = 0.5
		_HairCameraStartCutoff("Camera start cutoff", Range(-1, 1)) = 0.0
		_HairCameraEndCutoff("Camera end cutoff", Range(-1, 1)) = -0.05
		_HairDistanceStartCutoff("Distance start", Range(0, 0.1)) = 0.025
		_HairDistanceEndCutoff("Distance end", Range(0, 0.1)) = 0.03
		[Header(Specular)]
		[Toggle(_USE_SPECULAR)] _UseSpecular("Use Specular", Float) = 0
		_SpecularSize("Size", Range(0, 1)) = 0.0
		_SpecularIntensity("Intensity", Range(0, 1)) = 1.0
		_SpecularIntensityDark("Intensity (Dark)", Range(0, 1)) = 0.5
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
		_StencilRef("Stencil Ref", Int) = 0
		//[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1.0
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

		Pass
		{
			Name "UniversalForwardOnly"
			Tags { "LightMode" = "UniversalForwardOnly" }
			LOD 200
			Offset -1, -1
			Cull [_CullMode]
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#include_with_pragmas "./URP/ToonTransparentBase.hlsl"
			ENDHLSL
		}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue"="Transparent" "ForceNoShadowCasting"="True" "RenderPipeline" = "" }
		LOD 200
		Offset -1, -1
		Cull [_CullMode]

		CGPROGRAM
		#pragma surface surf Toon alpha:blend
		#pragma shader_feature _USE_SPECULAR
		#pragma shader_feature _USE_NEW_SHADING
		#pragma shader_feature _USE_AMBIENT
		#pragma target 4.0

		#include "./ToonLighting.cginc"

		#include "./ToonTransparentBase.cginc"

		ENDCG
	}
}
