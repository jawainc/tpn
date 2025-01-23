defmodule TpnWeb.Layouts do
  use TpnWeb, :html

  import TpnWeb.LayoutComponents.Administrator.{DesktopMenu, Header}

  embed_templates "layouts/*"
end
