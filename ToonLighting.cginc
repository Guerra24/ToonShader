#ifndef TOON_INCLUDED
#define TOON_INCLUDED

#include "UnityPBSLighting.cginc"

inline UnityGI UnityGI_Base_Custom(UnityGIInput data, half3 normalWorld)
{
	UnityGI o_gi;
	ResetUnityGI(o_gi);

	// Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
	#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
		half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
		float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
		float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
		data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
	#endif

	o_gi.light = data.light;
	o_gi.light.color *= data.atten;

	#if UNITY_SHOULD_SAMPLE_SH
		o_gi.indirect.diffuse = ShadeSHPerPixel(normalWorld, data.ambient, data.worldPos);
	#endif

	#if defined(LIGHTMAP_ON)
		// Baked lightmaps
		half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
		half3 bakedColor = DecodeLightmap(bakedColorTex);

		#ifdef DIRLIGHTMAP_COMBINED
			fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
			o_gi.indirect.diffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

			#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
				ResetUnityLight(o_gi.light);
				o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
			#endif

		#else // not directional lightmap
			o_gi.indirect.diffuse += bakedColor;

			#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
				ResetUnityLight(o_gi.light);
				o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
			#endif

		#endif
	#endif

	#ifdef DYNAMICLIGHTMAP_ON
		// Dynamic lightmaps
		fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
		half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

		#ifdef DIRLIGHTMAP_COMBINED
			half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
			o_gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
		#else
			o_gi.indirect.diffuse += realtimeColor;
		#endif
	#endif

	return o_gi;
}

struct SurfaceOutputToon
{
	half3 Albedo;      // base (diffuse or specular) color
	float3 Normal;      // tangent space normal, if written
	half3 Emission;
	half3 Dark;
	half Alpha;        // used by transparent shader
	#if _USE_SPECULAR
		float3 Refl;
	#endif
	half3 LightRim;
	half3 DarkRim;
};

#if _USE_SPECULAR
	half _SpecularSize;
	half _SpecularIntensity;
	half _SpecularIntensityDark;

	#define PI 3.14159265359

	float DistributionGGX(float3 N, float3 H, float a)
	{
		float a2 = a * a;
		float NdotH = max(dot(N, H), 0.0);
		float NdotH2 = NdotH * NdotH;

		float nom = a2;
		float denom = (NdotH2 * (a2 - 1.0) + 1.0);
		denom = PI * denom * denom;

		return nom / denom;
	}
#endif

half _Sharpness;
fixed3 _ShadowColor;
half _EdgeDarkMult;

half3 BRDF_DirectionalLight(SurfaceOutputToon s, half3 viewDir, UnityLight light, UnityIndirect indirect)
{
	half3 diffColor = s.Albedo;
	half3 darkColor = s.Dark;
	float3 normal = s.Normal;

	float NdotL = dot(normal, light.dir);
	half3 finalLight = (
	#if _USE_AMBIENT
		indirect.diffuse + 
	#endif
		light.color * smoothstep(-_Sharpness, _Sharpness, NdotL));
	half luminance = min(smoothstep(0.0, 0.5, Luminance(finalLight)), 1.0);

	#if _USE_SPECULAR
		half3 H = normalize(viewDir + light.dir);
		float specular = DistributionGGX(normal, H, _SpecularSize) * _SpecularIntensity * NdotL;
	#endif

	#if _USE_NEW_SHADING
		half3 shadedColor = diffColor * _ShadowColor + s.LightRim * _EdgeDarkMult;
		half3 lightenColor = diffColor + s.LightRim;
	#else
		half3 shadedColor = darkColor + s.DarkRim;
		half3 lightenColor = diffColor + s.LightRim;
	#endif
	#if _USE_SPECULAR
		lightenColor += specular;
	#endif
	return lerp(shadedColor, lightenColor, luminance);
}

half4 LightingToon(SurfaceOutputToon s, half3 viewDir, UnityGI gi)
{
	return half4(BRDF_DirectionalLight(s, viewDir, gi.light, gi.indirect), s.Alpha);
}

void LightingToon_GI(SurfaceOutputToon s, UnityGIInput data, inout UnityGI gi)
{
	gi = UnityGI_Base_Custom(data, s.Normal);
}

#endif