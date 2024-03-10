using DataFrames

function remove_unnecessary_locations(locs)
   n = length(locs)
   @label cycle_over_locs

   for i in 1:n
      if locs[i].techs == 0
         splice!(locs,i)
         n = n-1
         @goto cycle_over_locs
      end
   end
   return locs
end



function get_list_locations(locations)
    list_locations = Array{String,1}(undef,0)
    for i in 1:length(locations)
        if locations[i].techs == 0
        else
            push!(list_locations,locations[i].name)
        end
    end
    return list_locations
end



locs = my_system.nodes
locs = remove_unnecessary_locations(locs)
list_locations = get_list_locations(locs)

function generate_df_installed_capacity(locs,list_locations)
   df = DataFrame()
   
   for i in 1:length(locs)
   end
   
end