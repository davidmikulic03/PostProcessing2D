Shader "Hidden/RayMarcherPP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [HideInInspector] _FOV ("Field of View", Float) = 60
        [HideInInspector] _Aspect ("Aspect Ratio", Float) = 60
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

            #define MAX_STEPS 100
            #define MIN_DISTANCE 0.01
            #define MAX_DISTANCE 50
            
            
            float sceneDistance(float3 position) {
                float3 posA = position;
                float3 posB = position;

                pR(posA.xz, UNITY_HALF_PI * 0.5 * _Time.y);
                const float scale = 0.8;
                float noise = simplex3d(scale * posA) + 0.4 * simplex3d(scale * 2 *posA + 1) + 0.2 * simplex3d(scale * 3 * posA + 2);
                return fTorus(posA, 0.4, 2) + 0.4 * noise;

                pR(posB.xz, UNITY_HALF_PI * 0.5 * _Time.y);
                float a = fTruncatedIcosahedron(posB, 1);
                
                
                float b = fSphere(posB, 1);
                a = 3 * a - 2.5 * b;
                
                float t = (sin(_Time.y / 2) + 1) / 2;
                return a;
            }
            
            float4 march(in float3 origin, in float3 direction) {
                float3 position = origin;
                float4 result = 0;
                for(uint i = 0; i < MAX_STEPS; i++) {
                    float distance = sceneDistance(origin);
                    if(distance < MIN_DISTANCE)
                        return float4((float3)(i / (float)MAX_STEPS), 1);
                    else if(distance > MAX_DISTANCE)
                        continue;
                    
                    origin += direction * distance * 0.4;
                    result += 1 / (float)MAX_STEPS;
                }
                
                return result;
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
            float _FOV, _Aspect;

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
