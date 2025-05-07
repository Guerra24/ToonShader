#ifndef TOON_DEPTH_BASE
#define TOON_DEPTH_BASE

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
	#ifndef _DISABLE_GEOM
		float4 outline : TEXCOORD1;
	#endif
};

Varyings vert(Attributes IN)
{
	Varyings OUT;
	
	#ifndef _DISABLE_GEOM
		OUT.positionHCS = float4(IN.positionOS.xyz, 0.0);
	#else
		OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
	#endif
	OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

	#ifndef _DISABLE_GEOM
		OUT.outline = float4(normalize(IN.normalOS), 0.0);
	#endif
	
	return OUT;
}

#ifndef _DISABLE_GEOM
	#include_with_pragmas "./ToonOutlineGeometry.hlsl"
#endif

half frag(Varyings IN) : SV_TARGET
{
    half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
	clip(c.a - _AlphaCutoff);
	return IN.positionHCS.z;
}

#endif