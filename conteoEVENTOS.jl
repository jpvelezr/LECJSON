module AAAConteoEVENTOS

module AAAConteoEVENTOS

    @everywhere using JSON

    @everywhere function conteo(Nsis,data)      # Conteo de eventos y equipos en el sistema

        numberEquip=0
        numberEvents=0                                # Inicialización contador de equipos
        MaxEv=0
        va1=0

        for i=1:(Nsis-1)
            va1=JSON.json(data["lPLModeler:Process"]["systems"][i]["equipments"])
            if va1[1]=='{'                  # Evalúa si el sistema tiene un solo equipo para corregir bug provocado en el arhivo JSON
                va1=string("[", va1,"]")
                dataEq=JSON.parse(va1)                    # Corrección bug, Conteo de equipos
            else
                dataEq=data["lPLModeler:Process"]["systems"][i]["equipments"]
            end
            numberEquip = length(data["lPLModeler:Process"]["systems"][i]["equipments"]) + numberEquip     # Conteo de equipos
            for j=1:length(dataEq)
                if data["lPLModeler:Process"]["systems"][i]["equipments"][j]["name"][1] != '*'
                    va1=JSON.json(dataEq[j]["events"])
                    if va1[1]=='{'          # Evalúa si el equipo tiene un solo evento para corregir bug provocado en el arhivo JSON
                        va1=string("[", va1,"]")
                        dataEv=JSON.parse(va1)
                    else
                        dataEv=dataEq[j]["events"]
                    end
                    MaxEv=maximum([length(dataEv),MaxEv])       # Máximo valor de eventos por equipo
                    numberEvents=length(dataEv)+numberEvents    # Conteo número de eventos totales
                end
            end
        end
        return MaxEv,numberEvents,numberEquip # Salidas de la función
    end
end

end
