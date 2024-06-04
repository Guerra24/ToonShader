Shader "Guerra24/Toon Cutout"
{
	Properties
	{
		[Header(Textures)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_AlphaCutoff("Cutoff" , Range(0, 1)) = 0.5
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
		[Header(Outline)]
		_OutlineColor("Color", Color) = (0.5, 0.5, 0.5, 0.0)
		_OutlineWidth("Width", Range(0, 0.01)) = 0
		_OutlineDepth("Depth", Range(0, 0.05)) = 0.01
		_OutlineMulti("Texture Bleed", Range(0, 1)) = 1.0
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
		_StencilRef("Stencil Ref", Int) = 0
	}
	SubShader
	{
		Tags { "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }
		//https://gamedevbill.com/geometry-shaders-in-urp/

		Pass
		{
			Name "UniversalForwardOnly"
			Tags { "LightMode" = "UniversalForwardOnly" }
			LOD 200
			Cull [_CullMode]

			HLSLPROGRAM
			#include_with_pragmas "./URP/ToonCutoutBase.hlsl"
			ENDHLSL
		}

		Pass {
			Name "SRPDefaultUnlit"
			Tags { "LightMode" = "SRPDefaultUnlit" }
			LOD 200
			Cull Front

			HLSLPROGRAM
			#include_with_pragmas "./URP/ToonCutoutOutline.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "DepthNormalsOnly"
			Tags { "LightMode" = "DepthNormalsOnly" }
			LOD 200
			Cull [_CullMode]

			HLSLPROGRAM
			#include_with_pragmas "./URP/ToonDepthBase.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			LOD 200
			Cull Back
			ColorMask 0

			HLSLPROGRAM
			#include_with_pragmas "./URP/ToonShadowCasterBase.hlsl"
			ENDHLSL
		}
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

		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "" }
		LOD 200
		Cull [_CullMode]

		CGPROGRAM
		#pragma surface surf Toon vertex:vert fullforwardshadows addshadow
		#pragma shader_feature _NORMALMAP
		#pragma shader_feature _USE_LUMINANCE
		#pragma shader_feature _USE_SPECULAR
		#pragma shader_feature _EDGE_VERTICAL_VECTOR
		#pragma shader_feature _USE_NEW_SHADING
		#pragma shader_feature _USE_AMBIENT
		#pragma target 4.0

		#include "./ToonLighting.cginc"

		#include "./ToonCutoutBase.cginc"

		ENDCG
	}
}
