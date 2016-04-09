using UnityEngine;
using System.Collections;

public class Player : MonoBehaviour {
    [SerializeField] float m_StartHealth;

    [SerializeField] string m_GetHitSound;
    [SerializeField] string m_DeathSound;
    [SerializeField] MonoBehaviour[] m_PlayerScripts;
    [SerializeField] PlayerGetHitSphere m_PlayerGetHitSphere;
    [SerializeField] float m_DeathWaitTime;

    float m_DeathTime;
    bool m_IsDead;
    float m_Health;
	void Start () 
	{
        m_Health = m_StartHealth;
	}
	
	void Update () 
	{
	    if (m_IsDead && Time.time - m_DeathTime >= m_DeathWaitTime && Input.anyKeyDown)
        {
            Application.LoadLevel(Application.loadedLevel);
        }
	}

    public bool IsAlive()
    {
        return (m_Health > 0);
    }

    public void GetHit(float a_Damage)
    {
        
        m_PlayerGetHitSphere.Hit();
        CameraShake.Shake(CameraShake.Reason.GetHit);
        AudioManager.SpawnAudioInstance(m_GetHitSound, transform.position);
        if (m_IsDead) return;
        m_Health -= a_Damage;
        if (m_Health <= 0)
        {
            Die();
        }
    }

    public float GetHealthFactor()
    {
        return Mathf.Clamp(m_Health / m_StartHealth, 0.0f, 1.0f);
    }

    void Die()
    {
        if (m_IsDead) return;
        m_PlayerGetHitSphere.Die();
        for (int i = 0; i < m_PlayerScripts.Length; i++)
        {
            m_PlayerScripts[i].enabled = false;
        }
        AudioManager.SpawnAudioInstance(m_DeathSound, transform.position);
        m_IsDead = true;
        m_Health = 0;
        m_DeathTime = Time.time;
    }

    void OnTriggerEnter(Collider a_Other)
    {
        VolumeCollector t_Trigger = a_Other.gameObject.GetComponent<VolumeCollector>();
        if (t_Trigger != null && t_Trigger.m_KillPlayerOnEnter)
        {
            Die();
        }
    }
}
