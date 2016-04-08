using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//Manages all ParticleInstance objects. Derives from InstanceManager which is used for most in-game stuff.
//ParticleInstance objects reside in pools that are managed by ParticleInstanceManager. This allows them to be reused
//The static interface of ParticleInstanceManager means that other objects can fire particle effecs with a single line.
public class ParticleInstanceManager : InstanceManager<ParticleInstance>
{ 
    public static ParticleInstance SpawnSystem(string a_Name, Vector3 a_Position, Quaternion a_Rotation = default(Quaternion))
    {
        ParticleInstance t_Instance = GetAvailableInstance(a_Name);
        if (t_Instance == null)
        {
            Debug.Log("ParticleInstance not found in pools");
            return null;
        }
        t_Instance.transform.position = a_Position;
        t_Instance.transform.rotation = a_Rotation;
        t_Instance.StartParticles();
        return t_Instance;
    }
}
