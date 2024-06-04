#ifndef TOON_CUTOUT_OUTLINE_INCLUDED
#define TOON_CUTOUT_OUTLINE_INCLUDED

#pragma target 4.0
#pragma vertex vert
#pragma fragment frag

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#include "./ToonCutoutInput.hlsl"

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
};

Varyings vert(Attributes IN)
{
	Varyings OUT;

    half3 viewDir = GetObjectSpaceNormalizeViewDir(IN.positionOS.xyz);
    IN.positionOS.xyz += normalize(IN.normalOS) * _OutlineWidth - viewDir * _OutlineDepth;
	
	OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
	OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
	
	return OUT;
}

half4 frag(Varyings IN) : SV_Target
{
	half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
	clip(c.a - _AlphaCutoff);
    return half4(lerp(float3(1.0,1.0,1.0), c.rgb, _OutlineMulti) * _OutlineColor.rgb, 1.0);
}

#endif