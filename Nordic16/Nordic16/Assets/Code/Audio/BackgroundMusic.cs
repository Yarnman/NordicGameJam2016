using UnityEngine;
using System.Collections;

public class BackgroundMusic : MonoBehaviour {
    [SerializeField] AudioSource m_AudioSource;
    [SerializeField] AudioClip m_Clip2;
    [SerializeField] float m_FadeTime;
    [SerializeField] float m_TransitionTime;
    float m_Volume;
    float m_TransitionStartTime;
    bool m_IsFadingOut;
    bool m_IsFadingIn;
    bool m_IsEnding;
	void Start () 
	{
        m_Volume = m_AudioSource.volume;
	}
	
	void Update () 
	{
        if (m_IsEnding)
        {
            float t_Factor = Mathf.Clamp((Time.time - m_TransitionStartTime) / m_FadeTime, 0.0f, 1.0f);
            m_AudioSource.volume = (1.0f - t_Factor) * m_Volume;
        }
        else if (m_IsFadingOut)
        {
            float t_Factor = Mathf.Clamp((Time.time - m_TransitionStartTime) / m_FadeTime, 0.0f, 1.0f);
            m_AudioSource.volume = (1.0f - t_Factor) * m_Volume;
            if (Time.time - m_TransitionStartTime > m_TransitionTime)
            {
                m_IsFadingOut = false;
            }
        }
        else if (m_IsFadingIn)
        {
            float t_Factor = Mathf.Clamp((Time.time - m_TransitionStartTime) / m_FadeTime, 0.0f, 1.0f);

            m_AudioSource.volume = (t_Factor) * m_Volume;
            if (Time.time - m_TransitionStartTime > m_TransitionTime)
            {
                m_IsFadingIn = false;
            }
        }
	}

    public void TriggerEndTransition()
    {
        m_TransitionStartTime = Time.time;
        m_IsFadingIn = false;
        m_IsFadingOut = false;
        m_IsEnding = true;
    }
    public void TriggerOutTransition()
    {
        m_TransitionStartTime = Time.time;
        m_IsFadingOut = true;
        m_IsFadingIn = false;
    }
    public void TriggerInTransition()
    {
        m_TransitionStartTime = Time.time;
        m_IsFadingOut = false;
        m_IsFadingIn = true;
        m_AudioSource.clip = m_Clip2;
        m_AudioSource.Play();
    }
}
