using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//The instance pool is a class which controls a pool for one specific object template.
//The pools can be accessed by name by the InstanceManager that controls them.
//Originally it was meant to be a generic class, but this would prevent serialization. This means it could not be accessed easily in the editor.
//Therefore the GameObject class was used as a base for the prefabs.

//Pools have a start amount of entities in them, but new ones can be created during runtime.
//Since this can be costly, the start amount has been tweaked to prevent this.
[System.Serializable]
public class InstancePool
{
    public GameObject m_Template;
    public int m_StartAmount;
    public string m_Name;
    List<GameObject> m_List;
    Transform m_Parent;
    public void Initialize(Transform a_Parent)
    {
        m_Parent = a_Parent;
        m_List = new List<GameObject>();
        for (int i = 0; i < m_StartAmount; i++)
        {
            CreateNewInstance();
        }
    }

    GameObject CreateNewInstance()
    {
        if (m_Template == null)
        {
            Debug.LogError("Template for instance " + m_Name + " is null");
            return null;
        }
        GameObject t_NewInstance = GameObject.Instantiate(m_Template) as GameObject;
        t_NewInstance.transform.parent = m_Parent;
        t_NewInstance.transform.name = m_Name + m_List.Count.ToString();
        t_NewInstance.gameObject.SetActive(false);
        m_List.Add(t_NewInstance);
        return t_NewInstance;
    }

    public GameObject GetAvailableInstance()
    {
        for (int i = 0; i < m_List.Count; i++)
        {
            if (!m_List[i].gameObject.activeSelf)
            {
                return m_List[i];
            }
        }
        Debug.Log("Creating " + m_Name + " at runtime");
        return CreateNewInstance();
    }

    public int GetAmountOfInstances()
    {
        return m_List.Count;
    }

    public void DeactivateAllInstances()
    {
        for (int i = 0; i < m_List.Count; i++)
        {
            m_List[i].SetActive(false);
        }
    }
}
