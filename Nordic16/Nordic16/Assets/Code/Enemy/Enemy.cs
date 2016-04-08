using UnityEngine;
using System.Collections;

public class Enemy : MonoBehaviour {
    [SerializeField] DamageModelFlasher m_F;
    [SerializeField] float m_Health;
	void Start () 
	{
	
	}
	
	void Update () 
	{
	    if (Input.GetKeyDown(KeyCode.Space))
        {
            GetHit(15);
        }

	}

    public void GetHit(float a_Damage)
    {
        m_F.Hit();
    }
}
