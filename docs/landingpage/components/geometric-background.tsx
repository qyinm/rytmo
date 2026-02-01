'use client'

import { motion, useScroll, useTransform, useSpring, useMotionValue } from 'framer-motion';
import { useEffect, useRef } from 'react';

export function GeometricBackground() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start start", "end end"]
  });

  const y1 = useTransform(scrollYProgress, [0, 1], [0, 300]);
  const y2 = useTransform(scrollYProgress, [0, 1], [0, -300]);
  const rotate1 = useTransform(scrollYProgress, [0, 1], [0, 45]);

  // Mouse parallax interactive effect
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);
  
  // Window dimensions as MotionValues to prevent hydration mismatch
  const windowW = useMotionValue(0);
  const windowH = useMotionValue(0);

  useEffect(() => {
    // Initial size update ensuring it runs on client only
    const updateSize = () => {
      windowW.set(window.innerWidth);
      windowH.set(window.innerHeight);
    };

    const handleMouseMove = (e: MouseEvent) => {
      mouseX.set(e.clientX);
      mouseY.set(e.clientY);
    };

    updateSize();
    window.addEventListener("resize", updateSize);
    window.addEventListener("mousemove", handleMouseMove);
    
    return () => {
      window.removeEventListener("resize", updateSize);
      window.removeEventListener("mousemove", handleMouseMove);
    };
  }, [mouseX, mouseY, windowW, windowH]);

  const springConfig = { damping: 25, stiffness: 100 };
  
  // Use array version of useTransform to depend on both mouse and window size
  // This ensures that on the server (where w=0), the result is 0, matching the initial client render (where w=0 until useEffect)
  const moveX1 = useSpring(useTransform([mouseX, windowW], ([x, w]) => {
    if (w === 0) return 0;
    return (x - w / 2) * -0.05;
  }), springConfig);

  const moveY1 = useSpring(useTransform([mouseY, windowH], ([y, h]) => {
    if (h === 0) return 0;
    return (y - h / 2) * -0.05;
  }), springConfig);

  const moveX2 = useSpring(useTransform([mouseX, windowW], ([x, w]) => {
    if (w === 0) return 0;
    return (x - w / 2) * 0.08;
  }), springConfig);

  const moveY2 = useSpring(useTransform([mouseY, windowH], ([y, h]) => {
    if (h === 0) return 0;
    return (y - h / 2) * 0.08;
  }), springConfig);

  return (
    <div ref={ref} className="absolute inset-0 overflow-hidden pointer-events-none z-0">
      {/* Noise Texture Overlay */}
      <div className="absolute inset-0 opacity-[0.03] z-[50] pointer-events-none mix-blend-overlay"
           style={{ backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")` }}
      />

      {/* Large Blurred Circle - Top Right */}
      <motion.div 
        style={{ y: y2, x: moveX1, rotate: rotate1 }}
        className="absolute -top-[10%] -right-[10%] w-[600px] h-[600px] rounded-full bg-gradient-to-br from-gray-100 to-transparent blur-3xl opacity-60"
      />
      
      {/* Black Outlined Circle (Geometric) */}
      <motion.div
        style={{ x: moveX2, y: moveY2 }} 
        className="absolute top-[15%] right-[15%] w-[300px] h-[300px] border border-black/5 rounded-full"
      />

      {/* Rotating Square - Middle Left */}
      <motion.div 
        style={{ y: y1, x: moveY1, rotate: rotate1 }}
        className="absolute top-[40%] -left-[5%] w-[400px] h-[400px] border border-black/5 rotate-45"
      />

      {/* Solid Black Small Circle - Interactive */}
      <motion.div
        style={{ x: moveX2, y: moveY2 }} 
        className="absolute top-[30%] left-[20%] w-12 h-12 bg-black rounded-full opacity-5 blur-[1px]"
      />

       {/* Grid Pattern */}
       <div className="absolute inset-0" style={{ 
          backgroundImage: 'linear-gradient(rgba(0,0,0,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.03) 1px, transparent 1px)',
          backgroundSize: '100px 100px',
          maskImage: 'linear-gradient(to bottom, transparent, black, transparent)'
       }}></div>

    </div>
  );
}
