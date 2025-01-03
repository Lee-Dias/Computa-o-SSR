Shader "Custom/CustomSSR"
{
    HLSLINCLUDE

        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        // Stores all world space normals 
        TEXTURE2D_SAMPLER2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2);
        // Stores the RGB and smoothness
        TEXTURE2D_SAMPLER2D(_CameraGBufferTexture1, sampler_CameraGBufferTexture1);
        // Samples the world space
        TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

        float4 _MainTex_TexelSize;

        float4x4 unity_CameraInvProjection;
        float4x4 _InverseView;
        float4x4 _ViewProjectionMatrix;

        struct v2f 
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
            float3 ray : TEXCOORD1;
        };

        v2f vert (uint vertexID : SV_VertexID)
        {
            float far = _ProjectionParams.z;
            float x = (vertexID != 1) ? -1 : 3;
            float y = (vertexID == 2) ? -3 : 1;

            float3 vpos = float3(x, y, 1.0);

            // Calculate the ray in perspective space
            float3 rayPers = mul(unity_CameraInvProjection, vpos.xyzz * far).xyz;

            v2f o;
            o.vertex = float4(vpos.x, -vpos.y, 1, 1);
            o.uv = (vpos.xy + 1) / 2;
            o.ray = rayPers;
            return o;
        }

        // Gives a view space position from a uv coordinate
        float3 ComputeViewSpacePosition(float3 ray, float2 uv)
        {
            float near = _ProjectionParams.y;
            float far = _ProjectionParams.z;
            float z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);

            float mask = (z < 1) ? 1 : 0;

            float3 vposPers = ray * Linear01Depth(z);
            return vposPers * mask;
        }

        // Get the world position from the screen position
        float3 ScreenToWorldPos(float3 ray, float2 uv)
        {
            return mul(_InverseView, float4(ComputeViewSpacePosition(ray, uv),1.0)).xyz;
        }

        // Get the screen position from the world position
        float2 WorldToScreenPos(float3 worldPos)
        {
            float4 projectedCoords = mul(_ViewProjectionMatrix, float4(worldPos, 1.0));
            // Converts a world space position to clip space, then remaps from [-1, 1] to [0, 1] for screen space
            float2 uv = (projectedCoords.xy / projectedCoords.w) * 0.5 + 0.5;
            return uv;
        }

        // Vignette effect based on UV coordinates to darken the corners
        float Vignette(float2 uv)
        {
            float2 k = abs(uv - 0.5) * 1;
            k.x *= _MainTex_TexelSize.y * _MainTex_TexelSize.z;
            return pow(saturate(1.0 - dot(k, k)), 1);
        }

        // Simple hash function for randomization (used for reflection noise)
        float3 hash33(float3 p3)
        {
            p3 = frac(p3 * float3(.1031, .1030, .0973));
            p3 += dot(p3, p3.yxz + 33.33);
            return frac((p3.xxy + p3.yxx) * p3.zyx);
        }

        float4 Frag(v2f i) : SV_Target
        {
            float _StepSize = 0.07;
            float _MaxSteps = 100;
            float _MaxDistance = 200;
            uint _BinarySearchSteps = 5;
            float _Thickness = 0.1;

            // Gets the camera position
            float3 camPos = _WorldSpaceCameraPos;
            // Gets the world space position of the fragment
            float3 worldPos = ScreenToWorldPos(i.ray, i.uv);
            // Sample the normal map for the world space normal
            float3 worldNormal = SAMPLE_TEXTURE2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2, i.uv).xyz * 2.0 - 1.0;
            // Calculate the reflection direction (from the point of reflection to the object to be reflected)
            float3 rayDir = normalize(reflect(normalize(worldPos - camPos), normalize(worldNormal)));

            // Sample the smoothness value from the GBuffer
            float smoothness = SAMPLE_TEXTURE2D(_CameraGBufferTexture1, sampler_CameraGBufferTexture1, i.uv).a;
            // Add some randomization to the ray direction based on the smoothness (used for reflections)
            rayDir += (hash33(worldPos.xyz * 10) - float3(0.5, 0.5, 0.5)) * (1.0 - smoothness);

            float distTravelled = 0;
            float prevDistance = 0;

            float2 uvCoord = i.uv;
            float visibility = 1;
            float depth = _Thickness;

            // Ray marching loop
            for (int k = 0; k < _MaxSteps; k++)
            {
                // Dynamically adjust the step size to maintain good precision
                float dynamicStepSize = _StepSize * (1.0 / (1.0 + distTravelled * distTravelled));
                prevDistance = distTravelled;
                distTravelled += dynamicStepSize;

                float3 rayPos = worldPos + rayDir * distTravelled;
                float3 projectedPos = ScreenToWorldPos(i.ray, WorldToScreenPos(rayPos));
                // Get the distance between the projected position and the camera
                float projectedPosDist = distance(projectedPos, camPos);
                // Get the distance between the ray position and the camera
                float rayPosDist = distance(rayPos, camPos);

                depth = rayPosDist - projectedPosDist;
                // If the ray position is closer than the projected position, we've hit something
                if(depth > 0 && depth < _Thickness)
                {
                    // Perform binary search to get a more accurate reflection point
                    for(int j = 0; j < _BinarySearchSteps; j++)
                    {
                        float midPointDist = (distTravelled + prevDistance) * 0.5;
                        rayPos = worldPos + rayDir * midPointDist;
                        projectedPos = ScreenToWorldPos(i.ray, WorldToScreenPos(rayPos));
                        if (distance(projectedPos, camPos) <= distance(rayPos, camPos))
                        {
                            distTravelled = midPointDist;
                            uvCoord = WorldToScreenPos(rayPos);
                        } 
                        else 
                        {
                            prevDistance = midPointDist;
                        }
                    }
                    break;
                }
            }

            // Apply visibility factors (vignette, smoothness, etc.)
            visibility *= Vignette(i.uv);
            visibility *= saturate(dot(rayDir, normalize(worldPos - camPos)));
            visibility *= (1.0 - saturate(length(ScreenToWorldPos(i.ray, uvCoord) - worldPos) / _MaxDistance));
            visibility *= smoothness;
            visibility *= (uvCoord.x < 0 || uvCoord.x > 1 ? 0 : 1) * (uvCoord.y < 0 || uvCoord.y > 1 ? 0 : 1);
            visibility = saturate(visibility);

            // Sample the color at the original screen position and the reflected position
            float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
            float4 reflColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvCoord);
            color = lerp(color, reflColor, visibility);

            // Return the final color (original color mixed with reflection)
            return color;
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment Frag
            ENDHLSL
        }
    }
}
 