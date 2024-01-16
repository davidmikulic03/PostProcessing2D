// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "AffineTextureMapping"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Range(0, 1)) = 0.5
        _Roughness ("Roughness", Range(0, 1)) = 1.0
        [MaterialToggle] _Affine("Toggle Affine Mapping", Float) = 1 
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
            #pragma multi_compile_fog


            #include "UnityCG.cginc"

            class appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                fixed4 diff : COLOR0;
                fixed4 spec : COLOR1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 posWorld : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Diffuse;

            
            float _Affine;

            float _Specular;
            float _Roughness;

            v2f vert (appdata v)
            {
                v2f o;
                
                //v.vertex.xyzw = mul(UNITY_MATRIX_V, v.vertex.xyzw);
                //v.vertex.xyzw = floor(v.vertex.xyzw * 32.0) / (32.0f);
                //v.vertex.xyzw = mul(UNITY_MATRIX_I_V, v.vertex.xyzw);

                //v.vertex.xyz -= _WorldSpaceCameraPos;
                //v.vertex.xyz = floor(v.vertex.xyz * 32.0) / (32.0f);
                //v.vertex.xyz += _WorldSpaceCameraPos;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                o.vertex.xyzw = floor(o.vertex.xyzw * 32.0) / (32.0f);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                if(_Affine == 1)
                    o.uv *= o.vertex.w;
                
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.normal = worldNormal;
                
                half nl = clamp(dot(worldNormal, _WorldSpaceLightPos0.xyz), 0, 1);
                o.diff = nl * _LightColor0;
                o.spec = _LightColor0;
                o.diff.rgb += ShadeSH9(half4(worldNormal,1));
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0;
                if(_Affine == 1)
                    col = tex2D(_MainTex, i.uv / i.vertex.w);
                else 
                    col = tex2D(_MainTex, i.uv);
                col *= i.diff * _Diffuse;
                
                
                
                float4 reflection = 0;
                if(true)
                {
                    half3 refl = normalize(reflect(-_WorldSpaceLightPos0, i.normal));
                    half3 viewVector = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
                    half r = clamp(dot(viewVector, refl), 0, 1);
                    reflection = _Specular * i.spec * max(0, pow(r, 1 / _Roughness));
                }
                
                col += reflection;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
