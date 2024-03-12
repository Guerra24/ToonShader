﻿Shader "Custom/Toon Cutout"
{
	Properties
	{
		[Header(Textures)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_AlphaCutoff("Cutoff" , Range(0,1)) = 0.5
		_Dark("Albedo Dark (RGB)", 2D) = "white" {}
		[Toggle(_NORMALMAP)] _NormalMap("Use Normals", Float) = 0
		_BumpMap("Bumpmap", 2D) = "bump" {}
		_BumpMapIntensity("Bumpmap Intensity", Range(0, 1)) = 1.0
		[Header(Edge)]
		_EdgeIntensity("Intensity", Range(0,1)) = 0.0
		_EdgeDarkMult("Dark Mult", Range(0, 1)) = 0.25
		_EdgeColor("Color", Color) = (1.0,1.0,1.0,0.0)
		_EdgeStart("Start" , Range(-1,0)) = -0.5
		_EdgeEnd("End" , Range(-1,0)) = -0.6
		[Toggle(_USE_LUMINANCE)] _UseLuminance("Use Luminance", Float) = 0
		[Header(Specular)]
		[Toggle(_USE_SPECULAR)] _UseSpecular("Use Specular", Float) = 0
		_SpecularSize("Size", Range(0, 1)) = 0.0
		_SpecularPosition("Position", Range(-1, 1)) = 1.0
		_SpecularSharpness("Sharpness", Range(0.001, 1)) = 0.1
		_SpecularIntensity("Intensity", Range(0, 5)) = 1.0
		//_EdgeLuminanceMult("Luminance Mult", Range(0, 10)) = 2.0
		[Header(Outline)]
		_OutlineColor("Color", Color) = (0.5,0.5,0.5,0.0)
		_OutlineWidth("Width", Range(0, 0.01)) = 0
		_OutlineDepth("Depth", Range(0, 0.05)) = 0.01
		_OutlineMulti("Mult", Range(0, 1)) = 1.0
		[Header(Legacy)]
		_VerticalMult("Vertical Mult", 2D) = "white" {}
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
		_StencilRef("Stencil Ref", Int) = 0
	}
	SubShader
	{
		Pass {
			Tags { "RenderType" = "Opaque" }
			LOD 200
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "./ToonCutoutOutline.cginc"
			ENDCG
		}

		Tags { "RenderType" = "Opaque" "Queue" = "AlphaTest" }
		LOD 200
		Cull [_CullMode]

		CGPROGRAM
		#pragma surface surf Toon vertex:vert fullforwardshadows addshadow
		#pragma shader_feature _NORMALMAP
		#pragma shader_feature _USE_LUMINANCE
		#pragma shader_feature _USE_SPECULAR
		#pragma target 4.0

		#include "./Toon.cginc"

		#include "./ToonCutoutBase.cginc"

		ENDCG
	}
		FallBack "Diffuse"
}
