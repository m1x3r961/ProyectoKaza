/** @type {import('next').NextConfig} */
const nextConfig = {
  // ── Cache headers: HTML no se cachea, assets JS/CSS sí (tienen hash en nombre) ──
  async headers() {
    return [
      {
        // El HTML raíz debe verificarse en cada navegación
        source: '/',
        headers: [
          { key: 'Cache-Control', value: 'no-cache, no-store, must-revalidate' },
          { key: 'Pragma', value: 'no-cache' },
        ],
      },
      {
        // version.json tampoco se cachea (es el archivo que se pollea)
        source: '/version.json',
        headers: [
          { key: 'Cache-Control', value: 'no-cache, no-store, must-revalidate' },
        ],
      },
      {
        // Los chunks JS/CSS de Next.js ya tienen content-hash en el nombre,
        // cachearlos agresivamente está bien
        source: '/_next/static/:path*',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
