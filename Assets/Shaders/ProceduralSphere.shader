Shader "ProceduralSphere"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "white" {}
        [MaterialToggle] _IsTextured("Is Sphere Textured?", Float) = 1
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

            float4 _DiffuseColor;

            float _Shininess;
            float _Specular;

            uniform float _IsTextured;
            
            v2f vert (appdata v)
            {
                v2f o;
                
                v.vertex.xyz = mul(unity_CameraToWorld, v.vertex.xyz);
                
                o.posWorld.xyz = mul(unity_ObjectToWorld, v.vertex.xyz);
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                //o.vertex.xyz = floor(o.vertex.xyz * 64) / 64;
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
                
                half height = sqrt(1 - len * len);
                normal += float3(0,alpha * height, 0);
                normal = mul(float3x3(1,0,0,0,0,1,0,-1,0), normal);
                normal = mul(unity_CameraToWorld, normal);
                normal = normalize(normal);
                
                half lambertian = max(dot(normal, _WorldSpaceLightPos0.xyz), 0);

                half3 viewDir = -normalize(i.posWorld - _WorldSpaceCameraPos);

                float4 albedo = _DiffuseColor;
                
                if(_IsTextured == 1)
                {
                    //half3 camToObj = normalize(mul(unity_WorldToObject, float4(0,0,0,1)) - _WorldSpaceCameraPos.xyz);
                    half2 rot = atan2(viewDir, cross(viewDir, float3(0, 1, 0)));
                    //return float4(rot, 0, 1);
                    
                    float worldScale = length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x));
    
                    i.posWorld.xyz += 0.5 * worldScale * height * viewDir;
    
                    float2 newUV = (0.5 + (2 * i.uv - 1) / (height + 1));
                    newUV += worldScale * rot / UNITY_TWO_PI;
                    newUV = TRANSFORM_TEX(newUV, _Albedo);
                    
                    albedo *= tex2D(_Albedo, newUV);
                }
                
                float4 diffuse = _LightColor0 * albedo * lambertian;
                diffuse.rgb += albedo * ShadeSH9(half4(normal,1));

                if(_Specular == 0)
                    return diffuse;

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
