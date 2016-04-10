using UnityEngine;
using System.Collections;

public class ClearColorFader : MonoBehaviour {
    [SerializeField] Renderer m_C;
    [SerializeField] Renderer m_Logo;
    [SerializeField] Color m_Color;
    [SerializeField] float m_Time;

    Color t_C;
    float t_T;
	void Start () 
	{
        t_T = 0.0f;
	}
	
	void Update () 
	{
        t_T += Time.deltaTime;

        float t_Factor = Mathf.Clamp01(t_T / m_Time);
        m_C.material.color = Color.Lerp(m_Color, Color.white, t_Factor);
        if (t_T >= 0.5f)
        {
            float t_Time = t_T - 0.5f;
            t_Time /= 1.0f;
            Color t_C = m_Logo.material.color;
            t_C.a = Mathf.Clamp01(t_Time);
            m_Logo.material.color = t_C;
        }
        if (Input.anyKeyDown && t_T >= m_Time)
        {
            Application.LoadLevel(0);
        }
	}
}
