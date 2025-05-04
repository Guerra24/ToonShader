#ifndef TOON_CUTOUT_GEOMETRY
#define TOON_CUTOUT_GEOMETRY

#pragma geometry geom

[maxvertexcount(6)]
void geom(triangle Varyings input[3], inout TriangleStream<Varyings> triStream)
{
    Varyings vert0 = input[0];
    Varyings vert1 = input[1];
    Varyings vert2 = input[2];

    vert0.positionHCS = TransformObjectToHClip(vert0.positionHCS.xyz);
    vert1.positionHCS = TransformObjectToHClip(vert1.positionHCS.xyz);
    vert2.positionHCS = TransformObjectToHClip(vert2.positionHCS.xyz);

    triStream.Append(vert0);
    triStream.Append(vert1);
    triStream.Append(vert2);
    triStream.RestartStrip();

    vert0 = input[0];
    vert1 = input[1];
    vert2 = input[2];

    half3 viewDir0 = GetObjectSpaceNormalizeViewDir(vert0.positionHCS.xyz);
    half3 viewDir1 = GetObjectSpaceNormalizeViewDir(vert1.positionHCS.xyz);
    half3 viewDir2 = GetObjectSpaceNormalizeViewDir(vert2.positionHCS.xyz);

    vert0.positionHCS.xyz += vert0.outline.xyz * _OutlineWidth - viewDir0 * _OutlineDepth;
    vert1.positionHCS.xyz += vert1.outline.xyz * _OutlineWidth - viewDir1 * _OutlineDepth;
    vert2.positionHCS.xyz += vert2.outline.xyz * _OutlineWidth - viewDir2 * _OutlineDepth;

    float3 vert0WS = TransformObjectToWorld(vert0.positionHCS.xyz);
    float3 vert1WS = TransformObjectToWorld(vert1.positionHCS.xyz);
    float3 vert2WS = TransformObjectToWorld(vert2.positionHCS.xyz);

    float3 normal = normalize(cross(normalize(vert0WS - vert1WS), normalize(vert0WS - vert2WS)));

    [branch] if (dot(normal, -viewDir0) < 0 && dot(normal, -viewDir1) < 0 && dot(normal, -viewDir2) < 0)
        return;

    vert0.outline.w = 1;
    vert1.outline.w = 1;
    vert2.outline.w = 1;

    vert0.outline.xyz = normal;
    vert1.outline.xyz = normal;
    vert2.outline.xyz = normal;

    vert0.positionHCS = TransformObjectToHClip(vert0.positionHCS.xyz);
    vert1.positionHCS = TransformObjectToHClip(vert1.positionHCS.xyz);
    vert2.positionHCS = TransformObjectToHClip(vert2.positionHCS.xyz);

    triStream.Append(vert0);
    triStream.Append(vert1);
    triStream.Append(vert2);
    triStream.RestartStrip();
}

#endif