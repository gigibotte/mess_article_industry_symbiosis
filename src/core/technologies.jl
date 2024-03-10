
module Technologies
export pv,tradchp,tradboiler,heatpump,battery,custom_supply


"""
    pv(...)
Computes the energy produced [kWh] in the given timestep
Type of calculation depends on resource_unit
"""

function pv(resource_unit::String, # resource unit of measure i.e. type of data
            resource,              # data on energy produced/area        | can be both Float64 or missing
            area,                  # pv panels area                      | can be both Float64 or missing
            en_rated,              # rated power (energy)                | can be both Float64 or missing
            efficiency::Float64)   # pv panels overall efficiency (conversion + inverter)

    if(resource_unit == "energy")
        energy = resource
    elseif(resource_unit == "energy_per_area")

        # if() - check that name columns exists
        # error type throw(WrongEssentialLevel("Wrong essential name declared"))
        # + break (check if break is what is needed)

        energy = resource*area*efficiency

    elseif(resource_unit == "energy_per_cap")
        energy = resource*en_rated*efficiency

    else
        # error
    end

    return energy
end


"""
    tradchp(...)
Computes electrical and thermal energy produced [kWh] and energy consumption [kWh]
Electricity-match mode, heat-match mode to be added
"""

function tradchp(en_balance::Float64,         # electrical energy balance
                 th_balance::Float64,         # thermal energy balance
                 primary_carrier_out::String, # primary carrier out i.e. working mode
                 en_rated,           # rated power (energy)
                 ratio::Float64,              # primary carrier/secondary carrier ratio
                 efficiency::Float64)         # primary carrier efficiency

    # if heat-match mode en_rated is still electrical power?
    en_min = 0.
    en_max = en_rated

    if(primary_carrier_out == "electricity") # electricity-match mode
        if(en_balance >= 0.)
            energy = 0.
        elseif(en_balance < 0. && (-en_balance) < en_max)
            energy = -en_balance
        elseif(en_balance < 0. && (-en_balance) >= en_max)
            energy = en_max
        else
            # internal error
        end
        heat = energy*ratio
        consump = energy/efficiency
    elseif(primary_carrier_out == "heat") # to do - heat-match mode
    else
        # error
    end

    return energy,heat,consump

end # function tradchp


"""
    tradboiler(...)
Computes heat produced and gas consumption [kWh] in the given timestep
"""

function tradboiler(th_balance::Float64, # thermal energy balance
                    en_rated,   # rated power (energy)
                    efficiency::Float64) # boiler efficiency

    en_min = 0.
    en_max = en_rated

    if(th_balance >= 0.)
        heat = 0.
    elseif(th_balance < 0. && (-th_balance) < en_max)
        heat = -(th_balance)
    elseif(th_balance < 0. && (-th_balance) >= en_max)
        heat = en_max
    else
        # internal error
    end

    consump = heat/efficiency

    return heat,consump

end # function tradboiler


"""
    heatpump(...)
Computes heat produced and electricity consumption [kWh] in the given timestep
"""
function heatpump(th_balance::Float64, # thermal energy balance
                  en_rated::Float64,   # rated power (energy)
                  COP::Float64)        # COP
    en_min = 0.
    en_max = en_rated

    if(th_balance >= 0.)
        heat = 0.
    elseif(th_balance < 0. && (-th_balance) < en_max)
        heat = -(th_balance)
    elseif(th_balance < 0. && (-th_balance) >= en_max)
        heat = en_max
    else
        # internal error
    end
    consump = heat/COP

    return heat,-consump

end # function heatpump

#testing heatpump

#th_balance = -24.0
#en_rated = 15.0
#COP = 4.0

#results = heatpump(th_balance,en_rated,COP)


"""
    battery(...)
Updates electrical energy balance and SoC, computes delta energy
Working mode: charging if positive balance and room in the battery
discharging if negative balance and energy available
"""
function battery(en_balance::Float64,        # electrical energy balance
                 capacity_rated::Float64,    # battery capacity
                 soc_min::Float64,           # min state of charge i.e. max degree of discharge
                 soc_max::Float64,           # max state of charge
                 soc::Float64,               # initial soc (previous timestep)
                 efficiency::Float64)        # charging = discharging efficiencies


    if(capacity_rated == 0.)   # handling the case where capacity = 0
        soc = 0.
        delta_battery = 0.
        @goto outfromhere
    else
    end

    capacity       = capacity_rated             # capacity /= nominal capacity if SoH is introduced
    charge_initial = capacity*soc               # [kWh] Charge at beginning if timestep


    if(en_balance >= 0.) # More energy produced than consumed -> Battery charging or selling (if full)

        level_charge = charge_initial + en_balance*efficiency # [kWh] Temp battery charge level, might be > Capacity*SoCmax

        if(level_charge > (soc_max*capacity)) # Battery charging until full, en_balance is what is left (eg to be sold)
            en_balance = (level_charge - soc_max*capacity)/efficiency
            level_charge     =  soc_max*capacity
        else # Battery charging
            en_balance =  0.
        end
        
        # Energy Accumulated = charging = delta_battery<0
        delta_battery = (charge_initial - level_charge)/efficiency
    else # Less energy produced than consumed -> Battery discharging or buying (if empty)

        level_charge = charge_initial + en_balance/efficiency # [kWh] Temp battery charge level, might be < Capacity*SoCmin

        if(level_charge < (soc_min*capacity)) # Battery discharging until empty, then buying deltaProdDem
            en_balance = (level_charge - soc_min*capacity)*efficiency
            level_charge     =  soc_min*capacity
        else # Battery discharging
            en_balance =  0.
        end

        # Energy Released = discharging = delta_battery>0
        delta_battery = (charge_initial - level_charge)*efficiency
    end

    # Final state of charge
    soc = level_charge/capacity




    @label outfromhere
    return soc,en_balance,delta_battery

end # function battery

"""
    custom_supply(...)
Computes heat produced and gas consumption [kWh] in the given timestep
"""

function custom_supply(en_balance:: Float64, #Energy balance
                    en_rated,   # en_rated
                    efficiency::Float64
                    ) 
    
    en_min = 0.
    en_max = en_rated*efficiency
    if(en_balance >= 0.)
            energy = 0.
    elseif(en_balance < 0. && (-en_balance) < en_max)
            energy = -(en_balance)
    elseif(en_balance < 0. && (-en_balance) >= en_max)
            energy = en_max
    end
    

    return energy

end # custom supply

end # module technologies_new


# testing technologies

# en_balance = -10.
# capacity_rated = 5.
# soc_min = 0.2
# soc_max = 0.95
# soc = 0.5
# efficiency = 0.95
#
# results = battery(en_balance,capacity_rated,soc_min,soc_max,soc,efficiency)
