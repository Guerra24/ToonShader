#ifndef TOON_CUTOUT_INPUT
#define TOON_CUTOUT_INPUT

TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
TEXTURE2D(_Dark); SAMPLER(sampler_Dark);
TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
TEXTURE2D(_Matcap); SAMPLER(sampler_Matcap);
TEXTURE2D(_MatcapMask); SAMPLER(sampler_MatcapMask);
CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST;
	half _AlphaCutoff;
	float4 _BumpMap_ST;
	half _BumpMapIntensity;
	float3 _Dark_ST;
	half _EdgeStart;
	half _EdgeEnd;
	half _EdgeIntensity;
	float4 _EdgeColor;
	half _OutlineWidth;
	float4 _OutlineColor;
	half _OutlineDepth;
	half _OutlineMulti;
	#include "./ToonLightingInput.hlsl"
CBUFFER_END

#endif