clear all; clc
% DAVI ROCHA CARVALHO; ENG. ACUSTICA - UFSM; Fevereiro/2020
addpath(genpath([pwd, '\..\Functions']));
addpath([pwd, '\..\DADOS_TREINAMENTO']);

%% GENERAL INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ~ ASSEMBLE ANTHROPOMETRY FROM MULTIPLE DATABASES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Options 
% Defina quais datasets usar: {'cipic', 'ari', 'ita', '3d3a', 'riec', 'tub_sim', 'viking'}
Datasets = {'cipic', 'ari', 'ita', '3d3a'};
% Defina quais parametros de saida (Tabela CIPIC e valida para todos*)
head_torso = [1,3]; % aplicado a cipic e ari

left_ear = [1,2,3,5,7,8];    
% left_ear = [1:8];      
right_ear = [9,10,11,13,15,16];    % aplicado a cipic e ari
% right_ear = [9:16];    % aplicado a cipic e ari
% 
left_theta = [];       % aplicado a cipic e ari
right_theta = [];      % aplicado a cipic e ari

anthro = []; % inicializar save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CIPIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp('cipic', Datasets))   
    anthro_CIPIC = load('anthro_CIPIC.mat');
    % Orelhas
    d1_C = anthro_CIPIC.D(:, left_ear);
    d2_C = anthro_CIPIC.D(:, right_ear);
    t1_C = anthro_CIPIC.theta(:, left_theta);
    t2_C = anthro_CIPIC.theta(:, right_theta);

    % Cabeca e torso
    x_C = anthro_CIPIC.X(:,head_torso);

    % Concatena
    data_CIPIC(:,:,1) = [x_C, d1_C, t1_C].'; 
    data_CIPIC(:,:,2) = [x_C, d2_C, t2_C].'; 

    %%% Remor��o de indiv�duos sem antropometria   
    remove_CIPIC = any(any(isnan(data_CIPIC),1),3); % identifica quais colunas n�o possuem pelo menos uma das medidas necess�rias        
    remove_CIPIC(1) = true; % remover individuo pra posterior teste
    data_CIPIC(:,remove_CIPIC,:) = [];
    
    anthro = cat(2, [anthro, data_CIPIC]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ARI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp('ari', Datasets))
    anthro_ARI = load('anthro_ARI.mat');
    % Orelhas
    d1_A = anthro_ARI.D(:, left_ear);
    d2_A = anthro_ARI.D(:, right_ear);
    t1_A = anthro_ARI.theta(:, left_theta);
    t2_A = anthro_ARI.theta(:, right_theta);
    % Cabeca e torso
    x_A = anthro_ARI.X(:,head_torso);

    % Concatena
    data_ARI(:,:,1) = [x_A, d1_A, t1_A].'; 
    data_ARI(:,:,2) = [x_A, d2_A, t2_A].'; 

    %%% Remor��o de indiv�duos sem dados anthropom�tricos %%%   
    remove_ARI = any(any(isnan(data_ARI),1),3); % identifica quais colunas n�o possuem pelo menos uma das medidas necess�rias        
    remove_ARI([41,43,45]) = true; % remover outliers  
    data_ARI(:,remove_ARI,:) = [];
    
    anthro = cat(2, [anthro, data_ARI]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ITA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp('ita', Datasets))
    anthro_ITA = load('anthro_ITA.mat');
    d_I = anthro_ITA.D(left_ear,:); %ITA apresenta medi��es apenas para orelha esquerda
    x_I = anthro_ITA.X; % x1, x3: head width, head depth 
    ITA_anthro = [x_I; d_I];
    ITA_anthro(:,:,2) = ITA_anthro;
    % caso queira adcionar algum parametro, go to: Anthropometry_ITA.m
    % subjects 14 and 15 were removed 
    anthro = cat(2, [anthro, ITA_anthro]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3D3A %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp('3d3a', Datasets))
    anthro_D3A = load('anthro_3D3A.mat');
    d_3 = anthro_D3A.D(left_ear,:); %apresenta medi��es apenas para orelha esquerda
    x_3 = anthro_D3A.X(1:2, :); % x1, x3, x12: head width, head depth, torso width
    D3A_anthro = [x_3; d_3];
    D3A_anthro(:,:,2) = D3A_anthro;
    remove_D3A=false(length(D3A_anthro), 1);
    remove_D3A(7) = 1; 
    D3A_anthro(:,remove_D3A,:) = [];
    
    anthro = cat(2, [anthro, D3A_anthro]);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TU Berlim %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp('tub_meas', Datasets)) || any(strcmp('tub_sim', Datasets))
    anthro_TUB = load('anthro_TUB.mat');
    % Orelhas
    d1_T = anthro_TUB.D(:, left_ear);
    d2_T = anthro_TUB.D(:, right_ear);
    t1_T = anthro_TUB.theta(:, left_theta);
    t2_T = anthro_TUB.theta(:, right_theta);
    % Cabeca e torso
    x_T = anthro_TUB.X(:,head_torso);
%     x_T(:,3) = x_T(:,3)-10;
    % Concatena
    data_TUB(:,:,1) = [x_T, d1_T, t1_T].'; 
    data_TUB(:,:,2) = [x_T, d2_T, t2_T].'; 
    
    %%% Remor��o de indiv�duos sem dados anthropom�tricos %%%
    remove_TUB = any(any(isnan(data_TUB),1),3); % identifica quais colunas n�o possuem pelo menos uma das medidas necess�rias        
    remove_TUB([1,96]) = true; % remover Fabian (verifique pela geometria 3d)
    data_TUB(:,remove_TUB,:) = [];
    
    % assembly
    anthro = cat(2, [anthro, data_TUB]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% VIKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp('viking', Datasets))   
    anthro_VIKING = load('anthro_VIKING.mat');
    % Orelhas
    d1_V = anthro_VIKING.D(:, left_ear);
    d2_V = anthro_VIKING.D(:, right_ear);

    % Cabeca e torso
    x_V = anthro_VIKING.X; % x1, x3

    % Concatena
    data_VIKING(:,:,1) = [x_V, d1_V].'; 
    data_VIKING(:,:,2) = [x_V, d2_V].'; 
    
    anthro = cat(2, [anthro, data_VIKING]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SAVE
path_save = [pwd '\..\DADOS_TREINAMENTO\input'];
if any(strcmp('cipic', Datasets))
    path_save = append(path_save, '_CIPIC');
    save([pwd '\..\DADOS_TREINAMENTO\remove_CIPIC.mat'], 'remove_CIPIC')
end
if any(strcmp('ari', Datasets))
    path_save = append(path_save, '_ARI');
    save([pwd '\..\DADOS_TREINAMENTO\remove_ARI.mat'], 'remove_ARI')
end
if any(strcmp('ita', Datasets))
    path_save = append(path_save, '_ITA');
end
if any(strcmp('3d3a', Datasets))
    path_save = append(path_save, '_3D3A');
    save([pwd '\..\DADOS_TREINAMENTO\remove_D3A.mat'], 'remove_D3A')
end
if any(strcmp('riec', Datasets))
    path_save = append(path_save, '_RIEC');
end
if any(strcmp('tub_meas', Datasets))
    path_save = append(path_save, '_TUBMEAS');
    save([pwd '\..\DADOS_TREINAMENTO\remove_TUB.mat'], 'remove_TUB')
end
if any(strcmp('tub_sim', Datasets))
    path_save = append(path_save, '_TUBSIM');
    save([pwd '\..\DADOS_TREINAMENTO\remove_TUB.mat'], 'remove_TUB')
end
if any(strcmp('viking', Datasets))
    path_save = append(path_save, '_VIKING');
end


save(path_save, 'anthro')
disp('Dados Salvos!')


%%
plot(anthro(:,:,2))
