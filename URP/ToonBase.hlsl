#ifndef TOON_BASE
#define TOON_BASE

#pragma target 4.0
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
#pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
#pragma multi_compile _ _CLUSTER_LIGHT_LOOP
#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile_fragment _ _SHADOWS_SOFT
#pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

#pragma shader_feature_local _NORMALMAP
#pragma shader_feature_local _USE_LUMINANCE
#pragma shader_feature_local _USE_SPECULAR
#pragma shader_feature_local _EDGE_VERTICAL_VECTOR
#pragma shader_feature_local _USE_NEW_SHADING
#pragma shader_feature_local _USE_AMBIENT
#pragma shader_feature_local _USE_MATCAP
#pragma shader_feature_local _MATCAP_MULT

#endif