using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//tryuilo
public class EnemyInstanceManager : InstanceManager<Enemy>
{ 
    public static Enemy SpawnEnemy(string a_Name, Vector3 a_Position, Quaternion a_Rotation = default(Quaternion))
    {
        Enemy t_Instance = GetAvailableInstance(a_Name);
        if (t_Instance == null)
        {
            Debug.Log("EnemyInstance not found in pools");
            return null;
        }
        t_Instance.transform.position = a_Position;
        t_Instance.transform.rotation = a_Rotation;
        t_Instance.Spawn();
        return t_Instance;
    }
}
