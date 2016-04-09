using UnityEngine;
using System.Collections;

public class PlayerGetHitSphere : MonoBehaviour {
    [SerializeField] float m_Time;
    [SerializeField] AnimationCurve m_Curve;
    [SerializeField] Renderer m_Renderer;
    float m_StartTime;
	void Start () 
	{
	
	}
	
	void Update () 
	{
	    float t_Factor = (Time.time - m_StartTime)/ m_Time;

        float tAlpa = m_Curve.Evaluate(t_Factor);
        Color t = m_Renderer.material.GetColor("_TintColor");
        t.a = tAlpa;
        m_Renderer.material.SetColor("_TintColor", t);
    }

    public void Hit()
    {
        m_StartTime = Time.time;
    }
}
