#ifndef TOON_TRANSPARENT_BASE
#define TOON_TRANSPARENT_BASE

#include_with_pragmas "./ToonBase.hlsl"
#pragma shader_feature_local _USE_TRANSPARENT_HAIR

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
TEXTURE2D(_Dark); SAMPLER(sampler_Dark);
TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST;
	float3 _Dark_ST;
	float4 _BumpMap_ST;
	half _BumpMapIntensity;
	half _EdgeStart;
	half _EdgeEnd;
	half _EdgeIntensity;
	float4 _EdgeColor;
	half _OutlineWidth;
	float4 _OutlineColor;
	half _OutlineDepth;
	half _OutlineMulti;
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
	float vertexDepth : TEXCOORD4;
	float4 shadowCoords : TEXCOORD5;
	float3 positionWS : TEXCOORD6;
	DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
	#ifndef _DISABLE_GEOM
		float4 outline : TEXCOORD8;
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
	
	VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
	VertexNormalInputs normInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

	OUT.normalWS = normInputs.normalWS;
	OUT.tangentWS = float4(normInputs.tangentWS, IN.tangentOS.w);
	OUT.viewDir = GetWorldSpaceViewDir(vertexInput.positionWS);
	float zDepth = OUT.positionHCS.z / OUT.positionHCS.w;
	#if !UNITY_REVERSED_Z
		zDepth = zDepth * 0.5 + 0.5;
	#endif
	OUT.vertexDepth = zDepth;
	OUT.shadowCoords = GetShadowCoord(vertexInput);
	OUT.positionWS = vertexInput.positionWS;
	float4 occlusionOut = 0.0;
	OUTPUT_SH4(vertexInput.positionWS, OUT.normalWS, normalize(OUT.viewDir), OUT.vertexSH, occlusionOut);
	#ifndef _DISABLE_GEOM
		OUT.outline = float4(normalize(IN.normalOS), 0.0);
	#endif

	return OUT;
}

#ifndef _DISABLE_GEOM
	#include_with_pragmas "./ToonOutlineGeometry.hlsl"
#endif

half4 frag(Varyings IN, FRONT_FACE_TYPE frontFace : FRON_FACE_SEMANTIC) : SV_Target
{
	half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
	#ifndef _DISABLE_GEOM
		[branch] if (round(IN.outline.w))
		{
			return half4(lerp(float3(1.0,1.0,1.0), c.rgb, _OutlineMulti) * _OutlineColor.rgb, c.a);
		}
		else
	#endif
	{
		#if !_USE_NEW_SHADING
			half3 d = SAMPLE_TEXTURE2D(_Dark, sampler_Dark, IN.uv).rgb;
		#else
			half3 d = 0;
		#endif

		float3 viewDir = normalize(IN.viewDir);
		float3 normalWS = normalize(IN.normalWS);
		normalWS = frontFace > 0.5 ? -normalWS : normalWS;

		#if _NORMALMAP
			float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv));
			float3x3 tangentToWorld = CreateTangentToWorld(normalWS, IN.tangentWS.xyz, IN.tangentWS.w);
			normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld));
		#endif

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

		#if _USE_TRANSPARENT_HAIR
			float2 coords = IN.positionHCS.xy / _ScaledScreenParams.xy;
			#if UNITY_REVERSED_Z
				float depth = SampleSceneDepth(coords);
			#else
				float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(coords));
			#endif

			float distance = LinearEyeDepth(IN.vertexDepth, _ZBufferParams) - LinearEyeDepth(depth, _ZBufferParams);
			[branch] if (distance > 0.001) {
				c.a *= _HairMaxTransparency;
				c.a *= smoothstep(_HairCameraStartCutoff, _HairCameraEndCutoff, dot(normalWS, -IN.viewDir));
				float a = smoothstep(_HairDistanceEndCutoff, _HairDistanceStartCutoff, distance);
				c.a *= a;
			}
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
}

#endif