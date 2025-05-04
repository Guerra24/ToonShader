#ifndef TOON_CUTOUT_BASE
#define TOON_CUTOUT_BASE

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
	#ifndef _DISABLE_GEOM
		float4 outline : TEXCOORD7;
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
	clip(c.a - _AlphaCutoff);
	#ifndef _DISABLE_GEOM
		[branch] if (round(IN.outline.w))
		{
			return half4(lerp(float3(1.0,1.0,1.0), c.rgb, _OutlineMulti) * _OutlineColor.rgb, 1.0);
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

		#if _USE_MATCAP
			float3 matcap = SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, (normalize(mul((float3x3)UNITY_MATRIX_V, normalWS)) * 0.5 + 0.5).xy);
			half mask = SAMPLE_TEXTURE2D(_MatcapMask, sampler_MatcapMask, IN.uv).r;
			#if _MATCAP_MULT
				c.rgb = lerp(c.rgb, c.rgb * matcap, mask);
			#else
				c.rgb = lerp(c.rgb, matcap, mask);
			#endif
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
}

#endif