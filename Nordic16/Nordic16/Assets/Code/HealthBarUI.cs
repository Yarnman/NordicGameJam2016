using UnityEngine;
using UnityEngine.UI;
using System.Collections;

//The HealthBarUI displays the health of the player. When the player gets hit, the UI lights up to signify this.
//The healthbar will then shrink to the new health value.
//Health is used as a value between 0 and 1.
public class HealthBarUI : MonoBehaviour {
    [SerializeField] Player m_Player;
    [SerializeField] float m_UpdateTime = 0;
    [SerializeField] AnimationCurve m_SizeInterpolationCurve = null;
    [SerializeField] Color m_NeutralColor = Color.clear;
    [SerializeField] Color m_HurtColor = Color.clear;
    float m_LastSetTime;
    float m_CurrentHealth;
    float m_PreviousHealth;

    void Start()
    {
        m_CurrentHealth = 1.0f;
        m_PreviousHealth = 1.0f;
        SetSize(1.0f);
        SetColor(m_NeutralColor);
    }
	void Update ()
    {
        if (m_CurrentHealth != m_Player.GetHealthFactor())
        {
            SetHealthFactor(m_Player.GetHealthFactor());
        }
        float t_Time = Time.time - m_LastSetTime;

        if (t_Time >= m_UpdateTime)
        {
            SetSize(m_CurrentHealth);
            SetColor(m_NeutralColor);
        }
        float t_RelativeTime = t_Time / m_UpdateTime;
        float t_InterpolationFactor = m_SizeInterpolationCurve.Evaluate(t_RelativeTime);
        float t_Size = m_PreviousHealth + (m_CurrentHealth - m_PreviousHealth) * t_InterpolationFactor;
        SetSize(t_Size);

        if (m_CurrentHealth < m_PreviousHealth)//Has been hurt
        {
            Color t_Color = Color.Lerp(m_HurtColor, m_NeutralColor, t_RelativeTime);
            SetColor(t_Color);
        }
	}

    void SetSize(float a_Factor)
    {
        CoarseFXFrontBuffer.health = a_Factor;
    }

    void SetColor(Color a_Color)
    {
        CoarseFXFrontBuffer.healthColor = a_Color;
    }

    public void SetHealthFactor(float a_Health)
    {
        a_Health = Mathf.Clamp(a_Health, 0.0f, 1.0f);
        m_LastSetTime = Time.time;
        m_PreviousHealth = m_CurrentHealth;
        m_CurrentHealth = a_Health;
    }
}
