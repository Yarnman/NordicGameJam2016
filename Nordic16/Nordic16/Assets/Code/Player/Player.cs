using UnityEngine;
using System.Collections;

public class Player : MonoBehaviour {
    [SerializeField] float m_Health;

    [SerializeField] string m_GetHitSound;
    [SerializeField] string m_DeathSound;
    [SerializeField] MonoBehaviour[] m_PlayerScripts;
    [SerializeField] PlayerGetHitSphere m_PlayerGetHitSphere;
    bool m_IsDead;
	void Start () 
	{
	
	}
	
	void Update () 
	{
	
	}

    public bool IsAlive()
    {
        return (m_Health > 0);
    }

    public void GetHit(float a_Damage)
    {
        if (m_IsDead) return;
        m_PlayerGetHitSphere.Hit();
        CameraShake.Shake(CameraShake.Reason.GetHit);
        AudioManager.SpawnAudioInstance(m_GetHitSound, transform.position);
        m_Health -= a_Damage;
        if (m_Health <= 0)
        {
            Die();
        }
    }

    void Die()
    {
        if (m_IsDead) return;
        for (int i = 0; i < m_PlayerScripts.Length; i++)
        {
            m_PlayerScripts[i].enabled = false;
        }
        AudioManager.SpawnAudioInstance(m_DeathSound, transform.position);
        m_IsDead = true;
        m_Health = 0;
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
