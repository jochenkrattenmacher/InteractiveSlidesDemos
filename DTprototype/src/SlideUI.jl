module SlideUI
using Reexport
@reexport using Stipple, StipplePlotly, StippleUI
import Random

const m_max = 4 #max number of monitors. Note: This setting does not really (yet) affect anything except error messages (the max number of monitors depends on the model fields which are hardcoded).
m_used = 4 #number of used monitors. This affects the number of generated UI elements upon page load and can be changed without having to restart the julia session.

#PresentationModels
#region
export get_or_create_pmodel, PresentationModel, reset_counters
register_mixin(@__MODULE__)

@reactive! mutable struct PresentationModel <: ReactiveModel
    counters::Dict{Symbol, Int8} = Dict(:Bool => 1, :Int => 1, :Vector => 1, :PlotData => 1, :PlotLayout => 1, :PlotConfig => 1)
    current_id0::R{Int8} = 1
    current_id1::R{Int8} = 1
    current_id2::R{Int8} = 1
    current_id3::R{Int8} = 1
    current_id4::R{Int8} = 1
    drawer0::R{Bool} = false
    drawer1::R{Bool} = false
    drawer2::R{Bool} = false
    drawer3::R{Bool} = false
    drawer4::R{Bool} = false
    int1::R{Int} = 0
    int2::R{Int} = 0
    int3::R{Int} = 0
    int4::R{Int} = 0
    int5::R{Int} = 0
    int6::R{Int} = 0
    int7::R{Int} = 0
    int8::R{Int} = 0
    int9::R{Int} = 0
    int10::R{Int} = 0
    vector1::R{Vector} = []
    vector2::R{Vector} = []
    vector3::R{Vector} = []
    vector4::R{Vector} = []
    vector5::R{Vector} = []
    vector6::R{Vector} = []
    vector7::R{Vector} = []
    vector8::R{Vector} = []
    vector9::R{Vector} = []
    vector10::R{Vector} = []
    plotdata1::R{Vector{PlotData}} = [PlotData()]
    plotdata2::R{Vector{PlotData}} = [PlotData()]
    plotdata3::R{Vector{PlotData}} = [PlotData()]
    plotdata4::R{Vector{PlotData}} = [PlotData()]
    plotdata5::R{Vector{PlotData}} = [PlotData()]
    plotlayout1::R{PlotLayout} = PlotLayout()
    plotlayout2::R{PlotLayout} = PlotLayout()
    plotlayout3::R{PlotLayout} = PlotLayout()
    plotlayout4::R{PlotLayout} = PlotLayout()
    plotlayout5::R{PlotLayout} = PlotLayout()
    plotconfig1::R{PlotConfig} = PlotConfig()
    plotconfig2::R{PlotConfig} = PlotConfig()
    plotconfig3::R{PlotConfig} = PlotConfig()
    plotconfig4::R{PlotConfig} = PlotConfig()
    plotconfig5::R{PlotConfig} = PlotConfig()
end

pmodels = PresentationModel[]

function reset_counters(pmodel::PresentationModel)
    for key in keys(pmodel.counters)
        pmodel.counters[key] = 1
    end
end

function get_or_create_pmodel(; force_create = false::Bool)
    force_create && empty!(pmodels)
    if isempty(pmodels) || force_create
        pmodel = create_pmodel()
        push!(pmodels, pmodel)
    end
    pmodels[1]
end

function create_pmodel()
    println("Time to initialize model:")
    @time pmodel = Stipple.init(PresentationModel)
    on(pmodel.isready) do ready
        ready || return
        push!(pmodel)        
    end

    return pmodel
end
#endregion

#ModelManager
#region
export new_field!, new_multi_field!, new_handler, @multi
#this module should generate handlers and somehow populate fields for each pmodel (depending on slides), or expose functions/macros toward such ends

mutable struct ManagedField
    sym::Symbol
    ref
end

function new_field!(pmodel::PresentationModel, type::Symbol; value = Nothing, dummy = 0::Int)
    rng = Random.MersenneTwister(dummy)
    name = lowercase(string(type, pmodel.counters[type]))
    if name[1:4] == "bool"
        name = "int" * name[5:end]
    end
    name_sym = Symbol(name)
    if type == :PlotData
        if dummy > 0
          
            pd(name) = PlotData(
                x = 1:12,
                y = (1:12)/5,
                name = name,
                plot = "scatter",
            )
            
            value = [pd(string("Dummy Team ", m_id)) for m_id in 1:m_used]
        end
    elseif type == :Bool
        if dummy > 0
            value = rand(rng, [0 1])
        end
    end
    if value != Nothing
        getfield(pmodel, name_sym).o.val = value
    end
    pmodel.counters[type] += 1
    return ManagedField(name_sym, getfield(pmodel, name_sym))::ManagedField
end

function new_multi_field!(pmodel::PresentationModel, type::Symbol; value = Nothing, dummy = 0::Int)
    [new_field!(pmodel, type; value, dummy) for i in 1:m_used]
end

function Base.getindex(field::Vector{ManagedField}, sym::Symbol)
    return Symbol(field[1].sym, "<f_id")
end

handlers = Observables.ObserverFunction[]

function new_handler(fun::Function, field::ManagedField)
    handler = on(field.ref, weak = true) do val
        fun(val)
    end
    notify(field.ref)
    push!(handlers, handler)
end

function rep!(e, old, new)
    for (i,a) in enumerate(e.args)
        if a==old
            e.args[i] = new
        elseif a isa Expr
            rep!(a, old, new)
        end
    end
    e
end

macro multi(e1)
    e2 = copy(e1); e3 = copy(e1); e4 = copy(e1) #m_max relevant
    return quote
        $(esc(rep!(e1, :m_id, 1)))
        $(esc(rep!(e2, :m_id, 2)))
        $(esc(rep!(e3, :m_id, 3)))
        $(esc(rep!(e4, :m_id, 4)))
     end
end

#endregion

#SLIDE UI
#region
export ui, slide, standard_menu, standard_header, standard_footer

slides = Vector{Vector}[[],[],[],[]] #create slideshow for each monitor

function slide(args...)
    for m_id in 1:m_used
        monitor_slides = [replace(x,  
                                                "m_id" => "$m_id", 
                                    r"[0-9+](<f_id)" => y -> string(parse(Int8,y[1])+m_id-1))
                                    for x in args]
        push!(slides[m_id], monitor_slides)
    end
end

function render_slides(slides_to_render::Vector, monitor_id::Int)
    titles = String[]
    bodies = ParsedHTMLString[]
        for (id,sld) in enumerate(slides_to_render)
            push!(titles, strip(match(r">.*<", String(sld[1])).match[2:end-1]))
            push!(bodies, 
            Genie.Renderer.Html.div(class = "slide text-center flex-center q-gutter-sm q-col-gutter-sm", 
            sld, @iif("$id == current_id$monitor_id")))
        end
    return (titles, bodies)
end

function standard_menu(slide_titles::Vector{String}, m_id::Int)
    drawer(side="left", v__model="drawer$m_id", [
        list([
            item(item_section(string(id) * ": " * title), :clickable, @click("current_id$m_id = $(id); drawer$m_id = ! drawer$m_id")) 
            for 
            (id, title) in enumerate(slide_titles)
            ])
        ])
end

function standard_header(num_slides::Int, m_id::Int)
    quasar(:header, quasar(:toolbar, [
        btn("",icon="menu", @click("drawer$m_id = ! drawer$m_id"))
        btn("",icon="chevron_left", @click("current_id$m_id > 1 ? current_id$m_id-- : null"))
        btn("",icon="navigate_next", @click("current_id$m_id < $num_slides ? current_id$m_id++ : null"))
        ])
    )
end

function standard_footer(m_id::Int, folder::AbstractString)
    isfile("./public/$folder/img/logo.png") ? logo = icon("img:$folder/img/logo.png", size = "md") : logo = ParsedHTMLString("")
    quasar(:footer, quasar(:toolbar, [space(),
        logo,
        quasar(:toolbar__title, "GCF"), span("", @text(Symbol("current_id$m_id")))])
    )
end

function ui(pmodel::PresentationModel, create_slideshow::Function, request_params::Dict{Symbol, Any}, folder::String)
    m_id = get(request_params, :monitor_id, 1)::Int
    m_id > m_max && return "There are only $m_max monitors."
    m_id > m_used && return "Monitor $m_id not active."
    if isempty(slides[1]) || get(request_params, :reset, "0") != "0"
        foreach(x -> empty!(x),slides)
        create_slideshow(pmodel)
    end
    slide_titles, slide_bodies = render_slides(slides[m_id], m_id)
    page(pmodel, prepend = link(href = "$folder/style.css", rel = "stylesheet"),
    [
        StippleUI.Layouts.layout([
            standard_menu(slide_titles, m_id)
            standard_header(length(slide_titles), m_id)
            standard_footer(m_id, folder)
            StippleUI.Layouts.page_container("",
                slide_bodies
            )
        ])
    ])
end
#endregion
end