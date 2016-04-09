using UnityEngine;
using System.Collections;

public class CombatEncounter : MonoBehaviour {
    [SerializeField] Wave m_Wave;
	void Start () 
	{
	
	}
	
	void Update () 
	{
	    if (m_Wave.m_Done)
        {
            Debug.Log("Wave done");
        }
	}

    public void StartEncounter()
    {
        if (m_Wave.m_Done)
        {
            return;
        }
        Debug.Log("Starting encounter " + transform.name);
        m_Wave.StartSpawning();
    }
}
