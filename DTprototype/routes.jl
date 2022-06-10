using Genie.Router
using Stipple, StippleUI, StipplePlotly
using Presentations

function ui(presentation)
  slides = include("slides.jl")
  page(presentation, 
  [
      StippleUI.Layouts.layout([
          quasar(:header, quasar(:toolbar, [
                  btn("",icon="menu", @click("drawer = ! drawer"))
                  quasar(:toolbar__title, "Example App")])
          )
          quasar(:footer, quasar(:toolbar, [space(),
                  icon("img:img/GCFlogo.png", size = "md"),
                  quasar(:toolbar__title, "GCF")])
          )
          drawer(side="left", v__model="drawer", [
              list([
                  item([
                      item_section(icon("bar_chart"), :avatar)
                      item_section("Bar")
                  ], :clickable, :v__ripple, @click("show_bar = true, drawer = false"))
                  item([
                      item_section(icon("scatter_plot"), :avatar)
                      item_section("Scatter")
                  ], :clickable, :v__ripple, @click("show_bar = false, drawer = false"))
              ])
          ])
          StippleUI.Layouts.page_container("",
            [render_slide(id, slide) for (id,slide) in enumerate(slides)]
          )
      ])
  ])
end

function render_slide(id::Int, args...; kwargs...)
    row(class = "q-col-gutter-sm", args..., @iif(:($id == current_id)); kwargs...)
end

route("/") do
  init_presentation() |> ui |> html
end