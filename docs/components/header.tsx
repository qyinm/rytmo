'use client'

import React, { useState, useEffect, useRef, useTransition } from 'react'
import { RytmoIcon } from '@/components/rytmo-icon'
import { Button } from '@/components/ui/button'
import {useTranslations, useLocale} from 'next-intl';
import {Link, usePathname, useRouter} from '@/i18n/routing';
import { Globe } from "lucide-react" 
import { FaApple } from "react-icons/fa"; 

export function Header() {
  const t = useTranslations('Header');
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();
  const [isPending, startTransition] = useTransition();

  const [isScrolled, setIsScrolled] = useState(false)
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const headerRef = useRef<HTMLElement | null>(null)
  const [mobileMenuTop, setMobileMenuTop] = useState<number>(0)
  const [mobileMenuWidth, setMobileMenuWidth] = useState<number>(0)

  const toggleLanguage = () => {
    const nextLocale = locale === 'en' ? 'ko' : 'en';
    startTransition(() => {
      router.replace(pathname, {locale: nextLocale});
    });
  }

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50)
    }

    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  // Sync mobile menu position/width
  useEffect(() => {
    const updateMenuMetrics = () => {
      const el = headerRef.current
      if (!el) return
      const rect = el.getBoundingClientRect()
      setMobileMenuTop(rect.bottom + 8)
      setMobileMenuWidth(rect.width)
    }
    updateMenuMetrics()
    window.addEventListener('resize', updateMenuMetrics)
    window.addEventListener('scroll', updateMenuMetrics, { passive: true })
    return () => {
      window.removeEventListener('resize', updateMenuMetrics)
      window.removeEventListener('scroll', updateMenuMetrics)
    }
  }, [])

  // Lock body scroll when mobile menu is open
  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = 'unset'
    }
    return () => {
      document.body.style.overflow = 'unset'
    }
  }, [isMobileMenuOpen])

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen)
  }

  return (
    <>
      <header
        ref={headerRef}
        className={`fixed top-2 md:top-6 left-1/2 -translate-x-1/2 z-50 w-[calc(100%-16px)] md:w-[min(68vw,820px)] max-w-[520px] md:max-w-[820px] transition-all duration-300 ${
          isScrolled ? 'py-1.5 md:py-2' : 'py-2.5 md:py-3'
        }`}
        style={{
          background: isScrolled
            ? 'linear-gradient(to bottom, rgba(255, 255, 255, 0.3), rgba(255, 255, 255, 0.2))'
            : 'linear-gradient(to bottom, rgba(255, 255, 255, 0.25), rgba(255, 255, 255, 0.15))',
          backdropFilter: isScrolled ? 'saturate(200%) blur(40px)' : 'saturate(200%) blur(35px)',
          WebkitBackdropFilter: isScrolled ? 'saturate(200%) blur(40px)' : 'saturate(200%) blur(35px)',
          border: isScrolled ? '1px solid rgba(0, 0, 0, 0.1)' : '1px solid rgba(0, 0, 0, 0.08)',
          borderRadius: '9999px',
          boxShadow: isScrolled
            ? 'inset 0 1px 1px rgba(255, 255, 255, 0.3), inset 0 -1px 1px rgba(0, 0, 0, 0.05), 0 12px 32px rgba(0, 0, 0, 0.1), 0 2px 8px rgba(0, 0, 0, 0.06)'
            : 'inset 0 1px 1px rgba(255, 255, 255, 0.25), inset 0 -1px 1px rgba(0, 0, 0, 0.03), 0 6px 16px rgba(0, 0, 0, 0.06), 0 2px 4px rgba(0, 0, 0, 0.04)',
        }}
      >
        <div className="max-w-[1100px] mx-auto px-5 md:px-9 flex justify-between items-center">
          {/* Logo */}
          <a href="/" className="flex items-center gap-1.5 md:gap-2 group">
            <div className="w-7 h-7 md:w-8 md:h-8 bg-[#000000] rounded-full flex items-center justify-center transition-transform group-hover:scale-110">
              <RytmoIcon className="w-3.5 h-3.5 md:w-4 md:h-4 text-[#FFFFFF]" />
            </div>
            <span
              className={`font-serif font-bold text-[#000000] transition-all ${
                isScrolled ? 'text-lg md:text-xl' : 'text-xl md:text-2xl'
              }`}
              style={{ letterSpacing: '-0.02em' }}
            >
              Rytmo
            </span>
          </a>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-8">

            <Link
              href="/changelog"
              className="text-[#666666] hover:text-[#000000] font-sans font-medium text-sm transition-colors relative group"
            >
              {t('changelog')}
              <span className="absolute bottom-[-4px] left-0 w-0 h-0.5 bg-gradient-to-r from-[#000000] to-[#333333] transition-all group-hover:w-full"></span>
            </Link>
            <button
              onClick={toggleLanguage}
              className="text-[#666666] hover:text-[#000000] font-sans font-medium text-sm transition-colors flex items-center gap-2 group"
            >
               <Globe className="w-4 h-4" />
               {locale === 'en' ? 'KR' : 'EN'}
            </button>
          </nav>

          {/* Desktop CTA */}
          <div className="hidden md:block">
            <Button
              size="sm"
              className={`rounded-full font-semibold transition-all duration-300 ${
                isScrolled ? 'text-xs px-4 py-2' : 'text-sm px-5 py-2'
              }`}
              style={{
                background: 'linear-gradient(to bottom, rgba(0, 0, 0, 0.75), rgba(0, 0, 0, 0.85))',
                backdropFilter: 'saturate(200%) blur(40px)',
                WebkitBackdropFilter: 'saturate(200%) blur(40px)',
                border: '1px solid rgba(255, 255, 255, 0.18)',
                boxShadow: 'inset 0 1px 1px rgba(255, 255, 255, 0.25), inset 0 -1px 1px rgba(0, 0, 0, 0.1), 0 8px 24px rgba(0, 0, 0, 0.12), 0 2px 6px rgba(0, 0, 0, 0.08)',
                color: '#FFFFFF',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'scale(1.03) translateY(-1px)'
                e.currentTarget.style.background = 'linear-gradient(to bottom, rgba(0, 0, 0, 0.8), rgba(0, 0, 0, 0.9))'
                e.currentTarget.style.boxShadow = 'inset 0 1px 1px rgba(255, 255, 255, 0.3), inset 0 -1px 1px rgba(0, 0, 0, 0.15), 0 12px 32px rgba(0, 0, 0, 0.16), 0 4px 10px rgba(0, 0, 0, 0.12)'
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'scale(1) translateY(0)'
                e.currentTarget.style.background = 'linear-gradient(to bottom, rgba(0, 0, 0, 0.75), rgba(0, 0, 0, 0.85))'
                e.currentTarget.style.boxShadow = 'inset 0 1px 1px rgba(255, 255, 255, 0.25), inset 0 -1px 1px rgba(0, 0, 0, 0.1), 0 8px 24px rgba(0, 0, 0, 0.12), 0 2px 6px rgba(0, 0, 0, 0.08)'
              }}
              asChild
            >
              <a href="https://qyinm.github.io/rytmo-update/Rytmo.dmg" className="flex items-center gap-2">
                <FaApple className="w-4 h-4 mb-0.5" />
                {t('download_macos')}
              </a>
            </Button>
          </div>

          {/* Mobile Hamburger */}
          <button
            className="md:hidden w-10 h-10 flex flex-col justify-center items-center gap-1 hover:bg-black/5 active:bg-black/10 rounded-lg transition-colors"
            onClick={toggleMobileMenu}
            aria-label="Toggle menu"
          >
            <span
              className={`w-5 h-0.5 bg-[#000000] rounded-full transition-all ${
                isMobileMenuOpen ? 'rotate-45 translate-y-1.5' : ''
              }`}
            ></span>
            <span
              className={`w-5 h-0.5 bg-[#000000] rounded-full transition-all ${
                isMobileMenuOpen ? 'opacity-0' : ''
              }`}
            ></span>
            <span
              className={`w-5 h-0.5 bg-[#000000] rounded-full transition-all ${
                isMobileMenuOpen ? '-rotate-45 -translate-y-1.5' : ''
              }`}
            ></span>
          </button>
        </div>
      </header>

      {/* Mobile Menu */}
      <div
        className={`md:hidden fixed z-40 left-1/2 -translate-x-1/2 w-[calc(100%-32px)] max-w-[520px] rounded-3xl overflow-hidden transition-all duration-300 ${
          isMobileMenuOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
        }`}
        style={{
          top: mobileMenuTop,
          width: mobileMenuWidth ? `${mobileMenuWidth}px` : undefined,
          background: 'linear-gradient(to bottom, rgba(255, 255, 255, 0.35), rgba(255, 255, 255, 0.25))',
          backdropFilter: 'saturate(200%) blur(40px)',
          WebkitBackdropFilter: 'saturate(200%) blur(40px)',
          border: '1px solid rgba(0, 0, 0, 0.1)',
          boxShadow: 'inset 0 1px 1px rgba(255, 255, 255, 0.3), inset 0 -1px 1px rgba(0, 0, 0, 0.05), 0 12px 40px rgba(0, 0, 0, 0.14), 0 4px 12px rgba(0, 0, 0, 0.1)',
        }}
      >
        <nav className="p-4">
          <div className="space-y-1 mb-6 pb-6 border-b border-black/10">

            <Link
              href="/changelog"
              className="block px-2 py-3 text-[#000000] hover:text-[#666666] hover:bg-black/5 rounded-lg font-sans font-medium transition-all"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              {t('changelog')}
            </Link>
            <button
              className="w-full text-left px-2 py-3 text-[#000000] hover:text-[#666666] hover:bg-black/5 rounded-lg font-sans font-medium transition-all flex items-center gap-2"
              onClick={() => {
                toggleLanguage();
                setIsMobileMenuOpen(false);
              }}
            >
               <Globe className="w-4 h-4" />
               {locale === 'en' ? '한국어' : 'English'}
            </button>
          </div>

          <Button
            className="w-full rounded-xl font-semibold h-12 transition-all duration-300"
            style={{
              background: 'linear-gradient(to bottom, rgba(0, 0, 0, 0.75), rgba(0, 0, 0, 0.85))',
              backdropFilter: 'saturate(200%) blur(40px)',
              WebkitBackdropFilter: 'saturate(200%) blur(40px)',
              border: '1px solid rgba(255, 255, 255, 0.18)',
              boxShadow: 'inset 0 1px 1px rgba(255, 255, 255, 0.25), inset 0 -1px 1px rgba(0, 0, 0, 0.1), 0 10px 32px rgba(0, 0, 0, 0.14), 0 2px 8px rgba(0, 0, 0, 0.1)',
              color: '#FFFFFF',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'scale(1.02) translateY(-1px)'
              e.currentTarget.style.background = 'linear-gradient(to bottom, rgba(0, 0, 0, 0.8), rgba(0, 0, 0, 0.9))'
              e.currentTarget.style.boxShadow = 'inset 0 1px 1px rgba(255, 255, 255, 0.3), inset 0 -1px 1px rgba(0, 0, 0, 0.15), 0 14px 40px rgba(0, 0, 0, 0.18), 0 4px 12px rgba(0, 0, 0, 0.12)'
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'scale(1) translateY(0)'
              e.currentTarget.style.background = 'linear-gradient(to bottom, rgba(0, 0, 0, 0.75), rgba(0, 0, 0, 0.85))'
              e.currentTarget.style.boxShadow = 'inset 0 1px 1px rgba(255, 255, 255, 0.25), inset 0 -1px 1px rgba(0, 0, 0, 0.1), 0 10px 32px rgba(0, 0, 0, 0.14), 0 2px 8px rgba(0, 0, 0, 0.1)'
            }}
            asChild
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <a href="https://qyinm.github.io/rytmo-update/Rytmo.dmg" className="flex items-center justify-center gap-2">
              <FaApple className="w-5 h-5 mb-0.5" />
              {t('download_macos')}
            </a>
          </Button>
        </nav>
      </div>
    </>
  )
}
