Shader "SilVR/Misc Shaders/Matcap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _On("Turn alt method on", Range(0,1)) = 0.0
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                
                float3 wray : TEXCOORD1;

                float3 up : TEXCOORD2;
                float3 rt : TEXCOORD3;

                float3 fw : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _On;

            float4 multiplyQuaternions(float4 a, float4 b)
            {

                return float4 (a.w * b.w - dot(a.xyz, b.xyz), a.w * b.xyz + b.w * a.xyz + cross(a, b));
            }

            float4 conjugateQuaternion(float4 a)
            {
                return a * float4(-1.0, -1.0, -1.0, 1.0);
            }

            float3 rotateAlongAxis(float3 p, float3 axis, float angle)
            {
                float4 p_quat = float4(p, 0.0);
                float4 q_quat = float4(normalize(axis)*sin(angle), cos(angle));
                return multiplyQuaternions(multiplyQuaternions(q_quat, p_quat), conjugateQuaternion(q_quat)).xyz;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.tangent = mul((float3x3)unity_ObjectToWorld, v.tangent);
                
                o.wray = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;

                o.up = mul((float3x3)unity_CameraToWorld, float3(0.0, 1.0, 0.0));
                o.rt = mul((float3x3)unity_CameraToWorld, float3(1.0, 0.0, 0.0));
                o.fw = mul((float3x3)unity_CameraToWorld, float3(0.0, 0.0, 1.0));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {

                float3 ray = normalize(i.wray);                
                float3 normal = normalize(i.normal);
                float3 tangent = normalize(i.tangent);
     
                float2 origin = float2(0.5, 0.5);
                float radius = 0.5;

                float3 ray_up = normalize(float3(0, 1, 0) - ray * dot(ray, float3(0, 1, 0)));
                float3 ray_rt = normalize(cross(ray, ray_up));

                float up = dot(normal, ray_rt);
                float rt = dot(normal, ray_up);

                float2 uv = origin + float2(rt, up) * radius;



                float4 matcap = tex2D(_MainTex, uv);


                // sample the texture
                fixed4 col = matcap;
                return col;
            }
            ENDCG
        }
    }
}
