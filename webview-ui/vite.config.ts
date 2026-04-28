import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import cssInjectedByJsPlugin from "vite-plugin-css-injected-by-js";

export default defineConfig({
  plugins: [
    react(),

    tailwindcss(),

    cssInjectedByJsPlugin()
  ],

  build: {
    outDir: "dist",

    emptyOutDir: true,

    assetsInlineLimit: 100_000_000,

    cssCodeSplit: false,

    rollupOptions: {
      output: {
        entryFileNames: "index.js",

        chunkFileNames: "index.js",

        assetFileNames: "index.[ext]"
      }
    }
  }
});
