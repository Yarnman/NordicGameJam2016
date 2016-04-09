using UnityEngine;
using System.Collections;

public class PlayerMovement : MonoBehaviour {
    [SerializeField] float m_MaxSpeed;
    [SerializeField] float m_TerminalSpeed;
    [SerializeField] float m_Acceleration;
    [SerializeField] float m_Drag;
    [SerializeField] CharacterController m_Char;
    Vector3 m_Movement;
	void Start () 
	{
	
	}
	void Update()
    {
        float t_X = Input.GetAxis("Horizontal");
        float t_Y = Input.GetAxis("Vertical");
        Vector3 t_Input = new Vector3(t_X, 0.0f, t_Y);

        if (t_Input.magnitude > 1)
        {
            t_Input.Normalize();
        }
        Vector3 t_Accel = transform.rotation * t_Input * m_Acceleration * Time.deltaTime;
        if (Vector3.Dot(m_Movement, t_Accel.normalized) <= m_MaxSpeed)
        {
            m_Movement += t_Accel;
        }
        //else
        if (m_Movement.magnitude >= m_Drag * Time.deltaTime)
        {
            m_Movement -= m_Drag * Time.deltaTime * m_Movement.normalized;
        }
        m_Movement = Vector3.ClampMagnitude(m_Movement, m_TerminalSpeed);
        m_Char.Move(m_Movement * Time.deltaTime);
    }

    public void AddKnockback(Vector3 a_Knockback)
    {
        m_Movement += a_Knockback;
    }

    void OnControllerColliderHit(ControllerColliderHit hit)
    {
        float t_Dot = Vector3.Dot(m_Movement, hit.normal);
        if (t_Dot < 0)
        {
            m_Movement -= t_Dot * hit.normal;
        }
    }

    void OnTriggerEnter(Collider a_Other)
    {
        CombatTrigger t_Trigger = a_Other.gameObject.GetComponent<CombatTrigger>();
        if (t_Trigger != null)
        {
            t_Trigger.PlayerEnters();
        }
    }
}
