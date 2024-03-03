Shader "Unlit/RayMarcher"
{
    Properties
    {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        
        _Color ("Color", Color) = (1, 1, 1)
        _Scale ("Scale", Range(0, 10)) = 1
        _MaxSteps ("Max Steps", Integer) = 100
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            #define MIN_DISTANCE 0.001

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Scale;
            uint _MaxSteps;

            float3 _Bounds, _Color;

            float fSphere(float3 position, float3 center, float radius) {
                return distance(position, center) - radius;
            }
            float fBox(float3 position, float3 center, float3 size) {
                float3 offset = abs(position - center) - size;

                float unsignedDist = length(max(offset, 0));
                float insideDist = max(min(offset, 0), 0);
                return insideDist + unsignedDist;
            }

            float sceneDistance(float3 position) {
                float manhattanDistance = abs(position.x) + abs(position.y) + abs(position.z);
                float distance = length(position);
                float shape = manhattanDistance - 0.5;

                return shape;
            }

            half4 march(float3 origin, in float3 direction) {
                half3 lightColor = _LightColor0;
                half4 result = 0;
                float minDist = 1.#INF;
                
                for(uint i = 0; i < _MaxSteps; i++) {
                    float distance = sceneDistance(origin);
                    if(distance < MIN_DISTANCE)
                        return float4((float3)(i / (float)_MaxSteps), 1);
                    
                    if(distance < minDist)
                        minDist = distance;
                    origin += direction * distance;
                    //result += float4(0, 0, 0, _Density * _StepSize * _Absorption);
                }
                //return 0;
                return float4((float3)1, exp(-10 * minDist));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                const float3 worldPosition = i.worldPosition;
                const float3 viewDirection = normalize(-UnityWorldSpaceViewDir(worldPosition));
                float4 marched = march(worldPosition, viewDirection);
                
                return marched;
            }
            ENDCG
        }
    }
}
