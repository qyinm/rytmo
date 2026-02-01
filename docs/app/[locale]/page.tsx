'use client'

import { useRef } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { RytmoIcon } from "@/components/rytmo-icon"
import { Header } from "@/components/header"
import { ChromeOrb } from "@/components/chrome-orb"
import { FaApple } from "react-icons/fa";
import { Timer, Music, Zap, CheckCircle, Calendar, Smartphone, Layout, BarChart, Lock, ArrowRight } from "lucide-react"
import { motion, useScroll, useTransform, Variants } from 'framer-motion'

export default function RytmoLanding() {
  const tHero = useTranslations('Hero');
  const tLiveFeatures = useTranslations('LiveFeatures');
  const tRoadmap = useTranslations('Roadmap');
  const tValues = useTranslations('Values');
  const tFAQ = useTranslations('FAQ');
  const tCTA = useTranslations('CTA');
  const tFooter = useTranslations('Footer');

  const downloadUrl = "https://qyinm.github.io/rytmo-update/Rytmo.dmg";
  
  // Structured Data (JSON-LD) for SEO
  const structuredData = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "SoftwareApplication",
        "name": "Rytmo",
        "applicationCategory": "ProductivityApplication",
        "operatingSystem": "macOS 14.6 or later",
        "offers": {
          "@type": "Offer",
          "price": "0",
          "priceCurrency": "USD"
        },
        "description": tHero('subtitle'),
        "featureList": [
          tLiveFeatures('feature1_title'),
          tLiveFeatures('feature2_title'),
          tRoadmap('item1_title'),
          tRoadmap('item2_title'),
          tRoadmap('item3_title'),
          tRoadmap('item4_title')
        ],
        "screenshot": "https://rytmo.app/rytmo-screenshot.svg",
        "softwareVersion": "1.0.3",
        "aggregateRating": {
          "@type": "AggregateRating",
          "ratingValue": "5",
          "ratingCount": "1"
        },
        "author": {
          "@type": "Organization",
          "name": "Rytmo"
        }
      },
      {
        "@type": "WebPage",
        "name": "Rytmo - " + tHero('title_focus') + " " + tHero('title_rhythm'),
        "description": tHero('subtitle'),
        "url": "https://rytmo.app",
        "inLanguage": "en-US",
        "isPartOf": {
          "@type": "WebSite",
          "name": "Rytmo",
          "url": "https://rytmo.app"
        }
      }
    ]
  };

  // Scroll Animations
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"]
  });

  const heroOpacity = useTransform(scrollYProgress, [0, 0.15], [1, 0]);
  const heroScale = useTransform(scrollYProgress, [0, 0.15], [1, 0.95]);
  const heroY = useTransform(scrollYProgress, [0, 0.15], [0, 50]);

  // Animation Variants
  const fadeInUp: Variants = {
    hidden: { opacity: 0, y: 40 },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: { duration: 0.8, ease: [0.22, 1, 0.36, 1] }
    }
  };

  const staggerContainer: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.1
      }
    }
  };

  const scaleIn: Variants = {
    hidden: { opacity: 0, scale: 0.9, y: 20 },
    visible: { 
      opacity: 1, 
      scale: 1,
      y: 0,
      transition: { duration: 0.6, ease: [0.22, 1, 0.36, 1] }
    }
  };

  return (
    <div ref={containerRef} className="min-h-screen bg-[#FFFFFF] text-[#111111] relative overflow-hidden font-sans selection:bg-black selection:text-white">
      {/* Background Shapes */}
      <ChromeOrb />

      {/* Structured Data for SEO */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
      />
      <Header />
      
      {/* Hero Section */}
      <motion.section 
        className="relative pt-32 pb-20 md:pt-48 md:pb-32 px-6 overflow-hidden min-h-[90vh] flex flex-col justify-center z-10"
        style={{ opacity: heroOpacity, scale: heroScale, y: heroY }}
      >
        <div className="max-w-5xl mx-auto text-center z-10 relative mix-blend-difference text-white">
          
          <motion.div
             initial={{ opacity: 0, scale: 0.9 }}
             animate={{ opacity: 1, scale: 1 }}
             transition={{ duration: 0.6, ease: "easeOut" }}
          >
            <Badge variant="outline" className="mb-8 border-current px-4 py-1.5 text-sm backdrop-blur-md bg-white/10">
              {tHero('badge')}
            </Badge>
          </motion.div>

          {/* Main Heading */}
          <motion.h1 
            className="font-serif text-6xl md:text-8xl lg:text-9xl tracking-tighter mb-8 leading-[0.9] break-keep"
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1, ease: [0.16, 1, 0.3, 1], delay: 0.1 }}
          >
            {tHero('title_focus')} <br /> <span className="opacity-40">{tHero('title_rhythm')}</span>
          </motion.h1>

          {/* Subheading */}
          <motion.p 
            className="font-sans text-xl md:text-2xl opacity-70 max-w-2xl mx-auto mb-12 leading-relaxed text-balance break-keep"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: "easeOut", delay: 0.3 }}
          >
            {tHero('subtitle')}
          </motion.p>

          <motion.div 
            className="flex flex-col items-center gap-6"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: "easeOut", delay: 0.4 }}
          >
            <Button
              size="lg"
              className="group h-16 px-10 rounded-full bg-white text-black hover:bg-gray-200 font-medium text-lg transition-all duration-300 shadow-[0_10px_40px_-10px_rgba(255,255,255,0.3)] hover:shadow-[0_20px_40px_-10px_rgba(255,255,255,0.4)] hover:-translate-y-1"
              asChild
            >
              <a href={downloadUrl} className="flex items-center gap-2">
                <FaApple className="w-6 h-6 mb-1" />
                {tHero('download')}
                <ArrowRight className="w-5 h-5 opacity-0 -ml-4 group-hover:opacity-100 group-hover:ml-0 transition-all duration-300" />
              </a>
            </Button>
            <p className="text-sm opacity-50 font-medium">
              v1.0.3 • macOS 14.6+ • Apple Silicon
            </p>
          </motion.div>
        </div>
      </motion.section>

      {/* Live Features Section */}
      <section id="features" className="py-32 px-6 relative z-10">
        <div className="max-w-7xl mx-auto">
          <motion.div 
            className="mb-24 pl-4 border-l-2 border-black"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={fadeInUp}
          >
            <h2 className="font-serif text-4xl md:text-6xl font-medium mb-6 tracking-tight">{tLiveFeatures('title')}</h2>
            <p className="text-black/60 max-w-xl text-xl">{tLiveFeatures('subtitle')}</p>
          </motion.div>

          <motion.div 
            className="grid md:grid-cols-2 gap-8 md:gap-12"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
          >
            {/* Feature 1 */}
            <motion.div 
              className="group bg-white/50 backdrop-blur-md p-10 rounded-3xl border border-black/5 hover:border-black/10 transition-colors"
              variants={scaleIn}
            >
               <div className="w-16 h-16 bg-black rounded-2xl flex items-center justify-center mb-8 shadow-xl rotate-3 group-hover:rotate-6 transition-transform duration-500">
                  <Music className="w-8 h-8 text-white" />
               </div>
               <h3 className="font-serif text-3xl font-medium text-black mb-4">
                 {tLiveFeatures('feature1_title')}
               </h3>
               <p className="font-sans text-black/60 leading-relaxed text-lg">
                 {tLiveFeatures('feature1_desc')}
               </p>
            </motion.div>

            {/* Feature 2 */}
            <motion.div 
              className="group bg-white/50 backdrop-blur-md p-10 rounded-3xl border border-black/5 hover:border-black/10 transition-colors"
              variants={scaleIn}
            >
               <div className="w-16 h-16 bg-white border-2 border-black rounded-2xl flex items-center justify-center mb-8 shadow-xl -rotate-3 group-hover:-rotate-6 transition-transform duration-500">
                  <Timer className="w-8 h-8 text-black" />
               </div>
               <h3 className="font-serif text-3xl font-medium text-black mb-4">
                 {tLiveFeatures('feature2_title')}
               </h3>
               <p className="font-sans text-black/60 leading-relaxed text-lg">
                 {tLiveFeatures('feature2_desc')}
               </p>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Roadmap Section */}
      <section id="roadmap" className="py-32 px-6 bg-black text-white relative z-10 rounded-t-[3rem] -mt-10 shadow-2xl">
        <div className="max-w-7xl mx-auto">
          <motion.div 
            className="text-left mb-20"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={fadeInUp}
          >
            <Badge variant="outline" className="mb-6 border-white/20 text-white/80">Coming Soon</Badge>
            <h2 className="font-serif text-4xl md:text-6xl font-medium mb-6">{tRoadmap('title')}</h2>
            <p className="text-white/60 max-w-2xl text-xl">{tRoadmap('subtitle')}</p>
          </motion.div>

          {/* Grid with explicit lines */}
          <motion.div 
            className="grid md:grid-cols-2 border-t border-l border-white/10"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
          >
             <motion.div className="p-10 md:p-14 border-b border-r border-white/10 hover:bg-white/5 transition-colors" variants={fadeInUp}>
                <h4 className="font-medium text-2xl mb-4 flex items-center gap-3">
                  <Zap className="w-6 h-6 text-white" /> {tRoadmap('item1_title')}
                </h4>
                <p className="text-white/50 leading-relaxed">{tRoadmap('item1_desc')}</p>
             </motion.div>
             <motion.div className="p-10 md:p-14 border-b border-r border-white/10 hover:bg-white/5 transition-colors" variants={fadeInUp}>
                <h4 className="font-medium text-2xl mb-4 flex items-center gap-3">
                  <CheckCircle className="w-6 h-6 text-white" /> {tRoadmap('item2_title')}
                </h4>
                <p className="text-white/50 leading-relaxed">{tRoadmap('item2_desc')}</p>
             </motion.div>
             <motion.div className="p-10 md:p-14 border-b border-r border-white/10 hover:bg-white/5 transition-colors" variants={fadeInUp}>
                <h4 className="font-medium text-2xl mb-4 flex items-center gap-3">
                  <Calendar className="w-6 h-6 text-white" /> {tRoadmap('item3_title')}
                </h4>
                <p className="text-white/50 leading-relaxed">{tRoadmap('item3_desc')}</p>
             </motion.div>
             <motion.div className="p-10 md:p-14 border-b border-r border-white/10 hover:bg-white/5 transition-colors" variants={fadeInUp}>
                <h4 className="font-medium text-2xl mb-4 flex items-center gap-3">
                  <Smartphone className="w-6 h-6 text-white" /> {tRoadmap('item4_title')}
                </h4>
                <p className="text-white/50 leading-relaxed">{tRoadmap('item4_desc')}</p>
             </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Values Section */}
      <section id="values" className="py-32 px-6 bg-[#FaFaFa]">
        <div className="max-w-7xl mx-auto">
          <motion.div 
            className="text-center mb-20"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={fadeInUp}
          >
            <h2 className="font-serif text-3xl md:text-5xl font-medium mb-6">{tValues('title')}</h2>
            <p className="text-black/60 max-w-2xl mx-auto text-lg">{tValues('subtitle')}</p>
          </motion.div>

          <motion.div 
            className="grid md:grid-cols-3 gap-8"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={staggerContainer}
          >
            {[
              { icon: Layout, title: tValues('val1_title'), desc: tValues('val1_desc') },
              { icon: BarChart, title: tValues('val2_title'), desc: tValues('val2_desc') },
              { icon: Lock, title: tValues('val3_title'), desc: tValues('val3_desc') }
            ].map((item, idx) => (
              <motion.div key={idx} className="text-center p-8 rounded-2xl bg-white border border-black/5 shadow-sm" variants={fadeInUp}>
                 <div className="w-16 h-16 mx-auto bg-black/5 rounded-full flex items-center justify-center mb-6">
                   <item.icon className="w-8 h-8 text-black" />
                 </div>
                 <h3 className="font-bold text-xl mb-3">{item.title}</h3>
                 <p className="text-black/60 leading-relaxed">{item.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* FAQ Section */}
      <section className="py-32 px-6 bg-white relative z-10">
        <motion.div 
          className="max-w-3xl mx-auto"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          variants={fadeInUp}
        >
          <h2 className="font-serif text-3xl md:text-5xl font-medium text-center mb-6">{tFAQ('title')}</h2>
          <p className="font-sans text-xl text-black/60 text-center mb-16 max-w-2xl mx-auto">
            {tFAQ('subtitle')}
          </p>

          <Accordion type="single" collapsible className="w-full space-y-4">
            {['q1', 'q2', 'q3', 'q4', 'q5'].map((key, idx) => (
              <AccordionItem key={idx} value={`item-${idx}`} className="bg-white border text-black/80 rounded-xl px-6 data-[state=open]:border-black data-[state=open]:shadow-lg transition-all">
                <AccordionTrigger className="font-sans text-lg font-medium hover:no-underline text-left py-6">
                  {tFAQ(key)}
                </AccordionTrigger>
                <AccordionContent className="font-sans text-black/60 leading-relaxed text-base pb-6">
                  {tFAQ(key.replace('q', 'a'))}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </motion.div>
      </section>

      {/* CTA Section */}
      <section id="download" className="py-40 px-6 bg-black text-white rounded-t-[3rem] relative z-10 overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-white/10 to-transparent opacity-50 blur-3xl pointer-events-none"></div>
        <motion.div 
          className="max-w-4xl mx-auto text-center relative z-10"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          variants={fadeInUp}
        >
          <h2 className="font-serif text-5xl md:text-7xl font-medium mb-8 text-balance">{tCTA('title')}</h2>
          <p className="font-sans text-xl md:text-2xl text-white/60 mb-16 max-w-2xl mx-auto text-pretty leading-relaxed">
            {tCTA('subtitle')}
          </p>
          <div className="flex flex-col items-center gap-8">
             <Button
                size="lg"
                className="group h-16 md:h-20 px-12 rounded-full bg-white text-black hover:bg-gray-100 font-medium text-lg md:text-xl transition-all duration-300 shadow-[0_10px_40px_-10px_rgba(255,255,255,0.3)] hover:shadow-[0_20px_40px_-10px_rgba(255,255,255,0.4)] hover:-translate-y-1"
                asChild
             >
                <a href={downloadUrl} className="flex items-center gap-3">
                  <FaApple className="w-5 h-5 md:w-6 md:h-6 mb-1" />
                  {tCTA('download')}
                  <ArrowRight className="w-5 h-5 opacity-0 -ml-4 group-hover:opacity-100 group-hover:ml-0 transition-all duration-300" />
                </a>
             </Button>
             <div className="flex flex-wrap gap-3 justify-center">
                <Badge variant="outline" className="border-white/20 text-white/60 font-sans px-4 py-1.5">
                {tCTA('badge_macos')}
                </Badge>
                <Badge variant="outline" className="border-white/20 text-white/60 font-sans px-4 py-1.5">
                {tCTA('badge_size')}
                </Badge>
                <Badge variant="outline" className="border-white/20 text-white/60 font-sans px-4 py-1.5">
                {tCTA('badge_account')}
                </Badge>
             </div>
          </div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 bg-black text-white/40 border-t border-white/10">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center">
                <RytmoIcon className="w-4 h-4 text-black" />
              </div>
              <span className="font-sans text-xl font-bold text-white">Rytmo</span>
            </div>

            <nav className="flex gap-8">
              <a href="#features" className="text-sm font-medium hover:text-white transition-colors">{tFooter('features')}</a>
              <a href="#roadmap" className="text-sm font-medium hover:text-white transition-colors">{tFooter('roadmap')}</a>
              <a href="#values" className="text-sm font-medium hover:text-white transition-colors">{tFooter('values')}</a>
              <a href="#download" className="text-sm font-medium hover:text-white transition-colors">{tFooter('download')}</a>
            </nav>

            <p className="font-sans text-sm">{tFooter('copyright')}</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
