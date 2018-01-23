# CIS 566 Project 1: Noisy Planets

## Objective
- Continue practicing WebGL and Typescript
- Experiment with noise functions to procedurally generate the surface of a planet
- Review surface reflection models

## Base Code
You'll be using the same base code as in homework 0.

## Assignment Details
- Update the basic scene from your homework 0 implementation so that it renders
an icosphere once again. We recommend increasing the icosphere's subdivision
level to 6 so you have more vertices with which to work.
- Write a new GLSL shader program that incorporates various noise functions and
noise function permutations to offset the surface of the icosphere and modify
the color of the icosphere so that it looks like a planet with geographic
features. Try making formations like mountain ranges, oceans, rivers, lakes,
canyons, volcanoes, ice caps, glaciers, or even forests. We recommend using
3D noise functions whenever possible so that you don't have UV distortion,
though that effect may be desirable if you're trying to make the poles of your
planet stand out more.
- Implement various surface reflection models (e.g. Lambertian, Blinn-Phong,
Matcap/Lit Sphere, Raytraced Specular Reflection) on the planet's surface to
better distinguish the different formations (and perhaps even biomes) on the
surface of your planet. Make sure your planet has a "day" side and a "night"
side; you could even place small illuminated areas on the night side to
represent cities lit up at night.
- Add GUI elements via dat.GUI that allow the user to modify different
attributes of your planet. This can be as simple as changing the relative
location of the sun to as complex as redistributing biomes based on overall
planet temperature. You should have at least three modifiable attributes.
- Have fun experimenting with different features on your planet. If you want,
you can even try making multiple planets! Your score on this assignment is in
part dependent on how interesting you make your planet, so try to
experiment with as much as you can!

For reference, here is a planet made by your TA Dan last year for this
assignment:

![](danPlanet.png)

Notice how the water has a specular highlight, and how there's a bit of
atmospheric fog near the horizon of the planet. This planet used only simple
Fractal Brownian Motion to create its mountainous shapes, but we expect you all
can do something much more exciting! If we were to grade this planet by the
standards for this year's version of the assignment, it would be a B or B+.

## Useful Links
- [Implicit Procedural Planet Generation](https://static1.squarespace.com/static/58a1bc3c3e00be6bfe6c228c/t/58a4d25146c3c4233fb15cc2/1487196929690/ImplicitProceduralPlanetGeneration-Report.pdf)
- [Curl Noise](https://petewerner.blogspot.com/2015/02/intro-to-curl-noise.html)
- [GPU Gems Chapter on Perlin Noise](http://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch05.html)
- [Worley Noise Implementations](https://thebookofshaders.com/12/)


## Submission
Commit and push to Github, then submit a link to your commit on Canvas.

For this assignment, and for all future assignments, modify this README file
so that it contains the following information:
- Your name and PennKey

Joshua Nadel, jnad

- Citation of any external resources you found helpful when implementing this
assignment.

http://htmlcolorcodes.com/color-picker/
https://www.shadertoy.com/view/4sfGzS

- A link to your live github.io demo (we'll talk about how to get this set up
in class some time before the assignment is due)
- At least one screenshot of your planet

![](endor.png)
![](tatooine.png)
![](hoth.png)
![](dagobah.png)
![](mustafar.png)

- An explanation of the techniques you used to generate your planet features.
Please be as detailed as you can; not only will this help you explain your work
to recruiters, but it helps us understand your project when we grade it!

Each planet has, in decreasing order of scale, continent perlin noise, mountain perlin noise, beach perlin noise, and surface perlin noise. Each planet also has a sea level float.
The absolute value of the mountain noise is used to create the ridge-like effect of terrain peaks. The continent noise is added to this height to create more variety and separate areas of land from areas of sea. Furthermore, the continent noise is used as an alpha to blend between the mountain height and the sea level. Any height lower than the sea level is clamped. Beach noise is masked to ignore the mountains and then applied to create variety along the continent shores. For planets without oceans, the sea level is understood to less-literally distinguish between mountainous and plain regions. Surface noise is lightly applied everywhere to add variety. Most color is determined through a series of mix calls using variations of terrain height as the alpha.

The water uses animated noise to vary the color accross its surface to create a wavy, ocean-like appearance. Phong shading is used to add a small specular highlight to its surface.

Trees are generated with forest and tree noise components. The forest noise decides where forests are located, and is masked by height to ignore mountains and beaches. If the forest noise at a vertex exceeds a certain threshhold, the terrain is colored dark green and tree noise is applied to the height. The tree noise is dense perlin noise to indicate treetops.

Tatooine uses a terracing effect on the terrain height in mountainous regions to create a sense of the sedimentary rock that makes up desert terrain. The dunes in the flat regions are created with a sin function, the period of which is varied through more noise.

Mustafar has a lava material instead of water. The absolute value of dense, animated noise varies the color across the lava's surface, and an animated emissive property glows and dims the lava. In plain regions, the absolute value of noise is subtracted from sea level to create cracks of magma in the planet's surface. In mountainous regions, the peaks of mountains above a certain height are inverted and filled with lava to create volcanoes.

## Extra Credit
- Use a 4D noise function to modify the terrain over time, where time is the
fourth dimension that is updated each frame. A 3D function will work, too, but
the change in noise will look more "directional" than if you use 4D.
- Use music to animate aspects of your planet's terrain (e.g. mountain height,
  brightness of emissive areas, water levels, etc.)
- Create a background for your planet using a raytraced sky box that includes
things like the sun, stars, or even nebulae.
