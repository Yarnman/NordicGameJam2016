using UnityEngine;
using System.Collections;

public class PlayerGun : MonoBehaviour {//GUUUUUUUUUUUUUUUUUUUUNS
    [SerializeField] GunShake m_GunShake;
    [SerializeField] Transform m_GunMuzzle;
    [SerializeField] string m_BulletImpactParticleName;
    [SerializeField] string m_MuzzleFlashParticleName;
    [SerializeField] string m_FireSound;
    [SerializeField] string m_BulletImpactSound;
    [SerializeField] string m_FireButton;
    [SerializeField] string m_FireAxis;
    [SerializeField] string m_BackFireButton;
    [SerializeField] string m_BackFireAxis;
    public float m_WaitTime;
    [SerializeField] float damage;
    [SerializeField] LayerMask m_Layermask;
    [SerializeField] float m_knockback;
    [SerializeField] PlayerMovement m_PlayerMove;
    float m_LastFireTime;
    public bool m_IsFiring;
    public bool m_DidJustFire;
    public bool m_IsFiringBackwards;
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
                Fire(true);
                m_LastFireTime = Time.time;
            }
            CameraShake.Shake(CameraShake.Reason.Shooting);
        }
        else if (Input.GetButton(m_BackFireButton) || Input.GetAxis(m_BackFireAxis) > 0)
        {
            m_IsFiring = true;
            if (Time.time - m_LastFireTime >= m_WaitTime)
            {
                m_DidJustFire = true;
                Fire(false);
                m_LastFireTime = Time.time;
            }
            CameraShake.Shake(CameraShake.Reason.Shooting);
        }
        else
        {
            m_IsFiring = false;
            m_LastFireTime = 0.0f;
            m_IsFiringBackwards = false;
        }
	}

    void Fire(bool a_Forwards)
    {
        m_IsFiringBackwards = !a_Forwards;
        Vector3 t_Direction = transform.forward;
        if (!a_Forwards)
        {
            t_Direction *= -1.0f;
        }
        m_GunShake.UpdateForwards();
        m_PlayerMove.AddKnockback(-t_Direction * m_knockback);
        RaycastHit t_RaycastHit;
        AudioManager.SpawnAudioInstance(m_FireSound, transform.position);
        if (Physics.Raycast(transform.position, t_Direction, out t_RaycastHit, float.MaxValue, m_Layermask))
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
