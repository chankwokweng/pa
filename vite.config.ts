import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import fs from 'fs';
import path from 'path';
import {defineConfig} from 'vite';

export default defineConfig(() => {
  const certPath = path.resolve(__dirname, '.cert');
  const httpsConfig = fs.existsSync(`${certPath}/key.pem`)
    ? { key: fs.readFileSync(`${certPath}/key.pem`), cert: fs.readFileSync(`${certPath}/cert.pem`) }
    : undefined;

  return {
    base: '/pa/',
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      https: httpsConfig,
      headers: {
        'Cross-Origin-Opener-Policy': 'unsafe-none',
      },
      hmr: process.env.DISABLE_HMR !== 'true',
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
  };
});
