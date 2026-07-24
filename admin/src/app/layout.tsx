import React from 'react';

export const metadata = {
  title: 'Kaza Backoffice Admin',
  description: 'Consola de Moderación, Casos y Gobierno de Datos',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body style={{ margin: 0, padding: 0, backgroundColor: '#0B0F17' }}>
        {children}
      </body>
    </html>
  );
}
