clc;
% Variables
Dist = 1;                       % km
Dist_m=Dist*1000;               % Convert it into meters
Dist_Log_Km= log10(Dist);       % Distance in Log Scale (for Km)
Dist_Log_Meter=log10(Dist_m);   % Distance in Log Scale (FOr meters)
Bandwidth = 10e6;                % Bandwidth in Hz
Noise_Power_density = -174;     % Noise power density in dBm/Hz
Freq = 2.6e9;      % Frequency in Hz
c = 3e8;                        % Speed of light in m/s
wavelength = c /Freq ; % Wavelength in meters
BS_height = 32;
MS_height = 1.5;
TX_height = 30;
RX_height= 1.5;
num_users = 1000;                 % Number of users
Pt_dBm = 20;                    % Transmitted power in dBm
Pt = 10^(Pt_dBm / 10) / 1000;   % Transmitted power in Watts = 
transmitter_gain = 15;          % Transmitter antenna gain in dBi
receiver_gain = 0;              % Receiver antenna gain in dBi
areaWidth= 20000;
areaHeight=10000;
Break_dist =  (4 * BS_height * MS_height * Freq ) / c ;
cell_radius = 300;

%Cell Towers Positioning
num_towers = 10; % Number of cell towers
cellTowers = zeros(num_towers, 2); % initial positions of towers
cellTowers(1, :) = [areaWidth * rand(), areaHeight * rand()]; %  first one random
calculateDistance = @(y2, y1, x2, x1) sqrt((( ...
    y2 - y1).^2)+((x2 - x1).^2));
% Placing remaining towers with sufficient spacing 
for n = 2:num_towers
    valid_position = false; % Initialize flag to check if the position is valid
    % Keep trying until a valid position is found
    while ~valid_position
        temp_x = areaWidth * rand();
        temp_y = areaHeight * rand();

        % Check distance to all existing towers
        distances = sqrt((temp_x - cellTowers(1:n-1,1)).^2 + (temp_y - cellTowers(1:n-1,2)).^2);
        
        % maintaining min distance
        if all(distances >= Dist_m)
            cellTowers(n, :) = [temp_x, temp_y];
            valid_position = true;
        end
    end
end 

% UE positioning
%UE_Position = [rand()*areaWidth, rand()*areaHeight];
UE_Position = [rand(num_users,1)*areaWidth, rand(num_users,1)*areaHeight];
% Initialize an array to hold distances
distances = zeros(size(cellTowers, 1), 1);

% Pathloss with COST 231 model

a = 3.2 * (log10(11.75)^2) - 4.97;  % Height correction factor for urban areas
Cost = @(d) 46.3 + 33.9 * log10(Freq) - 13.82 * log10(30) - a + (44.9 - 6.55 * log10(30)) * log10(distance/1000) + c;
Noise= Noise_Power_density + 10 * log10(Bandwidth);


PathLoss = zeros(size(distances)); % Initialize PathLoss
SH = zeros(size(distances));       % Initialize SHADOWING
SNR = zeros(size(distances));      % Initialize  SNR 
SNR_all = zeros(num_users, num_towers);
% Distance from the UE to each cell tower
for i = 1:size(cellTowers, 1)
    distances(i) = sqrt((UE_Position(1) - cellTowers(i, 1))^2 + (UE_Position(2) - cellTowers(i, 2))^2);
    PathLoss(i) =  Cost(distances(i));
    if (10 < distances(i)) && (distances(i)< Break_dist)

        std = 4; % when shadow fading standard deviation is 4
        SH(i) =  std .* randn(1, 1);

    elseif (Break_dist < distances(i)) && (distances(i) < 10000)

        std = 6; % when shadow fading standard deviation is 6
        SH(i) =  std .* randn(1, 1);
    end

    receiced_power = Pt_dBm + 30 + 15 - PathLoss(i) - SH(i);
    SNR(i) = receiced_power - Noise_db;
    
end


% Find UE with highest SNR for each tower
[val, ind] = max(SNR_all);
x = floor(val);
max_SNR=max(SNR);
fprintf('The tower with the highest SNR is CT %d: %.2f meters\n', i, distances(i));



% Display the distances
for i = 1:length(distances)
   fprintf('Distance from a Mobile station to Cell Tower %d: %.2f meters\n', i, distances(i));
end

for i = 1:size(UE_Position, 1)
    pos = UE_Position(i,:);
    if norm(pos) <= cell_radius
        sector = determine_sector(pos);
        disp(['User equipment ', num2str(i), ' belongs to sector ', num2str(sector)]);
    end
end

figure;
hold on; 
plot(cellTowers(:,1), cellTowers(:,2), 'r^', 'MarkerSize', 10, 'LineWidth', 2);
%plot(UE_Position(1), UE_Position(2), 'bs', 'MarkerSize', 8, 'LineWidth', 2);
plot(UE_Position(:,1), UE_Position(:,2), 'bs', 'MarkerSize', 8, 'LineWidth', 2); % Plot UEs

% Label each cell tower
for i = 1:size(cellTowers, 1)
    text(cellTowers(i,1), cellTowers(i,2), sprintf('Tower %d', i), 'VerticalAlignment','bottom', 'HorizontalAlignment','right');
end

% Plot lines/arrows from UE to each cell tower and add distance labels
for i = 1:size(cellTowers, 1)
 
    plot([UE_Position(ind(i),1), cellTowers(i,1)], [UE_Position(ind(i),2), cellTowers(i,2)], 'k--'); % Black dashed line

    
 

    mid_x = (UE_Position(ind(i),1) + cellTowers(i, 1)) / 2;
    mid_y = (UE_Position(ind(i),2) + cellTowers(i, 2)) / 2;
    
    % Add text label for distance
    text(mid_x, mid_y, sprintf('%.2f m', distances(i)), 'HorizontalAlignment', 'center');
end
 


xlim([0, areaWidth]);
ylim([0, areaHeight]); 
ylabel('Height (m)');
xlabel('Width (m)');
title('Cell Tower and UE Placement (taking the distance from one UE to the 10 towers)');
grid on;
hold off;


function sector = determine_sector(position)
    angle = atan2d(position(2), position(1));
    if -60 <= angle && angle < 60
        sector = 1;
    elseif 60 <= angle && angle < 180
        sector = 2;
    else
        sector = 3;
    end
end
