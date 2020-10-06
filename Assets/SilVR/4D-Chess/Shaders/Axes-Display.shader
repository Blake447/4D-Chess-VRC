Shader "Unlit/Axes-Display"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Axes("Per Axis Visibility", Vector) = (1,1,1,1)
        _Ghost("Per Axis Opacity", Vector) = (1,1,1,1)

        _Matcap("Matcap", 2D) = "white" {}
        _Alpha("Alpha", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR;

                float3 normal : NORMAL;
                float3 tangent : TANGENT;

                float4 ghost : TEXCOORD2;

                float3 wpos : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _Matcap;
            float4 _MainTex_ST;
            float4 _Axes;
            float4 _Ghost;

            float _Alpha;

            // The purpose of this shader is to handle a specific gizmo for visualizing unit vectors in 4D space.
            // It allows the user to input two vectors, with components equal to either 0 or 1. These vectors
            // correspond to an x,y,z, and w axis. A "1" in the respective component of the _Axes vector will
            // make the axis visible in the first place, and a "1" in _Ghost will make it opaque as well.

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Cut the uv coordinates into two sections horizontally, and two sections vertically
                float uv_x_half = step(0.5, o.uv.x);
                float uv_y_half = step(0.5, o.uv.y);

                // Find the intersections of them to determine the quadrant we are in, referenced by color.
                // The texture Assets > SilVR > 4D-Chess > Textures > Gizmos > Axis is what these colors
                // align to.
                float red = (1-uv_x_half) * uv_y_half;
                float blu = uv_x_half * uv_y_half;
                float grn = (1 - uv_x_half) * (1 - uv_y_half);
                float alp = uv_x_half * (1 - uv_y_half);

                // Construct a float4 in which the location of a 1 determines what axis we're concerned about.
                // for example, if the mesh we are rendering is the x axis of the gizmo, its uv coordinates
                // will lie in the red range, and this float4 will be (1, 0, 0, 0)
                float4 axes = float4(red, blu, grn, alp);

                // Prepare to transfer this info to the fragment shader
                o.ghost = axes;

                // Use the dot product to determine if our portion of the mesh in question is to be visible,
                // as specified by the vector _Axes. For example, if _Axes was (1,0,1,0), the dot product would
                // be one for red and green, but zero for blue and alpha.
                float isVisible = saturate(dot(axes, _Axes));

                // Multiply the vertex position by the isVisible float. If visible, it unchanged. If not, its collapsed
                // into a single point and discarded by the rasterizer.
                o.vertex = UnityObjectToClipPos(v.vertex*isVisible);

                // Initialize float4 coordinates for sampling the colors
                float4 uv_x = float4(0.25, 0.75, 0.0, 0.0);
                float4 uv_y = float4(0.75, 0.75, 0.0, 0.0);
                float4 uv_z = float4(0.25, 0.25, 0.0, 0.0);
                float4 uv_w = float4(0.75, 0.25, 0.0, 0.0);

                // I believe this is unused, but I'd rather not delete it just in case
                float4 color = tex2Dlod(_MainTex, uv_z);
                o.color = color;

                // Transfer normal and tangent info to fragment shader
                o.normal = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.tangent = mul((float3x3)unity_ObjectToWorld, v.tangent);

                // transfer world position of the vertex to fragment shader (interpolates cleanly)
                o.wpos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // Calculate the normal
                float3 normal = normalize(i.normal);

                // Calculate the view direction ray and tangents
                float3 ray = normalize(i.wpos - _WorldSpaceCameraPos);
                float3 tangent = normalize(i.tangent);

                // define the center and radius of a 2D circle for use in sampling the matcap
                float2 origin = float2(0.5, 0.5);
                float radius = 0.5;

                // Use the component of the world space up vector not paralell to the view ray as the up vector
                float3 ray_up = normalize(float3(0, 1, 0) - ray * dot(ray, float3(0, 1, 0)));
                
                // Use that up vector to determine a right vector
                float3 ray_rt = normalize(cross(ray, ray_up));

                // compare to the normal vector to generate uv coordinates
                float up = dot(normal, ray_rt);
                float rt = dot(normal, ray_up);

                // Use the comparisons to construct uv coordinates for sampling from a matcap
                float2 mc_uv = origin + float2(rt, up).yx * radius;

                // Sample from the matcap for a bit of extra flare
                float4 matcap = tex2D(_Matcap, mc_uv);

                // Tint the matcap by the axis colors
                float3 color = tex2D(_MainTex, i.uv) * matcap;
                
                // Determine the transparency of the arrow. Note that completely hidden is covered in the vertex shader, so this is
                // either 1, or a user specified amount.
                float alpha = _Alpha + (1-_Alpha)*saturate(dot(i.ghost, _Ghost));

                // Construct our return color as a combination of the matcap color, axis color, and transparency.
                float4 col = float4(color, alpha);

                // return the fragment color.
                return col;
            }
            ENDCG
        }
    }
}
