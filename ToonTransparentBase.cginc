#ifndef TOON_TRANSPARENT_INCLUDED
#define TOON_TRANSPARENT_INCLUDED

#include "./ToonUtil.cginc"

struct Input
{
	float4 position : SV_POSITION;
	float2 uv_MainTex;
	float4 screenPos;
	float3 viewDir;
	float3 worldNormal; INTERNAL_DATA
	float3 cameraDir;
	fixed facing : VFACE;
	#if _USE_TRANSPARENT_HAIR
		float vertexDepth;
	#endif
};

sampler2D _CameraDepthTexture;

sampler2D _MainTex;
sampler2D _Dark;
sampler2D _BumpMap;
half _BumpMapIntensity;
half _EdgeStart;
half _EdgeEnd;
half _EdgeIntensity;
float4 _EdgeColor;

#if _USE_TRANSPARENT_HAIR
	half _HairMaxTransparency;
	half _HairCameraStartCutoff;
	half _HairCameraEndCutoff;
	half _HairDistanceStartCutoff;
	half _HairDistanceEndCutoff;
#endif

float4 _Color;

void vert(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input, o);
	o.cameraDir = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;
	#if _USE_TRANSPARENT_HAIR
		float4 clipPos = UnityObjectToClipPos(v.vertex);
		float zDepth = clipPos.z / clipPos.w;
		#if !defined(UNITY_REVERSED_Z) // basically only OpenGL
			zDepth = zDepth * 0.5 + 0.5; // remap -1 to 1 range to 0.0 to 1.0
		#endif
		o.vertexDepth = zDepth;
	#endif
}

UNITY_INSTANCING_BUFFER_START(Props)
UNITY_INSTANCING_BUFFER_END(Props)

void surf(Input IN, inout SurfaceOutputToon o)
{
	half4 c = tex2D(_MainTex, IN.uv_MainTex);

	#if !_USE_NEW_SHADING
		half3 d = tex2D(_Dark, IN.uv_MainTex).rgb;
	#else
		half3 d = half3(0, 0, 0);
	#endif

	#if _NORMALMAP
		float3 n = lerp(half3(0, 0, 1), UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex)), _BumpMapIntensity);
		o.Normal = IN.facing > 0 ? n : -n;
	#endif
	float3 pixelNormal = WorldNormalVector(IN, o.Normal);

	half rim = smoothstep(_EdgeEnd, _EdgeStart, dot(pixelNormal, normalize(IN.cameraDir)));
	#if _EDGE_VERTICAL_VECTOR
		half verticalLight = smoothstep(0.307, 0.55, dot(pixelNormal, half3(0, 1, 0)) * 0.5 + 0.5);
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
		float2 coords = IN.screenPos.xy / IN.screenPos.w;
		half depth = tex2D(_CameraDepthTexture, coords).r;

		float distance = LinearEyeDepth(IN.vertexDepth) - LinearEyeDepth(depth);
		if (distance > 0.001) {
			c.a *= _HairMaxTransparency;
			c.a *= smoothstep(_HairCameraStartCutoff, _HairCameraEndCutoff, dot(pixelNormal, IN.cameraDir));
			float a = smoothstep(_HairDistanceEndCutoff, _HairDistanceStartCutoff, distance);
			c.a *= a;
		}
	#endif

	o.Albedo = c.rgb * _Color.rgb;
	o.LightRim = lightRim;
	o.Dark = d;
	#if !_USE_NEW_SHADING
		o.DarkRim = darkRim * _EdgeDarkMult;
	#endif
	o.Alpha = c.a * _Color.a;
}

#endif