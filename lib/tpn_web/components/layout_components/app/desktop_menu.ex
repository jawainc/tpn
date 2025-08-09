defmodule TpnWeb.LayoutComponents.App.Menu do
  use Phoenix.Component
  use TpnWeb, :verified_routes

  import TpnWeb.CoreComponents
  alias Tpn.Formularies
  alias Tpn.Lab.Osmolarities
  alias TpnWeb.Auth.UserAccessLevel

  attr :is_admin, :boolean, default: false
  attr :user_access_level, :list, default: []

  def app_menu(assigns) do
    ~H"""
    <aside class="sidebar" data-side="left" aria-hidden="false">
      <nav aria-label="Main Navigation">
        <header class="border-b border-border h-14 justify-center">
          <div class="flex items-center gap-4">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6 text-brand-default ">
            <path stroke-linecap="round" stroke-linejoin="round" d="m21 7.5-2.25-1.313M21 7.5v2.25m0-2.25-2.25 1.313M3 7.5l2.25-1.313M3 7.5l2.25 1.313M3 7.5v2.25m9 3 2.25-1.313M12 12.75l-2.25-1.313M12 12.75V15m0 6.75 2.25-1.313M12 21.75V19.5m0 2.25-2.25-1.313m0-16.875L12 2.25l2.25 1.313M21 14.25v2.25l-2.25 1.313m-13.5 0L3 16.5v-2.25" />
          </svg>
          <h3 class="font-semibold text-secondary-foreground">XprTpn</h3>
        </div>
        </header>
        <section class="scrollbar mt-8">
          <div role="group">
            <ul>
            <li>
              <a href={~p"/dash"} class="cursor-pointer" hx-get={~p"/dash"} hx-target="#main-contents" hx-indicator="#main-contents-indicator">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
                </svg>
                <span>Dashboard</span>
              </a>
            </li>
            <li :if={@is_admin}>
                <details id="submenu-content-accounts">
                  <summary aria-controls="submenu-content-accounts-content">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M18 18.72a9.094 9.094 0 0 0 3.741-.479 3 3 0 0 0-4.682-2.72m.94 3.198.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0 1 12 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 0 1 6 18.719m12 0a5.971 5.971 0 0 0-.941-3.197m0 0A5.995 5.995 0 0 0 12 12.75a5.995 5.995 0 0 0-5.058 2.772m0 0a3 3 0 0 0-4.681 2.72 8.986 8.986 0 0 0 3.74.477m.94-3.197a5.971 5.971 0 0 0-.94 3.197M15 6.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm6 3a2.25 2.25 0 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Zm-13.5 0a2.25 2.25 0 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z" />
                    </svg>
                    <span>Accounts</span>
                  </summary>
                  <ul id="submenu-content-accounts-content">
                    <li>
                      <a href={~p"/roles"} hx-get={~p"/roles"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="cursor-pointer">
                        Roles
                      </a>
                    </li>
                    <li>
                      <a href={~p"/users"} hx-get={~p"/users"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="cursor-pointer">
                        Users
                      </a>
                    </li>
                  </ul>
                </details>
              </li>
              <li :if={@is_admin}>
                <details id="submenu-content-networks">
                  <summary aria-controls="submenu-content-networks-content">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418" />
                    </svg>
                    <span>Networks</span>
                  </summary>
                  <ul id="submenu-content-networks-content">
                    <li>
                      <a href={~p"/lhn"} class="cursor-pointer" hx-get={~p"/lhn"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Local Health Networks
                      </a>
                    </li>
                    <li>
                      <a href={~p"/facilities"} class="cursor-pointer" hx-get={~p"/facilities"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Facilities
                      </a>
                    </li>
                    <li>
                      <a href={~p"/campuses"} class="cursor-pointer" hx-get={~p"/campuses"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Campuses
                      </a>
                    </li>
                  </ul>
                </details>
              </li>
              <li :if={
                UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                  "Wards",
                  "Rooms",
                  "Beds",
                  "Patients"
                ])
              }>
                <details id="submenu-content-hospital">
                  <summary aria-controls="submenu-content-hospital-content">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
                    </svg>
                    <span>Hospital</span>
                  </summary>
                  <ul id="submenu-content-hospital-content">
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Wards"])}>
                      <a href={~p"/wards"} class="cursor-pointer" hx-get={~p"/wards"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Wards
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Rooms"])}>
                      <a href={~p"/rooms"} class="cursor-pointer" hx-get={~p"/rooms"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Rooms
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Beds"])}>
                      <a href={~p"/beds"} class="cursor-pointer" hx-get={~p"/beds"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Beds
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Patients"])}>
                      <a href={~p"/patients"} class="cursor-pointer" hx-get={~p"/patients"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Patients
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Orders"])}>
                      <a href={~p"/orders"} class="cursor-pointer" hx-get={~p"/orders"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Orders
                      </a>
                    </li>
                  </ul>
                </details>
              </li>
              <li :if={
                UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                  "UnitTypes",
                  "Units",
                  "VascularAccess",
                  "SolutionTypes",
                  "Classes",
                  "FillingMethods",
                  "PatientTypes",
                  "Osmolarities",
                  "Ingredients",
                  "Formularies",
                  "Templates",
                  "TemplateProducts",
                  "Settings"
                ])
              }>
                <details id="submenu-content-lab">
                  <summary aria-controls="submenu-content-lab-content">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25 2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0 1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0 0-.659-1.591L3.659 7.409A2.25 2.25 0 0 1 3 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0 1 12 3Z" />
                    </svg>
                    <span>Lab</span>
                  </summary>
                  <ul id="submenu-content-lab-content">
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["UnitTypes"])}>
                      <a href={~p"/unit_types"} class="cursor-pointer" hx-get={~p"/unit_types"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Unit Types
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Units"])}>
                      <a href={~p"/units"} class="cursor-pointer" hx-get={~p"/units"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Units
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["VascularAccess"])}>
                      <a href={~p"/vascular_accesses"} class="cursor-pointer" hx-get={~p"/vascular_accesses"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Vascular Access
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["SolutionTypes"])}>
                      <a href={~p"/solution_types"} class="cursor-pointer" hx-get={~p"/solution_types"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Solution Types
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["PatientTypes"])}>
                      <a href={~p"/patient_types"} class="cursor-pointer" hx-get={~p"/patient_types"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Patient Types
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Classes"])}>
                      <a href={~p"/classes"} class="cursor-pointer" hx-get={~p"/classes"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Classes
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["FillingMethods"])}>
                      <a href={~p"/filling_methods"} class="cursor-pointer" hx-get={~p"/filling_methods"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Filling Methods
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Osmolarities"])}>
                      <a href={~p"/osmolarities"} class="cursor-pointer" hx-get={~p"/osmolarities"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Osmolarities
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Ingredients"])}>
                      <a href={~p"/ingredients"} class="cursor-pointer" hx-get={~p"/ingredients"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Ingredients
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Formularies"])}>
                      <a href={~p"/formularies"} class="cursor-pointer" hx-get={~p"/formularies"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Formularies
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Templates"])}>
                      <a href={~p"/templates"} class="cursor-pointer" hx-get={~p"/templates"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Templates
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["TemplateProducts"])}>
                      <a href={~p"/template_products"} class="cursor-pointer" hx-get={~p"/template_products"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Template Products
                      </a>
                    </li>
                    <li :if={UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Settings"])}>
                      <a href={~p"/settings"} class="cursor-pointer" hx-get={~p"/settings"} hx-target="#main-contents" hx-indicator="#main-contents-indicator" class="sub-menu-item">
                        Settings
                      </a>
                    </li>
                  </ul>
                </details>
              </li>
            </ul>
          </div>
        </section>
      </nav>
    </aside>
    """
  end
end
