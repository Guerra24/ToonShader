#ifndef TOON_CUTOUT_INCLUDED
#define TOON_CUTOUT_INCLUDED

struct Input
{
	float2 uv_MainTex;
	float3 viewDir;
	float3 worldNormal; INTERNAL_DATA
	float3 worldRefl;
	float3 cameraDir;
	fixed facing : VFACE;
};

sampler2D _MainTex;
sampler2D _BumpMap;
half _BumpMapIntensity;
sampler2D _Dark;
//sampler2D _VerticalMult;
half _EdgeStart;
half _EdgeEnd;
half _EdgeIntensity;
half _EdgeDarkMult;
//half _EdgeLuminanceMult;
half _AlphaCutoff;
float4 _EdgeColor;

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
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	clip(c.a - _AlphaCutoff);

	#if !UNITY_PASS_SHADOWCASTER

		fixed3 d = tex2D(_Dark, IN.uv_MainTex).rgb;
		#if _NORMALMAP
			float3 n = lerp(half3(0, 0, 1), UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex)), _BumpMapIntensity);
			o.Normal = IN.facing > 0 ? n : -n;
		#endif
		float3 pixelNormal = WorldNormalVector(IN, o.Normal);
		#if _USE_SPECULAR
			o.Refl = WorldReflectionVector(IN, o.Normal);
		#endif

		half edge = smoothstep(_EdgeEnd, _EdgeStart, dot(pixelNormal, normalize(IN.cameraDir)));
		#if _EDGE_VERTICAL_VECTOR
			half verticalLight = smoothstep(0.307, 0.55, dot(pixelNormal, half3(0, 1, 0)) * 0.5 + 0.5);
			half rim = edge * verticalLight;
		#else
			half rim = edge;
		#endif

		o.Alpha = 1.0;

		half ll = Luminance(c.rgb);
		half dl = Luminance(d);

		half3 lightRim = rim
		#if _USE_LUMINANCE
			* pow(1 + ll, 4)
		#endif
			* _EdgeIntensity * _EdgeColor.rgb;

		half3 darkRim = rim
		#if _USE_LUMINANCE
			* pow(1 + dl, 4)
		#endif
			* _EdgeIntensity * _EdgeColor.rgb;

		o.Albedo = c.rgb + lightRim;
		o.Dark = d + darkRim * _EdgeDarkMult;
	#endif
}

#endif