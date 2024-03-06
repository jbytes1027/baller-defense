# Baller Defense
A mobile game I created in high school using the Godot game engine. The code reflects it, but the game design remains solid due to the hours I spent tweaking it. I designed the game to have a satisfying gameplay loop with a simple yet striking art style to compensate for the short time frame and limited resources I had available.

## Visual Design
The shimmering background was created by randomly spawning several partially transparent trapezoids that disappear after a short timeout. A GLSL particle shader was used to display the hundreds of shapes efficiently. The colors are algorithmically calculated to maximize contrast.

![bg-showcase](https://github.com/jbytes1027/baller-defense/assets/50090107/a7c23875-6aac-46e4-ba0d-553403874a50)

I also used a shader for natural fade in and fade out transitions.

![fade showcase](https://github.com/jbytes1027/baller-defense/assets/50090107/5a94221d-a447-47d6-ab12-13e0ff578cc6)

The game was animated to feel as smooth as possible. The player has several mid-air postures that change based on the player's distance to the ball.

![distance to ball](https://github.com/jbytes1027/baller-defense/assets/50090107/fccec4c9-5304-48ac-ab82-a0bf54add875)

These postures are the windup frames of the three punch animations.

![showcase punch animations](https://github.com/jbytes1027/baller-defense/assets/50090107/442d6a84-9b65-42c5-bf8a-3c4abf0bcd39)

Windups are a critical part of punch animations. This system allows for an instant punch response on tap, while keeping the windup. The punch impact is heightened by freezing the background for a frame, enlarging the ball, and queueing up a sound.

![punch showcase](https://github.com/jbytes1027/baller-defense/assets/50090107/250c5c2b-a85b-491d-a7f6-90c03e1dc033)

I also made sure that the player looked like he has a soul by adding a rest animation with an occasional blink.

![rest showcase](https://github.com/jbytes1027/baller-defense/assets/50090107/91cd78a1-03e3-46a5-a7af-373727cd9c0f)

If there is anything this project taught me, it's that the pixel-level decisions make or break the high level ideas. They should be deliberated over.
