using UnityEngine;
using System.Collections;

public class GunShake : MonoBehaviour {
    [SerializeField] PlayerGun m_Gun;
    [SerializeField] AnimationCurve m_SlideCurve;
    [SerializeField] float m_SlideDistance;
    [SerializeField] float m_MaxRotation;
    float m_LastFireTime;
    Vector3 m_LastFirePosition;
    Quaternion m_LastFireRotation = Quaternion.identity;
	void Start () 
	{
	
	}
	
    public void UpdateForwards()
    {
        if (m_Gun.m_IsFiringBackwards)
        {
            transform.parent.localRotation = Quaternion.Euler(180.0f, 0, 0);
        }
        else
        {
            transform.parent.localRotation = Quaternion.identity;
        }
    }
	void Update () 
	{
        UpdateForwards();
	    if (m_Gun.m_IsFiring)
        {
            if (m_Gun.m_DidJustFire)
            {
                float t_X = Random.Range(-m_MaxRotation, m_MaxRotation);
                float t_Y = Random.Range(-m_MaxRotation, m_MaxRotation);
                float t_Z = Random.Range(-m_MaxRotation, m_MaxRotation);
                transform.localRotation = Quaternion.Euler(t_X, t_Y, t_Z);
            }
            float t_SlideFactor = m_Gun.GetTimeFactor();
            float t_Factor = m_SlideCurve.Evaluate(t_SlideFactor);

            transform.localPosition = transform.localRotation * new Vector3(0.0f, 0.0f, t_Factor * m_SlideDistance);
            m_LastFireTime = Time.time;
            m_LastFirePosition = transform.localPosition;
            m_LastFireRotation = transform.localRotation;
        }
        else
        {
            float t_Factor = (Time.time - m_LastFireTime) / 0.5f;
            if (t_Factor < 1.0f)
            { 
                transform.localPosition = Vector3.Lerp(m_LastFirePosition, Vector3.zero, t_Factor);
                transform.localRotation = Quaternion.Lerp(m_LastFireRotation, Quaternion.identity, t_Factor);
            }
            else
            {
                transform.localPosition = Vector3.zero;
                transform.localRotation = Quaternion.identity;
            }
        }
	}
}
