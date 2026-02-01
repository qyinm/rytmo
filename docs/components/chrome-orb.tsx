'use client'

import { Canvas, useFrame } from '@react-three/fiber'
import { Environment, Float, MeshDistortMaterial, Sphere } from '@react-three/drei'
import { useRef, useState, useEffect } from 'react'
import * as THREE from 'three'

function Orb({ mouse }: { mouse: React.MutableRefObject<[number, number]> }) {
  const meshRef = useRef<THREE.Mesh>(null)

  useFrame((state) => {
    if (meshRef.current) {
      // Gentle rotation based on mouse
      const x = mouse.current[0] * 0.5
      const y = mouse.current[1] * 0.5
      
      meshRef.current.rotation.x = THREE.MathUtils.lerp(meshRef.current.rotation.x, y, 0.1)
      meshRef.current.rotation.y = THREE.MathUtils.lerp(meshRef.current.rotation.y, x, 0.1)
    }
  })

  return (
    <Float speed={2} rotationIntensity={1} floatIntensity={1}>
      <Sphere args={[1.5, 64, 64]} ref={meshRef}>
        <MeshDistortMaterial
          color="#000000"
          envMapIntensity={0.5}
          clearcoat={0.5}
          clearcoatRoughness={0.2}
          metalness={0.9}
          roughness={0.2}
          distort={0.4}
          speed={2}
        />
      </Sphere>
    </Float>
  )
}

export function ChromeOrb() {
  const mouse = useRef<[number, number]>([0, 0])
  
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      // Normalize mouse (-1 to 1)
      mouse.current = [
        (e.clientX / window.innerWidth) * 2 - 1,
        (e.clientY / window.innerHeight) * 2 - 1
      ]
    }
    
    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  return (
    <div className="absolute inset-0 z-0 h-[120vh] w-full pointer-events-none fade-in">
      <Canvas camera={{ position: [0, 0, 5], fov: 45 }} className="w-full h-full">
        <ambientLight intensity={1.5} />
        <directionalLight position={[5, 10, 7]} intensity={2} />
        
        <Orb mouse={mouse} />
        
        {/* 'city' preset gives abstract reflections without the specific 'studio umbrella' look */}
        <Environment preset="city" blur={1} /> 
      </Canvas>
    </div>
  )
}
