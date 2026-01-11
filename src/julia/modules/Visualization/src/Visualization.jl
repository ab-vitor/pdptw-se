module Visualization

using Plots, DataFrames, Colors, ColorSchemes

using Data
using Solutions
using Parameters

depot_tw = RGBA{Float64}(0, 1, 0,0.6)
vehicle_travel_color = RGBA{Float64}(0.961, 0.647, 0,0.6)
pickup_color = RGBA{Float64}(0, 0.976, 1,0.7)
delivery_color = RGBA{Float64}(0, 0.7, 0.2,0.7)
machine_waiting_color = RGBA{Float64}(0.694, 0, 1, 0.6)
machine_travel_color = RGBA{Float64}(0, 0, 1, 0.6)


function plot_instance(inst::InstanceData, params::ParameterData)
  rect(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])

  df = df_customers_time_windows(inst, params)
  r = [rect(t[1],0.1,t[2],t[3]) for t in zip(df.duration, df.earliest_time, df.request)]
  plot!(r, label=false, c=permutedims(df.color), yticks=(0:(nrow(df))), xlabel="Time", ylabel="Job ID")

  df = df_distances_depot_pickup(inst, params)
  r = [rect(t[1],0.1,t[2],t[3]) for t in zip(df.depot_pickup_dist, df.travel_start, df.request)]
  plot!(r, c=permutedims(df.color), label=false)

  df = df_distances_pickup_delivery(inst, params)
  r = [rect(t[1],0.1,t[2],t[3]) for t in zip(df.pickup_delivery_dist, df.travel_start, df.request)]
  plot!(r, c=permutedims(df.color), label=false)

  df = df_distances_delivery_depot(inst, params)
  r = [rect(t[1],0.1,t[2],t[3]) for t in zip(df.delivery_depot_dist, df.travel_start, df.request)]
  plot!(r, c=permutedims(df.color), label=false)


  savefig("./visualizations/" * inst.group * "/" * inst.name * ".svg")

end # function plot_instance()


function df_customers_time_windows(inst::InstanceData, params::ParameterData)

  earliest_times = Int64[inst.e[i] for i in inst.V]
  lat_times = Int64[inst.l[i] for i in inst.V]
  requests = vcat(0,Int64[i-1 for i in inst.V_p], Int64[i-inst.n-1 for i in inst.V_d])
  colors = vcat(depot_tw,RGBA{Float64}[pickup_color for i in inst.V_p], RGBA{Float64}[delivery_color for i in inst.V_d])
  
  df = DataFrame(earliest_time=earliest_times, lat_time=lat_times, request=requests, color=colors)
  df.duration = df.lat_time - df.earliest_time

  return df
end # function df_customers_time_windows()

function df_distances_depot_pickup(inst::InstanceData, params::ParameterData)
  travel_starts = Float64[]
  depot_pickup_dists = Float64[]
  requests = Float64[]
  colors = RGBA{Float64}[] 
  for i in inst.V_p
    if  (1,i) in inst.A_m
      for h in inst.H_e[1][i]
        push!(requests, i+0.1*h-1)
        push!(colors, vehicle_travel_color)
        push!(depot_pickup_dists, inst.d_bar[1, h, 1])
        push!(travel_starts, 0)

        arr_t = inst.d_bar[1, h, 1]
        start_machine_travel = max(arr_t,inst.O[(1, inst.f[1][h], h)])
        push!(requests, i+0.1*h-1)
        push!(colors, machine_waiting_color)
        push!(depot_pickup_dists, start_machine_travel-arr_t)
        push!(travel_starts, arr_t)

        push!(requests, i+0.1*h-1)
        push!(colors, machine_travel_color)
        push!(depot_pickup_dists, inst.O[(inst.f[1][h], inst.f[i][h], h)])
        push!(travel_starts, start_machine_travel)

        arr_t = start_machine_travel + inst.O[(inst.f[1][h], inst.f[i][h], h)]
        push!(requests, i+0.1*h-1)
        push!(colors, vehicle_travel_color)
        push!(depot_pickup_dists, inst.d_bar[i, h, 1])
        push!(travel_starts, arr_t)
      end
    else
      push!(requests, i-1+(0.1))
      push!(colors, vehicle_travel_color)
      push!(depot_pickup_dists, inst.d[1, i, 1])
      push!(travel_starts, 0)
    end
  end
  df = DataFrame(request=requests, color=colors, depot_pickup_dist=depot_pickup_dists, travel_start=travel_starts)

  return df
end # function plot_distances_depot_pickup_depot

function df_distances_pickup_delivery(inst::InstanceData, params::ParameterData)
  travel_starts = Float64[]
  pickup_delivery_dists = Float64[]
  requests = Float64[]
  colors = RGBA{Float64}[] 
  for i in inst.V_p
    if  (i,i+inst.n) in inst.A_m
      for h in inst.H_e[i][i+inst.n]
        push!(requests, i+0.1*h-1)
        push!(colors, vehicle_travel_color)
        push!(pickup_delivery_dists, inst.d_bar[i, h, 1])
        push!(travel_starts, inst.l[i])

        arr_t = inst.l[i] + inst.d_bar[i, h, 1]
        push!(requests, i+0.1*h-1)
        push!(colors, machine_travel_color)
        push!(pickup_delivery_dists, inst.O[(inst.f[i][h], inst.f[i+inst.n][h], h)])
        push!(travel_starts, arr_t)

        arr_t += inst.O[(inst.f[i][h], inst.f[i+inst.n][h], h)]
        push!(requests, i+0.1*h-1)
        push!(colors, vehicle_travel_color)
        push!(pickup_delivery_dists, inst.d_bar[i+inst.n, h, 1])
        push!(travel_starts, arr_t)
      end
    else
      push!(requests, i-1+(0.1))
      push!(colors, vehicle_travel_color)
      push!(pickup_delivery_dists, inst.d[i, i+inst.n, 1])
      push!(travel_starts, inst.l[i])
    end
  end
  df = DataFrame(request=requests, color=colors, pickup_delivery_dist=pickup_delivery_dists, travel_start=travel_starts)

  return df
end # function df_distances_pickup_delivery

function df_distances_delivery_depot(inst::InstanceData, params::ParameterData)
  travel_starts = Float64[]
  delivery_depot_dists = Float64[]
  requests = Float64[]
  colors = RGBA{Float64}[] 
  for i in inst.V_d
    if  (i,2*inst.n+2) in inst.A_m
      for h in inst.H_e[i][2*inst.n+2]
        push!(requests, i-inst.n+0.1*h-1)
        push!(colors, vehicle_travel_color)
        push!(delivery_depot_dists, inst.d_bar[i, h, 1])
        push!(travel_starts, inst.l[i])

        arr_t = inst.l[i] + inst.d_bar[i, h, 1]
        push!(requests, i-inst.n+0.1*h-1)
        push!(colors, machine_travel_color)
        push!(delivery_depot_dists, inst.O[(inst.f[i][h], inst.f[2*inst.n+2][h], h)])
        push!(travel_starts, arr_t)

        arr_t += inst.O[(inst.f[i][h], inst.f[2*inst.n+2][h], h)]
        push!(requests, i-inst.n+0.1*h-1)
        push!(colors, vehicle_travel_color)
        push!(delivery_depot_dists, inst.d_bar[2*inst.n+2, h, 1])
        push!(travel_starts, arr_t)
      end
    else
      push!(requests, i-inst.n-1+(0.1))
      push!(colors, vehicle_travel_color)
      push!(delivery_depot_dists, inst.d[i, 2*inst.n+2, 1])
      push!(travel_starts, inst.l[i])
    end
  end
  df = DataFrame(request=requests, color=colors, delivery_depot_dist=delivery_depot_dists, travel_start=travel_starts)

  return df
end # function df_distances_delivery_depot

end # module Visualization