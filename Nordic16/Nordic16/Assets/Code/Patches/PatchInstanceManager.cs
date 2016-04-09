using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//BLAAGBAKEBLEARG
public class PatchInstanceManager : InstanceManager<PatchInstance>
{ 
    public static PatchInstance SpawnPatch(string a_Name, Vector3 a_Position, Vector3 a_Direction)
    {
        PatchInstance t_Instance = GetAvailableInstance(a_Name);
        if (t_Instance == null)
        {
            Debug.Log("PatchInstance not found in pools");
            return null;
        }
        t_Instance.transform.position = a_Position;
        t_Instance.transform.rotation = Quaternion.LookRotation(a_Direction);
        return t_Instance;
    }
}
