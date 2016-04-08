using UnityEngine;
using System.Collections;

public class PlayerMovement : MonoBehaviour {
    [SerializeField] float m_MaxSpeed;
    [SerializeField] float m_Acceleration;
    [SerializeField] CharacterController m_Char;
    Vector3 m_Movement;
	void Start () 
	{
	
	}
	void Update()
    {
        float t_X = Input.GetAxis("Horizontal");
        float t_Y = Input.GetAxis("Vertical");
        Vector3 t_Movement = new Vector3(t_X, 0.0f, t_Y);

        if (t_Movement.magnitude > 1)
        {
            t_Movement.Normalize();
        }
        m_Movement = t_Movement;
        m_Movement *= m_MaxSpeed * Time.deltaTime;
        m_Char.Move(transform.rotation * m_Movement);
    }
}
