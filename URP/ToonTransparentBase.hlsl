#ifndef TOON_TRANSPARENT_BASE
#define TOON_TRANSPARENT_BASE

#pragma shader_feature_local _USE_SPECULAR
#pragma shader_feature_local _USE_NEW_SHADING
#pragma shader_feature_local _USE_AMBIENT

#include_with_pragmas "./ToonBase.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
TEXTURE2D(_Dark); SAMPLER(sampler_Dark);
CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST;
	float3 _Dark_ST;
    //#if _USE_TRANSPARENT_HAIR
        half _HairMaxTransparency;
        half _HairCameraStartCutoff;
        half _HairCameraEndCutoff;
        half _HairDistanceStartCutoff;
        half _HairDistanceEndCutoff;
    //#endif
	#include "./ToonLightingInput.hlsl"
CBUFFER_END

#include "./ToonLighting.hlsl"

struct Attributes
{
	float4 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float2 uv : TEXCOORD0;
};

struct Varyings
{
	float4 positionHCS  : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normalWS : TEXCOORD1;
	float3 viewDir : TEXCOORD2;
	float vertexDepth : TEXCOORD3;
	float4 shadowCoords : TEXCOORD4;
	float3 positionWS : TEXCOORD5;
	DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 6);
};

Varyings vert(Attributes IN)
{
	Varyings OUT;
	
	OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
	OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
	
	VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS);

	OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
	OUT.viewDir = GetWorldSpaceViewDir(vertexInput.positionWS);
	float zDepth = OUT.positionHCS.z / OUT.positionHCS.w;
	#if !UNITY_REVERSED_Z
		zDepth = zDepth * 0.5 + 0.5;
	#endif
	OUT.vertexDepth = zDepth;
	OUT.shadowCoords = GetShadowCoord(vertexInput);
	OUT.positionWS = vertexInput.positionWS;
	OUTPUT_SH4(vertexInput.positionWS, OUT.normalWS, normalize(OUT.viewDir), OUT.vertexSH);
	
	return OUT;
}

half4 frag(Varyings IN, FRONT_FACE_TYPE frontFace : FRON_FACE_SEMANTIC) : SV_Target
{
	half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

	#if !_USE_NEW_SHADING
		half3 d = SAMPLE_TEXTURE2D(_Dark, sampler_Dark, IN.uv).rgb;
	#else
		half3 d = 0;
	#endif

	float3 viewDir = normalize(IN.viewDir);
	float3 normalWS = normalize(IN.normalWS);
	normalWS = frontFace > 0.5 ? -normalWS : normalWS;

	#if _USE_TRANSPARENT_HAIR
		float2 coords = IN.positionHCS.xy / _ScaledScreenParams.xy;
		#if UNITY_REVERSED_Z
			float depth = SampleSceneDepth(coords);
		#else
			float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(coords));
		#endif

		float distance = LinearEyeDepth(IN.vertexDepth, _ZBufferParams) - LinearEyeDepth(depth, _ZBufferParams);
		if (distance > 0.001) {
			c.a *= _HairMaxTransparency;
			c.a *= smoothstep(_HairCameraStartCutoff, _HairCameraEndCutoff, dot(normalWS, -IN.viewDir));
			float a = smoothstep(_HairDistanceEndCutoff, _HairDistanceStartCutoff, distance);
			c.a *= a;
		}
	#endif

	ToonData data;
	data.Light = c.rgb;
	data.Dark = d;
	data.LightRim = 0;
	data.DarkRim = 0;
	data.positionWS = IN.positionWS;
	data.normalWS = normalWS;
	data.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);
	data.positionCS = IN.positionHCS;

	return half4(ToonLighting(data, viewDir, IN.shadowCoords), c.a);
}

#endif