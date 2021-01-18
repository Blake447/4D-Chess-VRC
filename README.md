# 4D-Chess-VRC
This package is a 4D Chess board for utilization in VRChat through Udon and UdonSharp. The game itself extends the rules of traditional 2D chess to 4 spatial dimensions by restating the move sets of the original game in terms of combinations of forward and lateral directions, and adds a hyperforward (w axis) and hyperlateral (z axis) direction, allowing for either, both, or neither to be chosen as the forward/lateral direction used to generate the original movesets. It also makes the board 4x4x4x4 as opposed to the traditional 8x8

## Requirements:

1. Unity 2018.4.20f1 or greater
2. VRCSDK3 with Udon: https://vrchat.com/home/download
3. Merlin's Udon Sharp compiler: https://github.com/MerlinVR/UdonSharp/releases
	- Note: Udon Sharp v0.19.0 is tested an works correctly. Older versions may handle int casts differently. In older versions, explicit integer casts may be treated as rounding operations instead of truncation, leading to the snap function breaking, upon which the visualizer depends.

## Installation:

Install the VRChat SDK and Udon Sharp compiler first, then merge the Assets folder included in the master branch with your Assets folder in the unity project.
	
## Usage:

There are two prefabs included in this package. The first is an actual chess board, all set up for a game, and the other is a set of informative structures accompanied by text that allows new players to get the grasp of understanding how to extend chess to 4 Dimensions. After the installation process is complete, simply drop either prefab into the scene. The prefab for the chess board can be rescaled, moved, and rotated without breaking, however this CAN NOT be done while in play mode and has to be done before runtime. Many calculations are done to ascertain the scale of the model and generate basis vectors for snapping logic that only occur on start up to maintain good performance.

## Customization

As stated above, you can scale, rotate, and move the main prefab. Additionally, you can change the material for the board and pieces. The visualizer material also allows you to pick the colors for valid moves and attacking moves, however the shader itself is fairly complicated and can't be easily modified. Finally, the scale of the individual pieces should also be adjustable without breaking any of the logic. The spacing between slices and volumes of the board in relation to the scale of the squares are fixed and cannot be easily altered.
