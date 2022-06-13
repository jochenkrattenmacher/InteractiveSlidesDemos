using Genie.Router
using Stipple, StippleUI, StipplePlotly
using Presentations

function ui(presentation)
  slides = include("slides.jl")
  page(presentation, style = "font-size:40px", prepend = style(
    """
    h1 {
        font-size: 3em !important;
        line-height: 1em !important;
    }
    """
    ),
  [
      StippleUI.Layouts.layout([
          quasar(:header, quasar(:toolbar, [
                  btn("",icon="menu", @click("drawer = ! drawer"))
                  btn("",icon="chevron_left", @click("if (current_id > 1) {current_id--}"))
                  btn("",icon="navigate_next", @click("current_id++"))
                  ])
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
    Html.div(class = "slide text-center flex-center q-gutter-sm q-col-gutter-sm", args..., @iif(:($id == current_id)); kwargs...)
end

route("/") do
  
end

route("/:name") do
    ui_out = init_presentation(params(:name)) |> ui |> html
end