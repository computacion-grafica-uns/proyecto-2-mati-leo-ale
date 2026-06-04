using System.Collections.Generic;
using UnityEngine;

public class ControladorCamara : MonoBehaviour
{
    [Header("Sistemas de Cámara")]
    public GameObject camaraOrbitalObj;
    public GameObject jugadorFPSObj;
    public CamaraOrbital camaraOrbital;

    [Header("Configuración de Escena")]
    public Vector3 centroEscena;
    public List<Transform> objetosDestacados = new List<Transform>();
    private int indiceActual = -1;

    void Start()
    {
        ActivarOrbital();
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.C) && camaraOrbitalObj != null && jugadorFPSObj != null)
        {
            if (camaraOrbitalObj.activeSelf)
                ActivarFPS();
            else
                ActivarOrbital();
        }

        if (camaraOrbitalObj != null && camaraOrbitalObj.activeSelf && objetosDestacados.Count > 0)
        {
            if (Input.GetKeyDown(KeyCode.RightArrow))
            {
                indiceActual++;
                if (indiceActual >= objetosDestacados.Count) indiceActual = 0;
                camaraOrbital.CambiarObjetivo(objetosDestacados[indiceActual].position, 4f);
            }

            if (Input.GetKeyDown(KeyCode.LeftArrow))
            {
                indiceActual--;
                if (indiceActual < 0) indiceActual = objetosDestacados.Count - 1;
                camaraOrbital.CambiarObjetivo(objetosDestacados[indiceActual].position, 4f);
            }

            if (Input.GetKeyDown(KeyCode.Space))
            {
                indiceActual = -1;
                camaraOrbital.CambiarObjetivo(centroEscena, 15f); 
            }
        }
    }

    void ActivarOrbital()
    {
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(true);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(false);
        
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    void ActivarFPS()
    {
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(false);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(true);
        
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }
}