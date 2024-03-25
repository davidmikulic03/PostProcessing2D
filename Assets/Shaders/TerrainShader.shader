Shader "Unlit/TerrainShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("Height Map", 2D) = "black" {}
        _FlowMap ("Flow Map", 2D) = "black" {}
        _NormalMap ("Normal Map", 2D) = "blue" {}
        _Height ("Height", Range(0, 16)) = 1
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase"}
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _HeightMap;
            float4 _HeightMap_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            sampler2D _FlowMap;
            float4 _FlowMap_ST;

            float _Height;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.y += _Height * tex2Dlod(_HeightMap, float4(v.uv, 0, 0)).r;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = tex2D(_NormalMap, i.uv).xyz;
                //return float4(normal, 1);
                fixed4 col = max(dot(normal.xzy, _WorldSpaceLightPos0.xyz), 0) * _LightColor0 + float4(ShadeSH9(half4(normal.xzy,1)), 0);
                float flow = tex2D(_FlowMap, i.uv).xyz;
                //return flow;
                col *= 0.5;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return (col);
            }
            ENDCG
        }
    }
}
