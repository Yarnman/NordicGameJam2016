using UnityEngine;
using System.Collections;

public class PlayerGun : MonoBehaviour {//GUUUUUUUUUUUUUUUUUUUUNS
    [SerializeField] Transform m_GunModel;
    [SerializeField] string m_BulletImpactParticleName;
    [SerializeField] string m_FireButton;
    [SerializeField] float m_WaitTime;
    [SerializeField] float damage;
    [SerializeField] LayerMask m_Layermask;

    float m_LastFireTime;
	void Start () 
	{
	
	}
	
	void Update () 
	{
        Debug.Log(Input.GetAxis("LeftTrigger") + " "  + Input.GetAxis("RightTrigger") + "        " + Time.time);
	    if (Input.GetButton(m_FireButton))
        {
            if (Time.time - m_LastFireTime >= m_WaitTime)
            { 
                Fire();
                m_LastFireTime = Time.time;
            }
        }
        else
        {
            m_LastFireTime = 0.0f;
        }
	}

    void Fire()
    {
        RaycastHit t_RaycastHit;
        if (Physics.Raycast(transform.position, transform.forward, out t_RaycastHit, float.MaxValue, m_Layermask))
        {
            Enemy enemy = t_RaycastHit.transform.GetComponent<Enemy>();
            if (enemy)
            enemy.GetHit(damage);

            ParticleInstanceManager.SpawnSystem(m_BulletImpactParticleName, t_RaycastHit.point, Quaternion.LookRotation(t_RaycastHit.normal));
        }
    }
}
