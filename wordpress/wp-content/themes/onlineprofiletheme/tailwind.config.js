/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./assets/js/**/*.js", "./**/*.{php,html}", "!./node_modules/**"],
  theme: {
    extend: {
      fontFamily: {
        garamond: ["Cormorant Garamond", "Noto Serif JP", "serif"],
        noto: ["Noto Serif JP", "serif"],
        notosans: ["Noto Sans JP", "sans-serif"],
        philosopher: ["Philosopher", "sans-serif"],
        parisienne: ["Parisienne", "serif"],
        dynalight: ["Dynalight", "serif"],
        tangerine: ["Tangerine", "serif"],
        ballet: ["Ballet", "serif"],
        cinzel: ["Cinzel", "serif"],
        playfair: ["Playfair Display", "serif"],
        libre: ["Libre Baskerville", "serif"],
        lora: ["Lora", "serif"],
        italianno: ["Italianno", "serif"],
        pinyon: ["Pinyon Script", "serif"],
      },
      colors: {
        main2: "#d7d2de",
        // 'accent': '#c5c4e0',
        // 'accent': '#c25f89',
        accent: "#dac7de",
        // 'accent': '#69113c',
        main1: "#ebb4b2",
        base: "#ffffff",
        "little-gr": "#f8f8f8",
        // 'base': '#ffe9dc',
        deco1: "#886b5e",
        deco2: "#d6af9e",
      },
    },
  },
  plugins: [],
};
