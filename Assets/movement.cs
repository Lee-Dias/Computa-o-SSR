using UnityEngine;

public class Movement : MonoBehaviour
{
    [SerializeField]
    private float mainSpeed = 10.0f; // regular speed
    [SerializeField]
    private float camSens = 0.25f; // Camera sensitivity for mouse movement
    private Vector2 rotation = Vector2.zero; // To store the current rotation

    public void Start()
    {
        // Lock the cursor to the center of the screen and hide it.
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        // Mouse movement to rotate the camera
        rotation.x += Input.GetAxis("Mouse X") * camSens;
        rotation.y -= Input.GetAxis("Mouse Y") * camSens;

        // Clamp the vertical rotation (pitch) to avoid flipping the camera
        rotation.y = Mathf.Clamp(rotation.y, -90f, 90f);

        // Apply rotation to the camera
        transform.eulerAngles = new Vector3(rotation.y, rotation.x, 0);

        // Keyboard movement for WASD and Shift for running
        Vector3 p = GetBaseInput();
        if (p.sqrMagnitude > 0) // only move while a direction key is pressed
        {
            p = p * mainSpeed; // normal movement speed
            

            p = p * Time.deltaTime;

            // Apply movement based on Spacebar for Y-axis control
            if (Input.GetKey(KeyCode.Space)) // If player wants to move on X and Z axis only
            {
                Vector3 newPosition = transform.position;
                transform.Translate(p);
                newPosition.x = transform.position.x;
                newPosition.z = transform.position.z;
                transform.position = newPosition;
            }
            else
            {
                transform.Translate(p);
            }
        }
    }

    private Vector3 GetBaseInput() // Returns the basic values based on keyboard input
    {
        Vector3 p_Velocity = new Vector3();
        if (Input.GetKey(KeyCode.W))
        {
            p_Velocity += new Vector3(0, 0, 1);
        }
        if (Input.GetKey(KeyCode.S))
        {
            p_Velocity += new Vector3(0, 0, -1);
        }
        if (Input.GetKey(KeyCode.A))
        {
            p_Velocity += new Vector3(-1, 0, 0);
        }
        if (Input.GetKey(KeyCode.D))
        {
            p_Velocity += new Vector3(1, 0, 0);
        }
        return p_Velocity;
    }
}
