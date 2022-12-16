defmodule Readmark.Cldr do
  use Cldr,
    locales: ["en"],
    default_locale: "en",
    otp_app: :readmark,
    gettext: ReadmarkWeb.Gettext,
    json_library: Jason,
    data_dir: "./priv/cldr",
    generate_docs: true,
    force_locale_download: Mix.env() == :prod,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
