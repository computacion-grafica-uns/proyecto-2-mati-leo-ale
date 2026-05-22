using UnityEngine;

public class GeneradorEscenaA : MonoBehaviour
{
    [Header("Prefabs de la Escena")]
    public GameObject modeloTetera;
    public GameObject prefabEstante;  
    public GameObject prefabPared;    

    [Header("Configuración de la Grilla (Plano XY)")]
    public int filas = 3;
    public int columnas = 6;
    public float espaciadoX = 3.0f;
    public float espaciadoY = 2.5f; // Altura entre estantes

    [Header("Ajustes de Alineación")]
    public float escalaTetera = 0.05f;
    public float offsetTeteraY = 0.1f; // Ajuste fino para que apoye sobre el estante
    public float grosorEstante = 0.1f;
    public float profundidadEstante = 1.5f;

    void Start()
    {
        ConstruirEscenaProcedural();
    }

    void ConstruirEscenaProcedural()
    {
        // Calculamos las dimensiones totales de la grilla para poder centrar los estantes y la pared
        float anchoTotal = (columnas - 1) * espaciadoX;
        float altoTotal = (filas - 1) * espaciadoY;
        Vector3 centroGrilla = new Vector3(anchoTotal / 2.0f, altoTotal / 2.0f, 0);

        // Generación de la pared del fondo
        if (prefabPared != null)
        {
            Vector3 posPared = new Vector3(centroGrilla.x, centroGrilla.y + 1.0f, 0.6f);            
            
            GameObject pared = Instantiate(prefabPared, posPared, Quaternion.Euler(-90, 0, 0));
            pared.name = "Pared_Fondo";
            pared.transform.SetParent(this.transform);

            pared.transform.localScale = new Vector3((anchoTotal + espaciadoX) * 0.1f, 1.0f, (altoTotal + espaciadoY) * 0.12f);
        }

        // Generación de estantes y teteras
        for (int fila = 0; fila < filas; fila++)
        {
            float alturaActual = fila * espaciadoY;

            if (prefabEstante != null)
            {
                Vector3 posEstante = new Vector3(centroGrilla.x, alturaActual, 0);
                GameObject estante = Instantiate(prefabEstante, posEstante, Quaternion.identity);
                estante.name = $"Estante_Fila_{fila}";
                estante.transform.SetParent(this.transform);

                estante.transform.localScale = new Vector3(anchoTotal + espaciadoX, grosorEstante, profundidadEstante);
            }

            // Crear las teteras sobre este estante
            for (int col = 0; col < columnas; col++)
            {
                Vector3 posTetera = new Vector3(col * espaciadoX, alturaActual + offsetTeteraY, 0);
                
                GameObject nuevaTetera = Instantiate(modeloTetera, posTetera, Quaternion.identity);
                nuevaTetera.transform.localScale = new Vector3(escalaTetera, escalaTetera, escalaTetera);
                nuevaTetera.name = $"Tetera_Fila{fila}_Col{col}";
                nuevaTetera.transform.SetParent(this.transform);
            }
        }
    }
}