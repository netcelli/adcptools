function [outx,outy,outz]=depthADCP(inadcp,varargin)
%DEPTHADCP determines position of detected bottom of the four ADCP beams
%         [Dx, Dy, Dz]=depthADCP(INADCP) reads the structure INADCP (as
%         generated by readadcp2) and returns the x,y and z offsets with
%         respect to the ADCP of the detected bottom for each beam. The
%         size of Dx, Dy and Dz is [1,Number of ensembles, 4 (beams)]
%         
%         INADCP is a adcp structure as generated by readadcp2
%
%         [Dx, Dy, Dz]=depthADCP(INADCP, 'PropertyName',PropertyValue) 
%         allows to specify the following additional settings:
%
%         TransdDepth
%         A numerical value indicating the depth of the transducer (in m)
%

%    Copyright 2009-2010 Bart Vermeulen, Maximiliano Sassi
%
%    This file is part of ADCPTools.
%
%    ADCPTools is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    ADCPTools is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with ADCPTools.  If not, see <http://www.gnu.org/licenses/>.


%         Last edit:  12-10-2010, allow pitch and roll to be as high as 40
%                     degrees
%
%         Last edit:  17-08-2010, calculation of pitch from raw tilts moved
%                     such that it's calculated before 180 degrees is added
%                     to the roll for upward looking case



%        Last edit: 06-07-2009
           

%% Handling input
%Creating an input parser
P=inputParser;
P.addRequired('inadcp',@isstruct)
P.addParamValue('TransdDepth',double(inadcp.depthtransd)/10,@(x) isnumeric(x) && x>=0)              % Offset to correct for the depth of the transducer
% P.addParamValue('IsUpward',false,@(x) islogical(x) && numel(x)==1)
P.addParamValue('Beam3misalign',getExtMisalign(inadcp),@isnumeric)         % Misalignment in degrees (wind directions, only necessary with ext. heading)
P.addParamValue('UseExtHeading',false,@islogical)                                                   % flag whether to use external heading or not
P.addParamValue('UseExtDepth',false,@islogical)                                                     % flag whether to use external depth or not
P.addParamValue('ExtDepthPitch',0,@isnumeric)
% P.addParamValue('DistCentreStar',0,@isnumeric)                                                       % Distance of the ADCP from the back-front axis of the boat
% P.addParamValue('DistCentreFwd',0,@isnumeric)                                                        % Distance of the ADCP from the axis of the boat 
% P.addParamValue('UseBtOffset',false,@islogical)
P.parse(inadcp,varargin{:})

%Getting input from Parser
TDepth=P.Results.TransdDepth;
if any(strcmpi(P.UsingDefaults,'TransdDepth'))
    TDepth=repmat(TDepth,[4 1]);
end

Beam3mis=P.Results.Beam3misalign;
ExtH=P.Results.UseExtHeading;
ExtD=P.Results.UseExtDepth;
ExtDpitch=P.Results.ExtDepthPitch;
% DistCentreStar=P.Results.DistCentreStar;
% DistCentreFwd=P.Results.DistCentreFwd;
% fBtOffset=P.Results.UseBtOffset;
% IsUpward=P.Results.IsUpward;
%Delete inpute parser
clear P

%% Change angles to radians and remove invalid angles
if ExtH
    heading=getADCPHeading(inadcp)';                                        %Read heading from external sensor
    if isempty(heading)
        heading=double(inadcp.heading)/100;                                    %Read heading from internal sensor
    end
else
    heading=double(inadcp.heading)/100;                                    %Read heading from internal sensor
end
heading(heading>359.99)=NaN;                                               %Filter out invalid headings
if ExtH
    heading=heading+Beam3mis;                                              %Correct for misalignment (heading in data file already corrected for bias)
end
heading=heading/180*pi;                                                    %Change to radians
pitch=double(inadcp.pitch)/100/180*pi;                                     %Change pitch to radians
pitch(abs(pitch)>2*pi/9)=NaN;                                                %Filter out invalid Pitches
roll=double(inadcp.roll)/100/180*pi;                                       %Change pitch to radians
roll(abs(roll)>2*pi/9)=NaN;                                                  %Filter out invalid Pitches
pitch=atan(tan(pitch).*cos(roll));                                         %Calculate real pitch from raw pitch (see adcp cor transf manual)
% if IsUpward
%     roll=roll+pi;
% end

%% Calculate offset in vertical due to boat movements
% Determine boat pitch and roll
% cb=cosd(Beam3mis);                                                         % Get cosine of beam 3 misalignment
% sb=sind(Beam3mis);                                                         % Get sin of beam 3 misalignment
% RM=[cb, sb; -sb, cb];                                                      % Make the rotation matrix
% Broll=roll*RM(1,1)+pitch*RM(1,2);
% Bpitch=roll*RM(2,1)+pitch*RM(2,2);                                         % Calculate the roll of the boat
% BoatRollOffset=-DistCentreStar*sin(Broll);                                 % Calculate the vertical offset of the boat due to roll of the boat
% BoatPitchOffset=-DistCentreFwd*sin(Bpitch);

%% Calculate offset in vertical from vertical bt velocity
% btOffset=zeros(1,length(heading));
% if fBtOffset
%     if ~(strcmp(inadcp.corinfo(4:5),'00')) %beam
%         btvelup=double(inadcp.btvel(:,3));
%         btvelup(btvelup==-32768)=0;
%         btvelup=btvelup/1000;
%         btvelup=btvelup-mean(btvelup);
%         TimeS=datenum(inadcp.timeV);
%         TimeS=(TimeS-TimeS(1))*3600*24;
%         Dt=diff(TimeS);
%         Dt=[Dt(1);Dt];
%         btOffset=(cumsum(btvelup).*Dt)';   
%     end
% end

%% Find beam angle
switch inadcp.sysconf(9:10)
    case '00'
    bangle=15/180*pi;
    case '10'
    bangle=20/180*pi;
    case '11'
    bangle=30/180*pi;
    case '01'
    error('mapADCP:UnknownBangle','Unknown beam-angle, unable to continue');
end

%% Determine range to the bottom along each beam
D=double(inadcp.btrange)';                                                 % Transform the range into doubles
D(D==0)=NaN;                                                               % Remove all null depths
D=D/100/cos(bangle);                                                       % transform vertical range to range along the beams

%% Determine 4 vectors each pointing in the beam directions in instrument coordinates (i.e. x: from b1 to b2, y: from b4 to b3, z: to ADCP)
tbangle=tan(bangle);                                                       % Find tangent of beam angle
nens=length(inadcp.ensnum);                                                % Find number of ensembles
zz=-ones(4,nens);                                                          % make an arbitrary vertical vector of unitary length pointing downwards
xx(1,:)=zz(1,:)*tbangle; %negative                                       % Find x component of a vector pointing in direction of beam 1
xx(2,:)=-zz(2,:)*tbangle;   %positive                                       % Find x component of a vector pointing in direction of beam 2
xx(3:4,:)=zeros(2,nens);                                                   % Find x component of a vector pointing in direction of beam 3,4
yy(1:2,:)=zeros(2,nens);                                                   % Find y component of a vector pointing in direction of beam 1,2
yy(3,:)=-zz(3,:)*tbangle;  %positive                                      % Find y component of a vector pointing in direction of beam 3
yy(4,:)=zz(4,:)*tbangle;   %negative                                      % Find y component of a vector pointing in direction of beam 4
vecmagn=sqrt(xx(1)^2+yy(1)^2+zz(1)^2);                                     % Magnitude of the vectors (all the same)
% if IsUpward
%     xx=-xx;
%     zz=-zz;
% end
% 
%% Change vectors from instrument coordinates to Earth coordinates
% Find rotation matrices (see adcp coordinate transformation manual)
heading=heading(:)';
ch=cos(heading);                                                           % Cosine of the heading
sh=sin(heading);                                                           % Sine of the heading
cp=cos(pitch);                                                             % Cosine of the pitch
sp=sin(pitch);                                                             % Sine of the pitch
cr=cos(roll);                                                              % Cosine of the roll
sr=sin(roll);                                                              % Sine of the roll
M11=repmat(ch.*cr+sh.*sp.*sr,[4,1]);                                       % (1,1) component of instrument to earth coordinates matrix
M12=repmat(sh.*cp,[4,1]);                                                  % (1,2) component of instrument to earth coordinates matrix
M13=repmat(ch.*sr-sh.*sp.*cr,[4,1]);                                       % (1,3) component of instrument to earth coordinates matrix
M21=repmat(-sh.*cr+ch.*sp.*sr,[4,1]);                                      % (2,1) component of instrument to earth coordinates matrix
M22=repmat(ch.*cp,[4,1]);                                                  % (2,2) component of instrument to earth coordinates matrix
M23=repmat(-sh.*sr-ch.*sp.*cr,[4,1]);                                      % (2,3) component of instrument to earth coordinates matrix
M31=repmat(-cp.*sr,[4,1]);                                                 % (3,1) component of instrument to earth coordinates matrix
M32=repmat(sp,[4,1]);                                                      % (3,2) component of instrument to earth coordinates matrix
M33=repmat(cp.*cr,[4,1]);                                                  % (3,3) component of instrument to earth coordinates matrix
% apply rotation
xxt=xx.*M11+yy.*M12+zz.*M13;                                               % eastward (X) component of the vectors pointing in direction of the beams
yyt=xx.*M21+yy.*M22+zz.*M23;                                               % northward (Y) component of the vectors pointing in direction of the beams
zzt=xx.*M31+yy.*M32+zz.*M33;                                               % upward (z) component of the vectors pointing in direction of the beams
clear xx yy zz M*                                                          % clear transformation matrix and old components in instrument coordinates
% correct for range (multyplying by ratio of vectors and range along each
% beam
xxt=D/vecmagn.*xxt;                                                        % divide x component of vector with its length and multiply with along beam range
yyt=D/vecmagn.*yyt;                                                        % divide y component of vector with its length and multiply with along beam range
zzt=D/vecmagn.*zzt;                                                        % divide z component of vector with its length and multiply with along beam range
zzt=zzt-TDepth;                  % Correct z for offsets

%% External depth
if ExtD
    warning('depthADCP:NoExtDepthYet',['Not able to use external depth yet...',num2str(ExtDpitch)])
end
%% Output result
outx=cat(3,xxt(1,:),xxt(2,:),xxt(3,:),xxt(4,:));
outy=cat(3,yyt(1,:),yyt(2,:),yyt(3,:),yyt(4,:));
outz=cat(3,zzt(1,:),zzt(2,:),zzt(3,:),zzt(4,:));
