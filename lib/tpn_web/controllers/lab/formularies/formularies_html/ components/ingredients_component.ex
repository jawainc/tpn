defmodule TpnWeb.Formularies.Components.IngredientsComponent do
  use Phoenix.Component
  import TpnWeb.CoreComponents

  @doc """
  defines the ingredients selecter
  """
  attr :ingredients, :list, required: true
  attr :selected, :list, required: true
  attr :units, :list, required: true

  def ingredients(assigns) do
    ~H"""
    <section
      class="w-full rounded-lg border scroll-mt-16"
      x-data={"{
              ingredients: [],
              all_ingredients: [#{@ingredients |> Enum.map(fn ingredient -> "{name: '#{ingredient.name}', id: '#{ingredient.id}'}" end) |> Enum.join(",")}],
              selected_ingredients: [],
              units: [#{@units}],
              open_ingredients: () => {
                ingredients_modal.showModal();
              },
              set_ingredients() {
                this.ingredients = differenceBy(this.all_ingredients, this.selected_ingredients, 'id');
              },
              set_selected_ingredients() {
                const old_selected_ingredients = [#{@selected |> Enum.map(fn select -> "{ingredient_id: '#{select.ingredient_id}', unit_id: '#{select.unit_id}', amount: '#{select.amount}'}" end) |> Enum.join(",")}]
                this.selected_ingredients = old_selected_ingredients.map((i) => {
                  const ingredient = this.all_ingredients.find((a) => a.id === i.ingredient_id);
                  return {id: i.ingredient_id, name: ingredient.name, unit_id: i.unit_id, amount: i.amount};
                });
              },
              add_ingredient(ingredient) {
                this.selected_ingredients.push(ingredient);
                this.set_ingredients();
              },
              remove_ingredient(id) {
                this.selected_ingredients = this.selected_ingredients.filter((i) => i.id !== id);
                this.set_ingredients();
              },
              get_ingredient_name(id) {
                return this.all_ingredients.find((i) => i.id === id).name;
              }
            }"}
      x-init="set_selected_ingredients(); set_ingredients();"
    >
      <header class="flex items-center justify-between border-b px-4 py-3 font-semibold bg-card text-card-foreground">
        <span>Ingredients</span>
        <button
          class="btn-sm-outline text-xs h-xs flex items-center gap-2"
          @click="open_ingredients()"
          type="button"
          aria-label="Add Ingredient"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4"><path d="M5 12h14"></path><path d="M12 5v14"></path></svg>
          <span>Add Ingredient</span>
        </button>
      </header>
      

      <ul role="list" class="divide-y divide-base-300">
        <template x-for="ingredient in selected_ingredients" x-bind:key="ingredient.id">
          <li class="gap-x-6 py-5">
            <div class="flex items-end gap-10">
              <div class="w-[500px]">
                <div class="flex items-start gap-x-3">
                  <label class="form-control w-full">
                    <div class="label">
                      <span class="label-text">
                        <span x-text="ingredient.name"></span> <span class="text-error">*</span>
                      </span>
                    </div>
                    <div class="input input-bordered flex items-center h-10 overflow-hidden pr-0">
                      <input
                        type="number"
                        x-bind:name="`formulary[ingredients][${ingredient.id}][amount]`"
                        x-bind:value="ingredient.amount || ''"
                        placeholder="0.00"
                        step=".01"
                        required
                        class="grow h-10 border-0 focus:ring-0 pl-0 pr-2 focus:outline-0"
                      />
                      <select
                        x-bind:name="`formulary[ingredients][${ingredient.id}][unit_id]`"
                        class="select h-10 join-item border-0 focus:ring-0 focus:outline-0 border-l border-neutral shrink-0"
                      >
                        <template x-for="unit in units" x-bind:key="unit.id">
                          <option
                            x-bind:value="unit.id"
                            x-text="unit.name"
                            x-bind:selected="unit.id === ingredient.unit_id"
                          >
                          </option>
                        </template>
                      </select>
                    </div>
                  </label>
                </div>
              </div>
              <button
                @click="remove_ingredient(ingredient.id)"
                type="button"
                class="btn btn-square btn-sm mb-1"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          </li>
        </template>
      </ul>
    

      <dialog id="ingredients_modal" class="modal">
        <div class="modal-box">
          <form method="dialog">
            <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
          </form>
          <h3 class="text-lg font-bold mb-5">Select Ingredients</h3>
          <ul role="list">
            <template x-for="ingredient in ingredients" x-bind:key="ingredient.id">
              <li class="group/item relative flex items-center justify-between rounded-xl p-3 hover:bg-base-200">
                <span x-text="ingredient.name" class="font-semibold"></span>
                <a
                  @click="add_ingredient(ingredient)"
                  href="#"
                  class="group/edit invisible relative flex items-center whitespace-nowrap rounded-full py-1 pl-4 pr-3 text-sm transition hover:bg-base-300 group-hover/item:visible"
                >
                  <span class="font-semibold transition group-hover/edit:text-base-content">Add</span>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="mt-px h-5 w-5 transition group-hover/edit:translate-x-0.5 group-hover/edit:text-base-content"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="m8.25 4.5 7.5 7.5-7.5 7.5"
                    />
                  </svg>
                </a>
              </li>
            </template>
          </ul>
        </div>
      </dialog>    
    </section>
    """
  end
end
