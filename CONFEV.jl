module AAACONFEV

    @everywhere using JSON

    @everywhere function configEvent(Nsis,data,numberEvents,occurrences,durations,costs,cap,idsEv)      # Conteo de eventos y equipos en el sistema

        idsRel = Array{Any}(numberEvents,3*numberEvents)
        eventListConfig = Array{Any}(numberEvents,15)
        acu = 1
        cont = 1
        acu1 = 1
        acu2 = 1
        relEv = []

        for i=1:Nsis-1
            va1 = JSON.json(data["lPLModeler:Process"]["systems"][i]["equipments"])
            if va1[1] == '{'
                va1 = string("[", va1,"]")            # Corrección "Bug#1"
                dataEq = JSON.parse(va1)
            else
                dataEq = data["lPLModeler:Process"]["systems"][i]["equipments"]
            end
            for j=1:length(dataEq)
                if data["lPLModeler:Process"]["systems"][i]["equipments"][j]["name"][1] != '*'
                    va1=JSON.json(dataEq[j]["events"])
                    if va1[1] == '{'
                        va1 = string("[", va1,"]")
                        dataEv = JSON.parse(va1)
                    else
                        dataEv = dataEq[j]["events"]
                    end
                    for k=1:length(dataEv)
                        eventListConfig[cont,1] = occurrences[j,4*(k-1)+1]
                        eventListConfig[cont,2] = Float64(occurrences[j,4*(k-1)+2])
                        eventListConfig[cont,3] = Float64(occurrences[j,4*(k-1)+3])
                        eventListConfig[cont,4] = Float64(occurrences[j,4*(k-1)+4])
                        eventListConfig[cont,5] = durations[j,4*(k-1)+1]
                        eventListConfig[cont,6] = Float64(durations[j,4*(k-1)+2])
                        eventListConfig[cont,7] = Float64(durations[j,4*(k-1)+3])
                        eventListConfig[cont,8] = Float64(durations[j,4*(k-1)+4])
                        eventListConfig[cont,9] = Float64(costs[j,k])
                        eventListConfig[cont,15] = Float64(cap[j,k])
                        if dataEv[k]["xsi:type"] == "lPLModeler:Maintenance"
                            eventListConfig[cont,10] = 2
                        else
                            eventListConfig[cont,10] = 1
                        end
                        eventListConfig[cont,11] = cont
                        eventListConfig[cont,13] = j
                        # La matriz se llenará a partir de los mantenimientos que tiene asociados cada falla
                        if dataEv[k]["xsi:type"] == "lPLModeler:Maintenance"
                            rel = JSON.json(dataEv[k]["failures"])
                            rel = chop(rel)
                            cantMxF = Int64(round(length(rel)/38,RoundUp))
                            for n=1:cantMxF
                                idsRel[acu,1] = i-1
                                idsRel[acu,2] = j-1
                                idsRel[acu,3] = k-1
                                if (13+37*(n-1)) < length(rel)
                                    idsRel[acu,3*n+1] = parse(Int64,rel[13+37*(n-1)])
                                    idsRel[acu,3*n+2] = parse(Int64,rel[27+37*(n-1)])     #identificadores de los Mantenimientos
                                    idsRel[acu,3*n+3] = parse(Int64,rel[37+37*(n-1)])
                                end
                                while idsRel[acu,1] != idsEv[acu1,1] || idsRel[acu,2] != idsEv[acu1,2] || idsRel[acu,3] != idsEv[acu1,3]
                                    acu1 = acu1+1;
                                end
                                while idsRel[acu,3*n+1] != idsEv[acu2,1] || idsRel[acu,3*n+2] != idsEv[acu2,2] || idsRel[acu,3*n+3] != idsEv[acu2,3]
                                    acu2 = acu2+1;
                                end
                                push!(relEv,acu2)
                                eventListConfig[acu1,12] = relEv
                                acu1 = 1
                                acu2 = 1
                            end
                            relEv = []
                            acu = acu+1;
                        else
                            eventListConfig[cont,12] = cont
                        end
                        cont = cont+1
                    end
                end
            end
        end
        return eventListConfig
    end
end
