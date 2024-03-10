module SystemStructMess

export Coordinates,Costs,Carrier_ratios, Essential, Tech, Location, System, Results_locations, Results_networks, System_results
export Monetary_supply, Monetary_supply_grid, Monetary_supply_plus, Monetary_demand, Monetary_storage, Monetary_transmission, Monetary_conversion, Monetary_conversion_plus
export Constraint_supply, Constraint_supply_grid, Constraint_supply_plus, Constraint_demand, Constraint_storage, Constraint_transmission, Constraint_conversion, Constraint_conversion_plus
export Model_configuration
export Location_post, Tech_post, Location_srgc, Results_economics
struct Coordinates
    lat::Float64
    long::Float64
end

Base.@kwdef mutable struct Costs
    monetary::Union{Any, Missing} = missing
    emissions::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_supply
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap::Union{Any, Missing} = missing
    export_::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
    om_con::Union{Any, Missing} = missing
    om_prod::Union{Any, Missing} = missing
    resource_area::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_supply_grid
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap::Union{Any, Missing} = missing
    export_::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
    om_con::Union{Any, Missing} = missing
    om_prod::Union{Any, Missing} = missing
    resource_area::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_supply_plus
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap::Union{Any, Missing} = missing
    export_::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
    om_annual_investment_fraction::Union{Any, Missing} = missing
    om_con::Union{Any, Missing} = missing
    om_prod::Union{Any, Missing} = missing
    purchase::Union{Any, Missing} = missing
    resource_area::Union{Any, Missing} = missing
    resource_cap::Union{Any, Missing} = missing
    storage_cap::Union{Any, Missing} = missing
end


Base.@kwdef mutable struct Monetary_demand
    #om_con::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_storage
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap::Union{Any, Missing} = missing
    export_::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
    om_annual_investment_fraction::Union{Any, Missing} = missing
    om_prod::Union{Any, Missing} = missing
    purchase::Union{Any, Missing} = missing
    storage_cap::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_transmission
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap_per_distance::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_conversion
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap::Union{Any, Missing} = missing
    export_::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
    om_con::Union{Any, Missing} = missing
    om_prod::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Monetary_conversion_plus
    depreciation_rate::Union{Any, Missing} = missing
    energy_cap::Union{Any, Missing} = missing
    export_::Union{Any, Missing} = missing
    interest_rate::Union{Any, Missing} = missing
    om_annual::Union{Any, Missing} = missing
    om_con::Union{Any, Missing} = missing
    om_prod::Union{Any, Missing} = missing
end


Base.@kwdef mutable struct Constraint_supply
    energy_cap_equals::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    force_resource::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
    resource::Union{Any, Missing} = missing
    resource_area_equals::Union{Any, Missing} = missing
    resource_unit::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_supply_grid
    energy_cap_equals::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    force_resource::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
    resource::Union{Any, Missing} = missing
    resource_area_equals::Union{Any, Missing} = missing
    resource_unit::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_supply_plus
    charge_rate::Union{Any, Missing} = missing #ok
    energy_cap_per_storage_cap_min::Union{Any, Missing} = missing #ok
    energy_cap_per_storage_cap_max::Union{Any, Missing} = missing #ok
    energy_cap_per_storage_cap_equals::Union{Any, Missing} = missing #maybe
    energy_cap_equals::Union{Any, Missing} = missing #YES
    energy_cap_equals_systemwide::Union{Any, Missing} = missing # only for control
    energy_cap_max::Union{Any, Missing} = missing
    energy_cap_max_systemwide::Union{Any, Missing} = missing
    energy_cap_min::Union{Any, Missing} = missing
    energy_cap_min_use::Union{Any, Missing} = missing
    energy_cap_per_unit::Union{Any, Missing} = missing
    energy_cap_scale::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    energy_prod::Union{Any, Missing} = missing
    energy_ramping::Union{Any, Missing} = missing
    export_cap::Union{Any, Missing} = missing
    export_carrier::Union{Any, Missing} = missing
    force_resource::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
    parasitic_eff::Union{Any, Missing} = missing
    resource::Union{Any, Missing} = missing
    resource_area_equals::Union{Any, Missing} = missing
    resource_area_max::Union{Any, Missing} = missing
    resource_area_min::Union{Any, Missing} = missing
    resource_area_per_energy_cap::Union{Any, Missing} = missing
    resource_cap_equals::Union{Any, Missing} = missing
    resource_cap_equals_energy_cap::Union{Any, Missing} = missing
    resource_cap_max::Union{Any, Missing} = missing
    resource_cap_min::Union{Any, Missing} = missing
    resource_eff::Union{Any, Missing} = missing
    resource_min_use::Union{Any, Missing} = missing
    resource_scale::Union{Any, Missing} = missing
    resource_unit::Union{Any, Missing} = missing
    storage_cap_equals::Union{Any, Missing} = missing
    storage_cap_max::Union{Any, Missing} = missing
    storage_cap_min::Union{Any, Missing} = missing
    storage_cap_per_unit::Union{Any, Missing} = missing
    storage_initial::Union{Any, Missing} = missing
    storage_loss::Union{Any, Missing} = missing
    units_equals::Union{Any, Missing} = missing
    units_equals_systemwide::Union{Any, Missing} = missing
    units_max::Union{Any, Missing} = missing
    units_max_systemwide::Union{Any, Missing} = missing
    units_min::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_demand
    resource::Union{Any, Missing} = missing
    resource_unit::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_storage
    charge_rate::Union{Any, Missing} = missing
    energy_cap_per_storage_cap_min::Union{Any, Missing} = missing
    energy_cap_per_storage_cap_max::Union{Any, Missing} = missing
    energy_cap_per_storage_cap_equals::Union{Any, Missing} = missing
    energy_cap_equals::Union{Any, Missing} = missing
    energy_cap_equals_systemwide::Union{Any, Missing} = missing
    energy_cap_max::Union{Any, Missing} = missing
    energy_cap_max_systemwide::Union{Any, Missing} = missing
    energy_cap_min::Union{Any, Missing} = missing
    energy_cap_min_use::Union{Any, Missing} = missing
    energy_cap_per_unit::Union{Any, Missing} = missing
    energy_cap_scale::Union{Any, Missing} = missing
    energy_con::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    energy_prod::Union{Any, Missing} = missing
    energy_ramping::Union{Any, Missing} = missing
    export_cap::Union{Any, Missing} = missing
    export_carrier::Union{Any, Missing} = missing
    force_asynchronous_prod_con::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
    storage_cap_equals::Union{Any, Missing} = missing
    storage_cap_max::Union{Any, Missing} = missing
    storage_cap_min::Union{Any, Missing} = missing
    storage_cap_per_unit::Union{Any, Missing} = missing
    storage_initial::Union{Any, Missing} = missing
    storage_loss::Union{Any, Missing} = missing
    storage_time_max::Union{Any, Missing} = missing
    storage_discharge_depth::Union{Any, Missing} = missing
    units_equals::Union{Any, Missing} = missing
    units_equals_systemwide::Union{Any, Missing} = missing
    units_max::Union{Any, Missing} = missing
    units_max_systemwide::Union{Any, Missing} = missing
    units_min::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_transmission
    energy_cap_equals::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    energy_eff_per_distance::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
    one_way::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_conversion
    energy_cap_equals::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
    COP::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Constraint_conversion_plus
    carrier_ratios::Union{Any, Missing} = missing
    energy_cap_equals::Union{Any, Missing} = missing
    energy_eff::Union{Any, Missing} = missing
    energy_ramping::Union{Any, Missing} = missing
    lifetime::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Carrier_ratios
    carrier_out::Union{Any, Missing} = missing
    carrier_out_2::Union{Any, Missing} = missing
    carrier_out_3::Union{Any, Missing} = missing
    carrier_in::Union{Any, Missing} = missing
    carrier_in_2::Union{Any, Missing} = missing
    carrier_in_3::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Essential
    name::Union{Any, Missing} = missing
    color::Union{Any, Missing} = missing
    parent::Union{Any, Missing} = missing
    carrier::Union{Any, Missing} = missing
    primary_carrier_out::Union{Any, Missing} = missing
    carrier_out::Union{Any, Missing} = missing
    carrier_out_2::Union{Any, Missing} = missing
    carrier_out_3::Union{Any, Missing} = missing
    carrier_in::Union{Any, Missing} = missing
    carrier_in_2::Union{Any, Missing} = missing
    carrier_in_3::Union{Any, Missing} = missing
end


Base.@kwdef mutable struct Tech
    name::String
    essentials::Essential
    constraints
    costs:: Costs
    priority::Union{Any, Missing} = missing
end


struct Location
    name::String
    techs
    area::Float64
    coords::Coordinates
    #level::Int64
end

struct System
    name::String
    nodes::Array{Location}
end

Base.@kwdef mutable struct Results_locations
    name::Union{Any, Missing} = missing
    df_el::Union{Any, Missing} = missing
    df_th::Union{Any, Missing} = missing
    df_gas::Union{Any, Missing} = missing
    additional_carriers::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct Results_networks
    df_el::Union{Any, Missing} = missing
    df_th::Union{Any, Missing} = missing
    df_gas::Union{Any, Missing} = missing
end

Base.@kwdef mutable struct System_results
    name::String
    network
    nodes::Array{Results_locations}
end

Base.@kwdef mutable struct Model_configuration
    name::Union{Any, Missing} = missing
    network_electricity::Union{Any, Missing} = missing
    network_district_heating::Union{Any, Missing} = missing
    industry::Union{Any, Missing} = missing
    network_type::Union{Any, Missing} = missing
    timestep::Union{Any, Missing} = missing
    timespan::Union{Any, Missing} = missing
    temporal_interval::Union{Any, Missing} = missing
end

struct Location_post
    name
    techs
end

struct Tech_post
    name::String
    color::String
    priority::Int64
end

struct Location_srgc
    name
    srgc
end

struct  Results_economics
    location::Array{Location_srgc}
    network
end

end #module SystemStructMess
