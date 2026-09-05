//https://vitejs.dev/config
import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';

const pkg = JSON.parse(fs.readFileSync(new URL('./package.json', import.meta.url), 'utf8'));
export const installerStartup = `if (process.platform === 'win32') require('velopack').VelopackApp.build().run();`;

export default defineConfig({
    build: {
        rollupOptions: {
            external: ['electron', ...Object.keys(pkg.dependencies)],
            // Run before even importing app helpers: installer hooks must not open UI,
            // register IPC, acquire the app lock, or touch user settings.
            output: { banner: installerStartup },
        },
    },
    resolve: {
        alias: {
            '@': fileURLToPath(new URL('./src', import.meta.url)),
        },
    },
    
});
