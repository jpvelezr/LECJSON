module AAAGROUPMANT

    @everywhere using JSON

    @everywhere function grMant(data,idsEv,eventListConfig)      # Conteo de eventos y equipos en el sistema

        cantMant = 0;

        if length(data["lPLModeler:Process"]["systems"][1]) == 9 || 1 == 1
            va3 = JSON.json(data["lPLModeler:Process"]["systems"][1]["groups"])
            if va3[1] == '{'
                va3 = string("[", va3,"]")
                dataGr = JSON.parse(va3)
            else
                dataGr = data["lPLModeler:Process"]["systems"][1]["groups"]
            end
            Ngr = length(dataGr)                   # Cantidad de grupos por sistema
            global configGroupMant = Array{Any}(Ngr,5)    # Variable que contendrá los valores de los timeos máximo, mínimo y de paso del manteniento por cada sistema.
            for i=1:Ngr
                gr = JSON.json(dataGr[i]["maintenances"])
                gr = chop(gr)
                cantMant = Int64(round(length(gr)/38,RoundUp))+cantMant # Conteo de la cantidad de mantenimientos por grupo

                configGroupMant[i,1] = i
                configGroupMant[i,2] = []
                configGroupMant[i,3] = Float64(dataGr[i]["minPer"])
                configGroupMant[i,4] = Float64(dataGr[i]["maxPer"])
                configGroupMant[i,5] = Float64(dataGr[i]["perChange"])
            end
            ids_Gr = Array{Any}(cantMant,3)
            acu = 1
            for i=1:length(dataGr)
                gr = JSON.json(dataGr[i]["maintenances"])
                gr = chop(gr)
                cantMxG = Int64(round(length(gr)/38,RoundUp)) # Conteo de la cantidad de mantenimientos por grupo
                for j=1:cantMxG
                    if (13+37*(j-1)) < length(gr)
                        # Identificadores de los Mantenimientos
                        ids_Gr[acu,1] = parse(Int64,gr[13+37*(j-1)])
                        ids_Gr[acu,2] = parse(Int64,gr[27+37*(j-1)])
                        ids_Gr[acu,3] = parse(Int64,gr[37+37*(j-1)])
                    end
                    x, y = size(idsEv)
                    for k=1:x
                        if idsEv[k, 1] == ids_Gr[acu,1] && idsEv[k, 2] == ids_Gr[acu,2] && idsEv[k, 3] == ids_Gr[acu,3]
                            push!(configGroupMant[i,2],eventListConfig[k, 11])
                        end
                    end
                    acu = acu+1
                end
            end
        end
        return configGroupMant
    end
end
