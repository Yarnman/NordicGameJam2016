using UnityEngine;
using System.Collections;

public class Door : MonoBehaviour {
    [SerializeField]
    GameObject collider;
    [SerializeField]
    GameObject upperdoor;
    [SerializeField]
    GameObject lowerdoor;
    [SerializeField] float m_TimeLength;
    [SerializeField] float m_HalfDoorLength;
    [SerializeField] AnimationCurve m_AnimationCurve;
    float m_StartTime;
    bool m_IsOpening;
    bool m_IsClosing;

	void Start () 
	{
	
	}
	
	void Update () 
	{
        if (Input.GetKeyDown(KeyCode.F))
        {
            StartOpening();
        }
        else if (Input.GetKeyDown(KeyCode.G))
        {
            StartClosing();
        }
        if (m_IsOpening || m_IsClosing)
        { 
            float t_RelativeTime = (Time.time - m_StartTime) / m_TimeLength;
            float t_Factor = m_AnimationCurve.Evaluate(t_RelativeTime);
            float t_Closed = m_HalfDoorLength * 0.5f;
            float t_Opened = m_HalfDoorLength * 1.5f;
            
            if (m_IsOpening)
            {
                float t_CurrentHeight = t_Closed + (t_Opened - t_Closed) * t_Factor;
                upperdoor.transform.localPosition = transform.up * t_CurrentHeight;
                lowerdoor.transform.localPosition = -transform.up * t_CurrentHeight;
            }
            else
            {
                float t_CurrentHeight = t_Opened + (t_Closed - t_Opened) * t_Factor;
                upperdoor.transform.localPosition = transform.up * t_CurrentHeight;
                lowerdoor.transform.localPosition = -transform.up * t_CurrentHeight;
            }

            if (t_RelativeTime >= 1.0f)
            {
                if (m_IsOpening)
                {
                    FinishOpening();
                }
                else
                {
                    FinishClosing();
                }
            }
        }
    }

    public void StartOpening()
    {
        m_IsOpening = true;
        m_StartTime = Time.time;
        if (collider)collider.SetActive(false);

        upperdoor.transform.localPosition = transform.up * m_HalfDoorLength * 0.5f;
        lowerdoor.transform.localPosition = -transform.up * m_HalfDoorLength * 0.5f;
    }
    public void StartClosing()
    {
        m_IsClosing = true;
        m_StartTime = Time.time;
        if (collider) collider.SetActive(true);

        upperdoor.transform.localPosition = transform.up * m_HalfDoorLength * 1.5f;
        lowerdoor.transform.localPosition = -transform.up * m_HalfDoorLength * 1.5f;
    }
    public void FinishClosing()
    {
        m_IsClosing = false;
        if (collider) collider.SetActive(true);
        upperdoor.transform.localPosition = transform.up * m_HalfDoorLength * 0.5f;
        lowerdoor.transform.localPosition = -transform.up * m_HalfDoorLength * 0.5f;
    }
    public void FinishOpening()
    {
        m_IsOpening = false;
        if (collider) collider.SetActive(false);
        upperdoor.transform.localPosition = transform.up * m_HalfDoorLength * 1.5f;
        lowerdoor.transform.localPosition = -transform.up * m_HalfDoorLength * 1.5f;
    }
}
