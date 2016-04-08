using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//Manages all AudioInstance objects. Derives from InstanceManager which is used for most in-game stuff.
//AudioInstance objects reside in pools that are managed by AudioManager. This allows them to be reused
//The static interface of AudioManager means that other objects can fire audio effecs with a single line.
public class AudioManager : InstanceManager<AudioInstance>
{
    public static AudioInstance SpawnAudioInstance(string a_Name, Vector3 a_Position)
    {
        AudioInstance t_Instance = GetAvailableInstance(a_Name);
        if (t_Instance == null)
        {
            Debug.Log("AudioInstance not found in pools");
            return null;
        }
        t_Instance.transform.position = a_Position;
        t_Instance.Play();
        return t_Instance;
    }
}
