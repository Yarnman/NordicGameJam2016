using UnityEngine;
using System.Collections;

public class EnemyGun : MonoBehaviour {
    [SerializeField] float m_WaitTime;
    [SerializeField] string m_ProjectileName;
    Player m_Player;
    float m_LastFireTime;
    void Start () 
	{
        m_Player = FindObjectOfType<Player>();
        m_LastFireTime = Time.time - Random.Range(0.0f, m_WaitTime);
    }
	
	void Update () 
	{
        if (Time.time - m_LastFireTime >= m_WaitTime)
        {
            Fire();
            m_LastFireTime = Time.time;
        }
        transform.parent.LookAt(m_Player.transform);
    }

    void Fire()
    {
        if (m_Player == null)
        {
            return;
        }

        ProjectileInstanceManager.SpawnProjectile(m_ProjectileName, transform.position, (m_Player.transform.position - transform.position).normalized);
    }
}
