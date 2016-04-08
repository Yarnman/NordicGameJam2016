using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//InstanceManager is the base class for most managers in the game.
//Every object type which needs to be spawned, destroyed and respawned often is managed by a version of InstanceManager.
//InstanceManager classes control a set of InstancePools which can be referred to by name.
//This class can be asked for a new object (either reactivated from a pool or created newly), and can be asked to shut down all instances.
//The class is made to be minimal effort for all new implementations.
public class InstanceManager<T> : MonoBehaviour where T : MonoBehaviour
{
    [SerializeField] protected InstancePool[] m_Pools = null;

    protected static InstanceManager<T> g_InstanceManager;

    protected void Awake()
    {
        for (int i = 0; i < m_Pools.Length; i++)
        {
            m_Pools[i].Initialize(this.transform);
        }
    }

    protected static T GetAvailableInstance(string a_Name)
    {
        if (a_Name.Length == 0)
        {
            Debug.Log("Name of requested instance is empty");
            return null;
        }
        if (g_InstanceManager == null)
        {
            g_InstanceManager = FindObjectOfType<InstanceManager<T>>();
            if (g_InstanceManager == null)
            {
                Debug.LogError("Instance manager not found in scene");
                return null;
            }
        }
        for (int i = 0; i < g_InstanceManager.m_Pools.Length; i++)
        {
            if (g_InstanceManager.m_Pools[i].m_Name == a_Name)
            {
                GameObject t_Object = g_InstanceManager.m_Pools[i].GetAvailableInstance();
                if (t_Object == null)
                {
                    Debug.Log("Instance with name " + a_Name + " could not be spawned");
                    return null;
                }
                T t_Instance = t_Object.GetComponent(typeof(T)) as T;
                if (t_Instance != null)
                { 
                    t_Instance.gameObject.SetActive(true);
                    return t_Instance;
                }
                else
                {
                    Debug.Log("Instance with name " + a_Name + " did not have requested component");
                    return null;
                }
            }
        }
        Debug.Log("Could not find instance pool for requested name: " + a_Name);
        return null;
    }

    public static void DeactivateAllInstances()
    {
        if (g_InstanceManager == null)
        {
            g_InstanceManager = FindObjectOfType<InstanceManager<T>>();
            if (g_InstanceManager == null)
            {
                Debug.LogError("Instance manager not found in scene");
                return;
            }
        }
        for (int i = 0; i < g_InstanceManager.m_Pools.Length; i++)
        {
            g_InstanceManager.m_Pools[i].DeactivateAllInstances();
        }
    }
}
