using UnityEngine;
using System.Collections;

public class EndGameCINEMATICS : MonoBehaviour {
    public enum State
    {
        Idle,
        Cut1,
        Cut2,
        End
    }

    State m_State;
    [SerializeField] float m_Cutscene1Time;
    [SerializeField] float m_Cutscene2Time;
    [SerializeField] AnimationCurve m_LookCurve;
    [SerializeField] AnimationCurve m_MotionCurve;
    [SerializeField] AnimationCurve m_FlyIntoSunCurve1;
    [SerializeField] AnimationCurve m_FlyIntoSunCurve2;
    [SerializeField] string m_StartVO;
    float m_StartTime;

    BackgroundMusic m_Music;
    Puke m_Puke;
    PlayerMovement m_PlayerMovement;
    PlayerCamera m_PlayerCamera;
    Sun m_Sun;
    FlyIntoSun m_FlyIntoSun;
    FinalDoor m_FinalDoor;

    Vector3 m_StartPosition;
    Quaternion m_StartRotation;
    Quaternion m_TargetRotation;
    void Start () 
	{
        m_Music = FindObjectOfType<BackgroundMusic>();
        m_Puke = FindObjectOfType<Puke>();
        m_PlayerMovement = FindObjectOfType<PlayerMovement>();
        m_PlayerCamera = FindObjectOfType<PlayerCamera>();
        m_Sun = FindObjectOfType<Sun>();
        m_FlyIntoSun = FindObjectOfType<FlyIntoSun>();
        m_FinalDoor = FindObjectOfType<FinalDoor>();
        AudioManager.SpawnAudioInstance(m_StartVO, transform.position);

    }
	
	void Update () 
	{
	    if (Input.GetKeyDown(KeyCode.T))
        {
            TriggerCutscene1();
        }
        if (Input.GetKeyDown(KeyCode.Y))
        {
            TriggerCutscene2();
        }

        switch (m_State)
        {
            case State.Cut1:
                if (Time.time - m_StartTime > m_Cutscene1Time)
                {
                    if (m_FinalDoor != null) m_FinalDoor.StartOpening();
                    TriggerCutscene2();
                }
                break;
            case State.Cut2:
                UpdateSunMovement();
                if (Time.time - m_StartTime > m_Cutscene2Time)
                {
                    TriggerEnd();
                }
                break;
            case State.End:
                //UpdateSunMovement();
            break;
        }
	}

    void UpdateSunMovement()
    {
        float t_Time = Mathf.Clamp((Time.time - m_StartTime) / m_Cutscene2Time, 0.0f, 1.0f);
        if (m_PlayerMovement && m_Sun)
        {
            
            float t_Factor = m_MotionCurve.Evaluate(t_Time);
            Vector3 t_Pos = m_StartPosition + (m_Sun.transform.position - m_StartPosition) * t_Factor;
            m_PlayerMovement.transform.position = t_Pos;
        }
        if (m_PlayerCamera)
        {
            float t_Factor = m_LookCurve.Evaluate(t_Time);
            Quaternion t_Rot = Quaternion.Lerp(m_StartRotation, m_TargetRotation, t_Factor);
            m_PlayerCamera.transform.localRotation = t_Rot;
        }
        if (m_FlyIntoSun)
        {
            m_FlyIntoSun.SetIntensity(m_FlyIntoSunCurve1.Evaluate(t_Time), m_FlyIntoSunCurve2.Evaluate(t_Time));
        }
    }

    public void TriggerCutscene1()
    {
        if (m_Music != null)
        {
            m_Music.TriggerOutTransition();
        }
        if (m_Puke) m_Puke.StartPuke();
        if (m_PlayerMovement) m_PlayerMovement.enabled = false;
        m_State = State.Cut1;
        m_StartTime = Time.time;
    }

    public void TriggerCutscene2()
    {
        if (m_Music != null)
        {
            m_Music.TriggerInTransition();
        }
        if (m_PlayerCamera)
        {
            m_PlayerCamera.enabled = false;
            m_StartRotation = m_PlayerCamera.transform.rotation;
            if (m_Sun)
            {
                m_TargetRotation = Quaternion.LookRotation((m_Sun.transform.position - m_PlayerCamera.transform.position).normalized);
            }
        }

        if (m_PlayerMovement)
        {
            m_StartPosition = m_PlayerMovement.transform.position;
        }
        m_State = State.Cut2;
        m_StartTime = Time.time;
    }

    public void TriggerEnd()
    {
        if (m_Music != null)
        {
            m_Music.TriggerEndTransition();
        }
        m_State = State.End;
    }
}
