function [CL,CD,CDprof,CDi,CDw, CDbody] = SolverA(A,avlfilename,af1,af2,V,M,rho,dynamic_viscocity,AR,epsilon,lambda) % �ngulos en grados
    Nb = 24;
    Sections = 8;
    
    [ wingData, S, CL, CDi ] = runAVLa(avlfilename,A);
    Cdsprof = zeros(length(Sections),1);

    for i=1:Sections
        airfoil = interpolateAirfoils(Sections-1,i-1,af1,af2);
        Cl = wingData(1).strip{1,i*(Nb/Sections)}.cl;
        c = wingData(1).strip{1,i*(Nb/Sections)}.Chord;
        Cdsprof(i) = stage2iter(Cl,M,V,rho,dynamic_viscocity,c,A,lambda,epsilon,airfoil)
    end
    
    for i=1:length(Cdsprof) % Resolver Convergencia
        airfoil = interpolateAirfoils(Sections-1,i-1,af1,af2);
        if Cdsprof(i) < 0
            if i ~= 1 && i ~= length(Cdsprof)
                Cl1 = wingData(1).strip{1,(i*(Nb/Sections))-1}.cl;
                c1 = wingData(1).strip{1,(i*(Nb/Sections))-1}.Chord;
                Cd1 = stage2iter(Cl1,M,V,rho,dynamic_viscocity,c1,A,lambda,epsilon,airfoil);
                Cl2 = wingData(1).strip{1,(i*(Nb/Sections))+1}.cl;
                c2 = wingData(1).strip{1,(i*(Nb/Sections))+1}.Chord;
                Cd2 = stage2iter(Cl2,M,V,rho,dynamic_viscocity,c2,A,lambda,epsilon,airfoil);
                Cdsprof(i) = (Cd1 + Cd2)/2;
            elseif i == length(Cdsprof)
                Cl = wingData(1).strip{1,(i*(Nb/Sections))-1}.cl;
                c = wingData(1).strip{1,(i*(Nb/Sections))-1}.Chord;
                Cdsprof(i) = stage2iter(Cl,M,V,rho,dynamic_viscocity,c,A,lambda,epsilon,airfoil);
            else
                Cl = wingData(1).strip{1,(i*(Nb/Sections))+1}.cl;
                c = wingData(1).strip{1,(i*(Nb/Sections))+1}.Chord;
                Cdsprof(i) = stage2iter(Cl,M,V,rho,dynamic_viscocity,c,A,lambda,epsilon,airfoil);
            end
        end
    end
    
    for i=1:length(Cdsprof) % "Resolver" Convergencia
        if Cdsprof(i) < 0
            if i ~= 1
                Cdsprof(i) = Cdsprof(i-1);
            else
                if Cdsprof(i+1) > 0
                    Cdsprof(i) = Cdsprof(i+1);
                elseif Cdsprof(i+2) > 0
                    Cdsprof(i) = Cdsprof(i+2);
                end
            end
        end
    end
    Cdsprof
    
    cs = zeros(1,Sections);
    for i=1:Sections, cs(1,i) = wingData(1).strip{1,i*(Nb/Sections)}.Chord; end
    CDprof = 2*trapz(sqrt(AR*S).*(1:Sections)/Sections,cs.*Cdsprof)/S;
    
    % Extra Drag Homework
    
    t = .1396; % espesor del perfil
    ka = 0.87; % factor de johrn
    CDw = WaveDrag(M,t,CL,lambda*pi/180,ka);
    l = 24; %m
    d = 3; %m
    Swet = l*d*pi;
    FF = 1+1.5/(l/d)^1.5+7/(l/d)^3; % factor forma fuselaje
    ReBody = rho*V*l/dynamic_viscocity;
    CF = 0.455*(log10(ReBody))^-2.58; % Coeficiente de fricci�n de placa plana en flujo turbulento
    CDbody = CF*FF*Swet/S;
    
    CD = CDi + CDprof + CDw + CDbody;
end