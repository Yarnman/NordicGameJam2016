using UnityEngine;
using System.Collections;

//Class to let the camera shake with varying severity when something in-game triggers it. 
//The three triggers are: An exploding entity, when the player gets hit and when the player dies.

public class CameraShake : MonoBehaviour {
    public enum Reason
    {
        Explosion,
        GetHit,
        PlayerDead,
        Shooting, 
        Puke,
        Direct
    }
    [SerializeField] float m_NormalMaxTime = 0;
    [SerializeField] float m_ShootMaxTime = 0;
    [SerializeField] float m_ExplosionDistance = 0;
    [SerializeField] float m_PlayerHitDistance = 0;
    [SerializeField] float m_PlayerDeadDistance = 0;
    [SerializeField] float m_PukeDistance = 0;
    [SerializeField] float m_ShootDistance;
    [SerializeField] AnimationCurve m_IntensityCurve = null;

    float m_StartTime;
    float m_MaxTime;
    float m_Distance;
    bool m_IsShaking;
    bool m_IsShootCurve;
    bool m_OneGunIsShooting;
    static CameraShake g_CameraShake;
	
	void Update ()
    {
        //Since the camera shake is not explicitly based on Time.deltaTime, return when the timescale is zero.
        if (Time.timeScale == 0.0f)
        {
            return;
        }
        m_OneGunIsShooting = false;
        if (m_IsShaking)
        {
            float t_Intensity = GetIntensity();
            //The camera is parented to an object and moves in a random circle around by changing its localPosition.
            transform.localPosition = Random.insideUnitSphere * t_Intensity;

            if ((Time.time - m_StartTime) / m_MaxTime >= 1.0f)
            {
                m_IsShaking = false;
                transform.localPosition = Vector3.zero;
            }
        }
    }

    float GetIntensity()
    {
        float t_RelativeTime = (Time.time - m_StartTime) / m_MaxTime;
        //An animationcurve allows for a smooth degradation of intensity.
        return m_IntensityCurve.Evaluate(t_RelativeTime) * m_Distance;
    }
    //Static method prevents every entity from searching for the camerashake object
    public static void Shake(Reason a_Reason, float a_Intensity = 0.0f)
    {
        if (g_CameraShake == null)
        {
            g_CameraShake = FindObjectOfType<CameraShake>();
            if (g_CameraShake == null)
            {
                return;
            }
        }

        float t_ProposedDistance = 0;
        g_CameraShake.m_IsShootCurve = false;
        g_CameraShake.m_MaxTime = g_CameraShake.m_NormalMaxTime;
        switch (a_Reason)
        {
            case Reason.Explosion:
                t_ProposedDistance = g_CameraShake.m_ExplosionDistance;
            break;
            case Reason.GetHit:
                t_ProposedDistance = g_CameraShake.m_PlayerHitDistance;
                break;
            case Reason.PlayerDead:
                t_ProposedDistance = g_CameraShake.m_PlayerDeadDistance;
                break;
            case Reason.Shooting:
                if (g_CameraShake.m_OneGunIsShooting)
                {
                    t_ProposedDistance = g_CameraShake.m_ShootDistance * 3.0f;
                }
                else
                {
                    t_ProposedDistance = g_CameraShake.m_ShootDistance;
                    g_CameraShake.m_OneGunIsShooting = true;
                }
                break;
            case Reason.Puke:
                t_ProposedDistance = g_CameraShake.m_PukeDistance;
                break;
            case Reason.Direct:
                t_ProposedDistance = a_Intensity;
                break;
        }
        
        if (t_ProposedDistance >= g_CameraShake.GetIntensity())
        {
            g_CameraShake.m_StartTime = Time.time;
            g_CameraShake.m_IsShaking = true;
            g_CameraShake.m_Distance = t_ProposedDistance;
            if (a_Reason == Reason.Shooting)
            {
                g_CameraShake.m_MaxTime = g_CameraShake.m_ShootMaxTime;
                g_CameraShake.m_IsShootCurve = true;
            }
        }

    }
}
