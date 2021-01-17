
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ChessPiece : UdonSharpBehaviour
{
    // Alright, this one is where all the logic is going to be concentrated

    //public bool printSnapLocation = false;

    // public field for the root or origin of our coordinate systems (world-scale and board-space)
    public Vector3 root;

    // parameters for snapping and board-space coordinates in world scale
    private float xy_offset = 0.0825f;
    private float z_offset = 0.1235f;
    private float z_scaling = 0.9f;
    private float w_offset = 0.4125f;

    // The intial position and rotation of our piece for snapping
    public Vector3 p0;
    public Quaternion r0;



    // Some default orthonormal basis for world scale
    public Vector3 rt = new Vector3(1, 0, 0);
    public Vector3 up = new Vector3(0, 1, 0);
    public Vector3 fw = new Vector3(0, 0, 1);

    // This pieces board-space coordinate
    public Vector4 coordinate;
    
    // The piece type for the grid interface moveset lookup
    public int pieceType;

    // The grid interfaces reference
    public GridInterface gi;

    // Determine whether to snap back to original position on invalid move (unimplemented)
    public bool returnOnInvalid = true;

    // Bool to check whether being held (for testing)
    public bool held = false;

    // Bool to decide whether to clear the grid interface on drop
    public bool clearOnDrop = false;

    // Origin reference object
    public GameObject rootObject;


    /////////////////////////////////////////////////
    ////             Debug Functions             ////
    /////////////////////////////////////////////////

    // Uncomment this to make it so that the pieces snap every frame. Drops FPS to about 15 in unity editor
    // so DO NOT leave it uncommented for upload.

    //public void Update()
    //{
    //    PerformSnap();
    //}


    /////////////////////////////////////////////////
    ////        Initialization Function(s)       ////
    /////////////////////////////////////////////////

    public void PerformSnap()
    {
        UpdateBasis();
        bool hasSnapped = SnapToCoordinateVerbose(this.transform.position);
    }


    // Method to update the scale of the parameters for the coordinate conversions. This is called by PieceManager.cs
    public void UpdateBasis()
    {
        // so long as we have a root object to reference
        if (rootObject != null)
        {
            // Get the objects transform
            Transform t = rootObject.transform;
            
            // Set our origin for the coordinate systems
            root = t.position;

            // Update our basis to its local basis
            rt = t.right;
            up = t.up;
            fw = t.forward;

            // Scale our offsets by its global scale
            xy_offset = 0.0825f*t.lossyScale.z;
            z_offset = 0.1235f*t.lossyScale.z;
            z_scaling = 0.9f;
            w_offset = 0.4125f*t.lossyScale.z;
        }
    }

    /////////////////////////////////////////////////
    ////      VRC Pickup override functions      ////
    /////////////////////////////////////////////////

    // Whenever the piece is dropped
    public override void OnDrop()
    {
        // Attempt to snap. Returns true if it was a valid snap, false if not.
        bool hasSnapped = SnapToCoordinateVerbose(this.transform.position);
        
        // If we want to clear on drop
        if (clearOnDrop)
        {
            // Check that the reference piece for the grid interface is still this piece, and that we snapped appropriately
            if (gi.refPiece == this && hasSnapped)
            {
                // If so, clear the gpu grid
                gi.HideGpuGrid();
            }
        }

    }

    // Whenever the piece is picked up
    public override void OnPickup()
    {
        // Attempt to snap. Returns true if it was a valid snap, false if not.
        // This is to ensure the grid interface gets the correct coordinate to display
        // from
        bool hasSnapped = SnapToCoordinateVerbose(this.transform.position);
        
        // If we did snap just before being picked up
        if (hasSnapped)
        {
            // Update the grid interface to use the piece type we specified.
            gi.refPiece = this;
            gi.UpdateGpuGrid();
        }
    }


    /////////////////////////////////////////////////
    ////     Lower level snapping functions      ////
    /////////////////////////////////////////////////


    // Logic for snapping to a coordinate. Returns true if the snap is on the board and successful
    bool SnapToCoordinateVerbose(Vector3 incoming)
    {
        // Nab the previous coordinate in case we want to go back
        Vector4 prev_coord = coordinate;

        // Get the offset from our root object
        Vector3 vec = incoming - root;

        // parsing to integer acts as a floor value, so we'll divde by some offsets to get these two values.
        int z_co = (int)(Vector3.Dot(vec, up) / z_offset + 0.5f);
        int w_co = (int)((Vector3.Dot(vec, fw) - xy_offset) / w_offset + 0.5f);

        // Project the pieces coordinate into the zeroth cube
        Vector3 projection = vec - fw * w_co * w_offset;

        // The board starts at a scale of 1, and shrinks by a fixed factor each time. Start at one
        float scaler = 1.0f;

        // On the zeroth level, z_co = 0, and the loop doesnt run. On the first level, it runs once.
        // Each time we go up a board vertical
        for (int i = 0; i < z_co; i++)
        {
            // scale by the constant factor
            scaler *= z_scaling;
        }

        // Project the 3D board in the zeroth w volume to the bottom 2D board
        projection = (projection - 1.5f * (rt + fw) * xy_offset) / scaler + 1.5f * (rt + fw) * xy_offset;

        // Snap the x and y coordinates
        int x_co = (int)(Vector3.Dot(projection, rt) / xy_offset + 0.5f);
        int y_co = (int)(Vector3.Dot(projection, fw) / xy_offset + 0.5f);

        // get all the coordinates into one vector4, and update it into the global variable
        coordinate = new Vector4(x_co, y_co, z_co, w_co);

        // Determine how far away we are from the center of the board
        Vector4 snapping = coordinate - new Vector4(1f, 1f, 1f, 1f) * 1.5f;

        // Check the magnitude of each coordinates offset, to determine whether or not we are on the board (i.e. have a valid snap)
        bool isSnappable =  (0 <= coordinate.x && coordinate.x <= 3) &&
                            (0 <= coordinate.y && coordinate.y <= 3) &&
                            (0 <= coordinate.z && coordinate.z <= 3) &&
                            (0 <= coordinate.w && coordinate.w <= 3);

        // If we have a valid snap
        if (isSnappable)
        {
            // Reconvert our coordinate to a position
            Vector3 newPos = PositionFromCoordinate();

            this.gameObject.GetComponent<Transform>().position = newPos;

            // Reset the piece to its original orientation
            this.gameObject.GetComponent<Transform>().rotation = r0;
        }

        // Return and tell us if we snapped succesfully
        return isSnappable;
    }

    private Vector3 PositionFromCoordinate()
    {

        // Okay, recall our chess set has 4 coordinates. The xy by chess in the chess convention is scaled the same, 
        // and represents our traditional chess board. The z direction is up and down, and the board scales by some
        // factor each time it goes up. The w direction is "Hyper-forward", and is a fixed offset.
        // To get from the bottom corner to any other given one given a coordinate, we need to that into account.

        // Easy, z coordinate multiplied the scale of the offset, times the up vector.
        Vector3 z = coordinate.z * z_offset * up;

        // Since the z coordinate scaleds by a factor as we go up, we want to move this offset to the center before scaling
        Vector3 center = xy_offset * 1.5f * (rt+fw);

        // Determine the scaling factor. Scales by a fixed factor each time up, so we'll use a for loop. On the zeroth layer,
        // coordinate.z = 0, the loop doesnt run. On the first, coordinate.z = 1 so it runs once. Start at one
        float scaler = 1.0f;

        // Each time we go up, multiply by our scaling factor.
        for (int i = 0; i < coordinate.z; i++)
        {
            scaler *= z_scaling;
        }

        // Next we want to undo our center vector, but multiplied by the scaling we specified.
        Vector3 un_center = -center * scaler;

        // XY offset is pretty easy. Just make sure to account for the scaling.
        Vector3 xy = (coordinate.x*rt + coordinate.y*fw) * xy_offset * scaler;

        // W offset is likewise easy, just apply a fixed offset
        Vector3 w = fw * coordinate.w * w_offset;

        Vector4 position_from_coordinate = root + center + z + un_center + xy + w;
        
        // Now lets go through the whole process. Move to center, move up, uncenter, and apply the rest of the coordinates
        return position_from_coordinate;

        // There we go. Now once the values are fine tuned, all the hypersquares should line themselves up based on their coordinates.
    }

}
