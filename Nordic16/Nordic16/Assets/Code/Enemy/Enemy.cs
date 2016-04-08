using UnityEngine;
using System.Collections;

public class Enemy : MonoBehaviour {
    [SerializeField] DamageModelFlasher m_F;
    [SerializeField] float m_Health;

    [SerializeField] string m_GetHitSound;
    [SerializeField] string m_ExplosionSound;
    [SerializeField] string m_ExplosionParticle;
	void Start () 
	{
	
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
        Destroy(this.gameObject);
    }
    public void GetHit(float a_Damage)
    {
        AudioManager.SpawnAudioInstance(m_GetHitSound, transform.position);
        m_F.Hit();
        m_Health -= a_Damage;
    }
}
