using UnityEngine;
using System.Collections;

//Class to let the camera shake with varying severity when something in-game triggers it. 
//The three triggers are: An exploding entity, when the player gets hit and when the player dies.

public class CameraShake : MonoBehaviour {
    public enum Reason
    {
        Explosion,
        GetHit,
        PlayerDead
    }
    [SerializeField] float m_MaxTime = 0;
    [SerializeField] float m_ExplosionDistance = 0;
    [SerializeField] float m_PlayerHitDistance = 0;
    [SerializeField] float m_PlayerDeadDistance = 0;
    [SerializeField] AnimationCurve m_IntensityCurve = null;

    float m_StartTime;
    float m_Distance;
    bool m_IsShaking;
    static CameraShake g_CameraShake;
	
	void Update ()
    {
        //Since the camera shake is not explicitly based on Time.deltaTime, return when the timescale is zero.
        if (Time.timeScale == 0.0f)
        {
            return;
        }
        if (m_IsShaking)
        { 
            float t_RelativeTime = (Time.time - m_StartTime) / m_MaxTime;

            //An animationcurve allows for a smooth degradation of intensity.
            float t_Intensity = m_IntensityCurve.Evaluate(t_RelativeTime) * m_Distance;
            //The camera is parented to an object and moves in a random circle around by changing its localPosition.
            transform.localPosition = Random.insideUnitCircle * t_Intensity;

            if (t_RelativeTime >= 1.0f)
            {
                m_IsShaking = false;
                transform.localPosition = Vector3.zero;
            }
        }
    }
    //Static method prevents every entity from searching for the camerashake object
    public static void Shake(Reason a_Reason)
    {
        if (g_CameraShake == null)
        {
            g_CameraShake = FindObjectOfType<CameraShake>();
            if (g_CameraShake == null)
            {
                return;
            }
        }

        g_CameraShake.m_StartTime = Time.time;
        g_CameraShake.m_IsShaking = true;

        switch(a_Reason)
        {
            case Reason.Explosion:
                g_CameraShake.m_Distance = g_CameraShake.m_ExplosionDistance;
            break;
            case Reason.GetHit:
                g_CameraShake.m_Distance = g_CameraShake.m_PlayerHitDistance;
                break;
            case Reason.PlayerDead:
                g_CameraShake.m_Distance = g_CameraShake.m_PlayerDeadDistance;
                break;
        }
        
    }
}
