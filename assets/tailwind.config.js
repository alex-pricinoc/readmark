const colors = require("tailwindcss/colors")
const defaultTheme = require("tailwindcss/defaultTheme")
const plugin = require("tailwindcss/plugin")

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans]
      },
      colors: {
        primary: colors.purple,
        secondary: colors.yellow
      },
      backgroundImage: {
        "graph-paper": "url('/images/graph-paper.svg')"
      }
    }
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    require("@tailwindcss/line-clamp"),
    require("@tailwindcss/aspect-ratio"),
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", ["&.phx-no-feedback", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", ["&.phx-click-loading", ".phx-click-loading &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", ["&.phx-submit-loading", ".phx-submit-loading &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", ["&.phx-change-loading", ".phx-change-loading &"])
    ),
    plugin(({ addVariant }) => addVariant("reveal", ["&.reveal", ".reveal &"]))
  ],
  future: {
    hoverOnlyWhenSupported: true
  }
}
