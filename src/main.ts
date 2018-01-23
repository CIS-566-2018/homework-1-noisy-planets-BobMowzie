import {vec3} from 'gl-matrix';
import {vec4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Drawable from './rendering/gl/Drawable';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import { log } from 'util';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 8,
  'Load Scene': loadScene, // A function pointer, essentially
  planet: 0,
  featuresScale: 1,
  seed: 0,
};

let icosphere: Icosphere;

let frame: number;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  frame = 0;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'planet', { Endor: 0, Tatooine: 1, Hoth: 2, Dagobah: 3, Mustafar: 4 });
  gui.add(controls, 'featuresScale', 0.1, 1.5).step(0.01);
  gui.add(controls, 'seed', 0, 50).step(1);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  let shader: ShaderProgram;

  // This function will be called every frame
  function tick() {
    shader = new ShaderProgram([
      new Shader(gl.VERTEX_SHADER, require('./shaders/myshader-vert.glsl')),
      new Shader(gl.FRAGMENT_SHADER, require('./shaders/myshader-frag.glsl')),
    ]);

    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    shader.setFrame(frame);
    shader.setPlanet(controls.planet);
    shader.setScale(controls.featuresScale);
    shader.setSeed(controls.seed);
    let shape: Drawable;
    shape = icosphere;
    renderer.render(camera, shader, [shape]);
    stats.end();

    frame += 1;

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
