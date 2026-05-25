Shader "ShaderToon"
{
    Properties
    {
        [Header(Configuracion Toon)]
        _ColorBase ("Color Base (A = Transparencia)", Color) = (0.5, 0.5, 0.5, 1)
        _Steps ("Cantidad de Bandas Toon", Range(1, 10)) = 3
        _BrilloMetalico ("Brillo Especifico Metal", Range(0.0, 1.0)) = 0.0
        
        [Header(Borde Comic)]
        _OutlineColor ("Color de Borde", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Grosor de Borde", Range(0.0, 0.05)) = 0.01

        [Header(Luces Base)]
        _AmbientLight ("Ambient Light", Color) = (0.2, 0.2, 0.2, 1)

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

        [Header(Texturas)]
        [Toggle(USE_ALBEDO_MAP)] _UseAlbedoMap("Use 2D Texture", Float) = 0
        _MainTex("Base Color Map", 2D) = "white" {}

        [Toggle(USE_NORMAL_MAP)] _UseNormalMap("Use Normal Map", Float) = 0
        _NormalMap("Normal Map", 2D) = "bump" {}

        [Toggle(USE_PROCEDURAL)] _UseProcedural("Use Procedural Texture", Float) = 0
    }

    SubShader
    {
        // Configuramos transparencia general para todo el shader
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        
        // ==========================================
        // PASS 1: BORDE NEGRO DE CÓMIC (OUTLINE)
        // ==========================================
        Pass
        {
            Name "OUTLINE"
            Cull Front // Dibujamos solo la cara interna (al inflar, se ve como borde)
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            float _OutlineWidth;
            float4 _OutlineColor;
            float4 _ColorBase; // Necesitamos leer la transparencia del material

            v2f vert (appdata v)
            {
                v2f o;
                // Inflamos el modelo en la dirección de sus normales
                v.vertex.xyz += v.normal * _OutlineWidth;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // El borde negro copia la transparencia del objeto principal
                return fixed4(_OutlineColor.rgb, _ColorBase.a);
            }
            ENDCG
        }

        // ==========================================
        // PASS 2: COLOR TOON E ILUMINACIÓN
        // ==========================================
        Pass
        {
            Name "FORWARD"
            Cull Back
            
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag
            
            // Declaramos las keywords de las texturas
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

            // Variables Generales
            float4 _ColorBase;
            float _Steps;
            float _BrilloMetalico;
            float4 _AmbientLight;
            
            // Luces
            float _EnableDirLight;
            float4 _DirLightDirection;
            float4 _DirLightColor;
            
            float _EnablePointLight;
            float4 _PointLightPosition;
            float4 _PointLightColor;
            
            float _EnableSpotLight;
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _Aperture;

            // Texturas
            sampler2D _MainTex;
            sampler2D _NormalMap;

            // --- FUNCIONES MATEMÁTICAS TOON ---

            // Función para cortar cualquier luz en "bandas" y agregarle brillo blanco si es metal
            float3 AplicarEstiloToon(float NdotL, float3 lightColor, float3 baseColor, float3 V, float3 L, float3 N)
            {
                // 1. Convertimos la luz suave en escalones
                float luzEscalonada = floor(NdotL * _Steps) / _Steps;
                float3 colorIluminado = baseColor * lightColor * luzEscalonada;

                // 2. Si _BrilloMetalico > 0, calculamos un punto de reflejo blanco afilado
                float3 H = normalize(L + V);
                float NdotH = max(0.0, dot(N, H));
                // Si el brillo supera 0.95, hacemos un ping blanco puro
                float brillo = step(0.95, NdotH) * _BrilloMetalico; 

                return colorIluminado + (brillo * lightColor);
            }

            float3 CalcularDireccionalToon(float3 N, float3 V, float3 lightDir, float3 lightColor, float3 baseColor)
            {
                float3 L = normalize(-lightDir);
                float NdotL = max(0.0, dot(N, L));
                return AplicarEstiloToon(NdotL, lightColor, baseColor, V, L, N);
            }

            float3 CalcularPuntualToon(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightColor, float3 baseColor)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float NdotL = max(0.0, dot(N, L));

                // Usamos la misma atenuación de tu código original
                float attenFactor = 1.0 / dist; 
                float3 luzAtenuada = lightColor * attenFactor;
                
                return AplicarEstiloToon(NdotL, luzAtenuada, baseColor, V, L, N);
            }

            float3 CalcularSpotToon(float3 N, float3 V, float3 worldPos, float3 lightPos, float3 lightDir, float3 lightColor, float apertura, float3 baseColor)
            {
                float3 toPoint = lightPos - worldPos;
                float dist = length(toPoint);
                float3 L = toPoint / dist;
                float NdotL = max(0.0, dot(N, L));

                // Matemáticas del cono de luz
                float3 sDir = normalize(-lightDir);
                float currentCos = dot(L, sDir);
                float aperturaCos = cos(radians(apertura));
                
                float spotIntensity = smoothstep(aperturaCos, aperturaCos + 0.05, currentCos);
                float attenFactor = 1.0 / dist;
                float3 luzAtenuada = lightColor * attenFactor * spotIntensity;

                return AplicarEstiloToon(NdotL, luzAtenuada, baseColor, V, L, N);
            }

            // Misma textura procedural que en Cook-Torrance
            float3 GenerarTexturaProcedural(float3 worldPos)
            {
                float3 color1 = float3(0.1, 0.6, 0.5); 
                float3 color2 = float3(0.05, 0.1, 0.15);
                float escalaPrincipal = 15.0; 
                float escalaDistorsion = 5.0; 
                float fuerzaDistorsion = 3.5; 
                float perturbacion = sin(worldPos.x * escalaDistorsion) * sin(worldPos.y * escalaDistorsion);
                float onda = sin(worldPos.z * escalaPrincipal + (perturbacion * fuerzaDistorsion));
                float factorMezcla = onda * 0.5 + 0.5;
                return lerp(color1, color2, factorMezcla);
            }

            // --- VÉRTICE Y FRAGMENTO ---

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
                // 1. Resolvemos el Color Base según las casillas del Inspector
                float3 baseColor = _ColorBase.rgb;

                #if USE_ALBEDO_MAP
                    baseColor = tex2D(_MainTex, i.uv).rgb;
                #elif USE_PROCEDURAL
                    baseColor = GenerarTexturaProcedural(i.worldPos.xyz);
                #endif

                // 2. Resolvemos la Normal
                float3 N = normalize(i.worldNormal);

                #if USE_NORMAL_MAP
                    float3 tangentNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
                    float3 T = normalize(i.worldTangent);
                    float3 B = normalize(i.worldBitangent);
                    N = normalize(T * tangentNormal.x + B * tangentNormal.y + N * tangentNormal.z);
                #endif

                // 3. Vector de Vista
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // 4. Calculamos todas las luces sumadas
                float3 contribAmbient = _AmbientLight.rgb * baseColor;
                float3 contribDir = CalcularDireccionalToon(N, V, _DirLightDirection.xyz, _DirLightColor.rgb, baseColor) * _EnableDirLight;
                float3 contribPoint = CalcularPuntualToon(N, V, i.worldPos, _PointLightPosition.xyz, _PointLightColor.rgb, baseColor) * _EnablePointLight;
                float3 contribSpot = CalcularSpotToon(N, V, i.worldPos, _SpotLightPosition.xyz, _SpotLightDirection.xyz, _SpotLightColor.rgb, _Aperture, baseColor) * _EnableSpotLight;
                
                float3 finalColor = contribAmbient + contribDir + contribPoint + contribSpot;

                // Devolvemos el color calculado + la transparencia (Alpha) original
                return fixed4(finalColor, _ColorBase.a);
            }
            ENDCG
        }
    }
}