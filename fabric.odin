package fabric

import math "core:math"
import rl "vendor:raylib"

// simple particle
Particle :: struct {
	position:    rl.Vector3,
	velocity:    rl.Vector3,
	forced:      rl.Vector3,
	mass:        f32,
	inverseMass: f32,
	fixed:       bool,
	index:       i32,
	color:       rl.Color,
}

Triangle :: struct {
	particles: [3]i32,
	normal:    rl.Vector3,
	area:      f32,
}

Cloth :: struct {
	particles: []Particle,
	triangles: []Triangle,
}

CreateMesh :: proc(height: f32, width: f32, rows: i32, columns: i32, color: rl.Color) -> Cloth {
	particles := make([]Particle, int(rows * columns))
	triangles := make([]Triangle, int((rows - 1) * (columns - 1) * 2))

	for row in 0 ..< rows {
		for col in 0 ..< columns {
			index := row * columns + col
			xPos := -width / 2 + f32(col) * (width / f32(columns - 1))
			yPos := height
			zPos := -height / 2 + f32(row) * (height / f32(rows - 1))

			particles[index] = Particle {
				position    = rl.Vector3{xPos, yPos, zPos},
				velocity    = rl.Vector3{0, 0, 0},
				forced      = rl.Vector3{0, 0, 0},
				mass        = 1.0,
				inverseMass = 1.0,
				fixed       = (col == 0 || col == columns - 1),
				index       = index,
				color       = color,
			}
		}
	}

	triIndex := 0
	for row in 0 ..< rows - 1 {
		for col in 0 ..< columns - 1 {
			p1 := row * columns + col
			p2 := row * columns + (col + 1)
			p3 := (row + 1) * columns + col

			triangles[triIndex] = Triangle {
				particles = {i32(p1), i32(p2), i32(p3)},
				normal    = rl.Vector3{0, 1, 0},
				area      = 0.5 * (width / f32(columns - 1)) * (height / f32(rows - 1)),
			}
			triIndex += 1

			p1 = (row + 1) * columns + col
			p2 = row * columns + (col + 1)
			p3 = (row + 1) * columns + (col + 1)

			triangles[triIndex] = Triangle {
				particles = {i32(p1), i32(p2), i32(p3)},
				normal    = rl.Vector3{0, 1, 0},
				area      = 0.5 * (width / f32(columns - 1)) * (height / f32(rows - 1)),
			}
			triIndex += 1
		}
	}

	return Cloth{particles = particles, triangles = triangles}
}

main :: proc() {
	rl.InitWindow(1600, 900, "fabric")
	rl.SetTargetFPS(144)

	meshHeight, meshWidth: f32 = 5.0, 5.0
	rows, columns: i32 = 10, 10
	cloth := CreateMesh(meshHeight, meshWidth, rows, columns, rl.BLUE)
  particles := cloth.particles
  triangles := cloth.triangles

	meshCenter := rl.Vector3{0, meshHeight / 2, 0}

	camera := rl.Camera3D {
		position   = rl.Vector3{0, meshHeight, meshHeight * 2},
		target     = meshCenter,
		up         = rl.Vector3{0, 1, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}

	cameraDistance: f32 = 10.0
	cameraAngleX, cameraAngleY: f32 = 0.0, 0.2

	prevMousePos := rl.Vector2{0, 0}
	isDragging := false

	for (!rl.WindowShouldClose()) {
		if rl.IsMouseButtonDown(.RIGHT) {
			currentMousePos := rl.GetMousePosition()

			if !isDragging {
				prevMousePos = currentMousePos
				isDragging = true
			}

			deltaX := currentMousePos.x - prevMousePos.x
			deltaY := currentMousePos.y - prevMousePos.y

			cameraAngleX += cast(f32)deltaX * 0.005
			cameraAngleY += cast(f32)deltaY * 0.005

			cameraAngleY = clamp(cameraAngleY, -1.5, 1.5)

			camera.position.x =
				meshCenter.x +
				f32(cameraDistance * math.cos(cameraAngleY) * math.sin(cameraAngleX))
			camera.position.y = meshCenter.y + f32(cameraDistance * math.sin(cameraAngleY))
			camera.position.z =
				meshCenter.z +
				f32(cameraDistance * math.cos(cameraAngleY) * math.cos(cameraAngleX))

			prevMousePos = currentMousePos
		} else {
			isDragging = false
		}

		mouseWheel := rl.GetMouseWheelMove()
		if mouseWheel != 0 {
			cameraDistance -= f32(mouseWheel)
			cameraDistance = clamp(cameraDistance, 2, 20)

			camera.position.x =
				meshCenter.x +
				f32(cameraDistance * math.cos(cameraAngleY) * math.sin(cameraAngleX))
			camera.position.y = meshCenter.y + f32(cameraDistance * math.sin(cameraAngleY))
			camera.position.z =
				meshCenter.z +
				f32(cameraDistance * math.cos(cameraAngleY) * math.cos(cameraAngleX))
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		rl.BeginMode3D(camera)

		for particle in particles {
			rl.DrawSphere(particle.position, 0.1, particle.color)
		}

		for row in 0 ..< rows {
			for col in 0 ..< columns {
				index := row * columns + col

				if col < columns - 1 {
					rl.DrawLine3D(
						particles[index].position,
						particles[index + 1].position,
						rl.BLACK,
					)
				}

				if row < rows - 1 {
					rl.DrawLine3D(
						particles[index].position,
						particles[index + columns].position,
						rl.BLACK,
					)
				}
				if row < rows - 1 && col < columns - 1 {
					rl.DrawLine3D(
						particles[index + 1].position,
						particles[index + columns].position,
						rl.DARKGRAY,
					)
				}
			}
		}

		rl.EndMode3D()
		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	delete(particles)
	delete(triangles)
	rl.CloseWindow()
}
