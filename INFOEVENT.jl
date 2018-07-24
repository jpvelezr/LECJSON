module AAAINFOEVENT

    @everywhere using JSON

    @everywhere function infoEvent(Nsis,data,numberEquip,MaxEv,numberEvents)      # Conteo de eventos y equipos en el sistema

        occurrences = Array{Any}(numberEquip,4*MaxEv)     #Vector de Ocurrencias de los eventos, Tiene numberEquip filas y cada fila contiene: ("Tipo de Distribución"::String Par1::Int Par2::Int Par3::Int)por cada evento del equipo
        durations = Array{Any}(numberEquip,4*MaxEv)       #Vector de duraciones de los eventos, Tiene numberEquip filas y cada fila contiene: ("Tipo de Distribución"::String Par1::Int Par2::Int Par3::Int)por cada evento del equipo
        costs = Array{Any}(numberEquip,MaxEv)
        cap = Array{Any}(numberEquip,MaxEv)           #Vector de costos de los eventos, Tiene numberEquip filas y cada fila contiene: (Costo::Int)
        types = Array{Any}(numberEquip,MaxEv)            #Vector de tipos (Ejecución o Calendario) en caso de que el evento sea un mantenimiento
        idsEv = Array{Any}(numberEvents,3)

        acu = 1           # Acumulador para guardar los parámetros en los vectores
        cont = 1

        for i=1:(Nsis-1)        # Se recorre hasta el número de sistemas
            va1 = JSON.json(data["lPLModeler:Process"]["systems"][i]["equipments"])
            if va1[1] == '{'
               va1 = string("[", va1,"]")                      # Corrección de bug
               dataEq = JSON.parse(va1)
            else
               dataEq = data["lPLModeler:Process"]["systems"][i]["equipments"]
            end
            for j=1:length(dataEq)      # Se recorre hasta el número de equipos de cada sistema
               if data["lPLModeler:Process"]["systems"][i]["equipments"][j]["name"][1] !='*'
               va1 = JSON.json(dataEq[j]["events"])
               if va1[1] == '{'
                   va1 = string("[", va1,"]")                # Corrección de bug
                   dataEv = JSON.parse(va1)
               else
                   dataEv = dataEq[j]["events"]
               end                                     # Se recorre hasta el número de eventos de cada equipo de cada sistema
               for k=1:length(dataEv)
                   # Almacenamiento de ocurrencias de eventos
                   if dataEv[k]["xsi:type"] == "lPLModeler:Maintenance"      # Si el evento es un mantenimiento
                       occurrences[j,acu] = "C";
                       occurrences[j,acu+1] = dataEv[k]["occurrence"]["time"];
                       occurrences[j,acu+2] = 0.0;
                       occurrences[j,acu+3] = 0.0;
                       types[j,k] = dataEv[k]["type"];      #Si el evento es de tipo Falla, se evalúan los tipos de distibuciones de probabilidad de la ocurrencia y se asignan los valores según corresponda.
                   elseif dataEv[k]["xsi:type"] == "lPLModeler:Failure"
                       if dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:Normal" # Si el evento tiene distribución Normal
                           occurrences[j,acu] = "N";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["mu"];
                           occurrences[j,acu+2] = dataEv[k]["occurrence"]["sigma"] ;
                           occurrences[j,acu+3] = 0.0;
                       elseif dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:Weibull" # Si el evento tiene distribución Weibull
                           occurrences[j,acu] = "W";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["beta"];
                           occurrences[j,acu+2] = dataEv[k]["occurrence"]["eta"];
                           occurrences[j,acu+3] = 0.0;
                       elseif dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:UniformTriangular" # Si el evento tiene distribución Triangular Uniforme
                           occurrences[j,acu] = "P";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["P1"];
                           occurrences[j,acu+2] = dataEv[k]["occurrence"]["P2"];
                           occurrences[j,acu+3] = 0.0;
                       elseif dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:LogNormal" # Si el evento tiene distribución LogNormal
                           occurrences[j,acu] = "L";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["mu"];
                           occurrences[j,acu+2] = dataEv[k]["occurrence"]["sigma"];
                           occurrences[j,acu+3] = 0.0;
                       elseif dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:constant" # Si el evento es constantte
                           occurrences[j,acu] = "C";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["time"];
                           occurrences[j,acu+2] = 0.0;
                           occurrences[j,acu+3] = 0.0;
                       elseif dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:Triangular" # Si el evento tiene distribución Triangular
                           occurrences[j,acu] = "T";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["P1"];
                           occurrences[j,acu+2] == dataEv[k]["occurrence"]["P2"];
                           occurrences[j,acu+3] == dataEv[k]["occurrence"]["Pm"];
                       elseif dataEv[k]["occurrence"]["xsi:type"] == "lPLModeler:Exponential" # Si el evento tiene distribución Exponencial
                           occurrences[j,acu] = "E";
                           occurrences[j,acu+1] = dataEv[k]["occurrence"]["theta"];
                           occurrences[j,acu+2] = 0.0;
                           occurrences[j,acu+3] = 0.0;
                       end
                   end
                   # Almacenamiento de duraciones de eventos
                   if dataEv[k]["duration"]["xsi:type"] == "lPLModeler:Normal" # Si el evento tiene distribución Normal
                       durations[j,acu] = "N";
                       durations[j,acu+1] = dataEv[k]["duration"]["mu"];
                       durations[j,acu+2] = dataEv[k]["duration"]["sigma"];
                       durations[j,acu+3] = 0.0;
                   elseif dataEv[k]["duration"]["xsi:type"] == "lPLModeler:Weibull" # Si el evento tiene distribución Weibull
                       durations[j,acu] = "W";
                       durations[j,acu+1] = dataEv[k]["duration"]["beta"];
                       durations[j,acu+2] = dataEv[k]["duration"]["eta"];
                       durations[j,acu+3] = 0.0;
                   elseif dataEv[k]["duration"]["xsi:type"] == "lPLModeler:UniformTriangular" # Si el evento tiene distribución Triangular Uniforme
                       durations[j,acu] = "P";
                       durations[j,acu+1] = dataEv[k]["duration"]["P1"];
                       durations[j,acu+2] = dataEv[k]["duration"]["P2"];
                       durations[j,acu+3] = 0.0;
                   elseif dataEv[k]["duration"]["xsi:type"] == "lPLModeler:LogNormal" # Si el evento tiene distribución LogNormal
                       durations[j,acu] = "L";
                       durations[j,acu+1] = dataEv[k]["duration"]["mu"];
                       durations[j,acu+2] = dataEv[k]["duration"]["sigma"];
                       durations[j,acu+3] = 0.0;
                   elseif dataEv[k]["duration"]["xsi:type"] == "lPLModeler:Constant" # Si el evento tiene distribución constante
                       durations[j,acu] = "C";
                       durations[j,acu+1] = dataEv[k]["duration"]["time"];
                       durations[j,acu+2] = 0.0;
                       durations[j,acu+3] = 0.0;
                   elseif dataEv[k]["duration"]["xsi:type"] == "lPLModeler:Triangular" # Si el evento tiene distribución Triangular
                       durations[j,acu] = "T";
                       durations[j,acu+1] = dataEv[k]["duration"]["P1"];
                       durations[j,acu+2] = dataEv[k]["duration"]["P2"];
                       durations[j,acu+3] = dataEv[k]["duration"]["Pm"];
                   elseif dataEv[k]["duration"]["xsi:type"] == "lPLModeler:Exponential" # Si el evento tiene distribución Exponencial
                       durations[j,acu] = "E";
                       durations[j,acu+1] = dataEv[k]["duration"]["theta"];
                       durations[j,acu+2] = 0.0;
                       durations[j,acu+3] = 0.0;
                   end
                   costs[j,k] = dataEv[k]["cost"]
                   cap[j,k] = dataEv[k]["performance"]
                   idsEv[cont,1] = i-1
                   idsEv[cont,2] = j-1
                   idsEv[cont,3] = k-1
                   cont = cont + 1
                   acu = acu + 4;      # Aumento del contador para asignar los parámetros de un nuevo evento.
               end
               acu = 1;          # Reinicio del acumulador para un nuevo equipo
               end
            end
        end
        return occurrences, types, durations, costs, cap, idsEv
    end
end
