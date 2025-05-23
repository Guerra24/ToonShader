#ifndef TOON_CUTOUT_INCLUDED
#define TOON_CUTOUT_INCLUDED

#include "./ToonUtil.cginc"

struct Input
{
	float2 uv_MainTex;
	float3 viewDir;
	float3 worldNormal; INTERNAL_DATA
	float3 worldRefl;
	float3 cameraDir;
	fixed facing : VFACE;
	float4 screenPos;
};

sampler2D _MainTex;
half _AlphaCutoff;
sampler2D _BumpMap;
half _BumpMapIntensity;
sampler2D _Dark;
//sampler2D _VerticalMult;
half _EdgeStart;
half _EdgeEnd;
half _EdgeIntensity;
float4 _EdgeColor;
//half _EdgeLuminanceMult;
sampler2D _Matcap;
sampler2D _MatcapMask;

void vert(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input, o);
	#if !UNITY_PASS_SHADOWCASTER
		o.cameraDir = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;
	#endif
}

UNITY_INSTANCING_BUFFER_START(Props)
UNITY_INSTANCING_BUFFER_END(Props)

void surf(Input IN, inout SurfaceOutputToon o)
{
	half4 c = tex2D(_MainTex, IN.uv_MainTex);
	clip(c.a - _AlphaCutoff);
	//clip(isDithered(IN.screenPos.xy / IN.screenPos.w, c.a));

	#if !UNITY_PASS_SHADOWCASTER

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

		#if _USE_MATCAP
			float3 matcap = tex2D(_Matcap, (normalize(mul((float3x3)UNITY_MATRIX_V, pixelNormal)) * 0.5 + 0.5).xy);
			half mask = tex2D(_MatcapMask, IN.uv_MainTex).r;
			#if _MATCAP_MULT
				c.rgb = lerp(c.rgb, c.rgb * matcap, mask);
			#else
				c.rgb = lerp(c.rgb, matcap, mask);
			#endif
		#endif

		o.Alpha = 1.0;

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

		o.Albedo = c.rgb;
		o.LightRim = lightRim;
		o.Dark = d;
		#if !_USE_NEW_SHADING
			o.DarkRim = darkRim * _EdgeDarkMult;
		#endif
	#endif
}

#endif