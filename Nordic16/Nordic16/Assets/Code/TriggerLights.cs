﻿using UnityEngine;
using System.Collections;

public class TriggerLights : MonoBehaviour {
    [SerializeField] GameObject m_LightGroup;

    void Start()
    {
        m_LightGroup.SetActive(false);
    }

    public void PlayerEnters()
    {
        m_LightGroup.SetActive(true);
    }

    public void PlayerLeaves()
    {
        m_LightGroup.SetActive(false);
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.magenta;
        Gizmos.DrawWireCube(transform.position, transform.localScale);      
    }
}
