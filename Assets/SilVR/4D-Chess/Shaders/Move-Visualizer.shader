Shader "Unlit/Move-Visualizer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Color("Color", Color) = (1,1,1,1)
        _Color2("Color", Color) = (1,1,1,1)


        _Bishop("bishop moveset", 2D) = "black" {}
        _King("King moveset", 2D) = "black" {}
        _Knight("Knight moveset", 2D) = "black" {}
        _Rook("Rook moveset", 2D) = "black" {}
        _Queen("Queen moveset", 2D) = "black" {}

        _Pawn("Pawn moveset", 2D) = "black" {}
        _PawnAttack("Pawn Attack moveset", 2D) = "black" {}


        _Vector("Coordinate", Vector) = (0,0,0,0)
        _Piece("Piece ID", int) = 0
        
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Vector;
            float4 _Color;
            float4 _Color2;

            int _Piece;

            sampler2D _Bishop;
            sampler2D _King;
            sampler2D _Knight;
            sampler2D _Rook;
            sampler2D _Queen;
            sampler2D _Pawn;
            sampler2D _PawnAttack;
            //sampler2D _Queen;

            // This shader operates on a specially prepared mesh that is 256 cubes superimposed on each other. Each
            // cube has uv coordinates centered in the center of a unique pixel, which is used to calculate an index
            // and 4D coordinate within the chess board for each one. The index ranges from 0-255, and the 4D coordinates
            // range from (0,0,0,0) to (3,3,3,3), the 4D coordinate essentially being a base 4 represenation of the index.

            // Method for converting between a cubes uv coordinate to an index from 0-255.
            int indexFromUV(float2 uv)
            {
                int index = (int)(uv.x * 16.0 + uv.y * 16.0 * 16.0);
                return index;
            }

            // Method for converting the index to the coordinate. Note that this is really just the algorithm for
            // converting to base 4
            int4 coordinateFromIndex(int index)
            {
                uint i = index;

                uint x = i % 4;
                i /= 4;

                uint y = i % 4;
                i /= 4;

                uint z = i % 4;
                i /= 4;

                uint w = i % 4;            
                return int4(x, y, z, w);
            
            }

            // Given an integer describing the moveset to use, the location of the piece being moved,
            // and some coordinate, determine whether or not the given coordinate is a valid move for
            // that piece.
            float vertexRule(int i, int4 piece, int4 coord)
            {
                // Calculate the coordinates relative position to the piece
                float4 difference = piece - coord;

                // Initialize a bunch of floats describing what piece we are using
                float bishop = 0;
                float king = 0;
                float knight = 0;
                float rook = 0;
                float queen = 0;
                float pawn = 0;

                // Handle edge case of given coordinate = piece coordinate
                if (dot(difference, difference) == 0)
                {
                    return false;
                }

                // Instead of using index directly, add one to the piece describer based on the index
                // (mostly for readability).
                if (i == 1)
                {
                    bishop += 1;
                }
                if (i == 2)
                {
                    king += 1;
                }
                if (i == 3)
                {
                    knight = 1;
                }
                if (i == 4)
                {
                    rook += 1;
                }
                if (i == 5)
                {
                    queen += 1;
                }

                // boolean for pawn movement
                bool pds = true;

                // 6 and 7 both refer to pawns, but traveling opposite directions.
                if (i == 6)
                {
                    pawn += 1;
                    pds = (difference.y < 0 || difference.w < 0);
                }
                if (i == 7)
                {
                    pawn += 1;
                    pds = (difference.y > 0 || difference.w > 0);
                }
                
                // So the piece movesets are stored in textures that take advantage of chess pieces movements mostly being symmetrical. We map the
                // x and y coordinate onto a single uv axis by treating the coordinate xy sub-vector as a base 4 representation of a number ranging
                // from 0-15, for which that index is scaled down to be used as the x component of the uv coordinate. The zw subvector is treated
                // similarly for the y component. Using the absolute values of the relative coordinate allows us to simplify the textures the ruleset
                // is stored in.
                float4 uv = float4( abs(difference.x) + abs(difference.y)*4 , abs(difference.z) + abs(difference.w) * 4, 0, 0) * (float)pds / 16.0;

                // We then determine if the coordinate is a valid move for all of the possible pieces
                float bishop_valid      =  1 - step(0.5, tex2Dlod(_Bishop       , uv).x);
                float king_valid        =  1 - step(0.5, tex2Dlod(_King         , uv).x);
                float knight_valid      =  1 - step(0.5, tex2Dlod(_Knight       , uv).x);
                float rook_valid        =  1 - step(0.5, tex2Dlod(_Rook         , uv).x);
                float queen_valid       =  1 - step(0.5, tex2Dlod(_Queen        , uv).x);
                float pawn_valid        =  1 - step(0.5, tex2Dlod(_Pawn         , uv).x);
                float pawn_valid_attack =  1 - step(0.5, tex2Dlod(_PawnAttack   , uv).x);

                // and weight the movement accordingly. Note that we saturate the weights of all the rules except the special case
                // where a pawn is attacking, which is the only case where this value will be more than one. We can then use this to
                // distinguish between not a valid move (0), a valid generic move (1), and a pawn attacking move (2+) in the visualizer.
                return saturate(
                                    bishop_valid    * bishop    +
                                    king_valid      * king      + 
                                    knight_valid    * knight    +
                                    rook_valid      * rook      +
                                    queen_valid     * queen     +
                                    pawn_valid      * pawn
                                )
                                + pawn_valid_attack * pawn * 2;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // Again, this shader operates on superimposed cubes assigned to unique pixels in the uv coordinates.
                // So for every cube (in paralell)

                // Calculate the index from the uv coordinate
                int index = indexFromUV(o.uv);

                // Calculate the coordinate of the cube based on its index
                int4 coord_int = coordinateFromIndex(index);

                // convert to float4 just because typing
                float4 coord = coord_int;

                // Scale up a basis of vectors based on the scale of the object, determined by the effect the world to object
                // matrix has on the magnitude of unit vectors
                float3 rt = float3(1, 0, 0) * length(mul((float3x3)unity_WorldToObject, float3(1, 0, 0)));
                float3 up = float3(0, 0, 1) * length(mul((float3x3)unity_WorldToObject, float3(0, 1, 0)));
                float3 fw = -float3(0, 1, 0) * length(mul((float3x3)unity_WorldToObject, float3(0, 0, 1)));;

                // Get the z scale by using a simlar method to the one above
                float z_scale = length(mul((float3x3)unity_WorldToObject, float3(0, 0, 1)));

                // Hard coded scale values. Hear me out on this, these values only operate locally, i.e. they are unaffected by
                // the prefabs scale, only this interfaces scale in relation to the chess boards scale. They were initially
                // left open as parameters, but were hard coded into this and the udon side of things once the values were found.
                // They are also hard coded on the udon side for the same reason, but also because multi-editing is disabled for
                // U# behaviors so hard coding actually the most convenient way to update prefabs for literally 80+ chess pieces.
                


                // Describes base scale for xy offsets, i.e. individual squares
                float xy_offset = 0.0825 / (z_scale * 4.8386);

                // Describes base scale for offsetting between z levels up and down
                float z_offset = 0.1235 / (z_scale * 4.8386);

                // Describes how much z levels shrink each time you go up (as a multiplicitive factor each time)
                float z_scaling = 0.9;

                // Describes offset between volumes of chess cubes as w coordinate shifts through them.
                float w_offset = 0.4125 / (z_scale * 4.8386);



                // initialize a coordinate
                float4 co = coord;

                // calculate vertical offset as the coordinate's z component times z offset scale times the up vector from the basis
                float3 z = co.z * z_offset * up;

                // calculate an offset from the origin square (the center of (0,0,0,0)) to the center of its xy section. The factor
                // of 1.5 describes that from the center of the corner square, you move 1.5 squares to get to the center of the board slice.
                float3 center = (rt + fw) * xy_offset * 1.5;

                // Determine how much the xy slice shrinks as a result of its z coordinate
                float scaler = pow(z_scaling, co.z);

                // Calculate a vector that goes from the center of a z-scaled xy slice to its origin square
                float3 un_center = -center * scaler;
                
                // Calculate the xy offset from the origin square of the z-scaled xy-slice
                float3 xy = (co.x * rt + co.y * fw) * xy_offset * scaler;

                // calcualate the w offset based on coordinate
                float3 w = fw * co.w * w_offset;

                // determine if we should show the visualizer cube at this location based on the piece type, the pieces coordinate,
                // and our cubes current coordinate as an int4.
                float isVisible = vertexRule(_Piece, (int4)_Vector, coord_int);
                
                // Determine if our visualized move is a pawn attack
                float pawnAttack = 1 - step(1.5, isVisible);
                
                // Get our visibility in range of 0-1 (i.e. discard info about pawn attack now that its in a differnet variable)
                isVisible = saturate(isVisible);

                // Offset the vertices of the cube based on its coordinate and the calculated offsets, and collapse the cubes
                // vertices to a single point to be discarded by the rasterizer if we want to hide the visualizers cube at the
                // current coordinate.
                o.vertex = UnityObjectToClipPos(v.vertex * isVisible + center + z + un_center + xy + w);

                // If we are visualizing a pawn attack, output a different color
                o.color = lerp(_Color, _Color2, 1-pawnAttack);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // return our visualizers color
                return i.color;
            }
            ENDCG
        }
    }
}
