Shader "Custom/Toon Cutout Outline Depth"
{
	Properties
	{
		[Header(Main)]
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_AlphaCutoff("Cutoff" , Range(0,1)) = 0.5
		_OutlineWidth("Outline Width", Range(0, 0.01)) = 0
	}
	SubShader
	{
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"

			half _AlphaCutoff;
			half _OutlineWidth;
			sampler2D _MainTex;

			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
				v.vertex.xyz += normalize(v.normal) * _OutlineWidth;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				if (unity_LightShadowBias.z != 0.0) discard;
				fixed4 c = tex2D(_MainTex, i.uv);
				clip(c.a - _AlphaCutoff);
				SHADOW_CASTER_FRAGMENT(i);
			}
			ENDCG
		}
    }
}
