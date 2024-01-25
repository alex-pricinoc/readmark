const colors = require("tailwindcss/colors");
const defaultTheme = require("tailwindcss/defaultTheme");
const plugin = require("tailwindcss/plugin");

const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    screens: {
      "sm": "640px",
      "md": "712px",
      "lg": "1024px",
      "xl": "1280px",
      "2xl": "1536px",
    },
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        primary: colors.indigo,
        secondary: colors.yellow,
      },
      backgroundImage: {
        "graph-paper": "url('/images/graph-paper.svg')",
      },
      height: {
        "screen": "100dvh",
      },
      minHeight: {
        "screen": "100dvh",
      },
      transitionTimingFunction: {
        // custom easing variables: https://gist.github.com/bendc/ac03faac0bf2aee25b49e5fd260a727d
        "in-quad": "cubic-bezier(.55, .085, .68, .53)",
        "in-cubic": "cubic-bezier(.550, .055, .675, .19)",
        "in-quart": "cubic-bezier(.895, .03, .685, .22)",
        "in-quint": "cubic-bezier(.755, .05, .855, .06)",
        "in-expo": "cubic-bezier(.95, .05, .795, .035)",
        "in-circ": "cubic-bezier(.6, .04, .98, .335)",

        "out-quad": "cubic-bezier(.25, .46, .45, .94)",
        "out-cubic": "cubic-bezier(.215, .61, .355, 1)",
        "out-quart": "cubic-bezier(.165, .84, .44, 1)",
        "out-quint": "cubic-bezier(.23, 1, .32, 1)",
        "out-expo": "cubic-bezier(.19, 1, .22, 1)",
        "out-circ": "cubic-bezier(.075, .82, .165, 1)",

        "in-out-quad": "cubic-bezier(.455, .03, .515, .955)",
        "in-out-cubic": "cubic-bezier(.645, .045, .355, 1)",
        "in-out-quart": "cubic-bezier(.77, 0, .175, 1)",
        "in-out-quint": "cubic-bezier(.86, 0, .07, 1)",
        "in-out-expo": "cubic-bezier(1, 0, 0, 1)",
        "in-out-circ": "cubic-bezier(.785, .135, .15, .86)",
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    require("@tailwindcss/line-clamp"),
    require("@tailwindcss/aspect-ratio"),
    plugin(({ addVariant }) => addVariant("phx-no-feedback", ["&.phx-no-feedback", ".phx-no-feedback &"])),
    plugin(({ addVariant }) => addVariant("phx-click-loading", ["&.phx-click-loading", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", ["&.phx-submit-loading", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", ["&.phx-change-loading", ".phx-change-loading &"])),
    plugin(({ addVariant }) => addVariant("open", ["&.open", ".open &"])),

    // Embeds Hero Icons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map(file => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "");
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": theme("spacing.5"),
            "height": theme("spacing.5"),
          };
        },
      }, { values });
    }),
  ],
  future: {
    hoverOnlyWhenSupported: true,
  },
};
