Shader "ProceduralSphere"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "white" {}
        _Normal("Normal", 2D) = "blue" {}
        _DiffuseColor ("Diffuse", Color) = (1, 1, 1, 1)
        _Shininess ("Shininess", Range(0, 25)) = 5.0
        _Specular ("Specular", Range(0, 1)) = 0.5
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
                float4 vertex : SV_POSITION;
                float4 posWorld : TEXCOORD1;
            };

            sampler2D _Albedo;
            float4 _Albedo_ST;

            sampler2D _Normal;
            float4 _Normal_ST;

            float4 _DiffuseColor;

            float _Shininess;
            float _Specular;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = 2 * float3(i.uv - 0.5, 0);
                normal = normal.xzy;
                float len = length(normal);
                float alpha = 0;
                
                if(len < 1)
                    alpha = 1;
                else
                {
                    alpha = 0;
                    discard;
                }
                //return sqrt(1 - len * len);
                float height = sqrt(1 - len * len);
                normal += float3(0,alpha * height, 0);
                normal = normalize(normal);
                normal = mul(float3x3(1,0,0,0,0,1,0,-1,0), normal);
                normal = mul(unity_ObjectToWorld, normal);
                normal = normal.xyz;

                float lambertian = max(dot(normal, _WorldSpaceLightPos0.xyz), 0);

                
                float3 viewDir = -normalize(i.posWorld - _WorldSpaceCameraPos);

                //float2 newUV = (2 * i.uv - 1) - 0.5 * (2 * i.uv - 1) * height;
                
                float4 albedo = _DiffuseColor;
                float4 diffuse = _LightColor0 * albedo * lambertian;
                diffuse.rgb += albedo * ShadeSH9(half4(normal,1));

                float3 halfway = normalize(viewDir + _WorldSpaceLightPos0.xyz);

                float shininess = 0.000001;
                if (_Shininess > 0)
                    shininess = _Shininess * _Shininess;
                
                
                float4 specular = _Specular * _LightColor0 * pow(max(dot(halfway, normal), 0), shininess);

                return diffuse + specular;
                
                return float4(viewDir, 1);
                
                return diffuse;
            }
            ENDCG
        }
    }
}
