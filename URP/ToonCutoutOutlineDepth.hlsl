#ifndef TOON_CUTOUT_OUTLINE_DEPTH_INCLUDED
#define TOON_CUTOUT_OUTLINE_DEPTH_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST;
	half _AlphaCutoff;
	half _OutlineWidth;
	half _OutlineDepth;
CBUFFER_END

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
};

Varyings vert(Attributes IN)
{
	Varyings OUT;

	half3 viewDir = GetObjectSpaceNormalizeViewDir(IN.positionOS.xyz);
	IN.positionOS.xyz += normalize(IN.normalOS) * _OutlineWidth - viewDir * _OutlineDepth;
	
	OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
	OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

	OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
	
	return OUT;
}

void frag(Varyings IN, out half4 outNormalWS : SV_Target0)
{
	half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
	clip(c.a - _AlphaCutoff);
	outNormalWS = half4(-normalize(IN.normalWS), 0.0);
}

#endif