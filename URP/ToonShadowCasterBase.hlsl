#ifndef TOON_SHADOW_CASTER
#define TOON_SHADOW_CASTER

#pragma target 4.0
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "./ToonCutoutInput.hlsl"

float3 _LightDirection;
float3 _LightPosition;

struct Attributes
{
	float4 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Varyings
{
	float4 positionCS  : SV_POSITION;
	float2 uv : TEXCOORD0;
};

Varyings vert(Attributes IN)
{
	Varyings OUT;
	
	OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

	float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
	float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);

	#if _CASTING_PUNCTUAL_LIGHT_SHADOW
		float3 lightDirectionWS = normalize(_LightPosition - positionWS);
	#else
		float3 lightDirectionWS = _LightDirection;
	#endif
	float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

	#if UNITY_REVERSED_Z
		positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
	#else
		positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
	#endif

	OUT.positionCS = positionCS;
	
	return OUT;
}

half4 frag(Varyings IN) : SV_TARGET
{
	half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
	clip(c.a - _AlphaCutoff);

	return 0;
}

#endif