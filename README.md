# FSM Pathfinding NPC in Roblox

This project implements a **Finite State Machine (FSM)** to control NPC behavior in Roblox Studio. The NPC transitions between states like `idle`, `attack`, `escape`, and `die`, using **pathfinding** to navigate and interact with players.

## Features
- **Idle**: NPC waits for a player to come within range.
- **Attack**: NPC follows and attacks players.
- **Escape**: NPC flees when its health is low.
- **Die**: NPC dies when health reaches zero.

## Installation

### Step 1: Download and Open the Project
1. Clone the repository using the following command:
   
   ```bash
   git clone https://github.com/JunSayke/FSM-Application.git
3. Open **Roblox Studio**.
4. Click **File > Open from File** and select the downloaded `.rbxl` file.

### Step 2: Explore the Place
- The place contains an NPC (rig) set up with a Finite State Machine (FSM) script.
- In the **Explorer** window, find the NPC under the **Workspace**.

### Step 3: Customize the FSM Logic (Optional)
1. Select the NPC in **Explorer**.
2. Look for a script attached to the NPC. You can modify the FSM code here to suit your game’s needs (e.g., changing health thresholds, adding more states, or altering behaviors).
3. You can adjust the **state transition table** or the NPC’s pathfinding logic directly in the script.

### Step 4: Run the Game
1. Click **Play** in **Roblox Studio** to test the NPC’s behavior.
2. The NPC will transition between `idle`, `attack`, `escape`, and `die` states based on the proximity of players and the NPC's health.

## How to Use
- The NPC automatically transitions between states based on in-game conditions:
  - **Idle**: When no player is nearby.
  - **Attack**: When a player comes within range.
  - **Escape**: When the NPC's health drops below a threshold.
  - **Die**: When the NPC's health reaches zero.

You can modify these behaviors by editing the state transition logic in the script.

## Additional Information
- **State Management**: The NPC uses a state transition table to switch between behaviors. Modify the table to add or change state transitions.
- **Pathfinding**: Roblox’s **PathfindingService** is used for NPC navigation.

## DFA Structure
![image](https://github.com/user-attachments/assets/f69ffb59-8d73-4d3b-a3b7-11053737f274)

Feel free to extend the project by tweaking the states or adding new behaviors!
[Reference Link](https://www.ijarsct.co.in/Paper2062.pdf)
