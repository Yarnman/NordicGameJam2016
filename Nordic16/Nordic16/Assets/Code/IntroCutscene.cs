using UnityEngine;
using System.Collections;

public class IntroCutscene : MonoBehaviour {
    [SerializeField] bool Skip;
    public GameObject previousSlide;
    public GameObject Slide1;
    public GameObject Slide2;
    public GameObject Slide3;
    public GameObject Slide4;
    public GameObject Slide5;
    public GameObject Slide6;
    public GameObject Slide7;
    public GameObject Slide8;

    public float currentTime;
    public float initialDelay;

    public int currentSlide;

    public float timeStamp1;
    public float timeStamp2;
    public float timeStamp3;
    public float timeStamp4;
    public float timeStamp5;
    public float timeStamp6;
    public float timeStamp7;
    public float timeStamp8;
    public float timeStamp9;

    private AudioSource introClip;
    float m_StartTime;
    [SerializeField] float m_SlideEndTime;
    [SerializeField] AnimationCurve m_SlideCurve;
    // Use this for initialization
    void Start ()
    {
        m_StartTime = Time.time;
        if (Skip)
        { 
            CoarseFXFrontBuffer.reveal = 1.0f;
            return;
        }
        CoarseFXFrontBuffer.reveal = 0.0f;
        AudioSource introClip = GetComponent<AudioSource>();
        introClip.PlayDelayed(initialDelay);
        currentTime = 0;
	}
	
	// Update is called once per frame
	void Update ()
    {
        if (Skip)
        {
            return;
        }
        PlayerMovement t_Movement = FindObjectOfType<PlayerMovement>();
        if (t_Movement) t_Movement.enabled = false;
        currentTime = Time.time - m_StartTime - initialDelay;

        if (currentTime <= m_SlideEndTime)
        {
            float t_Factor = (Time.time - m_StartTime) / (m_SlideEndTime);
            float t_CurveFactor = m_SlideCurve.Evaluate(t_Factor);
            CoarseFXFrontBuffer.reveal = t_CurveFactor;
            if (currentTime >= m_SlideEndTime)
            {
                CoarseFXFrontBuffer.reveal = 1.0f;
            }
        }

        if (currentTime >= 0 && currentSlide == 0)
        {
            previousSlide = Slide1;
            SwitchSlide(Slide1);
            currentSlide = 1;
        }
        else if (currentTime >= timeStamp1 && currentSlide == 1)
        {
            previousSlide = Slide1;
            SwitchSlide(Slide2);
            currentSlide = 2;
        }
        else if (currentTime >= timeStamp2 && currentSlide == 2)
        {
            previousSlide = Slide2;
            SwitchSlide(Slide8);
            currentSlide = 3;
        }
        else if (currentTime >= timeStamp3 && currentSlide == 3)
        {
            previousSlide = Slide8;
            SwitchSlide(Slide4);
            currentSlide = 4;
        }
        else if (currentTime >= timeStamp4 && currentSlide == 4)
        {
            previousSlide = Slide4;
            SwitchSlide(Slide5);
            currentSlide = 5;
        }
        else if (currentTime >= timeStamp5 && currentSlide == 5)
        {
            previousSlide = Slide5;
            SwitchSlide(Slide3);
            currentSlide = 6;
        }
        else if (currentTime >= timeStamp6 && currentSlide == 6)
        {
            previousSlide = Slide3;
            SwitchSlide(Slide6);
            currentSlide = 7;
        }
        else if (currentTime >= timeStamp7 && currentSlide == 7)
        {
            previousSlide = Slide6;
            SwitchSlide(Slide7);
            currentSlide = 8;
        }
        else if (currentTime >= timeStamp8 && currentSlide == 8)
        {
            previousSlide = Slide6;
            SwitchSlide(Slide7);
            currentSlide = 9;
        }
        else if (currentTime >= timeStamp9 && currentSlide == 9)
        {
            previousSlide.SetActive(false);
            gameObject.SetActive(false);
            if (t_Movement) t_Movement.enabled = true;
        }
    }

    void SwitchSlide(GameObject nextSlide)
    {
        Debug.Log(nextSlide);
        previousSlide.SetActive(false);
        nextSlide.SetActive(true);
    }


}
