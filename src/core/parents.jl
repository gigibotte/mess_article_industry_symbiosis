module Parents
export demand,supply,conversion,conversion_plus,storage
using Main.SystemStructMess, Main.Technologies

"""
Missing:
- complete storage parent with battery
- add air conditioner OR add it to heat pump n.b. it requires cooling demand
"""


"""
    demand(balance::Float64,tech::Tech,tt::Int64,timestep::Float64)
Function handling techs with demand as parent
"""
function demand(balance::Float64,tech::Tech,tt::Int64,timestep::Float64)

    energy = tech.constraints.resource[tt]
    balance = balance + energy

    return balance,energy
end 


"""
    supply(balance::Float64,tech::Tech,tt::Int64,timestep::Float64)
Function handling techs with supply as parent
"""
function supply(balance::Float64,tech::Tech,tt::Int64,timestep::Float64,location)

    if(tech.name == "pv")
        results_pv = Main.Technologies.pv(tech.constraints.resource_unit,
                                     tech.constraints.resource[tt,location],
                                     tech.constraints.resource_area_equals,
                                     tech.constraints.energy_cap_equals,
                                     tech.constraints.energy_eff)

        balance = balance + results_pv
        energy  = results_pv

    elseif(tech.name == "wind")
        #todo
    elseif(tech.name == "solar_thermal")
        #todo
    elseif(tech.name == "supply_grid_power")
        #todo
    elseif(tech.name == "supply_gas")
        #todo
    else

        results_custom_supply = Main.Technologies.custom_supply(balance,#Energy energy balance
                                                                tech.constraints.energy_cap_equals,   # en_rated
                                                                tech.constraints.energy_eff)
        balance = balance + results_custom_supply
        energy = results_custom_supply
        # perhaps custom supply could be another elseif called "custom" (more error-proof?)
    end

    return balance, energy
end

"""
    supply_grid(balance::Float64,tech::Tech,tt::Int64,timestep::Float64)
Function handling techs with supply_grid as parent
"""
function supply_grid(balance::Float64,tech::Tech,tt::Int64,timestep::Float64)

    if tech.name == "district_heating"
        if balance <= 0.
            energy = -balance
            balance = 0.
        else 
            energy = 0.
        end
    else
        energy = - balance
        balance = 0.
    end

    return balance,energy
end


"""
    conversion(en_balance,th_balance,tech::Tech,tt::Int64,timestep::Float64)
Function handling techs with conversion as parent
"""
function conversion(en_balance,th_balance,tech::Tech,tt::Int64,timestep::Float64)

    if(tech.name == "boiler")
        # carrin  = gas
        # carrout = heat
        results_boiler = Main.Technologies.tradboiler(th_balance,
                                                 tech.constraints.energy_cap_equals,
                                                 tech.constraints.energy_eff)

        th_balance  = th_balance + results_boiler[1]
        carrin      = results_boiler[2]
        carrout     = results_boiler[1]
    elseif(tech.name == "heat_pump")
        # carrin  = electr
        # carrout = heat
        results_heat_pump = Main.Technologies.heatpump(th_balance,
                                                  tech.constraints.energy_cap_equals,
                                                  tech.constraints.COP)

        en_balance  = en_balance + results_heat_pump[2]                                          
        th_balance  = th_balance + results_heat_pump[1]
        carrin      = results_heat_pump[2]
        carrout     = results_heat_pump[1]
    else

        # either error (name missing) or custom supply tech
        # perhaps custom supply could be another elseif called "custom" (more error-proof?)
    end

    return en_balance,th_balance,carrin,carrout
end

"""
    conversion_plus(en_balance,th_balance,tech::Tech,tt::Int64,timestep::Float64)
Function handling techs with conversion_plus as parent
"""
function conversion_plus(en_balance,th_balance,tech::Tech,tt::Int64,timestep::Float64)

    if(tech.name == "chp")
        # carrin   = gas
        # carrout1 = electricity
        # carrout2 = heat
        results_chp = Main.Technologies.tradchp(en_balance,
                                           th_balance,
                                           tech.essentials.primary_carrier_out,
                                           tech.constraints.energy_cap_equals,
                                           tech.constraints.carrier_ratios.carrier_out_2,
                                           tech.constraints.energy_eff)

        en_balance   = en_balance + results_chp[1]
        th_balance   = th_balance + results_chp[2]
        carrin       = results_chp[3]
        if(tech.essentials.primary_carrier_out == "electricity")
            carrout1     = results_chp[1]
            carrout2     = results_chp[2]
        elseif(tech.essentials.primary_carrier_out == "heat")
            carrout1     = results_chp[2]
            carrout2     = results_chp[1]

        else
            # error
        end

    else
        # either error (name missing) or custom supply tech
        # perhaps custom supply could be another elseif called "custom" (more error-proof?)
    end

    return en_balance,th_balance,carrin,carrout1,carrout2
end

"""
    storage(tech::Tech,tt::Int64)
Function handling techs with storage as parent
"""
function storage(en_balance,soc,tech::Tech,tt::Int64,timestep)

    if(tech.name == "battery")
        results_battery = Main.Technologies.battery(en_balance,
                                                    tech.constraints.storage_cap_equals,
                                                    tech.constraints.storage_cap_min,
                                                    tech.constraints.storage_cap_max,
                                                    soc,
                                                    tech.constraints.energy_eff)
        
        soc = results_battery[1]
        en_balance = results_battery[2]
        delta_battery = results_battery[3]

    else
        # either error (name missing) or custom supply tech
        # perhaps custom supply could be another elseif called "custom" (more error-proof?)
    end

    return en_balance,delta_battery,soc
end


end # module parents
