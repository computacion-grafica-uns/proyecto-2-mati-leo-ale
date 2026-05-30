using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ControladorLuces : MonoBehaviour
{
    public Transform luzDireccionalObj;
    public Transform luzPuntualObj;
    public Transform luzSpotObj;

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

    public bool luzDireccionalActiva = true;
    public bool luzPuntualActiva = true;
    public bool luzSpotActiva = true;

    void Start()
    {
        
    }

    void Update()
    {
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

            mat.SetFloat("_EnableDirLight", luzDireccionalActiva ? 1.0f : 0.0f);
            mat.SetFloat("_EnablePointLight", luzPuntualActiva ? 1.0f : 0.0f);
            mat.SetFloat("_EnableSpotLight", luzSpotActiva ? 1.0f : 0.0f);
        }
    }
}
