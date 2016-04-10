using UnityEngine;
using System.Collections;

public class ClearColorFader : MonoBehaviour {
    [SerializeField] Renderer m_C;
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

        if (Input.anyKeyDown && t_T >= m_Time)
        {
            Application.LoadLevel(0);
        }
	}
}
