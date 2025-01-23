defmodule TpnWeb.LayoutComponents.Administrator.DesktopMenu do
  use Phoenix.Component
  use TpnWeb, :verified_routes

  import TpnWeb.CoreComponents

  def admin_menu(assigns) do
    ~H"""
    <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col bg-neutral">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-700/50 px-6 pb-4">
        <div class="flex gap-x-4 h-16 items-center">
          <.icon name="hero-cube-transparent" class="h-10 w-10 text-indigo-600" />
          <span class="prose text-xl font-bold">XprTpn</span>
        </div>
        
        <nav class="flex flex-1 flex-col">
          <ul role="list" class="flex flex-1 flex-col gap-y-7">
            <li>
              <ul
                role="list"
                class="-mx-2 space-y-1 desktop-menu-group"
                hx-target="#main-contents"
                hx-indicator=".main-contents-loader"
                hx-on:htmx-after-on-load="let currentMenu = document.querySelector('.selected');
                currentMenu.classList.remove('selected')
                let newMenu = event.target
                newMenu.classList.add('selected')"
              >
                <li
                  hx-get={~p"/administrator/dash"}
                  class="group flex gap-x-3 rounded-md p-2 text-sm leading-6 hover:bg-base-300 cursor-pointer selected"
                >
                  <.icon name="hero-home" class="h-6 w-6 shrink-0" /> Dashboard
                </li>
                
                <li
                  hx-get={~p"/administrator/users"}
                  hx-target="#main-contents"
                  hx-indicator=".main-contents-loader"
                  class="group flex gap-x-3 rounded-md p-2 text-sm leading-6 hover:bg-base-300 cursor-pointer"
                >
                  <.icon name="hero-identification" class="h-6 w-6 shrink-0" /> Administrators
                </li>
                
                <li
                  hx-get={~p"/administrator/contexts"}
                  hx-target="#main-contents"
                  hx-indicator=".main-contents-loader"
                  class="group flex gap-x-3 rounded-md p-2 text-sm leading-6 hover:bg-base-300 cursor-pointer"
                >
                  <.icon name="hero-circle-stack" class="h-6 w-6 shrink-0" /> Contexts
                </li>
                
                <li
                  hx-get={~p"/administrator/roles"}
                  hx-target="#main-contents"
                  hx-indicator=".main-contents-loader"
                  class="group flex gap-x-3 rounded-md p-2 text-sm leading-6 hover:bg-base-300 cursor-pointer"
                >
                  <.icon name="hero-briefcase" class="h-6 w-6 shrink-0" /> Roles
                </li>
                
                <li
                  hx-get={~p"/administrator/accounts"}
                  hx-target="#main-contents"
                  hx-indicator=".main-contents-loader"
                  class="group flex gap-x-3 rounded-md p-2 text-sm leading-6 hover:bg-base-300 cursor-pointer"
                >
                  <.icon name="hero-users" class="h-6 w-6 shrink-0" /> Users
                </li>
              </ul>
            </li>
            
            <li class="mt-auto">
              <a
                href="#"
                class="group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold hover:bg-base-300"
              >
                <.icon name="hero-cog" class="h-6 w-6 shrink-0" /> Settings
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </div>
    """
  end
end
