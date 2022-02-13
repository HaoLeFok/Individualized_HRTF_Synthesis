function [itd, obj_radius] = itd_synthesis(width, depth, positions, fs, varargin)
% Sintese de ITD a partir de dimens�es da cabe�a de um indiv�duo
% Davi R. Carvalho @UFSM - Engenharia Acustica - Julho/2020

%   Input Parameters:
%    width:      Largura da cabe�a, determinada pela distancia entre orelhas
%    depth:      Profundidade da cabe�a [cm]
%    positions:  Matriz Mx2 em que M corresponde ao n�mero total de
%                posicoes, contem na primeira coluna azimutes e na seguinte
%                as elevacoes (coordenadas SOFA 0.6 ou superior)

%   Output Parameters:
%     itd:       Diferen�a interaural de tempo, para as posi��es de entrada

%   Optional Parameters:
%    'spheric':   Determina o itd para aproxima��o da cabeca a um modelo
%                 esf�rico [Kuhn com otimiza��o Savioja]
%    'adapt':     Determina o itd pela adapta��o de um itd medido em
%                 rela��o ao itd calculado a partir da antropometria do
%                 indiv�duo. O itd medido aqui utilizado refe-se ao Fabian,
%                 principalmente pela discretiza��o espacial, o que
%                 permite grande flexibilidade em rela��o as posi��es de
%                 entrada. (default)
%    'match':     Escolhe dentro do banco de dados ITA o indiv�duo com
%                 tamanho de cabe�a mais semehante ao input, e toma o itd.

%    'samples':   Determina a sa�da do itd em samples. (Default)
%    'time':      Determina a sa�da do itd em tempos.

%%% Exemplos do uso 
% itd = itd_synthesis(width, depth, positions, 'adapt', 'samples', 44100)
% itd = itd_synthesis(width, depth, positions, 'spheric', 'samples', 44100)

% Matlab R2020a
%% Parse Arguments
defaultMethod = 'adapt';
validMethods =  {'spheric', 'adapt', 'match'};
checkMethod = @(x) any(validatestring(x, validMethods));

% Op��o de sa�da em samples
defaultMode = 'samples';
validOutputs = {'samples','time'};
checkOutMode = @(x) any(validatestring(x, validOutputs));

p = inputParser;
addRequired(p,'width',@isnumeric);
addRequired(p,'depth',@isnumeric);
addRequired(p,'positions',@ismatrix);
addRequired(p,'fs',@isnumeric);
addOptional(p,'method',defaultMethod,checkMethod)
addOptional(p,'outputMode', defaultMode,checkOutMode)

parse(p,width,depth,positions,fs, varargin{:})
%% Vari�veis comuns 
% HEAD DIMENSIONS 
wid = p.Results.width;
dep = p.Results.depth;
obj_radius = 0.51*wid + 0.18*dep + 3.2; % (cm) algazi 

no_directions = length(positions); 
c0 = 343e2; %[cm/s] velocidade do som

% Azimutes
azz = p.Results.positions(:, 1); 
% naz = length(unique(round(azz)));

% Eleva��es
ell = p.Results.positions(:, 2);
% nel = length(unique(round(ell)));

%% Spheric
switch p.Results.method
    case 'spheric'
        itd(:, 1) = 3*obj_radius/(2*c0)*sind(azz).*cosd(ell);   
        
%% Adapt
    case 'adapt' 
        % selecionar posi��es correspondentes a out_pos 
%         load('KU100_itd.mat')
        load('fabian_itd.mat')
        idx_pos = dsearchn(ref_pos(:,1:2), positions(:,1:2));      
       
        % Reference Head
        itd_ref = ref_itd(idx_pos);
        ref_radius = 0.51*ref_width + 0.18*ref_depth + 3.2;

%-------%%% ADAPTAR %%%----------------------------------------------------
        itd = itd_ref .* (obj_radius/ref_radius);

        
%% Best match 
    case 'match' 
        load('DADOS_TREINAMENTO\ITD_ITA.mat', 'data')
        % Selecionar posi��es
        ita_pos = data(1).SourcePosition;
        for k = 1:length(positions)  
            [~,idx_pos(k)] = min(sqrt((ita_pos(:,1)-positions(k,1)).^2 + ...
                                      (ita_pos(:,2)-positions(k,2)).^2));
        end

        % Selecionar melhor match para dimens�es pela propor��o
        for k = 1:length(data)  
            tsqr_head(k) = (data(k).x(1)/data(k).x(2) - wid/dep);
        end
        [~,idx_head] = min(tsqr_head); 
        itd = (data(idx_head).itd(idx_pos))./44100;
end


%% Output Units
% Caso solicitada a sa�da em n�mero de samples
switch p.Results.outputMode
    case 'samples'
        itd = (itd.*p.Results.fs);
end

itd = abs(itd);
end






