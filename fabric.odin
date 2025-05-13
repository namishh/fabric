package fabric

import math "core:math"
import rl "vendor:raylib"

Particle :: struct {
	position:    rl.Vector3,
	velocity:    rl.Vector3,
	force:       rl.Vector3,
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

SpringType :: enum {
	Structural,
	Stretch,
	Bend,
}

Spring :: struct {
	particleA:      i32,
	particleB:      i32,
	restLength:     f32,
	stiffness:      f32,
	damping:        f32,
	maxStretch:     f32,
	maxCompression: f32,
	t:              SpringType,
}

// bend elements
BendElement :: struct {
	particleA:  i32,
	particleB:  i32,
	particleC:  i32,
	particleD:  i32,
	restAngle:  f32,
	stiffness:  f32,
	damping:    f32,
	edgeVector: rl.Vector3,
}

Cloth :: struct {
	particles:    []Particle,
	triangles:    []Triangle,
	springs:      []Spring,
	bendElements: []BendElement,
}

CreateSprings :: proc(cloth: ^Cloth, rows: i32, columns: i32) {
	structuralSprings := (rows - 1) * columns + rows * (columns - 1)
	shearSprings := (rows - 1) * (columns - 1) * 2
	bendSprings := (rows - 2) * columns + rows * (columns - 2)
	cloth.springs = make([]Spring, int(structuralSprings + shearSprings + bendSprings))

	springIndex := 0

	for row in 0 ..< rows {
		for col in 0 ..< columns {
			index := row * columns + col

			if col < columns - 1 {
				restLength := rl.Vector3Distance(
					cloth.particles[index].position,
					cloth.particles[index + 1].position,
				)

				cloth.springs[index] = Spring {
					particleA  = index,
					particleB  = index + 1,
					restLength = restLength,
					stiffness  = 0.5,
					damping    = 0.1,
					t          = .Structural,
				}

				springIndex += 1
			}


			if row < rows - 1 {
				restLength := rl.Vector3Distance(
					cloth.particles[index].position,
					cloth.particles[index + columns].position,
				)

				cloth.springs[springIndex] = Spring {
					particleA      = i32(index),
					particleB      = i32(index + columns),
					restLength     = restLength,
					stiffness      = 1000.0,
					damping        = 10.0,
					maxStretch     = restLength * 1.1,
					maxCompression = restLength * 0.9,
					t              = .Structural,
				}

				springIndex += 1
			}
		}
	}

	for row in 0 ..< rows - 1 {
		for col in 0 ..< columns - 1 {
			index := row * columns + col

			restLength1 := rl.Vector3Distance(
				cloth.particles[index].position,
				cloth.particles[index + columns + 1].position,
			)

			cloth.springs[springIndex] = Spring {
				particleA      = i32(index),
				particleB      = i32(index + columns + 1),
				restLength     = restLength1,
				stiffness      = 800.0,
				damping        = 8.0,
				maxStretch     = restLength1 * 1.15,
				maxCompression = restLength1 * 0.85,
				t              = .Stretch,
			}
			springIndex += 1

			restLength2 := rl.Vector3Distance(
				cloth.particles[index + 1].position,
				cloth.particles[index + columns].position,
			)

			cloth.springs[springIndex] = Spring {
				particleA      = i32(index + 1),
				particleB      = i32(index + columns),
				restLength     = restLength2,
				stiffness      = 800.0,
				damping        = 8.0,
				maxStretch     = restLength2 * 1.15,
				maxCompression = restLength2 * 0.85,
				t              = .Stretch,
			}
			springIndex += 1
		}
	}

	for row in 0 ..< rows {
		for col in 0 ..< columns {
			index := row * columns + col

			if col < columns - 2 {
				restLength := rl.Vector3Distance(
					cloth.particles[index].position,
					cloth.particles[index + 2].position,
				)

				cloth.springs[springIndex] = Spring {
					particleA      = i32(index),
					particleB      = i32(index + 2),
					restLength     = restLength,
					stiffness      = 300.0, 
					damping        = 5.0,
					maxStretch     = restLength * 1.2,
					maxCompression = restLength * 0.8,
					t              = .Bend,
				}
				springIndex += 1
			}

			if row < rows - 2 {
				restLength := rl.Vector3Distance(
					cloth.particles[index].position,
					cloth.particles[index + columns * 2].position,
				)

				cloth.springs[springIndex] = Spring {
					particleA      = i32(index),
					particleB      = i32(index + columns * 2),
					restLength     = restLength,
					stiffness      = 300.0, 
					damping        = 5.0,
					maxStretch     = restLength * 1.2,
					maxCompression = restLength * 0.8,
					t              = .Bend,
				}
				springIndex += 1
			}
		}
	}
}

// BEND ELEMENTS
CalculateDihedralAngle :: proc(p1, p2, p3, p4: rl.Vector3) -> f32 {
    v21 := p2 - p1
    v31 := p3 - p1
    v41 := p4 - p1
    
		n1 := rl.Vector3CrossProduct(v21, v31)
    n1 = rl.Vector3Normalize(n1)
    
    n2 := rl.Vector3CrossProduct(v41, v21)
    n2 = rl.Vector3Normalize(n2)
    
    cosAngle := rl.Vector3DotProduct(n1, n2)
    
    if cosAngle > 1.0 do cosAngle = 1.0
    if cosAngle < -1.0 do cosAngle = -1.0
    
    angle := math.acos(cosAngle)
    
    e := rl.Vector3Normalize(v21)
    if rl.Vector3DotProduct(rl.Vector3CrossProduct(n1, n2), e) < 0 {
        angle = -angle
    }
    
    return angle
}

FixFirstRow :: proc(cloth: ^Cloth, columns: i32) {
    for col in 0..<columns {
        cloth.particles[col].fixed = true
    }
}

CreateBendElements :: proc(cloth: ^Cloth, rows: i32, columns: i32) {

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
				force       = rl.Vector3{0, 0, 0},
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
