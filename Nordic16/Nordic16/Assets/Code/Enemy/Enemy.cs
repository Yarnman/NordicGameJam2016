using UnityEngine;
using System.Collections;

public class Enemy : MonoBehaviour {
    [SerializeField] DamageModelFlasher m_F;
    [SerializeField] float m_StartHealth;

    [SerializeField] string m_GetHitSound;
    [SerializeField] string m_ExplosionSound;
    [SerializeField] string m_ExplosionParticle;
    [SerializeField] string m_SpawnSound;
    [SerializeField] string m_SpawnParticle;
    [SerializeField] DroneMovement m_DroneMovement;
    float m_Health;
	void Start () 
	{
        Spawn();
	}
	
	void Update () 
	{
	    if (Input.GetKeyDown(KeyCode.Space))
        {
            GetHit(15);
        }
        if (m_Health <= 0)
        {
            Explode();
        }
	}

    public void Explode()
    {
        AudioManager.SpawnAudioInstance(m_ExplosionSound, transform.position);
        ParticleInstanceManager.SpawnSystem(m_ExplosionParticle, transform.position);
        CameraShake.Shake(CameraShake.Reason.Explosion);
        this.gameObject.SetActive(false);
    }
    public void GetHit(float a_Damage)
    {
        AudioManager.SpawnAudioInstance(m_GetHitSound, transform.position);
        m_F.Hit();
        m_Health -= a_Damage;
    }
    public void Spawn()
    {
        m_Health = m_StartHealth;

        AudioManager.SpawnAudioInstance(m_SpawnSound, transform.position);
        if (m_SpawnParticle.Length != 0) ParticleInstanceManager.SpawnSystem(m_SpawnParticle, transform.position);

        if (m_DroneMovement)
        {
            m_DroneMovement.enabled = true;
        }
    }
}
