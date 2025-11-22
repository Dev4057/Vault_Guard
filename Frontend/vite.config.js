import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/Vault_Guard/',  // Important: Must match your repo name
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false
  }
})
EOF