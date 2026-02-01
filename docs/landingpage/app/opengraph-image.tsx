import { ImageResponse } from 'next/og'

// Route segment config
export const runtime = 'edge'

// Image metadata
export const alt = 'Rytmo - Focus with Rhythm'
export const size = {
  width: 1200,
  height: 630,
}

export const contentType = 'image/png'

// Image generation
export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          fontSize: 60,
          background: 'linear-gradient(135deg, #FAFAFA 0%, #F5F5F5 50%, #E5E5E5 100%)',
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '60px',
          fontFamily: 'sans-serif',
        }}
      >
        {/* Logo/Icon Circle */}
        <div
          style={{
            width: 120,
            height: 120,
            background: '#000000',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 40,
          }}
        >
          <svg
            width="60"
            height="60"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              stroke="#FFFFFF"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>

        {/* Main Title */}
        <div
          style={{
            fontSize: 72,
            fontWeight: 'bold',
            color: '#000000',
            marginBottom: 20,
            textAlign: 'center',
          }}
        >
          Rytmo
        </div>

        {/* Subtitle */}
        <div
          style={{
            fontSize: 40,
            color: '#666666',
            marginBottom: 30,
            textAlign: 'center',
          }}
        >
          Focus with Rhythm
        </div>

        {/* Description */}
        <div
          style={{
            fontSize: 28,
            color: '#888888',
            textAlign: 'center',
            maxWidth: '900px',
            lineHeight: 1.4,
          }}
        >
          A minimalist Pomodoro timer with seamless YouTube playlist integration for macOS
        </div>

        {/* Badge */}
        <div
          style={{
            marginTop: 40,
            background: '#000000',
            color: '#FFFFFF',
            padding: '12px 32px',
            borderRadius: '999px',
            fontSize: 24,
            fontWeight: '600',
          }}
        >
          ✨ Live on macOS
        </div>
      </div>
    ),
    {
      ...size,
    }
  )
}
