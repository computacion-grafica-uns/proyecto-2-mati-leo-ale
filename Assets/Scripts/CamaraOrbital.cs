using UnityEngine;

public class CamaraOrbital : MonoBehaviour
{
    [Header("Objetivo y Posicionamiento")]
    public Vector3 objetivo;      
    public float distancia = 12f;  

    [Header("Límites de Zoom")]
    public float minDistancia = 2f;
    public float maxDistancia = 25f;

    [Header("Sensibilidad")]
    public float sensibilidadRotacion = 3f;
    public float sensibilidadZoom = 10f;

    private float anguloX = 0f;     
    private float anguloY = 45f;   

    void Start()
    {
        Vector3 angulos = transform.eulerAngles;
        anguloX = angulos.y;
        anguloY = angulos.x;
    }

    void Update()
    {
        if (objetivo == null) return;

        // Click derecho
        if (Input.GetMouseButton(1)) 
        {
            anguloX += Input.GetAxis("Mouse X") * sensibilidadRotacion;
            anguloY -= Input.GetAxis("Mouse Y") * sensibilidadRotacion;
        }

        anguloY = Mathf.Clamp(anguloY, 5f, 85f);

        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distancia -= scroll * sensibilidadZoom;
        distancia = Mathf.Clamp(distancia, minDistancia, maxDistancia);

        Quaternion rotacion = Quaternion.Euler(anguloY, anguloX, 0);
        Vector3 posicion = rotacion * new Vector3(0.0f, 0.0f, -distancia) + objetivo;

        transform.rotation = rotacion;
        transform.position = posicion;
    }

    public void CambiarObjetivo(Vector3 nuevoObjetivo, float nuevaDistancia)
    {
        objetivo = nuevoObjetivo;
        distancia = nuevaDistancia;
    }
}