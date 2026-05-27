using System.Collections.Generic;
using UnityEngine;

public class ControladorCamara : MonoBehaviour
{
    public CamaraOrbital camaraOrbital;
    public Vector3 centroEscena;
    public List<Transform> teteras = new List<Transform>();
    private int indiceActual = -1; 

    void Update()
    {
        if (teteras.Count == 0) return;

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            indiceActual++;
            if (indiceActual >= teteras.Count) indiceActual = 0; 
            camaraOrbital.CambiarObjetivo(teteras[indiceActual].position, 4f);
        }

        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            indiceActual--;
            if (indiceActual < 0) indiceActual = teteras.Count - 1; 
            camaraOrbital.CambiarObjetivo(teteras[indiceActual].position, 4f);
        }

        if (Input.GetKeyDown(KeyCode.Space))
        {
            indiceActual = -1; 
            camaraOrbital.CambiarObjetivo(centroEscena, 15f); 
        }
    }
}