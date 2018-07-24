module AAAPARLECJSON

    @everywhere using JSON
    @everywhere using AAAConteoEVENTOS
    @everywhere using AAAINFOEVENT
    @everywhere using AAACONFEV
    @everywhere using AAAGROUPMANT
    @everywhere using AAAEQPAR

    @everywhere function LecturaJsonPar()

        global configGroupMant      # Matriz para la Optimizacion
        global costNoFlow           # Costo de lucro por flujo cesante
        global confidenceInterval   # Intervalo de confianza
        global eventListConfig      # Para la configuracion de los parametros de los eventos
        global iterations           # Número de iteaciones
        global lifeCycleTime        # Ciclo de vida
        global numberEvents         # Número de Eventos
        global numberEquip          # Número de Equipos
        global Nsis
        global data

        # Extracción de archivo JSON
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

        # Creación de la matriz de configuración de eventos [ AAACONFEV ]
        eventListConfig = configEvent(Nsis,data,numberEvents,occurrences,durations,costs,cap,idsEv)

        # Creación de la matriz de configuración de grupos de mantenimiento [ AAAGROUPMANT ]
        configGroupMant = grMant(data,idsEv,eventListConfig)

        # Creación de matriz de control de súper equipos y actualiza matriz de configuración de eventos con relación
        matSupEq = regEqPar(Nsis,data,eventListConfig)[1]
        eventListConfig = regEqPar(Nsis,data,eventListConfig)[2]
    end
end
