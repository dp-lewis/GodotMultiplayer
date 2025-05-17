# Godot Multiplayer

This is the result of me following the Godot Multiplayer course on GameDev.tv 

https://www.gamedev.tv/courses/godot-multiplayer


## Notes on getting this online

- The game needs a relay server to connect the clients
- In the original course W4 Games was used, but they don't appear to accept registrations anymore
- When using W4 the instructor also used a WebRTC addon for the native application as only web gets it for free
- The instructor had to change the name of the auto loaded Lobby class as it clashed with W4 games version
- Authentication was done in the lobby script after subscribing to the multiplayer events
- The instructor was able to remove most of the connection set up in create_game as W4 handles it
- A lobby is the equivilent of the Host button being pressed in the original project
