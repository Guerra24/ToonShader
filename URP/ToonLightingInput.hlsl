#ifndef TOON_LIGHTING_INPUT
#define TOON_LIGHTING_INPUT

//#if _USE_SPECULAR
	half _SpecularSize;
	half _SpecularIntensity;
	half _SpecularIntensityDark;
//#endif

half _Sharpness;
half _IndirectSharpness;
half3 _ShadowColor;
half _EdgeDarkMult;

#endif