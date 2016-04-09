using UnityEngine;
using System.Collections;

public class EnemyGun : MonoBehaviour {
    [SerializeField] float m_WaitTime;
    [SerializeField] string m_ProjectileName;
    [SerializeField] string m_FireParticleName;
    [SerializeField] ParticleSystem m_ChargeParticles;
    Player m_Player;
    float m_LastFireTime;
    void Start () 
	{
        m_Player = FindObjectOfType<Player>();
        m_LastFireTime = Time.time - Random.Range(0.0f, m_WaitTime);
    }
	
	void Update () 
	{
        if (Time.time - m_LastFireTime >= m_WaitTime * 3.0f)
        {
            m_LastFireTime = Time.time - Random.Range(0.0f, m_WaitTime);
        }
        if (m_WaitTime - (Time.time - m_LastFireTime) < m_ChargeParticles.duration && !m_ChargeParticles.isPlaying)
        {
            m_ChargeParticles.Play();
        }
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
        ParticleInstanceManager.SpawnSystem(m_FireParticleName, transform.position, Quaternion.LookRotation(transform.forward));
        ProjectileInstanceManager.SpawnProjectile(m_ProjectileName, transform.position, (m_Player.transform.position - transform.position).normalized);
    }
}
