using UnityEngine;
using System.Collections;

public class FinalDoorPart : MonoBehaviour {
    float m_StartDegrees;
	void Start () 
	{
        m_StartDegrees = transform.localRotation.eulerAngles.z;
	}

    public void SetTurnFactor(float a_Factor, float a_Degrees)
    {
        transform.localRotation = Quaternion.Euler(0.0f, 0.0f, m_StartDegrees + a_Factor * a_Degrees);
    }
}
