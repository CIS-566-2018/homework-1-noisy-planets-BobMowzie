#version 300 es

//This is amp1 vertex shader. While it is called amp1 "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in amp1 FOR loop, one at amp1 time.
//This simultaneous transformation allows your program to run much faster, efs_specially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written amp1 static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Frame;
uniform int u_Planet;
uniform float u_Scale;
uniform float u_Seed;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Pos;
out vec4 my_Pos;
out float fs_spec;
out float fs_emiss;

uniform vec2 u_Dimensions;

const vec3 amp1 = vec3(0.4, 0.5, 0.8);
const vec3 freq1 = vec3(0.2, 0.4, 0.2);
const vec3 freq2 = vec3(1.0, 1.0, 2.0);
const vec3 amp2 = vec3(0.25, 0.25, 0.0);

const vec3 e = vec3(0.2, 0.5, 0.8);
const vec3 f = vec3(0.2, 0.25, 0.5);
const vec3 g = vec3(1.0, 1.0, 0.1);
const vec3 h = vec3(0.0, 0.8, 0.2);

// Return amp1 random direction in amp1 circle
vec2 random2( vec2 p ) {
    p += u_Seed;
    return normalize(2. * fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453) - 1.);
}

vec3 Gradient(float t)
{
    return amp1 + freq1 * cos(6.2831 * (freq2 * t + amp2));
}

vec3 Gradient2(float t)
{
    return e + f * cos(6.2831 * (g * t + h));
}

float surflet(vec2 P, vec2 gridPoint)
{
    // Compute falloff function by converting linear distance to amp1 polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float tX = 1. - 6. * pow(distX, 5.0) + 15. * pow(distX, 4.0) - 10. * pow(distX, 3.0);
    float tY = 1. - 6. * pow(distY, 5.0) + 15. * pow(distY, 4.0) - 10. * pow(distY, 3.0);

    // Get the random vector for the grid point
    vec2 gradient = random2(gridPoint);
    // Get the vector from the grid point to P
    vec2 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY;
}

float PerlinNoise(vec2 uv)
{
    // Tile the space
    vec2 uvXLYL = floor(uv);
    vec2 uvXHYL = uvXLYL + vec2(1.,0.);
    vec2 uvXHYH = uvXLYL + vec2(1.,1.);
    vec2 uvXLYH = uvXLYL + vec2(0.,1.);

    return surflet(uv, uvXLYL) + surflet(uv, uvXHYL) + surflet(uv, uvXHYH) + surflet(uv, uvXLYH);
}

float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
	p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

float myPerlinOffset(float freq, float dx, float dy, float dz)
{
    float x = (my_Pos.x + dx) * freq;
    float y = (my_Pos.y + dy) * freq;
    float z = (my_Pos.z + dz) * freq;
    float XY = PerlinNoise(vec2(x, y));
    float XZ = PerlinNoise(vec2(x, z));
    float YZ = PerlinNoise(vec2(y, z));
    return (XY + XZ + YZ)/3.;//noise(vec3(x, y, z)) - 0.5;
}

float myPerlin(float freq) {
    return myPerlinOffset(freq, 0., 0., 0.);
}

float myclamp(float v, float min, float max)
{
    if (v < min) v = min;
    else if (v > max) v = max;
    return v;
}

float terrace(float v, float increment) {
    float a = floor(v / increment);
    return (a * increment);
}

const vec4 lightPos = vec4(5., 5., 3., 1.); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

void main()
{
    float invScale = 1./u_Scale;
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    my_Pos = vs_Pos;
    fs_emiss = 0.;
    float amp1 = 1.3 * u_Scale;
    float amp2 = 0.6 * u_Scale;
    float amp3 = 0.15 * u_Scale;
    float amp4 = 0.1 * u_Scale;
    float sealevel = 0.45;
    float mountainNoise = myPerlin(5. * invScale);
    float continentNoise = myPerlin(1.2 * invScale);
    float beachNoise = myPerlin(12. * invScale);
    float surfaceNoise = myPerlin(24. * invScale);
    float offset;

    //Endor
    if (u_Planet == 0){
        offset = amp1 * (mix(sealevel * (1. - 0.05 * u_Scale), 1. - abs(mountainNoise) - 0.5, 1. - pow(1. - continentNoise, 2. * u_Scale)) + (amp2 * continentNoise) - sealevel) + sealevel + beachNoise * amp3 * (1. - continentNoise) + surfaceNoise * amp4;
        if (offset < sealevel) {
            offset = sealevel;
            float perlin5 = myPerlinOffset(20. * invScale, u_Frame * 0.002, u_Frame * 0.002, u_Frame * 0.002) + 0.5;
            fs_Col = mix(vec4(38./255., 120./255., 165./255., 1), vec4(68./255., 188./255., 208./255., 1), myclamp(perlin5, 0., 1.));
            fs_spec = 1.;
        }
        else {
            fs_Col = mix(vec4(214./255., 202./255., 158./255., 1), vec4(0.1, 0.7, 0.1, 1), (offset - sealevel)/(1. - sealevel) * 8. * invScale * invScale);
            fs_Col = mix(fs_Col, vec4(0.5, 0.5, 0.5, 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 3.5 * invScale * invScale, 2.8 * invScale), 0., 1.));
            fs_Col = mix(fs_Col, vec4(0.9, 0.9, 0.9, 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 2.2 * invScale * invScale, 6. * invScale), 0., 1.));
            fs_spec = 0.;

            if (offset > sealevel * (1. + 0.1 * u_Scale)) {
                float forestNoise = (myPerlin(13. * invScale) + 0.5);
                float treeNoise = myPerlin(100. * invScale);
                if (forestNoise > 0.4 && ((offset - sealevel)/amp1 < 0.1 * u_Scale)) {
                    offset += treeNoise * 0.15 * u_Scale;
                    fs_Col = mix(vec4(0., 0.2, 0., 1.), vec4(0., 0.4, 0., 1.), treeNoise);
                }
            }
        }
    }

    //Tatooine
    else if (u_Planet == 1) {
        offset = amp1 * (mix(sealevel * (1. - 0.05 * u_Scale), 1. - abs(mountainNoise) - 0.5, 1. - pow(1. - continentNoise, 2. * u_Scale)) + (amp2 * continentNoise) - sealevel) + sealevel + beachNoise * amp3 * (1. - continentNoise) + surfaceNoise * amp4;
        offset = terrace(offset, 0.04 * u_Scale * u_Scale);
        offset = offset + myPerlin(30. * invScale) * 0.05 * u_Scale;
        if (offset < sealevel) {
            offset = sealevel;
            offset += 0.01 * sin((my_Pos.x + 0.15 * mountainNoise * u_Scale) * 80. * invScale) * u_Scale;
        }

        fs_Col = mix(vec4(234./255., 202./255., 158./255., 1), vec4(139./255., 81./255., 43./255., 1), myclamp((offset - sealevel)/(1. - sealevel) * 12. * invScale * invScale, 0., 1.));
        fs_Col = mix(fs_Col, vec4(255./255., 249./255., 216./255., 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 6. * invScale * invScale, 6.), 0., 1.));
        fs_Col = mix(fs_Col, vec4(70./255., 30./255., 0./255., 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 4. * invScale * invScale, 6.), 0., 1.));
        fs_Col = mix(fs_Col, vec4(159./255., 101./255., 53./255., 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 3. * invScale * invScale, 6.), 0., 1.));
        fs_spec = 0.;
    }

    //Hoth
    else if (u_Planet == 2) {
        amp1 = 1.4 * u_Scale;
        sealevel = 0.35;
        offset = amp1 * (mix(sealevel * (1. - 0.05 * u_Scale), 1. - abs(mountainNoise) - 0.5, 1. - pow(1. - continentNoise, 2. * u_Scale)) + (amp2 * continentNoise) - sealevel) + sealevel + beachNoise * amp3 * (1. - continentNoise) + surfaceNoise * amp4;
        if (offset < sealevel) {
            offset = sealevel;
        }

        fs_Col = mix(vec4(250./255., 250./255., 250./255., 1), vec4(0.7, 0.7, 0.72, 1), (offset - sealevel)/(1. - sealevel) * 12. * invScale * invScale);
        fs_Col = mix(fs_Col, vec4(0.9, 0.9, 0.9, 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 3. * invScale * invScale, 6. * invScale), 0., 1.));
        fs_spec = 0.;
    }

    //Dagobah
    else if (u_Planet == 3) {
        amp1 = 0.2 * u_Scale;
        amp3 = 0.05 * u_Scale;
        amp4 = 0.05 * u_Scale;
        sealevel = 0.3;
        offset = amp1 * (mix(sealevel * (1. - 0.05 * u_Scale), 1. - abs(mountainNoise) - 0.5, 1. - pow(1. - continentNoise, 2. * u_Scale)) + (amp2 * continentNoise) - sealevel) + sealevel + beachNoise * amp3 * (1. - continentNoise) + surfaceNoise * amp4;
        if (offset < sealevel) {
            offset = sealevel;
            float perlin5 = myPerlinOffset(20. * invScale, u_Frame * 0.002, u_Frame * 0.002, u_Frame * 0.002) + 0.5;
            fs_Col = mix(vec4(31./255., 58./255., 40./255., 1.), vec4(51./255., 82./255., 60./255., 1.), myclamp(perlin5, 0., 1.));
            fs_spec = 1.;
        }
        else {
            fs_Col = mix(vec4(81./255., 75./255., 56./255., 1), vec4(46./255., 80./255., 44./255., 1.), (offset - sealevel)/(1. - sealevel) * 8. * invScale * invScale);
            fs_Col = mix(fs_Col, vec4(0.5, 0.5, 0.5, 1.), myclamp(pow((offset - sealevel)/(1. - sealevel) * 3.5 * invScale * invScale, 2.8 * invScale), 0., 1.));
            fs_Col = mix(fs_Col, vec4(0.9, 0.9, 0.9, 1.), myclamp(pow((offset - sealevel)/(1. - sealevel) * 2.2 * invScale * invScale, 6. * invScale), 0., 1.));
            fs_spec = 0.;

            if ((offset > sealevel * (1. + 0.02 * u_Scale))) {
                float forestNoise = (myPerlin(13. * invScale) + 0.5);
                float treeNoise = myPerlin(100. * invScale);
                if (forestNoise > 0.3) {
                    offset += treeNoise * 0.06 * u_Scale;
                    fs_Col = mix(vec4(0./255., 25./255., 0./255., 1), vec4(25./255., 55./255., 24./255., 1), treeNoise);
                }
            }
        }
    }

    //Mustafar
    else if (u_Planet == 4) {
        amp1 = 1.4 * u_Scale;
        sealevel = 0.35;
        offset = amp1 * (mix(sealevel * (1. - 0.05 * u_Scale), 1. - abs(mountainNoise) - 0.5, 1. - pow(1. - continentNoise, 2. * u_Scale)) + (amp2 * continentNoise) - sealevel) + sealevel + beachNoise * amp3 * (1. - continentNoise) + surfaceNoise * amp4;
        if (offset < sealevel) {
            offset = sealevel;
            float lavaCracks = pow(1. - abs(mountainNoise) * 2., 12. * invScale);
            offset -= 0.05 * lavaCracks * u_Scale * u_Scale;
            fs_emiss = mix(0.6 + 0.4 * sin(u_Frame * 0.15), 0., myclamp(pow((offset + 0.1 * u_Scale * u_Scale - sealevel)/(1. - sealevel) * 8. * invScale * invScale, 6. * invScale), 0., 1.));
        }

        vec4 lavaColor = mix(vec4(250./255., 250./255., fs_emiss * 30./255., 1), vec4(250./255., 100./255., fs_emiss * 30./255., 1), pow(1. - abs(myPerlinOffset(35. * invScale, u_Frame * 0.002, u_Frame * 0.002, u_Frame * 0.002)) * 2., 2. * invScale));

        fs_Col = lavaColor;
        fs_Col = mix(fs_Col, vec4(62./255., 50./255., 36./255., 1), myclamp(pow((offset + 0.1 * u_Scale * u_Scale - sealevel)/(1. - sealevel) * 8. * invScale * invScale, 6. * invScale * invScale), 0., 1.));
        fs_Col = mix(fs_Col, vec4(0.15, 0.1, 0.1, 1), myclamp(pow((offset - sealevel)/(1. - sealevel) * 3. * invScale * invScale, 1.), 0., 1.));
        fs_spec = 0.;

        float volcanoHeight = sealevel + u_Scale * u_Scale * (0.25 + 0.2 * beachNoise + continentNoise * 0.3);
        if (offset > volcanoHeight) {
            offset = volcanoHeight - (offset - volcanoHeight);
            fs_emiss = 0.6 + 0.4 * sin(u_Frame * 0.15);
            fs_Col = lavaColor;
        }
    }

    

    
    fs_Pos = vec4(vs_Pos[0] + vs_Nor[0] * offset, vs_Pos[1] + vs_Nor[1] * offset, vs_Pos[2] +  vs_Nor[2] * offset, vs_Pos[3]);
    vec4 modelposition = u_Model * fs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is amp1 built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
