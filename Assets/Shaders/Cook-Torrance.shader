Shader "Cook-Torrance"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)
        _Ka ("Ka", Color) = (0, 0, 0, 1)
        _Kd ("Kd", Color) = (0.5, 0.5, 0.5, 1) 

        [Toggle] _EnableDirLight ("Enable Directional Light", Float) = 1
        _DirLightDirection ("Directional Light Direction", Vector) = (0, -1, 1, 0) 
        [HDR] _DirLightColor ("Directional Light Color", Color) = (1, 1, 1, 1)

        [Toggle] _EnablePointLight ("Enable Point Light", Float) = 1
        _PointLightPosition ("Point Light Position", Vector) = (0, 2, 0, 1)
        [HDR] _PointLightColor ("Point Light Color", Color) = (1, 1, 1, 1)

        [Toggle] _EnableSpotLight ("Enable Spot Light", Float) = 1
        _SpotLightPosition ("Spot Light Position", Vector) = (0, 3, 0, 1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0, -1, 0, 0)
        [HDR] _SpotLightColor ("Spot Light Color", Color) = (1, 1, 1, 1)
        _Aperture("Aperture", Range(0.0, 90)) = 30.0

        _F0("F0", Vector) = (0.4, 0.4, 0.4)
        _rp("rp", Range(0.01, 1.0)) = 0.2

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
                float3 worldTangent : TANGENT;
                float3 worldBitangent : BINORMAL;
                float2 uv : TEXCOORD0;
            };

            float4 _AmbientLight;
            float4 _Ka;
            float4 _Kd;

            float4 _DirLightDirection;
            float4 _DirLightColor;
            float4 _PointLightPosition;
            float4 _PointLightColor;
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _Aperture;

            float3 _F0;
            float _rp;
            
            float _EnableDirLight;
            float _EnablePointLight;
            float _EnableSpotLight;

            sampler2D _MainTex;
            sampler2D _NormalMap;

            float3 F_Schlick(float3 V, float3 H)
            {
                float VdotH = max(0.0, dot(V, H));
                float x = 1.0 - VdotH;
                float x2 = x * x;
                float x5 = x2 * x2 * x; 
                return _F0 + (1.0 - _F0) * x5;
            }

            float D_GGX(float3 N, float3 H)
            {
                float alpha = _rp * _rp;
                float alpha2 = alpha * alpha;
                
                float NdotH = max(0.0, dot(N, H));
                float NdotH2 = NdotH * NdotH;
                
                float denom = NdotH2 * (alpha2 - 1.0) + 1.0;
                return alpha2 / (3.14159 * denom * denom);
            }

            float G1_Schlick_GGX(float3 N, float3 X)
            {
                float alpha = _rp * _rp;
                float k = alpha / 2.0;
                float NdotX = max(0.0, dot(N, X));
                
                return NdotX / (NdotX * (1.0 - k) + k);
            }

            float G_Smith(float3 L, float3 V, float3 N)
            {
                return G1_Schlick_GGX(N, L) * G1_Schlick_GGX(N, V);
            }

            float3 CalcularEspecular(float3 V, float3 H, float3 L, float3 N)
            {
                float NdotL = max(0.001, dot(N, L));
                float NdotV = max(0.001, dot(N, V));

                float3 F = F_Schlick(V, H);
                float D = D_GGX(N, H);
                float G = G_Smith(L, V, N);

                return (F * D * G) / (4.0 * NdotL * NdotV); 
            }
            
            float3 CalcularDireccional(float3 N, float3 V, float3 lightDir, float3 lightColor, float3 baseColor)
            {
                float3 L = normalize(-lightDir);
                float3 H = normalize(L + V);
                float NdotL = max(0.0, dot(N, L));

                float3 diffuse = baseColor * NdotL;
                float3 specular = CalcularEspecular(V, H, L, N);

                return lightColor * (diffuse + specular);
            }

            float3 CalcularPuntual(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightColor, float3 baseColor)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float3 H = normalize(L + V);
                
                float NdotL = max(0.0, dot(N, L));

                float attenFactor = 1.0 / dist;
                float3 diffuse = baseColor * NdotL;
                float3 specular = CalcularEspecular(V, H, L, N);
                
                return lightColor * attenFactor * (diffuse + specular);
            }

            float3 CalcularSpot(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightDir, float3 lightColor, float apertura, float3 baseColor)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float3 H = normalize(L + V);
                
                float NdotL = max(0.0, dot(N, L));
                
                float3 sDir = normalize(-lightDir);
                float currentCos = dot(L, sDir);
                float aperturaCos = cos(radians(apertura));
                
                float spotIntensity = smoothstep(aperturaCos, aperturaCos + 0.05, currentCos);
                float attenFactor = 1.0 / dist;
                
                float3 diffuse = baseColor * NdotL;
                float3 specular = CalcularEspecular(V, H, L, N);
                
                return lightColor * attenFactor * spotIntensity * (diffuse + specular);
            }

            float3 GenerarTexturaProcedural(float3 worldPos)
            {
                float3 color1 = float3(0.1, 0.6, 0.5); 
                float3 color2 = float3(0.05, 0.1, 0.15);

                float escalaPrincipal = 15.0; 
                float escalaDistorsion = 5.0; 
                float fuerzaDistorsion = 3.5; 

                // Generar la perturbación cruzando los ejes X e Y
                float perturbacion = sin(worldPos.x * escalaDistorsion) * sin(worldPos.y * escalaDistorsion);

                // Calcular el patrón principal sobre el eje Z, desplazando su fase con la perturbación
                float onda = sin(worldPos.z * escalaPrincipal + (perturbacion * fuerzaDistorsion));

                // Normalizar la onda de [-1, 1] a un rango de [0, 1]
                float factorMezcla = onda * 0.5 + 0.5;

                return lerp(color1, color2, factorMezcla);
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
                float3 baseColor = _Kd.rgb;

                #if USE_ALBEDO_MAP
                    baseColor = tex2D(_MainTex, i.uv).rgb;
                #elif USE_PROCEDURAL
                    baseColor = GenerarTexturaProcedural(i.worldPos.xyz);
                #endif

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

                float3 contribAmbient = _AmbientLight.rgb * _Ka.rgb;
                float3 contribDir = CalcularDireccional(N, V, _DirLightDirection.xyz, _DirLightColor.rgb, baseColor) * _EnableDirLight;
                float3 contribPoint = CalcularPuntual(N, V, i.worldPos, _PointLightPosition.xyz, _PointLightColor.rgb, baseColor) * _EnablePointLight;
                float3 contribSpot = CalcularSpot(N, V, i.worldPos, _SpotLightPosition.xyz, _SpotLightDirection.xyz, _SpotLightColor.rgb, _Aperture, baseColor) * _EnableSpotLight;
                
                float3 finalColor = contribAmbient + contribDir + contribPoint + contribSpot;

                return fixed4(finalColor, _Kd.a);
            }
            ENDCG
        }
    }
}