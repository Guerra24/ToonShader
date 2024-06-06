Shader "Guerra24/Toon Transparent (Stencil)"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Dark("Albedo Dark (RGB)", 2D) = "white" {}
		[Toggle(_NORMALMAP)] _NormalMap("Use Normals", Float) = 0
		[Normal] _BumpMap("Normal Map", 2D) = "bump" {}
		_BumpMapIntensity("Normal Map Intensity", Range(0, 1)) = 1.0
		[Header(Lighting)]
		_Sharpness("Sharpness", Range(0, 1)) = 0.1
		_IndirectSharpness("Indirect sharpness", Range(0, 0.5)) = 0.05
		[Toggle(_USE_NEW_SHADING)] _UseNewShading("Use new shading", Float) = 0
		_ShadowColor("Shadow color", Color) = (1.0, 1.0, 1.0, 0.0)
		[Toggle(_USE_AMBIENT)] _UseAmbient("Use ambient", Float) = 0
		[Header(Edge)]
		_EdgeIntensity("Intensity", Range(0, 1)) = 0.0
		_EdgeDarkMult("Dark Mult", Range(0, 1)) = 0.25
		_EdgeColor("Color", Color) = (1.0, 1.0, 1.0, 0.0)
		_EdgeStart("Start" , Range(-1, 0)) = -0.5
		_EdgeEnd("End" , Range(-1, 0)) = -0.6
		[Toggle(_EDGE_VERTICAL_VECTOR)] _EdgeVerticalVector("Use Vertical Vector", Float) = 0
		[Toggle(_USE_LUMINANCE)] _UseLuminance("Use Luminance", Float) = 0
		[Header(Specular)]
		[Toggle(_USE_SPECULAR)] _UseSpecular("Use Specular", Float) = 0
		_SpecularSize("Size", Range(0, 1)) = 0.0
		_SpecularIntensity("Intensity", Range(0, 1)) = 1.0
		_SpecularIntensityDark("Intensity (Dark)", Range(0, 1)) = 0.5
		[Header(Transparent hair)]
		[Toggle(_USE_TRANSPARENT_HAIR)] _UseTransparentHair("Transparent Hair", Float) = 0
		_HairMaxTransparency("Max Transparency", Range(0, 1)) = 0.5
		_HairCameraStartCutoff("Camera start cutoff", Range(-1, 1)) = 0.0
		_HairCameraEndCutoff("Camera end cutoff", Range(-1, 1)) = -0.05
		_HairDistanceStartCutoff("Distance start", Range(0, 0.1)) = 0.025
		_HairDistanceEndCutoff("Distance end", Range(0, 0.1)) = 0.03
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
		_StencilRef("Stencil Ref", Int) = 0
		//[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1.0
	}
	SubShader
	{
		PackageRequirements
		{
				"com.unity.render-pipelines.universal": "17.0.0"
		}
		Tags { "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

		Pass
		{
			Name "UniversalForwardOnly"
			Tags { "LightMode" = "UniversalForwardOnly" }
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
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma shader_feature_local _USE_TRANSPARENT_HAIR
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
		#pragma shader_feature _NORMALMAP
		#pragma shader_feature _USE_LUMINANCE
		#pragma shader_feature _USE_SPECULAR
		#pragma shader_feature _EDGE_VERTICAL_VECTOR
		#pragma shader_feature _USE_NEW_SHADING
		#pragma shader_feature _USE_AMBIENT
		#pragma target 4.0

		#include "./ToonLighting.cginc"

		#include "./ToonTransparentBase.cginc"

		ENDCG
	}
}
