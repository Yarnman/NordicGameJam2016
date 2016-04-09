using UnityEngine;
using System.Collections;

//Class to light up an object with a bright white. Is triggered by different scripts when the object gets hit. This indicates damage.
public class DamageModelFlasher : MonoBehaviour {

    [SerializeField] Renderer m_Renderer = null;
    [SerializeField] AnimationCurve m_FlashCurve = null;
    [SerializeField] Color m_BaseColor = Color.clear;
    [SerializeField] float m_MaxTime = 0;
    bool m_IsFlashing;
    float m_StartTime;
    void Start ()
    {
        Clear();
	}
	
	void Update ()
    {
        if (m_IsFlashing)
        { 
            float t_CurrentTime = (Time.time - m_StartTime) / m_MaxTime;
            if (t_CurrentTime > 1.0f)
            {
                Clear();
                m_IsFlashing = false;
            }
            else
            { 
                float t_Value = m_FlashCurve.Evaluate(t_CurrentTime);
                Color t_Color = m_BaseColor;
                t_Color.a = t_Value;

                if (m_Renderer.materials.Length >= 2)
                { 
                    m_Renderer.materials[1].SetColor("_Color", t_Color);
                }
            }
        }
    }

    void Clear()
    {
        Color t_Color = m_BaseColor;
        t_Color.a = 0;

        if (m_Renderer.materials.Length >= 2)
        {
            m_Renderer.materials[1].SetColor("_Color", t_Color);
        }
    }

    public void Hit()
    {
        m_StartTime = Time.time;
        m_IsFlashing = true;
    }
}
