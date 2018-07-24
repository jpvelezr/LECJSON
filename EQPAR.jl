module AAAEQPAR

    @everywhere using JSON

    @everywhere function regEqPar(Nsis,data,eventListConfig)      # Conteo de eventos y equipos en el sistema

        EqPar = []
        n = 1
        y = 0
        for i=1:Nsis-1
            if i > 1
                dataEq = data["lPLModeler:Process"]["systems"][i-1]["equipments"]
                y = y + dataEq
            end
            dataRel = data["lPLModeler:Process"]["systems"][i]["relations"]
            NSE = length(dataRel)-1                      # Numero de super equipos
            global matSupEq = Array{Any}(NSE,2)
            for j=1:length(dataRel)
                if dataRel[j]["xsi:type"] == "lPLModeler:Redundant"
                    ral = dataRel[j]["inEquipment"]
                    cantExR = Int64(round(length(ral)/27,RoundUp))
                    superEq = Array{Any}(cantExR,2)
                    for k=1:cantExR
                        superEq[k,1] = parse(Int64,ral[26+27*(k-1)]) + 1 + y
                        superEq[k,2] = 0
                        push!(EqPar,superEq[k,1])
                    end
                matSupEq[n,1] = superEq
                matSupEq[n,2] = 0
                n = n + 1
                end
            end
        end

        idEq = eventListConfig[:,13]

        for i=1:length(idEq)
            for j=1:length(EqPar)
                if idEq[i] == EqPar[j]
                    eventListConfig[i,14] = "P"
                    break
                else
                    eventListConfig[i,14] = "S"
                end
            end
        end
        return matSupEq,eventListConfig
    end
end
