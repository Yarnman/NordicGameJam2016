using UnityEngine;
using System.Collections;

public class Player : MonoBehaviour {
    [SerializeField] float m_Health;

    [SerializeField] string m_GetHitSound;
	void Start () 
	{
	
	}
	
	void Update () 
	{
	
	}

    public void GetHit(float a_Damage)
    {
        CameraShake.Shake(CameraShake.Reason.GetHit);
        AudioManager.SpawnAudioInstance(m_GetHitSound, transform.position);
        m_Health -= a_Damage;
    }
}
