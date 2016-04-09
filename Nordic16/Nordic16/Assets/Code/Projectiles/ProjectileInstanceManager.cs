using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//BLAAGBAKEBLEARG
public class ProjectileInstanceManager : InstanceManager<ProjectileInstance>
{ 
    public static ProjectileInstance SpawnProjectile(string a_Name, Vector3 a_Position, Vector3 a_Direction)
    {
        ProjectileInstance t_Instance = GetAvailableInstance(a_Name);
        if (t_Instance == null)
        {
            Debug.Log("ProjectileInstance not found in pools");
            return null;
        }
        t_Instance.transform.position = a_Position;
        t_Instance.transform.rotation = Quaternion.LookRotation(a_Direction);
        t_Instance.StartProjectile();
        return t_Instance;
    }
}
