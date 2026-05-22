Shader "Custom/ComicShader"
{
    Properties
    {
        _Color ("Color Base", Color) = (0.9, 0.3, 0.3, 1)
        _LightIntensity ("Intensidad de Luz", Float) = 1.0
        _LightPosition_w ("Posicion de Luz", Vector) = (0, 5, 0, 1)
        
        // Propiedades Toon
        _Steps ("Cantidad de Bandas Toon", Range(1, 10)) = 3
        
        // Propiedades Cómic (Borde)
        _OutlineColor ("Color de Tinta (Borde)", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Grosor del Borde", Range(0.001, 0.05)) = 0.01

        // Propiedades Cómic (Puntitos de Sombra)
        _HalftoneFreq ("Frecuencia de Puntos", Float) = 150.0
        _ShadowThreshold ("Umbral de Sombra", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // ==========================================
        // PASS 1: EL BORDE DE TINTA (OUTLINE)
        // ==========================================
        Pass
        {
            Name "OUTLINE"
            // "Cull Front" dibuja el interior del modelo en lugar del exterior.
            // Al "inflarlo", solo vemos el contorno negro asomándose por detrás.
            Cull Front 

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

            v2f vert (appdata v)
            {
                v2f o;
                // Movemos los vértices hacia afuera siguiendo su normal para "inflar" el objeto
                v.vertex.xyz += v.normal * _OutlineWidth;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Pintamos todo de negro (o el color de tinta que elijas)
                return _OutlineColor;
            }
            ENDCG
        }

        // ==========================================
        // PASS 2: EL COLOR TOON + PUNTITOS (HALFTONE)
        // ==========================================
        Pass
        {
            Name "FORWARD"
            Cull Back // Dibujamos las caras normales

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 position_w : TEXCOORD0;
                float3 normal_w : TEXCOORD1;
                float4 screenPos : TEXCOORD2; // Necesitamos saber la posición en la pantalla
            };

            float4 _Color;
            float _LightIntensity;
            float4 _LightPosition_w;
            float _Steps;
            float _HalftoneFreq;
            float _ShadowThreshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal_w = UnityObjectToWorldNormal(v.normal);
                
                // Calculamos la posición del píxel en la pantalla del monitor
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 n = normalize(i.normal_w);
                float3 l = normalize(_LightPosition_w.xyz - i.position_w);

                // --- 1. LUZ TOON BASE ---
                float NdotL = max(0.0, dot(n, l));
                float toonLight = floor(NdotL * _Steps) / _Steps;

               // --- 2. TRAMA DE PUNTITOS (HALFTONE) ---
                
                // OPCIÓN A: Pegados a la pantalla (Efecto Spider-Verse)
                // float2 coords = i.screenPos.xy / i.screenPos.w;
                
                // OPCIÓN B: Pegados al objeto (Se mueven con el modelo)
                // Usamos position_w (coordenadas del mundo) para que envuelva al objeto sin importar sus UVs
                float2 coords = i.position_w.xy; // Podés probar .xz o .yz dependiendo de qué cara mires
                
                // CAMBIO CLAVE: Usamos suma (+) en lugar de multiplicación (*) para hacer círculos
                float patron = sin(coords.x * _HalftoneFreq) + sin(coords.y * _HalftoneFreq);
                
                // Jugando con este número (ej. 0.5 en vez de 0.0) hacés que los puntos sean más chicos o más grandes
                float puntosDeTinta = step(0.5, patron);

                // --- 3. MEZCLA FINAL ---
                // Si la luz en este píxel es menor al umbral de sombra, le aplicamos los puntitos.
                // Si no, lo dejamos liso.
                float3 colorFinal = _Color.rgb * _LightIntensity * toonLight;
                
                if (NdotL < _ShadowThreshold)
                {
                    // Multiplicar por puntosDeTinta hace que los puntos sean negros
                    colorFinal *= puntosDeTinta; 
                }

                return fixed4(colorFinal, 1.0);
            }
            ENDCG
        }
    }
}