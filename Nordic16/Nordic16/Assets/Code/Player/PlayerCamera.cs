using UnityEngine;
using System.Collections;

public class PlayerCamera : MonoBehaviour {
    [SerializeField] float m_HorizontalTurnSpeed;
    [SerializeField] float m_VerticalTurnSpeed;
	void Start () 
	{
	
	}
	
	void Update () 
	{
        //
        float t_YRotate = Input.GetAxis("HorizontalCamera") * m_HorizontalTurnSpeed * Time.deltaTime;
        float t_XRotate = Input.GetAxis("VerticalCamera") * m_VerticalTurnSpeed * Time.deltaTime;
        transform.Rotate(t_XRotate, 0.0f, 0.0f);

        if (transform.up.y < 0)//UPSIDE DOWN WOOP WHAT
        {
            t_YRotate *= -1.0f;
        }
        transform.Rotate(0.0f, t_YRotate, 0.0f, Space.World);
        /*EZ LYFE
        float t_YRotate = Input.GetAxis("HorizontalCamera") * m_HorizontalTurnSpeed * Time.deltaTime;
        float t_XRotate = Input.GetAxis("VerticalCamera") * m_VerticalTurnSpeed * Time.deltaTime;
        transform.Rotate(t_XRotate, t_YRotate, 0.0f);
        */
    }
}
