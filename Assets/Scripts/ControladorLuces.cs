using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ControladorLuces : MonoBehaviour
{
    public Transform luzDireccionalObj;
    public Transform luzPuntualObj;
    public Transform luzSpotObj;
    public Transform luzSpotObj2;

    public Material[] materiales;
    public Vector3 luzDireccionalDir;
    public Color luzDireccionalColor;
    public Vector3 luzPuntualPos;
    public Color luzPuntualColor;
    public Vector3 luzSpotPos;
    public Vector3 luzSpotDir;
    public Color luzSpotColor; 
    [Range(0f, 90f)]
    public float luzSpotAperture = 30.0f;
    public Vector3 luzSpotPos2;
    public Vector3 luzSpotDir2;
    public Color luzSpotColor2; 
    [Range(0f, 90f)]
    public float luzSpotAperture2 = 30.0f;

    [Header("Interruptores")]
    public bool luzDireccionalActiva = true;
    public bool luzPuntualActiva = true;
    public bool luzSpotActiva = true;
    public bool luzSpotActiva2 = true;

    [Header("Efecto RGB")]
    private bool efectoRGBActivo = false;
    public float velocidadRGB = 0.15f;
    private Color colorSpotOriginal;

    void Start()
    {
        colorSpotOriginal = luzSpotColor;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.T))
        {
            efectoRGBActivo = !efectoRGBActivo;
            
            if (!efectoRGBActivo) luzSpotColor = colorSpotOriginal;
        }

        if (efectoRGBActivo)
        {
            float matiz = Mathf.Repeat(Time.time * velocidadRGB, 1f);
            luzSpotColor = Color.HSVToRGB(matiz, 1f, 1f);
        }

        if (luzDireccionalObj != null)
        {
            luzDireccionalDir = luzDireccionalObj.up; 
        }

        if (luzPuntualObj != null)
        {
            luzPuntualPos = luzPuntualObj.position;
        }

        if (luzSpotObj != null)
        {
            luzSpotPos = luzSpotObj.position;
            luzSpotDir = luzSpotObj.up;
        }

        if (luzSpotObj2 != null)
        {
            luzSpotPos2 = luzSpotObj2.position;
            luzSpotDir2 = luzSpotObj2.up;
        }

        foreach(Material mat in materiales)
        {
            mat.SetVector("_PointLightPosition", luzPuntualPos);
            mat.SetVector("_PointLightColor", luzPuntualColor);
            mat.SetVector("_SpotLightPosition", luzSpotPos);
            mat.SetVector("_SpotLightDirection", luzSpotDir);
            mat.SetVector("_SpotLightColor", luzSpotColor); 
            mat.SetFloat("_Aperture", luzSpotAperture);
            mat.SetVector("_DirLightDirection", luzDireccionalDir);
            mat.SetVector("_DirLightColor", luzDireccionalColor);
            mat.SetVector("_SpotLightPosition2", luzSpotPos2);
            mat.SetVector("_SpotLightDirection2", luzSpotDir2);
            mat.SetVector("_SpotLightColor2", luzSpotColor2); 
            mat.SetFloat("_Aperture2", luzSpotAperture2);

            mat.SetFloat("_EnableDirLight", luzDireccionalActiva ? 1.0f : 0.0f);
            mat.SetFloat("_EnablePointLight", luzPuntualActiva ? 1.0f : 0.0f);
            mat.SetFloat("_EnableSpotLight", luzSpotActiva ? 1.0f : 0.0f);
            mat.SetFloat("_EnableSpotLight2", luzSpotActiva2 ? 1.0f : 0.0f);
        }
    }
}