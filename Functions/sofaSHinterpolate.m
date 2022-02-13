% SOFA HRTF INTERPOLATATION USING SPHERICAL HARMONICS
function  Obj = sofaSHinterpolate(IR, pos, varargin)
% INTERPOLATION BASED ON SPHERICAL HARMONICS 
% MAKE SURE YOU HAVE INSTALLED THE  ITA, SUpDEq, OR THE SOFA API
% Davi Rocha Carvalho - AUG/2021
% Refereces:
% https://git.rwth-aachen.de/ita/toolbox
% https://github.com/AudioGroupCologne/SUpDEq
% https://github.com/sofacoustics/API_MO

defaultMethod = 'ITA_api';
validMethods = {'SOFA_api', 'SUPDEQ_api', 'ITA_api'};
checkMethod = @(x) any(validatestring(x,validMethods));

%Verificar entradas
p = inputParser;
addRequired(p,'IR',@isstruct);
addOptional(p,'method',defaultMethod,checkMethod)
parse(p,IR,varargin{:})

%% Genral parameters
azi = pos(:,1);
ele = pos(:,2);
fs=IR.Data.SamplingRate;
IR.GLOBAL_APIVersion=SOFAgetVersion;


if abs(IR.ReceiverPosition(3)) > 0.25 % HUTUBS measured data got this wrong
   IR.ReceiverPosition = IR.ReceiverPosition/10;
end

%% Let's interpolate!
switch p.Results.method
    case validMethods{1} % SOFA API
        %% Convert to TF
        TF=SOFAgetConventions('SimpleFreeFieldHRTF');
        TF.ListenerPosition=IR.ListenerPosition;
        TF.ListenerPosition_Type=IR.ListenerPosition_Type;
        TF.ListenerPosition_Units=IR.ListenerPosition_Units;
        TF.ListenerView=IR.ListenerView;
        TF.ListenerView_Type=IR.ListenerView_Type;
        TF.ListenerView_Units=IR.ListenerView_Units;
        TF.ListenerUp=IR.ListenerUp;
        TF.SourcePosition=IR.SourcePosition;
        TF.SourcePosition_Type=IR.SourcePosition_Type;
        TF.SourcePosition_Units=IR.SourcePosition_Units;
        TF.EmitterPosition=IR.EmitterPosition;
        TF.EmitterPosition_Type=IR.EmitterPosition_Type;
        TF.EmitterPosition_Units=IR.EmitterPosition_Units;
        TF.ReceiverPosition=IR.ReceiverPosition;
        TF.ReceiverPosition_Type=IR.ReceiverPosition_Type;
        TF.ReceiverPosition_Units=IR.ReceiverPosition_Units;

        TF.Data.Real=zeros(IR.API.M,IR.API.R,IR.API.N+1);
        TF.Data.Imag=zeros(IR.API.M,IR.API.R,IR.API.N+1);
        for ii=1:IR.API.M
          for jj=1:IR.API.R
           sp=fft(squeeze(IR.Data.IR(ii,jj,:)),2*IR.API.N); % Delay not considered!
           TF.Data.Real(ii,jj,:)=real(sp(1:IR.API.N+1,:));
           TF.Data.Imag(ii,jj,:)=imag(sp(1:IR.API.N+1,:));
          end
        end
        TF.N=(0:fs/2/IR.API.N:fs/2)';
        TF=SOFAupdateDimensions(TF);

        %% Convert to an emitter-based representation, TFE
        TFE=TF; 
        TFE.GLOBAL_SOFAConventions = 'GeneralTF-E';
        TFE.GLOBAL_DataType = 'TF-E';
        TFE.API.E=TF.API.M;
        TFE.API.M=1;
        TFE.Data=rmfield(TFE.Data,{'Real','Imag'});
        TFE.Data.Real(1,:,:,:)=shiftdim(TF.Data.Real,1); % MRN --> 1RNM --> MRNE with M=1
        TFE.API.Dimensions.Data.Real='MRNE';
        TFE.Data.Imag(1,:,:,:)=shiftdim(TF.Data.Imag,1);
        TFE.API.Dimensions.Data.Imag='MRNE';
        TFE.EmitterPosition=TF.SourcePosition;
        TFE.EmitterPosition_Type=TF.SourcePosition_Type;
        TFE.EmitterPosition_Units=TF.SourcePosition_Units;
        TFE.API.Dimensions.EmitterPosition='ECI';
        TFE.SourcePosition=[0 0 0];
        TFE.API.Dimensions.SourcePosition='IC';
        TFE=SOFAupdateDimensions(TFE);

        %% Convert to SH
        SH=TFE;
        SH.GLOBAL_SOFAConventions = 'FreeFieldHRTF';

%         Lmax=floor(sqrt(size(SH.EmitterPosition,1))-1); % Max SH order
        Lmax=floor(sqrt(size(SH.EmitterPosition,1)/2)-1); % Max SH order
        L=Lmax; % actual SH order
        [S, SH.API.E]=sph2SH(SH.EmitterPosition(:,1:2), L);

        Sinv=pinv(S);
        SH.Data.Real=zeros(1, SH.API.R, SH.API.N, SH.API.E);
        SH.Data.Imag=zeros(1, SH.API.R, SH.API.N, SH.API.E);
        for ii=1:TFE.API.R
          for jj=1:TFE.API.N
           SH.Data.Real(1,ii,jj,:)=Sinv*squeeze(TFE.Data.Real(1,ii,jj,:));
           SH.Data.Imag(1,ii,jj,:)=Sinv*squeeze(TFE.Data.Imag(1,ii,jj,:));
          end
        end
        SH.EmitterPosition=mean(SH.EmitterPosition);
        SH.EmitterPosition_Type='Spherical Harmonics';

        SH = SOFAupdateDimensions(SH);


        %% interpolate for the horizontal and median planes to SimpleFreeFieldHRTF (TF)
        TFint=TF;
        radius=IR.SourcePosition(1,3)*ones(size(ele));
        TFint.SourcePosition=[azi ele radius];
        Sint = sph2SH(TFint.SourcePosition(:,1:2), sqrt(SH.API.E)-1);
        TFint.API.M=size(Sint,1);
        TFint.Data.Real=zeros(TFint.API.M,2,TFint.API.N);
        TFint.Data.Imag=zeros(TFint.API.M,2,TFint.API.N);
        for ii=1:TFint.API.R
          for jj=1:TFint.API.N
            TFint.Data.Real(:,ii,jj)=Sint*squeeze(SH.Data.Real(1,ii,jj,:));
            TFint.Data.Imag(:,ii,jj)=Sint*squeeze(SH.Data.Imag(1,ii,jj,:));
          end
        end

        TFint = SOFAupdateDimensions(TFint);
        Obj   = SOFAconvertConventions(TFint);
        
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case validMethods{2} % SUpDEq API
        sparseHRIRdataset_SOFA = IR;
        % sparseHRIRdataset_SOFA = SOFAload('sparseHRIRdataset_L38.sofa');
        %Transform to sparseHRTFdataset struct with pre-defined samplingGrid 
        %(Lebedev grid with 38 nodes here), Nmax = 4, and FFToversize = 4.
%         Nmax = floor(sqrt(size(IR.Data.IR,1))-1);
        Nmax = floor(sqrt(size(IR.Data.IR,1)/2)-1); % Max SH order
        FFToversize = 4;
        sparseHRTFdataset = supdeq_sofa2hrtf(sparseHRIRdataset_SOFA,Nmax,[],FFToversize);
        %% (3) - Get equalization dataset (SH-coefficients)
        %The eqDataset describes the sound pressure distribution on a sphere 
        NFFT=(length(sparseHRTFdataset.HRTF_L(1,:))-1)*2;
        ear_distance = IR.ReceiverPosition(3)*2;
        
        eqDataset = supdeq_getEqDataset(35, ear_distance, NFFT, fs);
        %% (4) - Perform equalization
        %Here, the sparse HRTF dataset is equalized with the eqDataset. The
        %equalized HRTF are transformed to the SH-domain again with the maximal 
        %order N which is possible with the sparse sampling grid.
        %N and the sparse sampling grid are part of the sparseHRTFdataset struct
        sparseSamplingGrid = sparseHRTFdataset.samplingGrid;
        Nsparse = sparseHRTFdataset.Nmax;

        eqHRTFdataset = supdeq_eq(sparseHRTFdataset,eqDataset,Nsparse,...
                                  sparseSamplingGrid, 1e-8);

        % (5) - Perform de-equalization 
        %Here, the sparse equalized HRTF dataset is de-equalized with the
        %deqDataset. This is done on a dense spatial sampling grid. The results is a
        %dense HRTF/HRIR dataset. In this case, deqDataset is the same as the
        %eqDataset...

        %First, define dense spatial sampling grid. 
        des_pos = [azi, ele]; % sofa style 
        des_pos(:,2) = 90-des_pos(:,2); % supdeq style
        denseSamplingGrid = des_pos;
        % denseSamplingGrid = supdeq_lebedev(2702);
        Ndense = Nmax;

        %Perform de-equalization. Apply head and tail window (8 and 32 samples
        %respectively) to de-equalized HRIRs/HRTFs.
        [~, denseHRIRdataset, ~] = ...
            supdeq_deq(eqHRTFdataset, eqDataset, Ndense,...
            denseSamplingGrid);


        % (6) - Optional: Save as SOFA object
        Obj = supdeq_writeSOFAobj(denseHRIRdataset.HRIR_L,...
                                  denseHRIRdataset.HRIR_R,...
                                  denseSamplingGrid,...
                                  fs);
                              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                             
    case validMethods{3} % ITA API       
        this = SOFA2itaHRTF(IR); % convert SOFA to itaHRTF 
        
        % Generate high density objective grid 
        radius = this.dirCoord.r(1);
%         out_pos = equiangular_coordinates(1, radius);
%         out_pos = unique([out_pos; IR.SourcePosition], 'rows');
        
        % Create ita coordinates object
        coords = itaCoordinates(size(pos,1));
        coords.phi_deg = pos(:,1);
        coords.theta_deg = pos(:,2)+90;
        coords.r = ones(length(pos),1)*radius;
        
        % Interpolate 
        headr = abs(IR.ReceiverPosition(3));
        
        % Select SH order: for this to work you need to relax the order
        % requirements at the function itaHRTF.interp       
        if min(IR.SourcePosition(:,2)) < -70 
            order = ceil(sqrt(this.nDirections/2)-1);
            epsilon = 1e-8; % Tikhonov regularization coeff
        else
            order = floor(sqrt(this.nDirections/4)-1);           
            epsilon = 1e-4; % Tikhonov regularization coeff
        end
        
        cThis = ITAinterp(this, coords, 'epsilon', epsilon, 'order', order,...
                            'shiftToEar', true,...
                            'shiftOffset', [-headr, headr]);
        
        % Convert itaHRTF to SOFA    
        Obj = itaHRTF2SOFA(cThis); 
        idx_pos = dsearchn(Obj.SourcePosition(:,1:2), pos(:, 1:2));
        Obj.SourcePosition = Obj.SourcePosition(idx_pos,:);
        Obj.Data.IR = Obj.Data.IR(idx_pos,:,:);
        Obj = SOFAupdateDimensions(Obj);        
end

Obj.Data.IR = Obj.Data.IR(:,:,1:size(IR.Data.IR,3));  
end
%% summary
% SOFA_api               SUPDEQ_api                      ITA_api
% TUBmeas (ruim)      CIPIC (mais ou menos)		    CIPIC (mais ou mens)
%                                                   ARI (mais ou menos)
%                     ARI (mais ou menos)           ITA (bom)
%                     ITA (bom)                     3d3a (éeeh mais o menns)
% TUBsim (muito bom)  3d3a (éeeh mais o menns)  	TUBmeas (boom)			
%                     TUBmeas (bom)                 TUBsim(top)
%                     TUBsim (bem bom)


