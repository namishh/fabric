package fabric

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(1600, 900, "fabric")
    rl.SetTargetFPS(144)

    for (!rl.WindowShouldClose()) {
        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)

        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}