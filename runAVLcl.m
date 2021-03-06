function [ Surfaces, a ] = runAVL(avlfile,cl)
    dos(['del ',avlfile,'.SF']);
    dos(['del ',avlfile,'.run']);
    fid = fopen([avlfile,'.run'], 'w');% Create run file
    fprintf(fid, 'LOAD %s\n', [avlfile,'.avl']);
    fprintf(fid, 'PLOP\ng\n\n'); %Disable Graphics
    fprintf(fid, 'OPER\n'); %Open the OPER menu
    fprintf(fid, 'a\nc %f\n', cl); %Define constraint
    fprintf(fid, '%s\n',   'x'); % Execute
    fprintf(fid, 'FS\n'); %Save the surface data
    fprintf(fid, '%s%s\n',avlfile,'.SF');
    fprintf(fid, '\nQuit\n'); 
    fclose(fid);
    [status,result] = dos(['avl.exe < ',avlfile,'.run']); % Execute run
    
    fid = fopen('temp','w');
    fprintf(fid,result);
    file = textread('temp', '%s', 'delimiter', '\n','whitespace', '');
    fclose(fid);
    dos('del temp');
    a = findValue(file,'Alpha =',[1,length(file)]);
    
    file = textread([avlfile,'.SF'], '%s', 'delimiter', '\n','whitespace', '');
    % Surfaces;
    surfIndex=1;
    i=1;
    while i<length(file)
        str = char(file(i));
        header = regexp(str, 'Surface #', 'once');
        if(~isempty(header))
            clearvars surface
            surface.name = strtrim(str(18:length(str)));
            i=i+1;
            while i<length(file)
                str = char(file(i));
                header = regexp(str, 'Strip Forces referred to Strip Area, Chord', 'once');
                if(~isempty(header))
                    i=i+2;
                    str = char(file(i));
                    j=1;
                    while(~isempty(str) && i<length(file))
                        surface.strip{j} = readLine(str);
                        j=j+1;
                        i=i+1;
                        str = char(file(i));
                    end
                    break;
                end
                i=i+1;
            end
            Surfaces(surfIndex) = surface;
            surfIndex = surfIndex+1;
        end
        i=i+1;
    end
        function [strip] = readLine(string)
            string = [string ' '];
            s2 = regexp(string, ' ', 'split');
            %j      Yle    Chord     Area     c cl      ai      cl_norm  cl
            %cd       cdv    cm_c/4    cm_LE  C.P.x/c
            [strip.j, sIndex] = readValue(s2,1);
            [strip.Yle, sIndex] = readValue(s2,sIndex+1);
            [strip.Chord, sIndex] = readValue(s2,sIndex+1);
            [strip.Area, sIndex] = readValue(s2,sIndex+1);
            [strip.ccl, sIndex] = readValue(s2,sIndex+1);
            [strip.ai, sIndex] = readValue(s2,sIndex+1);
            [strip.cl_norm, sIndex] = readValue(s2,sIndex+1);
            [strip.cl, sIndex] = readValue(s2,sIndex+1);
            [strip.cd, sIndex] = readValue(s2,sIndex+1);
            [strip.cdv, sIndex] = readValue(s2,sIndex+1);
            [strip.cm_c4, sIndex] = readValue(s2,sIndex+1);
            [strip.cm_LE, sIndex] = readValue(s2,sIndex+1);
            [strip.CPxc, sIndex] = readValue(s2,sIndex+1);
        end
        function [val,endIndex] = readValue(s2,index)
            val = 'NAN';
            while index<length(s2)
                if(length(char(s2(index)))>=1)
                    val = str2double(char(s2(index)));
                    break;
                end
                index = index+1;
            end
            endIndex = index;
        end
end