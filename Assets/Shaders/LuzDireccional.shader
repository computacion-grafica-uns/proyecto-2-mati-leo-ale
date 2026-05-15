Shader "LuzDireccional"
{
    Properties
    {
        [NoScaleOffset] _DirLightDirection ("Directional Light Direction", Vector) = (0, -1, 0, 0)
        [NoScaleOffset] _DirLightColor ("Directional Light Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
            };

            float4 _DirLightDirection;
            float4 _DirLightColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 L = normalize(-_DirLightDirection);
                float NdotL = max(0, dot(i.worldNormal, L));
                return _DirLightColor * NdotL;
            }
            
            ENDCG
        }
    }
}