Shader "Custom/Toon Transparent"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Dark("Albedo Dark (RGB)", 2D) = "white" {}
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
		_StencilRef("Stencil Ref", Int) = 0
		//[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1.0
		[Header(Extra)]
		[Toggle(_TRANSPARENT_HAIR)] _Multi_Light("Transparent Hair", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue"="Transparent" "ForceNoShadowCasting"="True" }
		LOD 200
		Offset -1, -1
		Cull [_CullMode]

		CGPROGRAM
		#pragma surface surf Toon alpha:blend
		#pragma target 4.0

		#include "./Toon.cginc"

		#include "./ToonTransparentBase.cginc"

		ENDCG
	}
		FallBack "Diffuse"
}
