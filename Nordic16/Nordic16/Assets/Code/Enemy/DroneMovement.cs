using UnityEngine;
using System.Collections;

public class DroneMovement : MonoBehaviour {
    [SerializeField] Rigidbody m_Rigidbody;

    [SerializeField] float m_MaxVelocity;
    [SerializeField] float m_Acceleration;
    [SerializeField] float m_StopForce;
    [SerializeField] float m_DragForce;
    Player m_Player;
    void Start () 
	{
        m_Player = FindObjectOfType<Player>();
	}
	
	void Update () 
	{
	    if (m_Player == null)
        {
            return;
        }

        Vector3 t_Dir = (m_Player.transform.position - transform.position).normalized;

        Vector3 t_Velocity = m_Rigidbody.velocity;

        float t_Force = m_Acceleration;
        if (Vector3.Dot(t_Velocity, t_Dir) <= 0.5f)
        {
            t_Force += m_StopForce;
        }
        if (Vector3.Dot(t_Velocity, t_Dir) <= m_MaxVelocity)
        {
            t_Velocity += t_Dir * m_Acceleration * Time.deltaTime;
        }

        if (t_Velocity.magnitude >= m_MaxVelocity)
        {
            t_Velocity += t_Velocity.normalized * -m_DragForce * Time.deltaTime;
        }
        m_Rigidbody.velocity = t_Velocity;

        transform.LookAt(m_Player.transform);
	}
}
