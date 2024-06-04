#ifndef TOON_CUTOUT_OUTLINE_INCLUDED
#define TOON_CUTOUT_OUTLINE_INCLUDED

#include "UnityCG.cginc"

half _OutlineWidth;
sampler2D _MainTex;
half _AlphaCutoff;
float4 _OutlineColor;
half _OutlineDepth;
half _OutlineMulti;

struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};

v2f vert (appdata_base v) {
	v2f o;
	/*float3 camDir = mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos;*/
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
	return half4(lerp(float3(1.0,1.0,1.0), c.rgb, _OutlineMulti) * _OutlineColor.rgb, 1.0);
}

#endif