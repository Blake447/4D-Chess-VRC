
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

// Logic for the specific reset button using VRChat Interact() method to call.
public class ResetButton : UdonSharpBehaviour
{
    // field for the two piece managers
    public PieceManager[] managers;

    // field for if the button is enabled
    public bool isButton;

    // field for master check only
    public bool requiresMaster = true;

    // Resets all pieces
    public void ResetAllPieces()
    {
        foreach (PieceManager m in managers)
        {
            m.ResetPieces();
        }
    }

    // Act as a VRChat interactable. Upon clicking or pressing trigger near in game,
    public override void Interact()
    {
        // If the button is enabled and our player is master of the instance / not master required
        if (isButton && (Networking.IsMaster || !requiresMaster))
        {
            // Reset all the pieces
            ResetAllPieces();
        }
    }

}
