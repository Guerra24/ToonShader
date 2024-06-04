#ifndef TOON_LIGHTING
#define TOON_LIGHTING

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#if _USE_SPECULAR
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

struct ToonData {
    half3 Light;
    half3 Dark;
    half3 LightRim;
    half3 DarkRim;
	float3 positionWS;
    float3 normalWS;
	float2 normalizedScreenSpaceUV;
	float4 positionCS;
	half3 vertexSH;
};

half2 CalculateLight(Light light, ToonData data, float3 viewDir, half2 lighting)
{
	float NdotL = dot(data.normalWS, light.direction);
	half luminance = min(smoothstep(0.0, 0.5, Luminance(light.color * light.distanceAttenuation * light.shadowAttenuation * smoothstep(-_Sharpness, _Sharpness, NdotL))), 1.0);

	#if _USE_SPECULAR
		half3 H = normalize(viewDir + light.direction);
		half specular = DistributionGGX(data.normalWS, H, _SpecularSize) * _SpecularIntensity * NdotL * light.color;
	#else
		half specular = 0;
	#endif
	return half2(max(lighting.r, luminance), max(lighting.g, specular));
}

half3 ToonLighting(ToonData inputData, float3 viewDir, float4 shadowCoords)
{	
	half2 lighting = CalculateLight(GetMainLight(shadowCoords), inputData, viewDir, half2(0, 0));

	#if _ADDITIONAL_LIGHTS
		uint pixelLightCount = GetAdditionalLightsCount();

		LIGHT_LOOP_BEGIN(pixelLightCount)
			Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
			light.shadowAttenuation = AdditionalLightRealtimeShadow(lightIndex, inputData.positionWS, light.direction);
			lighting = CalculateLight(light, inputData, viewDir, lighting);
		LIGHT_LOOP_END
	#endif

	#if defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2)
		half3 gi = SampleProbeVolumePixel(inputData.vertexSH, GetAbsolutePositionWS(inputData.positionWS), inputData.normalWS, viewDir, inputData.positionCS.xy);
	#else 
		half3 gi = SampleSHPixel(inputData.vertexSH, inputData.normalWS);
	#endif

	lighting.r = max(lighting.r, smoothstep(0.5 - _IndirectSharpness, 0.5 + _IndirectSharpness, Luminance(gi)));

	#if _USE_NEW_SHADING
		half3 shadedColor = inputData.Light * _ShadowColor + inputData.LightRim * _EdgeDarkMult;
		half3 lightenColor = inputData.Light + inputData.LightRim;
	#else
		half3 shadedColor = inputData.Dark + inputData.DarkRim;
		half3 lightenColor = inputData.Light + inputData.LightRim;
	#endif
	#if _USE_SPECULAR
		lightenColor += lighting.g;
	#endif
	return lerp(shadedColor, lightenColor, lighting.r);
}

#endif