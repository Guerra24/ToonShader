#ifndef TOON_TRANSPARENT_INCLUDED
#define TOON_TRANSPARENT_INCLUDED

struct Input
{
	float4 position : SV_POSITION;
	float2 uv_MainTex;
	float4 screenPos;
	float3 viewDir;
	float3 worldNormal; INTERNAL_DATA
	#if _USE_TRANSPARENT_HAIR
		float vertexDepth;
		float3 cameraDir;
	#endif
};

sampler2D _MainTex;
sampler2D _Dark;
sampler2D _CameraDepthTexture;

#if _USE_TRANSPARENT_HAIR
	half _HairMaxTransparency;
	half _HairCameraStartCutoff;
	half _HairCameraEndCutoff;
	half _HairDistanceStartCutoff;
	half _HairDistanceEndCutoff;
#endif

void vert(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input, o);
	#if _USE_TRANSPARENT_HAIR
		float4 clipPos = UnityObjectToClipPos(v.vertex);
		float zDepth = clipPos.z / clipPos.w;
		#if !defined(UNITY_REVERSED_Z) // basically only OpenGL
			zDepth = zDepth * 0.5 + 0.5; // remap -1 to 1 range to 0.0 to 1.0
		#endif
		o.vertexDepth = zDepth;
		o.cameraDir = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;
	#endif
}

UNITY_INSTANCING_BUFFER_START(Props)
UNITY_INSTANCING_BUFFER_END(Props)

void surf(Input IN, inout SurfaceOutputToon o)
{
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	fixed3 d = tex2D(_Dark, IN.uv_MainTex).rgb;
	#if _USE_TRANSPARENT_HAIR
		float2 coords = IN.screenPos.xy / IN.screenPos.w;
		half depth = tex2D(_CameraDepthTexture, coords).r;

		float distance = LinearEyeDepth(IN.vertexDepth) - LinearEyeDepth(depth);
		if (distance > 0.001) {
			c.a *= _HairMaxTransparency;
			float3 pixelNormal = WorldNormalVector(IN, o.Normal);
			c.a *= smoothstep(_HairCameraStartCutoff, _HairCameraEndCutoff, dot(pixelNormal, IN.cameraDir));
			float a = smoothstep(_HairDistanceEndCutoff, _HairDistanceStartCutoff, distance);
			c.a *= a;
		}
	#endif
	o.Albedo = c.rgb;
	o.Dark = d;
	o.Alpha = c.a;
}

#endif