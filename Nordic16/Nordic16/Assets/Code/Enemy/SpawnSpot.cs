using UnityEngine;
using System.Collections;

public class SpawnSpot : MonoBehaviour {

	void Start () 
	{
	
	}
	
	void Update () 
	{
	
	}


    void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawSphere(transform.position, 0.1f);
    }
}
