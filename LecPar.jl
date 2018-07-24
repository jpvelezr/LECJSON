module AAAPARLECJSON

    @everywhere using JSON
    @everywhere using AAAConteoEVENTOS
    @everywhere using AAAINFOEVENT

    @everywhere function LecturaJsonPar()

        global configGroupMant      # Matriz para la Optimizacion
        global costNoFlow           # Costo de lucro por flujo cesante
        global confidenceInterval   # Intervalo de confianza
        global eventListConfig      # Para la configuracion de los parametros de los eventos
        global iterations           # Numero de iteaciones
        global lifeCycleTime        # Ciclo de vida
        global numberEvents         # Numero de Eventos
        global numberEquip          # Numero de Equipos
        global Nsis
        global data

        # Extraemos el JSON
        p = 1
        if (p == 1)
            data = JSON.parsefile("/home/knar/Escritorio/Git/prueba2f.json"; dicttype=Dict, inttype=Int64, use_mmap=true) #Lectura de archivo JSON
        elseif (p == 2)
            data = JSON.parsefile("/home/knar/Escritorio/Git/json_prueba.json"; dicttype=Dict, inttype=Int64, use_mmap=true) #Lectura de archivo JSON
        else
            data = JSON.parsefile("/home/knar/Escritorio/Git/A.json"; dicttype=Dict, inttype=Int64, use_mmap=true) #Lectura de archivo JSON
        end

        # Declaraciones Globales: Número de sistemas, Tiempo de Simulación, Número de Iteraciones
        Nsis = length(data["lPLModeler:Process"]["systems"])
        iterations = data["lPLModeler:Process"]["nSimu"]
        lifeCycleTime = Float64(data["lPLModeler:Process"]["lifeCycle"])

        # Conteo de la cantidad de sistemas en el proceso
        costNoFlow = Float64(data["lPLModeler:Process"]["systems"][Nsis]["cLostFlow"])    # Costo de Lucro ded Flujo Cesante
        confidenceInterval = Float64(data["lPLModeler:Process"]["confiInterval"])         # Intervalo de Confianza

        # Inicialización de variables de conteo de equipos y eventos
        dataEv = 0
        dataEq = 0                  # Inicialización contador de eventos y equipos
        va1 = 0

        # Conteo de la cantidad de equipos y eventos de cada sistema [ AAAConteoEVENTOS ]
        MaxEv = conteo(Nsis,data)[1]
        numberEvents = conteo(Nsis,data)[2]
        numberEquip = conteo(Nsis,data)[3]

        # Extracción de información de los eventos [ AAAINFOEVENT ]
        occurrences = infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)[1]     
        types = infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)[2]
        durations = infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)[3]
        costs = infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)[4] 
        cap = infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)[5]
        idsEv = infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)[6]

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
                cantMant = Int64(round(length(gr)/38,RoundUp))+cantMant #conteo de la cantidad de mantenimientos por grupo

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
                cantMxG = Int64(round(length(gr)/38,RoundUp)) #conteo de la cantidad de mantenimientos por grupo
                for j=1:cantMxG
                    if (13+37*(j-1)) < length(gr)
                        #identificadores de los Mantenimientos
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

        global MatSupEq
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
            MatSupEq = Array{Any}(NSE,2)
            for j=1:length(dataRel)
                if dataRel[j]["xsi:type"] == "lPLModeler:Redundant"
                    ral = dataRel[j]["inEquipment"]
                    cantExR = Int64(round(length(ral)/27,RoundUp))
                    superEq = Array{Any}(cantExR,2)
                    for k=1:cantExR
                        superEq[k,1] = parse(Int64,ral[26+27*(k-1)]) + 1 + y
                        push!(EqPar,superEq[k,1])
                        superEq[k,2] = 0
                    end
                MatSupEq[n,1] = superEq
                MatSupEq[n,2] = 0
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
    end
end
