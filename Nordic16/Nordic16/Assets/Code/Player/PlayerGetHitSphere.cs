using UnityEngine;
using System.Collections;

public class PlayerGetHitSphere : MonoBehaviour {
    [SerializeField] float m_Time;
    [SerializeField] AnimationCurve m_Curve;
    [SerializeField] Renderer m_Renderer;
    float m_StartTime;
    bool m_IsDead;
	void Start () 
	{
        m_StartTime = -m_Time * 3.0f;
	}
	
	void Update () 
	{
        if (m_IsDead)
        {
            Color t = m_Renderer.material.GetColor("_TintColor");
            t.a = m_Curve.Evaluate(0);
            m_Renderer.material.SetColor("_TintColor", t);
        }
        else
        { 
	        float t_Factor = (Time.time - m_StartTime)/ m_Time;

            float tAlpa = m_Curve.Evaluate(t_Factor);
            Color t = m_Renderer.material.GetColor("_TintColor");
            t.a = tAlpa;
            m_Renderer.material.SetColor("_TintColor", t);
        }
    }

    public void Hit()
    {
        m_StartTime = Time.time;
    }

    public void Die()
    {
        m_IsDead = true;
    }
}
