Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float _Resolution;
            float _NumColors;

            static const int bayer2[] = {
                0, 2,
                3, 1
            };
            static const int bayer4[4][4] = {
                {0, 8, 2, 10, },
                {12, 4, 14, 6,},
                {3, 11, 1, 9, },
                {15, 7, 13, 5 }
            };
            static const int bayer8[8][8] = {
                {0, 32, 8, 40, 2, 34, 10, 42,      },
                {48, 16, 56, 24, 50, 18, 58, 26,   },
                {12, 44, 4, 36, 14, 46, 6, 38,     },
                {60, 28, 52, 20, 62, 30, 54, 22,   },
                {3, 35, 11, 43, 1, 33, 9, 41,      },
                {51, 19, 59, 27, 49, 17, 57, 25,   },
                {15, 47, 7, 39, 13, 45, 5, 37,     },
                {63, 31, 55, 23, 61, 29, 53, 21    },
            };
            float4 Snap(float4 input){
                return (uint4)(input * _NumColors) / _NumColors;
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _PixelDensity;
            float2 _AspectRatioMultiplier;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float2 pixelScaling = _PixelDensity * _AspectRatioMultiplier;
               i.uv = round(i.uv * pixelScaling)/ pixelScaling;
               fixed4 newTex = tex2D(_MainTex, i.uv);
               float x = pixelScaling.x * i.uv.x;
               float y = pixelScaling.y * i.uv.y;
               fixed threshold = (bayer8[x % 8][y % 8]) / (_NumColors * 8 * 8);
               fixed4 output = newTex + threshold;


               return Snap(output);
            }
            ENDCG
        }
    }
}
