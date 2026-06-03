using UnityEngine;

public class CamaraPrimeraPersona : MonoBehaviour
{
    [Header("Movimiento")]
    public float velocidadCaminar = 5f;
    public float velocidadCorrer = 10f;

    [Header("Mirada")]
    public float sensibilidadMouse = 2f;
    public Transform camaraTransform;

    private float rotacionX = 0f;

    void Update()
    {
        float mouseX = Input.GetAxis("Mouse X") * sensibilidadMouse;
        float mouseY = Input.GetAxis("Mouse Y") * sensibilidadMouse;

        rotacionX -= mouseY;
        rotacionX = Mathf.Clamp(rotacionX, -90f, 90f);

        camaraTransform.localRotation = Quaternion.Euler(rotacionX, 0f, 0f);
        transform.Rotate(Vector3.up * mouseX);

        float velocidadActual = Input.GetKey(KeyCode.LeftShift) ? velocidadCorrer : velocidadCaminar;
        
        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");

        Vector3 movimiento = transform.right * x + transform.forward * z;
        transform.position += movimiento * velocidadActual * Time.deltaTime;
    }
}