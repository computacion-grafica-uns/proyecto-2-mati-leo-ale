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
        _DirLightDirection ("Directional Light Direction", Vector) = (0, -1, 0, 0)
        [HDR] _DirLightColor ("Directional Light Color", Color) = (1, 1, 1, 1)

        [Toggle] _EnablePointLight ("Enable Point Light", Float) = 1
        _PointLightPosition ("Point Light Position", Vector) = (0, 2, 0, 1)
        [HDR] _PointLightColor ("Point Light Color", Color) = (1, 1, 1, 1)

        [Toggle] _EnableSpotLight ("Enable Spot Light", Float) = 1
        _SpotLightPosition ("Spot Light Position", Vector) = (0, 3, 0, 1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0, -1, 0, 0)
        [HDR] _SpotLightColor ("Spot Light Color", Color) = (1, 1, 1, 1)
        _Apertura("Apertura", Range(0.0, 90)) = 30.0

        [Header(Texturas)]
        [Toggle(USE_ALBEDO_MAP)] _UseAlbedoMap("Use 2D Texture", Float) = 0
        _MainTex("Base Color", 2D) = "white" {}

        [Toggle(USE_NORMAL_MAP)] _UseNormalMap("Use Normal Map", Float) = 0
        _NormalMap("Normal Map", 2D) = "bump" {}

        [Toggle(USE_PROCEDURAL)] _UseProcedural("Use Procedural Texture", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature USE_ALBEDO_MAP
            #pragma shader_feature USE_NORMAL_MAP
            #pragma shader_feature USE_PROCEDURAL

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float3 worldTangent : TANGENT;
                float3 worldBitangent : BINORMAL;
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

            sampler2D _MainTex;
            sampler2D _NormalMap;

            // Blinn-Phong para luz direccional
            float3 CalcularDireccional(float3 N, float3 V, float3 lightDir, float3 lightColor, float3 baseColor)
            {
                float3 L = normalize(-lightDir);
                float3 H = normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float HdotN = max(0.0, dot(H, N));

                float3 diffuse = baseColor * NdotL;
                float3 specular = _Ks.rgb * pow(HdotN, _n);

                return lightColor * (diffuse + specular);
            }

            // Blinn-Phong para luz puntual
            float3 CalcularPuntual(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightColor, float3 baseColor)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float3 H = normalize(L + V);
                
                float NdotL = max(0.0, dot(N, L));
                float HdotN = max(0.0, dot(H, N));
                float attenFactor = 1.0 / dist;
                
                float3 diffuse = baseColor * NdotL;
                float3 specular = _Ks.rgb * pow(HdotN, _n);
                
                return lightColor * attenFactor * (diffuse + specular);
            }

            // Blinn-Phong para luz spot
            float3 CalcularSpot(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightDir, float3 lightColor, float apertura, float3 baseColor)
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
                
                float3 diffuse = baseColor * NdotL;
                float3 specular = _Ks.rgb * pow(HdotN, _n);
                
                return lightColor * attenFactor * spotIntensity * (diffuse + specular);
            }

            float3 hash33(float3 p)
            {
                p = float3(dot(p, float3(127.1, 311.7, 74.7)),
                           dot(p, float3(269.5, 183.3, 246.1)),
                           dot(p, float3(113.5, 271.9, 124.6)));
                return frac(sin(p) * 43758.5453123);
            }

            float voronoiGrietas3D(float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);

                float minDist = 8.0;
                float segundaMinDist = 8.0;

                for(int k = -1; k <= 1; k++)
                for(int j = -1; j <= 1; j++)
                for(int i = -1; i <= 1; i++)
                {
                    float3 b = float3(float(i), float(j), float(k));
                    float3 randPoint = hash33(p + b);
                    float3 r = b - f + randPoint;
                    float d = dot(r, r); 

                    if(d < minDist)
                    {
                        segundaMinDist = minDist;
                        minDist = d;
                    }
                    else if(d < segundaMinDist)
                    {
                        segundaMinDist = d;
                    }
                }

                return sqrt(segundaMinDist) - sqrt(minDist);
            }

            float3 GenerarTexturaProcedural(float3 worldPos) 
            {
      
                float scale = 5.0; 

                float3 posDistorsionada = worldPos + (sin(worldPos * 15.0) * 0.03);

                float distanciaBorde = voronoiGrietas3D(posDistorsionada * scale);

                float factorGrieta = smoothstep(0.01, 0.06, distanciaBorde); 

                float3 colorTierra = float3(0.72, 0.72, 0.72); 
                float3 colorGrieta = float3(0.34, 0.34, 0.34); 
    
                return lerp(colorGrieta, colorTierra, factorGrieta);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                o.worldBitangent = cross(o.worldNormal, o.worldTangent) * tangentSign;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 N = normalize(i.worldNormal);

                #if USE_NORMAL_MAP
                    // Leemos el color del normal map y lo convertimos a un vector de dirección [-1, 1]
                    float3 tangentNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
    
                    float3 T = normalize(i.worldTangent);
                    float3 B = normalize(i.worldBitangent);
    
                    // Multiplicamos el vector de la textura por la matriz TBN para perturbar la normal 'N'
                    N = normalize(T * tangentNormal.x + B * tangentNormal.y + N * tangentNormal.z);
                #endif

                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // Término ambiente general
                float3 contribAmbient = _AmbientLight.rgb * _Ka.rgb;
                float3 colorBase = _Kd.rgb;

                #if USE_ALBEDO_MAP
                    colorBase = tex2D(_MainTex, i.uv).rgb;
                #elif USE_PROCEDURAL
                    colorBase = GenerarTexturaProcedural(i.worldPos.xyz);
                #endif



                // Contribuciones individuales de cada luz (difuso + especular)
                float3 contribDir = CalcularDireccional(N, V, _DirLightDirection.xyz, _DirLightColor.rgb, colorBase) * _EnableDirLight;
                float3 contribPoint = CalcularPuntual(N, V, i.worldPos, _PointLightPosition.xyz, _PointLightColor.rgb, colorBase) * _EnablePointLight;
                float3 contribSpot = CalcularSpot(N, V, i.worldPos, _SpotLightPosition.xyz, _SpotLightDirection.xyz, _SpotLightColor.rgb, _Apertura, colorBase) * _EnableSpotLight;
                
                float3 finalColor = contribAmbient + contribDir + contribPoint + contribSpot;

                return fixed4(finalColor, _Kd.a);
            }
            ENDCG
        }
    }
}