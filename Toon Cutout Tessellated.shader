Shader "Custom/Toon Cutout Tessellated"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Dark("Albedo Dark (RGB)", 2D) = "white" {}
		[Toggle(_NORMALMAP)] _NormalMap("Use Normals", Float) = 0
		_BumpMap("Bumpmap", 2D) = "bump" {}
		_BumpMapIntensity("Bumpmap Intensity", Range(0, 1)) = 1.0
		_AlphaCutoff("Cutoff" , Range(0,1)) = 0.5
		_VerticalMult("Vertical Mult", 2D) = "white" {}
		_EdgeIntensity("Edge Intensity", Range(0,1)) = 0.0
		_EdgeStart("Edge Start" , Range(-1,0)) = -0.5
		_EdgeEnd("Edge End" , Range(-1,0)) = -0.6
		_EdgeColor("Edge Color", Color) = (1.0,1.0,1.0,0.0)
		_OutlineColor("Outline Color", Color) = (0.5,0.5,0.5,0.0)
		_OutlineWidth("Outline Width", Range(0, 0.01)) = 0
		_OutlineDepth("Outline Depth", Range(0, 0.05)) = 0.01
		_TessEdgeLength ("Tess Edge length", Range(1,50)) = 5
		_TessPhong ("Tess Phong Strengh", Range(0,1)) = 0.5
		[Header(Fixed Function)]
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0
	}
	SubShader
	{
		Pass {
			Tags { "RenderType" = "Opaque"}
			LOD 200
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#pragma target 5.0
			#include "UnityCG.cginc"

			half _OutlineWidth;
			sampler2D _MainTex;
			half _AlphaCutoff;
			float4 _OutlineColor;
			half _OutlineDepth;
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata_base v) {
				v2f o;
				float3 camDir = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;
				float3 viewDir = ObjSpaceViewDir(v.vertex);
				v.vertex.xyz += normalize(v.normal) * _OutlineWidth - normalize(viewDir) * _OutlineDepth;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			half4 frag (v2f IN) : SV_Target
			{
				fixed4 c = tex2D(_MainTex, IN.uv);
				clip(c.a - _AlphaCutoff);
				return half4(c.rgb * _OutlineColor.rgb, 1.0);
			}
			ENDCG
		}

		Tags { "RenderType" = "Opaque" "Queue" = "AlphaTest" }
		LOD 200
		Cull [_CullMode]

		CGPROGRAM
		#pragma surface surf Toon fullforwardshadows vertex:vert addshadow nolightmap tessellate:tessEdge tessphong:_TessPhong
		#pragma shader_feature _NORMALMAP
		#pragma target 5.0

		#include "UnityPBSLighting.cginc"
		#include "Tessellation.cginc"

		// Based on Unity 2018 default PBR shaders
		// PBR-TOON Hybrid with stylized direct light and pbr indirect light
		half4 BRDF(half3 diffColor, half3 darkColor, float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi)
		{
			half nv = dot(normal, viewDir);
			half diffuseTerm = smoothstep(-0.1, 0.1,dot(normal, light.dir));
			float finalLight = (gi.diffuse + light.color * diffuseTerm);
			half3 color = lerp(darkColor, diffColor * max(finalLight - 1.0, 1.0), min(finalLight, 1.0));
			return half4(color, 1);
		}

		half4 LightingToon(SurfaceOutputStandard s, float3 viewDir, UnityGI gi)
		{
			s.Normal = normalize(s.Normal);
			half3 darkColor = half3(s.Metallic, s.Smoothness, s.Occlusion);
			half4 c = BRDF(s.Albedo, darkColor, s.Normal, viewDir, gi.light, gi.indirect);
			c.a = s.Alpha;
			return c;
		}

		void LightingToon_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
		#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
			gi = UnityGlobalIllumination(data, 1.0 /* Occlusion */, s.Normal);
		#else
			Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(0.0 /* Smoothness */, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, 0.0 /* Metallic */));
			gi = UnityGlobalIllumination(data, 1.0 /* Occlusion */, s.Normal, g);
		#endif
		}

		struct Input
		{
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldNormal; INTERNAL_DATA
			float4 color : COLOR;
		};

		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _BumpMapIntensity;
		sampler2D _Dark;
		sampler2D _VerticalMult;
		half _EdgeStart;
		half _EdgeEnd;
		half _EdgeIntensity;
		half _AlphaCutoff;
		float4 _EdgeColor;

		float _TessPhong;
        float _TessEdgeLength;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		float4 tessEdge(appdata_full v0, appdata_full v1, appdata_full v2)
		{
			return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _TessEdgeLength, 0);
		}

		void vert(inout appdata_full v) {
			v.color.rgb = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

			clip(c.a - _AlphaCutoff);

			fixed3 d = tex2D(_Dark, IN.uv_MainTex).rgb;
		#if defined(_NORMALMAP)
			float3 n = lerp(half3(0, 0, 1), UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex)), _BumpMapIntensity);
			o.Normal = dot(IN.viewDir, half3(0, 0, 1)) > 0 ? n : -n;
		#endif
			float3 pixelNormal = WorldNormalVector(IN, o.Normal);

			half edge = smoothstep(_EdgeEnd, _EdgeStart, dot(pixelNormal, normalize(IN.color.rgb)));
			half verticalLight = smoothstep(0.307, 0.55, dot(pixelNormal, half3(0, 1, 0)) * 0.5 + 0.5);

			half rim = edge * lerp(verticalLight, 1.0, tex2D(_VerticalMult, IN.uv_MainTex).r);

			half3 rimFinal = rim * _EdgeIntensity  * _EdgeColor.rgb;
			half3 color = c.rgb + rimFinal;
			d = d + rimFinal * 0.25;
			o.Albedo = color;
			o.Metallic = d.r;
			o.Smoothness = d.g;
			o.Occlusion = d.b;
			o.Alpha = 1;
		}
		ENDCG
	}
		FallBack "Diffuse"
}
