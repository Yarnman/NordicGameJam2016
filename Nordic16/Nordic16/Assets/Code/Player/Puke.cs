using UnityEngine;
using System.Collections;

public class Puke : MonoBehaviour {
    [SerializeField] float m_PukeTime;
    [SerializeField] float m_FadeTime;
    [SerializeField] AnimationCurve m_FadeCurve;
    [SerializeField] AnimationCurve m_PukeCurve;
    [SerializeField] Renderer m_Renderer;
    [SerializeField] float m_MaxAlpha;
    [SerializeField] ParticleSystem m_FadeParticles;
    [SerializeField] string m_WarmupSound;
    [SerializeField] string m_PukeSound;
    [SerializeField] string m_SquishSound;
    [SerializeField] string m_ToxicWarning;
    float m_StartTime;

    bool m_Puking;
    bool m_Fading;
	void Start () 
	{
	
	}

    public void StartPuke()
    {
        m_StartTime = Time.time;
        m_Puking = true;
        AudioManager.SpawnAudioInstance(m_WarmupSound, transform.position);
    }
	
	void Update () 
	{
        if (Input.GetKeyDown(KeyCode.F))
        {
            StartPuke();
        }
        if (m_Puking)
        {
            CameraShake.Shake(CameraShake.Reason.Puke);
            float t_Factor = (Time.time - m_StartTime) / m_PukeTime;

            float tAlpa = m_PukeCurve.Evaluate(t_Factor) * m_MaxAlpha;
            Color t = m_Renderer.material.GetColor("_TintColor");
            t.a = tAlpa;
            m_Renderer.material.SetColor("_TintColor", t);
            if (t_Factor > 1.0f)
            {
                m_Puking = false;
                m_Fading = true;
                m_FadeParticles.Play();
                m_StartTime = Time.time;
                AudioManager.SpawnAudioInstance(m_PukeSound, transform.position);
                AudioManager.SpawnAudioInstance(m_SquishSound, transform.position);
            }
        }
        else if (m_Fading)
        { 
	        float t_Factor = (Time.time - m_StartTime)/ m_FadeTime;
            float tAlpa = m_FadeCurve.Evaluate(t_Factor) * m_MaxAlpha;
            Color t = m_Renderer.material.GetColor("_TintColor");
            t.a = tAlpa;
            m_Renderer.material.SetColor("_TintColor", t);
            if (t_Factor > 1.0f)
            {
                m_Puking = false;
                m_Fading = false;
                AudioManager.SpawnAudioInstance(m_ToxicWarning, transform.position);
            }
        }
    }
}
