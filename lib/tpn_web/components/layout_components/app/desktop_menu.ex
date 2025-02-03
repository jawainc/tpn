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
    <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col bg-base-200">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto border-r border-neutral px-6 pb-4">
        <div class="flex gap-x-4 h-16 items-center">
          <.icon name="hero-cube-transparent" class="h-10 w-10 text-indigo-600" />
          <span class="prose text-xl font-bold">XprTpn</span>
        </div>

        <nav>
          <ul
            class="menu bg-base-200 space-y-2 p-0 desktop-menu-group"
            hx-on:htmx-after-on-load="let currentMenu = document.querySelector('.selected');
                currentMenu.classList.remove('selected')
                let newMenu = event.target
                newMenu.classList.add('selected')"
          >
            <li hx-get={~p"/dash"} class="menu-item selected">
              <.icon name="hero-home" class="h-6 w-6 shrink-0" /> Dashboard
            </li>

            <li :if={@is_admin}>
              <details>
                <summary class="parent-menu">
                  <.icon name="hero-users" class="h-6 w-6 shrink-0" /> Accounts
                </summary>

                <ul>
                  <li>
                    <a
                      hx-get={~p"/roles"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Roles
                    </a>
                  </li>

                  <li>
                    <details>
                      <summary class="parent-menu">
                        Networks
                      </summary>

                      <ul>
                        <li>
                          <a
                            hx-get={~p"/lhn"}
                            hx-target="#main-contents"
                            hx-indicator=".main-contents-loader"
                            class="sub-menu-item"
                          >
                            Local Health Networks
                          </a>
                        </li>

                        <li>
                          <a
                            hx-get={~p"/facilities"}
                            hx-target="#main-contents"
                            hx-indicator=".main-contents-loader"
                            class="sub-menu-item"
                          >
                            Facilities
                          </a>
                        </li>

                        <li>
                          <a
                            hx-get={~p"/campuses"}
                            hx-target="#main-contents"
                            hx-indicator=".main-contents-loader"
                            class="sub-menu-item"
                          >
                            Campuses
                          </a>
                        </li>
                      </ul>
                    </details>
                  </li>

                  <li>
                    <a
                      hx-get={~p"/accounts"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Users
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
              <details>
                <summary class="parent-menu">
                  <.icon name="hero-building-office" class="h-6 w-6 shrink-0" /> Hospital
                </summary>

                <ul>
                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Wards"])
                  }>
                    <a
                      hx-get={~p"/wards"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Wards
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Rooms"])
                  }>
                    <a
                      hx-get={~p"/rooms"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Rooms
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Beds"])
                  }>
                    <a
                      hx-get={~p"/beds"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Beds
                    </a>
                  </li>
                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Patients"])
                  }>
                    <a
                      hx-get={~p"/patients/dashboard"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Patients
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
              <details>
                <summary class="parent-menu">
                  <.icon name="hero-funnel" class="h-6 w-6 shrink-0" /> Lab
                </summary>

                <ul>
                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "UnitTypes"
                    ])
                  }>
                    <a
                      hx-get={~p"/unit_types"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Unit Types
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, ["Units"])
                  }>
                    <a
                      hx-get={~p"/units"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Units
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "VascularAccess"
                    ])
                  }>
                    <a
                      hx-get={~p"/vascular_accesses"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Vascular Access
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "SolutionTypes"
                    ])
                  }>
                    <a
                      hx-get={~p"/solution_types"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Solution Types
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "PatientTypes"
                    ])
                  }>
                    <a
                      hx-get={~p"/patient_types"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Patient Types
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "Classes"
                    ])
                  }>
                    <a
                      hx-get={~p"/classes"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Classes
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "FillingMethods"
                    ])
                  }>
                    <a
                      hx-get={~p"/filling_methods"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Filling Methods
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "Osmolarities"
                    ])
                  }>
                    <a
                      hx-get={~p"/osmolarities"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Osmolarities
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "Ingredients"
                    ])
                  }>
                    <a
                      hx-get={~p"/ingredients"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Ingredients
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "Formularies"
                    ])
                  }>
                    <a
                      hx-get={~p"/formularies"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Formularies
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "Templates"
                    ])
                  }>
                    <a
                      hx-get={~p"/templates"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Templates
                    </a>
                  </li>

                  <li :if={
                    UserAccessLevel.has_menu_access_level?(@user_access_level, @is_admin, [
                      "Settings"
                    ])
                  }>
                    <a
                      hx-get={~p"/settings"}
                      hx-target="#main-contents"
                      hx-indicator=".main-contents-loader"
                      class="sub-menu-item"
                    >
                      Settings
                    </a>
                  </li>
                </ul>
              </details>
            </li>
          </ul>
        </nav>
      </div>
    </div>
    """
  end
end
