using UnityEngine;
using System.Collections;

public class Player : MonoBehaviour {
    [SerializeField] float m_Health;

    [SerializeField] string m_GetHitSound;

    [SerializeField] MonoBehaviour[] m_PlayerScripts;
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
        if (m_Health <= 0) return;
        CameraShake.Shake(CameraShake.Reason.GetHit);
        AudioManager.SpawnAudioInstance(m_GetHitSound, transform.position);
        m_Health -= a_Damage;
        if (m_Health <= 0)
        {
            for (int i = 0; i < m_PlayerScripts.Length; i ++)
            {
                m_PlayerScripts[i].enabled = false;
            }
        }
    }
}
