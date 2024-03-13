#ifndef TOON_UTIL_INCLUDED
#define TOON_UTIL_INCLUDED

float4x4 contrastMatrix(float c)
{
	float t = (1.0 - c) * 0.5;
	return float4x4(c, 0, 0, 0, 0, c, 0, 0, 0, 0, c, 0, t, t, t, 1);
}

float3 RGBToHSV(float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVToRGB(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float3 Hue(float3 p, float v)
{
	p.x *= v;
	return p;
}

float3 Saturation(float3 p, float v)
{
	p.y *= v;
	return p;
}

float3 Contrast(float3 p, float v)
{
	return mul(float4(p, 1.0), contrastMatrix(v)).rgb;
}

#endif