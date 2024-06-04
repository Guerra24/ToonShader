#ifndef TOON_CUTOUT_BASE
#define TOON_CUTOUT_BASE

#pragma shader_feature_local _NORMALMAP
#pragma shader_feature_local _USE_LUMINANCE
#pragma shader_feature_local _USE_SPECULAR
#pragma shader_feature_local _EDGE_VERTICAL_VECTOR
#pragma shader_feature_local _USE_NEW_SHADING
#pragma shader_feature_local _USE_AMBIENT

#include_with_pragmas "./ToonBase.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "./ToonCutoutInput.hlsl"

#include "./ToonLighting.hlsl"

struct Attributes
{
	float4 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Varyings
{
	float4 positionHCS  : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normalWS : TEXCOORD1;
	float4 tangentWS : TEXCOORD2;
	float3 viewDir : TEXCOORD3;
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
	VertexNormalInputs normInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

	OUT.normalWS = normInputs.normalWS;
	OUT.tangentWS = float4(normInputs.tangentWS, IN.tangentOS.w);
	OUT.viewDir = GetWorldSpaceViewDir(vertexInput.positionWS);
	OUT.shadowCoords = GetShadowCoord(vertexInput);
	OUT.positionWS = vertexInput.positionWS;
	OUTPUT_SH4(vertexInput.positionWS, OUT.normalWS, normalize(OUT.viewDir), OUT.vertexSH);
	
	return OUT;
}

half4 frag(Varyings IN, FRONT_FACE_TYPE frontFace : FRON_FACE_SEMANTIC) : SV_Target
{
	half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
	clip(c.a - _AlphaCutoff);

	#if !_USE_NEW_SHADING
		half3 d = SAMPLE_TEXTURE2D(_Dark, sampler_Dark, IN.uv).rgb;
	#else
		half3 d = 0;
	#endif

	float3 viewDir = normalize(IN.viewDir);
	float3 normalWS = normalize(IN.normalWS);
	normalWS = frontFace > 0.5 ? -normalWS : normalWS;

	float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv));
	float3x3 tangentToWorld = CreateTangentToWorld(normalWS, IN.tangentWS.xyz, IN.tangentWS.w);
	normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld));

	half rim = smoothstep(_EdgeEnd, _EdgeStart, dot(normalWS, -viewDir));
	#if _EDGE_VERTICAL_VECTOR
		half verticalLight = smoothstep(0.307, 0.55, dot(normalWS, half3(0, 1, 0)) * 0.5 + 0.5);
		rim *= verticalLight;
	#endif

	half ll = Luminance(c.rgb);
	half dl = Luminance(d);

	half3 lightRim = rim
	#if _USE_LUMINANCE
		* pow(1 + ll, 4)
	#endif
		* _EdgeIntensity * _EdgeColor.rgb;

	#if !_USE_NEW_SHADING
		half3 darkRim = rim
		#if _USE_LUMINANCE
			* pow(1 + dl, 4)
		#endif
			* _EdgeIntensity * _EdgeColor.rgb;
	#endif

	ToonData data;
	data.Light = c.rgb;
	data.Dark = d;
	data.LightRim = lightRim;
	#if !_USE_NEW_SHADING
		data.DarkRim = darkRim * _EdgeDarkMult;
	#endif
	data.positionWS = IN.positionWS;
	data.normalWS = normalWS;
	data.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);
	data.positionCS = IN.positionHCS;

	return half4(ToonLighting(data, viewDir, IN.shadowCoords), c.a);
}

#endif