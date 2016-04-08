using UnityEngine;
using System.Collections;

public class ProjectileInstance : MonoBehaviour {
    [SerializeField] float m_Speed;
    [SerializeField] Rigidbody m_Rigidbody;
	public void StartProjectile()
    {
        m_Rigidbody.velocity = m_Speed * transform.forward;
    }

    void Update()
    {
        
    }

    void OnCollisionEnter(Collision a_Other)
    {
        Player t_Player = a_Other.transform.GetComponent<Player>();
        if (t_Player)
        {
            
        }

        this.gameObject.SetActive(false);
    }
}
