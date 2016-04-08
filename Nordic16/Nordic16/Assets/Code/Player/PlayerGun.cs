using UnityEngine;
using System.Collections;

public class PlayerGun : MonoBehaviour {//GUUUUUUUUUUUUUUUUUUUUNS
    [SerializeField] Transform m_GunMuzzle;
    [SerializeField] string m_BulletImpactParticleName;
    [SerializeField] string m_MuzzleFlashParticleName;
    [SerializeField] string m_FireSound;
    [SerializeField] string m_BulletImpactSound;
    [SerializeField] string m_FireButton;
    [SerializeField] string m_FireAxis;
    public float m_WaitTime;
    [SerializeField] float damage;
    [SerializeField] LayerMask m_Layermask;

    float m_LastFireTime;
    public bool m_IsFiring;
    public bool m_DidJustFire;
	void Start () 
	{
	
	}
	
	void Update () 
	{
        //Debug.Log(Input.GetAxis("LeftTrigger") + " "  + Input.GetAxis("RightTrigger") + "        " + Time.time);
        m_DidJustFire = false;
	    if (Input.GetButton(m_FireButton) || Input.GetAxis(m_FireAxis) > 0)
        {
            m_IsFiring = true;
            if (Time.time - m_LastFireTime >= m_WaitTime)
            {
                m_DidJustFire = true;
                Fire();
                m_LastFireTime = Time.time;
            }
            CameraShake.Shake(CameraShake.Reason.Shooting);
        }
        else
        {
            m_IsFiring = false;
            m_LastFireTime = 0.0f;
        }
	}

    void Fire()
    {
        RaycastHit t_RaycastHit;
        AudioManager.SpawnAudioInstance(m_FireSound, transform.position);
        if (Physics.Raycast(transform.position, transform.forward, out t_RaycastHit, float.MaxValue, m_Layermask))
        {
            Enemy enemy = t_RaycastHit.transform.GetComponent<Enemy>();
            if (enemy)
            enemy.GetHit(damage);

            FragilePanelInstance panel = t_RaycastHit.transform.GetComponent<FragilePanelInstance>();
            if (panel)
                panel.GetHitByBullet(t_RaycastHit.point);

            ParticleInstanceManager.SpawnSystem(m_BulletImpactParticleName, t_RaycastHit.point, Quaternion.LookRotation(t_RaycastHit.normal));
            AudioManager.SpawnAudioInstance(m_BulletImpactSound, t_RaycastHit.point);
        }

        if (m_GunMuzzle != null)
        {
            ParticleInstanceManager.SpawnSystem(m_MuzzleFlashParticleName, m_GunMuzzle.position, m_GunMuzzle.rotation);
        }
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, 0.05f);
    }

    public float GetTimeFactor()
    {
        return ((Time.time - m_LastFireTime) / m_WaitTime);
    }
}
