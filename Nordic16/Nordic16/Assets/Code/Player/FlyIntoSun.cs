using UnityEngine;
using System.Collections;

public class FlyIntoSun : MonoBehaviour {
    [SerializeField] Renderer m_Renderer;
    [SerializeField] float m_MaxColor;
    [SerializeField] float m_MaxShake;
	void Start () 
	{
        SetIntensity(0.0f, 0.0f);
	}

    public void SetIntensity(float a_Intensity1, float a_Intensity2)
    {
        float tAlpa = a_Intensity1 * m_MaxColor;
        Color t = m_Renderer.material.GetColor("_TintColor");
        t.a = tAlpa;
        m_Renderer.material.SetColor("_TintColor", t);

        float t_Shake = a_Intensity2* m_MaxShake;
        CameraShake.Shake(CameraShake.Reason.Direct, t_Shake);

        if (a_Intensity1 == 0.0f)
        {
            Debug.Log("Wow");
        }
    }
}
