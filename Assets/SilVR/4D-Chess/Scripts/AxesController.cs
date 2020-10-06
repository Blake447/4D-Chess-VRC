
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

// This program is just a little manager for the 4D axis gizmos I use. It interfaces with a material in order
// to set its unique state of what axes should be shown opaquely, transparently, or not at all.
public class AxesController : UdonSharpBehaviour
{

    public Vector4 EnabledAxes;
    public Material mat;
    public GameObject[] MovesetsEnabled;
    public GameObject[] MovesetsDisabled;



    public override void Interact()
    {
        mat.SetVector("_Ghost", EnabledAxes);
        foreach (GameObject g in MovesetsEnabled)
        {
            g.SetActive(true);
        }
        foreach (GameObject g in MovesetsDisabled)
        {
            g.SetActive(false);
        }
    }
}
