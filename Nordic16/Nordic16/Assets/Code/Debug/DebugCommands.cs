using UnityEngine;
using System.Collections;

public class DebugCommands : MonoBehaviour {
	
	void Update () {
	    if (Input.GetKeyDown(KeyCode.R))
        {
            Application.LoadLevel(Application.loadedLevel);
        }
	}
}
