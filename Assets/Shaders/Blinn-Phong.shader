Shader "Blinn-Phong"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)
        _Ka ("Ka", Color) = (0, 0, 0, 1)
        _Kd ("Kd", Color) = (0, 0, 0, 1)
        _Ks ("Ks", Color) = (0, 0, 0, 1)
        _n ("n", float) = 1

        [Toggle] _EnableDirLight ("Enable Directional Light", Float) = 1
        [NoScaleOffset] _DirLightDirection ("Directional Light Direction", Vector) = (0, -1, 0, 0)
        [NoScaleOffset] _DirLightColor ("Directional Light Color", Color) = (1, 1, 1, 1)

        [Toggle] _EnablePointLight ("Enable Point Light", Float) = 1
        [NoScaleOffset] _PointLightPosition ("Point Light Position", Vector) = (0, 2, 0, 1)
        [NoScaleOffset] _PointLightColor ("Point Light Color", Color) = (1, 1, 1, 1)

        [Toggle] _EnableSpotLight ("Enable Spot Light", Float) = 1
        [NoScaleOffset] _SpotLightPosition ("Spot Light Position", Vector) = (0, 3, 0, 1)
        [NoScaleOffset] _SpotLightDirection ("Spot Light Direction", Vector) = (0, -1, 0, 0)
        [NoScaleOffset] _SpotLightColor ("Spot Light Color", Color) = (1, 1, 1, 1)
        _Apertura("Apertura", Range(0.0, 90)) = 30.0
    }

    SubShader
    {
        //Tags { "RenderType"="Opaque" }
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
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 worldPos : TEXCOORD1;
            };

            // Variables globales mapeadas desde Properties
            float4 _AmbientLight;
            float4 _Ka;
            float4 _Kd;
            float4 _Ks;
            float _n;

            float4 _DirLightDirection;
            float4 _DirLightColor;
            float4 _PointLightPosition;
            float4 _PointLightColor;
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _Apertura;

            float _EnableDirLight;
            float _EnablePointLight;
            float _EnableSpotLight;

            // Blinn-Phong para luz direccional
            float3 CalcularDireccional(float3 N, float3 V, float3 lightDir, float3 lightColor)
            {
                float3 L = normalize(-lightDir);
                float3 H = normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float HdotN = max(0.0, dot(H, N));

                float3 diffuse = _Kd.rgb * NdotL;
                float3 specular = _Ks.rgb * pow(HdotN, _n);

                return lightColor * (diffuse + specular);
            }

            // Blinn-Phong para luz puntual
            float3 CalcularPuntual(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightColor)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float3 H = normalize(L + V);
                
                float NdotL = max(0.0, dot(N, L));
                float HdotN = max(0.0, dot(H, N));
                float attenFactor = 1.0 / dist;
                
                float3 diffuse = _Kd.rgb * NdotL;
                float3 specular = _Ks.rgb * pow(HdotN, _n);
                
                return lightColor * attenFactor * (diffuse + specular);
            }

            // Blinn-Phong para luz spot
            float3 CalcularSpot(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightDir, float3 lightColor, float apertura)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float3 H = normalize(L + V);
                
                float3 sDir = normalize(-lightDir);
                float currentCos = dot(L, sDir);
                float aperturaCos = cos(radians(apertura));
                
                float spotIntensity = smoothstep(aperturaCos, aperturaCos + 0.05, currentCos);
                float attenFactor = 1.0 / dist;
                
                float NdotL = max(0.0, dot(N, L));
                float HdotN = max(0.0, dot(H, N));
                
                float3 diffuse = _Kd.rgb * NdotL;
                float3 specular = _Ks.rgb * pow(HdotN, _n);
                
                return lightColor * attenFactor * spotIntensity * (diffuse + specular);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 N = normalize(i.worldNormal);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // Término ambiente general
                float3 contribAmbient = _AmbientLight.rgb * _Ka.rgb;

                // Contribuciones individuales de cada luz (difuso + especular)
                float3 contribDir = CalcularDireccional(N, V, _DirLightDirection.xyz, _DirLightColor.rgb) * _EnableDirLight;
                float3 contribPoint = CalcularPuntual(N, V, i.worldPos, _PointLightPosition.xyz, _PointLightColor.rgb) * _EnablePointLight;
                float3 contribSpot = CalcularSpot(N, V, i.worldPos, _SpotLightPosition.xyz, _SpotLightDirection.xyz, _SpotLightColor.rgb, _Apertura) * _EnableSpotLight;
                
                float3 finalColor = contribAmbient + contribDir + contribPoint + contribSpot;

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}