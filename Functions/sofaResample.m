function Obj = sofaResample(Obj, Fs, Nintp)
% Muda resolu��o aparente de objeto SOFA para valor especificado
% e faz zero padding para 2^nextpow2(N)

% Davi R. Carvalho @UFSM - Engenharia Acustica - Setembro/2020

%   Input Parameters:
%    Obj:        Objeto de HRTFs SOFA a ser modificado 
%    Fs:         Taxa de amostragem Objetivo
%    Nint (opcional):       Comprimento do vetor na saida, (adiciona zeros no final)

%   Output Parameters:
%     Obj_out:   Objeto de HRTFs SOFA com a taxa de amostragem Fs
%
% Matlab 2020a
%% Resample
Fs_sofa = Obj.Data.SamplingRate;
N = ceil((Fs/Fs_sofa) * size(Obj.Data.IR, 3)); % length after resample
if nargin<3 || Nintp<N
    Nintp = N;
end
zpad = zeros((Nintp - N), 1);


%% options
tx = (0:Obj.API.N-1)/Fs_sofa;
[p,q] = rat(Fs / Fs_sofa);
% normFc = .98 / max(p,q);
% order = 256 * max(p,q);
% beta = 12;
% %%% Cria um filtro via Least-square linear-phase FIR filter design
% lpFilt = firls(order, [0 normFc normFc 1],[1 1 0 0]);
% lpFilt = lpFilt .* kaiser(order+1,beta)';
% lpFilt = lpFilt / sum(lpFilt);
% % multiply by p
% lpFilt = p * lpFilt;
% Actual Resample
for k = 1:size(Obj.Data.IR, 1)
    for l = 1:size(Obj.Data.IR, 2)
%         IRpre(k, l, :) = resample(Obj.Data.IR(k, l, :),p,q,lpFilt);
        IRpre(k, l, :) = resample(squeeze(Obj.Data.IR(k, l, :)), ...
                                          tx, Fs, p,q, 'spline');
        IR(k, l, :) = [squeeze(IRpre(k, l, :)); zpad];
    end 
end
%% Output
% norm = max(abs(Obj.Data.IR));
Obj.Data.IR = IR;
% update sampling rate
Obj.Data.SamplingRate = Fs;
Obj = SOFAupdateDimensions(Obj);
end