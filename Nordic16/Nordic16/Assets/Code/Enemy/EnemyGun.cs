using UnityEngine;
using System.Collections;

public class EnemyGun : MonoBehaviour {
    Player m_Player;

    void Start () 
	{
        m_Player = FindObjectOfType<Player>();
    }
	
	void Update () 
	{
	
	}
}
