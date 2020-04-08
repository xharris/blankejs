const r = require('raylib')

// Initialization
//--------------------------------------------------------------------------------------
const screenWidth = 800;
const screenHeight = 450;

r.InitWindow(screenWidth, screenHeight, "raylib [shaders] example - texture waves");

// Load texture texture to apply shaders
var texture = r.LoadTexture("resources/space.png");

// Load shader and setup location points and values
const shader = r.LoadShader(__dirname+`/resources/empty.vs`, __dirname+`/resources/wave.fs`);

var sizeLoc = r.GetShaderLocation(shader, "size");
var secondsLoc = r.GetShaderLocation(shader, "secondes");
var freqXLoc = r.GetShaderLocation(shader, "freqX");
var freqYLoc = r.GetShaderLocation(shader, "freqY");
var ampXLoc = r.GetShaderLocation(shader, "ampX");
var ampYLoc = r.GetShaderLocation(shader, "ampY");
var speedXLoc = r.GetShaderLocation(shader, "speedX");
var speedYLoc = r.GetShaderLocation(shader, "speedY");

// Shader uniform values that can be updated at any time
var freqX = 25.0;
var freqY = 25.0;
var ampX = 5.0;
var ampY = 5.0;
var speedX = 8.0;
var speedY = 8.0;
var screenSize = r.Vector2(r.GetScreenWidth(), r.GetScreenHeight());

r.SetShaderValue(shader, sizeLoc, screenSize, r.UNIFORM_VEC2);
r.SetShaderValue(shader, freqXLoc, freqX, r.UNIFORM_FLOAT);
r.SetShaderValue(shader, freqYLoc, freqY, r.UNIFORM_FLOAT);
r.SetShaderValue(shader, ampXLoc, ampX, r.UNIFORM_FLOAT);
r.SetShaderValue(shader, ampYLoc, ampY, r.UNIFORM_FLOAT);
r.SetShaderValue(shader, speedXLoc, speedX, r.UNIFORM_FLOAT);
r.SetShaderValue(shader, speedYLoc, speedY, r.UNIFORM_FLOAT);

var seconds = 0.0;

r.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
// -------------------------------------------------------------------------------------------------------------

// Main game loop
while (!r.WindowShouldClose())    // Detect window close button or ESC key
{
    // Update
    //----------------------------------------------------------------------------------
    seconds += r.GetFrameTime();
    
    r.SetShaderValue(shader, secondsLoc, seconds, r.UNIFORM_FLOAT);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    r.BeginDrawing();

        r.ClearBackground(r.RAYWHITE);

        r.BeginShaderMode(shader);
        
            r.DrawTexture(texture, 0, 0, r.WHITE);
            r.DrawTexture(texture, texture.width, 0, r.WHITE);
            
        r.EndShaderMode();

    r.EndDrawing();
    //----------------------------------------------------------------------------------
}

// De-Initialization
//--------------------------------------------------------------------------------------
r.UnloadShader(shader);         // Unload shader
r.UnloadTexture(texture);       // Unload texture

r.CloseWindow();              // Close window and OpenGL context
//--------------------------------------------------------------------------------------

return 0;
