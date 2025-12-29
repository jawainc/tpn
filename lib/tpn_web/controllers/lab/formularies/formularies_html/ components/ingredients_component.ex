defmodule TpnWeb.Formularies.Components.IngredientsComponent do
  use Phoenix.Component
  use TpnWeb, :html
  import TpnWeb.CoreComponents

  @doc """
  defines the ingredients selecter
  """
  attr :ingredients, :string, required: true
  attr :selected_ingredients, :string, required: true
  attr :ingredients_units, :string, required: true

  def ingredients(assigns) do
    ~H"""
    <section
      class="w-full rounded-lg border scroll-mt-16"
      x-data="formulariesIngredients"
      x-init={"
      all_ingredients = #{@ingredients};
      units = #{@ingredients_units};
      old_selected_ingredients = #{@selected_ingredients};
      set_ingredients();
      set_selected_ingredients();
      "}
    >
      <header class="flex items-center justify-between border-b px-4 py-3 font-semibold bg-card text-card-foreground">
        <span>Ingredients</span>
        <button
          class="btn-sm-outline"
          @click="open_ingredients()"
          type="button"
          aria-label="Add Ingredient"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="h-4 w-4"
          >
            <path d="M5 12h14"></path>
            <path d="M12 5v14"></path>
          </svg>
          <span>Add Ingredient</span>
        </button>
      </header>

      <template x-if="!selected_ingredients.length">
        <div class="flex items-center justify-center py-10">
          <div class="text-center">
            <div class="text-forground">No ingredients selected</div>
          </div>
        </div>
      </template>

      <ul role="list" class="divide-y divide-border">
        <template x-for="ingredient in selected_ingredients" x-bind:key="ingredient.id">
          <li class="gap-x-6 p-4">
            <div class="flex items-end gap-10">
              <div class="grid gap-3">
                <label x-bind:for="`ingredient-${ingredient.id}-input`" class="label">
                  <span x-text="ingredient.name"></span><span class="text-destructive">*</span>
                </label>
                <div class="flex items-center rounded w-full relative">
                  <input
                    type="number"
                    x-bind:name="`formulary[ingredients][${ingredient.id}][amount]`"
                    x-bind:value="ingredient.amount || ''"
                    x-bind:id="`ingredient-${ingredient.id}-input`"
                    placeholder="0.0000"
                    step=".0001"
                    required
                    class="input pr-[155px]"
                  />
                  <div
                    x-bind:id="`select-${ingredient.id}`"
                    class="select absolute right-0 top-[1px] w-[150px]"
                  >
                    <button
                      type="button"
                      class="btn-outline justify-between font-normal h-[34px] w-full border-t-0 border-b-0 rounded-l-none"
                      x-bind:id="`select-${ingredient.id}-trigger`"
                      aria-haspopup="listbox"
                      aria-expanded="false"
                      x-bind:aria-controls="`select-${ingredient.id}-listbox`"
                    >
                      <span class="truncate"></span>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="text-muted-foreground opacity-50 shrink-0"
                      >
                        <path d="m6 9 6 6 6-6"></path>
                      </svg>
                    </button>
                    <div
                      x-bind:id="`select-${ingredient.id}-popover`"
                      data-popover
                      data-side="bottom"
                      data-align="end"
                      aria-hidden="true"
                      class="w-40"
                    >
                      <header>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="lucide lucide-search-icon lucide-search"
                        >
                          <circle cx="11" cy="11" r="8" />
                          <path d="m21 21-4.3-4.3" />
                        </svg>
                        <input
                          type="text"
                          value=""
                          placeholder="Search ..."
                          autocomplete="off"
                          autocorrect="off"
                          spellcheck="false"
                          aria-autocomplete="list"
                          role="combobox"
                          aria-expanded="false"
                          x-bind:aria-controls="`select-${ingredient.id}-listbox`"
                          x-bind:aria-labelledby="`select-${ingredient.id}-trigger`"
                        />
                      </header>
                      <div
                        role="listbox"
                        class="scrollbar overflow-y-auto max-h-64"
                        x-bind:id="`select-${ingredient.id}-listbox`"
                        aria-orientation="vertical"
                        x-bind:aria-labelledby="`select-${ingredient.id}-trigger`"
                      >
                        <div
                          role="group"
                          x-bind:aria-labelledby="`group-label-select-${ingredient.id}-items-1`"
                        >
                          <div
                            role="heading"
                            x-bind:id="`group-label-select-${ingredient.id}-items-1`"
                          >
                            Search
                          </div>
                          <template x-for="unit in units" x-bind:key="unit.id">
                            <div
                              role="option"
                              x-bind:data-value="unit.id"
                              x-bind:aria-selected="unit.id == ingredient.unit_id"
                              x-text="unit.name"
                            />
                          </template>
                        </div>
                      </div>
                    </div>
                    <input
                      type="hidden"
                      x-bind:id="`select-${ingredient.id}`"
                      x-bind:name="`formulary[ingredients][${ingredient.id}][unit_id]`"
                      x-bind:value="ingredient.unit_id || ''"
                    />
                  </div>
                </div>
              </div>
              <button
                @click="remove_ingredient(ingredient.id)"
                type="button"
                class="btn-sm-icon-destructive mb-[3px]"
              >
                <.icon_trash />
              </button>
            </div>
          </li>
        </template>
      </ul>

      <dialog id="ingredients_modal" class="dialog w-full sm:max-w-[425px] max-h-[612px]">
        <div>
          <header>
            <h2 id="dialog-example-title">Ingredients</h2>
            <p id="dialog-example-description">Add new ingredients by clicking the "+ Add" button.</p>
            <div class="relative">
              <input
                x-model="query"
                x-on:input="search_ingredients(query)"
                type="text"
                class="input pl-9 pr-20"
                placeholder="Search..."
              />
              <div class="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none text-muted-foreground [&>svg]:size-4">
                <.icon_select_search />
              </div>
              <div class="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-muted-foreground text-sm">
                <span x-text="ingredients.length"></span> results
              </div>
            </div>
          </header>

          <section class="overflow-y-auto scrollbar">
            <ul role="list">
              <template x-for="ingredient in ingredients" x-bind:key="ingredient.id">
                <li class="rounded-lg border hover:bg-accent/50 p-2 mb-4 flex items-center justify-between">
                  <span x-text="ingredient.name"></span>
                  <button
                    type="button"
                    @click="add_ingredient(ingredient)"
                    class="btn-sm-outline text-xs h-xs flex items-center gap-2"
                  >
                    <.icon_plus class="size-4" /> Add
                  </button>
                </li>
              </template>
            </ul>
          </section>

          <button
            type="button"
            aria-label="Close dialog"
            onclick="this.closest('dialog').close()"
            class="absolute top-4 right-4 opacity-50 hover:opacity-70"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-5"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide lucide-x-icon lucide-x"
            >
              <path d="M18 6 6 18" />
              <path d="m6 6 12 12" />
            </svg>
          </button>
        </div>
      </dialog>
    </section>
    """
  end
end
