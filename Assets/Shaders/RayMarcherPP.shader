Shader "Hidden/RayMarcherPP"
{
    Properties
    {
        _Smoothness ("Smoothness", Range(0, 1)) = 0.25
        _MaxRotationSpeed ("Max Rotation Speed", Range(0, 2)) = 0.5
        _MinRotationSpeed ("Min Rotation Speed", Range(0, 2)) = 0.25
        
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "SignedDistancePrimitives.cginc"
            #include "Generators.cginc"

            #define MAX_STEPS 500
            #define MIN_DISTANCE 0.00025
            #define MAX_DISTANCE 50

            float _Smoothness, _MaxRotationSpeed, _MinRotationSpeed;
            
            
            float sceneDistance(float3 position) {
                const float scale = 2;
                
                float noise = simplex13(scale * position) + 0.6 * simplex13(scale * 2 *position + 1) + 0.3 * simplex13(scale * 3 * position + 2);

                float tori = 1.#INF;
                //for(uint i = 0; i < 16; i++) {
                //    float3 rand = dotHash3(i);
                //    float3 pos = position;
                //    
                //    pR(pos.xz, 1749 / rand.x);
                //    pR(pos.yz, 1497 / rand.x);
                //    pR(pos.xy, UNITY_HALF_PI * lerp(_MinRotationSpeed, _MaxRotationSpeed, (1 + rand.y) / 2) * _Time.y);
                //    tori = fOpUnionRound(tori, fTorus(pos, 0.05, (rand.z + 1)) + 0.04 * noise, (rand.z + 1) *_Smoothness);
                //}
                float t = (sin(_Time.y / 2) + 1) / 2;
                //
                float3 pos = position;
                pR(pos.xz, 0.1 * UNITY_HALF_PI * _Time.y);
                return fMandelBulb(1 * pos, 200, (sin(_Time.y * 0.05) + 1) * 7 + 1);
            }
            
            float4 march(in float3 origin, in float3 direction) {
                float3 colorA = 0;
                float3 colorB = 1;
                
                float4 result = 0;
                for(uint i = 0; i < MAX_STEPS; i++) {
                    float distance = sceneDistance(origin);
                    if(distance < MIN_DISTANCE) {
                        float t = float4((float3)(i / (float)MAX_STEPS), 1);
                        return float4(lerp(colorA, colorB, exp(-10 * t)), 1);
                    }
                    else if(distance > MAX_DISTANCE)
                        continue;
                    
                    origin += direction * distance;
                    result += 1 * exp(1 * -distance) / MAX_STEPS;
                }

                float t = result;
                
                return 0 * float4(lerp(colorA, colorB, t), 1);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            float4 frag (v2f i) : SV_Target
            {
                i.uv = 2 * i.uv - 1;
                
                float3 direction = mul(unity_CameraInvProjection, float4(i.uv, 0.0f, 1.0f)).xyz;
                // Transform the direction from camera to world space and normalize
                direction = float3(direction.x, direction.y, -direction.z);
                direction = normalize(mul(unity_CameraToWorld, float4(direction, 0.0f)).xyz);
                const float3 position = _WorldSpaceCameraPos;

                return march(position, direction);
            }
            ENDCG
        }
    }
}
