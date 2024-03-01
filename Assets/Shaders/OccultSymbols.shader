Shader "Unlit/OccultSymbols"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Steps ("Radial Steps", Integer) = 6
        _InnerDiameter ("Radial Inner Diameter", Float) = 0.1
        _Scale ("UV Scale", Float) = 1
        _CutOff ("Shape Value Cutoff", Range(0, 1)) = 0
        _Fractions ("Fractions", Float) = 1
        _FractionOffset ("Fraction Offset", Float) = 0
        _CosineFrequency ("Cosine Frequency", Float) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            int _Steps;
            float _InnerDiameter, _Scale, _CutOff, _Fractions, _FractionOffset, _CosineFrequency;

            v2f vert (appdata v) {
                v2f o;
                v.vertex.xyz = mul(unity_CameraToWorld, v.vertex.xyz);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed Bias(fixed val, fixed t) {
                t++;
                return pow(val, (2 - t) / t);
            }

            fixed4 frag (v2f i) : SV_Target {
                const fixed sqrt2 = 1.41421356237;
                i.uv = 2 * i.uv - 1;
                i.uv *= _Scale;
                fixed u = (UNITY_PI + atan2(i.uv.x, -i.uv.y)) * UNITY_INV_TWO_PI;
                uint radialIndex = (uint)(u * _Steps);
                u = frac(u.r * _Steps);
                
                fixed v = length(i.uv);
                fixed uvLength = v;
                v = (v - _InnerDiameter) / (1 - _InnerDiameter);
                
                fixed2 radialUV = fixed2(u,v);

                //fixed4 col = tex2D(_MainTex, radialUV);
                //if(col.a < 1)
                //    discard;
                //UNITY_APPLY_FOG(i.fogCoord, col);

                radialUV = 2 * radialUV - 1;

                fixed a = 1 - frac(abs(radialUV.x) + abs(radialUV.y) * _Fractions + _FractionOffset);
                fixed b = (abs(radialUV.x / radialUV.y));
                fixed c = a - b;
                fixed d = exp(-length(radialUV * length(i.uv)));
                fixed e = (cos((c / (abs(c) + 1)) * UNITY_TWO_PI * _CosineFrequency));
                fixed f = c * d * e;

                if(f < _CutOff * _CutOff)
                    discard;
                
                return 1;
                return float4(radialUV, 0, 1);
            }
            ENDCG
        }
    }
}
