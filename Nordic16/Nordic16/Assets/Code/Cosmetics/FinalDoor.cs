using UnityEngine;
using System.Collections;

public class FinalDoor : MonoBehaviour {
    [SerializeField] float m_Time;
    [SerializeField] float m_Degrees;
    [SerializeField] string m_AlarmSound;
    [SerializeField] GameObject m_Collider;
    FinalDoorPart[] m_Children;
    float m_StartTime;
    [SerializeField] AnimationCurve m_MoveCurve;

    GameObject m_Alarms;
    bool m_IsOpening;
	void Start () 
	{
        m_Children = FindObjectsOfType<FinalDoorPart>();
	}
	
	void Update ()
    { 
        if (m_IsOpening)
        { 
            if (Time.time - m_StartTime > m_Time)
            {
                m_IsOpening = false;
                m_Alarms.SetActive(false);
            }
            float t_Factor = (Time.time - m_StartTime) / m_Time;
            t_Factor = m_MoveCurve.Evaluate(t_Factor);

            for (int i = 0; i < m_Children.Length; i++)
            {
                m_Children[i].SetTurnFactor(t_Factor, m_Degrees);
            }
        }
    }

    public void StartOpening()
    {
        m_IsOpening = true;
        m_StartTime = Time.time;
        m_Alarms = AudioManager.SpawnAudioInstance(m_AlarmSound, transform.position).gameObject;
        m_Collider.SetActive(false);
    }
}
