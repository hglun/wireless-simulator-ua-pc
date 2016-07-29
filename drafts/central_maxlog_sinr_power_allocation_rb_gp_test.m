function [power_allocation_matrix, sinr_matrix] = central_maxlog_sinr_power_allocation_rb_gp_test(netconfig, pathloss_matrix, BS)
% Maximize total SINR in a downlink multi-cell network
% Centralized approach

total_nb_users=netconfig.total_nb_users;
nb_sectors=netconfig.nb_sectors;
nb_RBs=netconfig.nb_RBs;
max_power_per_sector=netconfig.max_power_per_sector;
noise_density=netconfig.noise_density;

% Geometric programming formulation of the problem
cvx_begin gp
cvx_solver mosek
% variables are power levels
variable power_allocation_matrix(nb_sectors,nb_RBs)
variable sinr(total_nb_users,nb_sectors,nb_RBs)

expression objective

for j=1:nb_sectors
    for i=BS(j).attached_users
        for k=1:nb_RBs
            interference_mask = eye(nb_sectors,nb_sectors);
            interference_mask(j,j) = 0;
        end
    end
end

for j=1:nb_sectors
    for i=BS(j).attached_users
        for k=1:nb_RBs
            objective = objective + log(log(sinr(i,j,k))+0.00001);
        end
    end
end
maximize(objective)

subject to
% constraints are power limits for each BS
for j=1:nb_sectors
    sum(power_allocation_matrix(j,:)) <= max_power_per_sector;
end  
power_allocation_matrix <= 20;

for j=1:nb_sectors
    for i=BS(j).attached_users
        for k=1:nb_RBs
            sinr(i,j,k) <= (power_allocation_matrix(j,k)*pathloss_matrix(i,j,k))/(noise_density + power_allocation_matrix(:,k)'*interference_mask*pathloss_matrix(i,:,k)');
        end
    end
end
cvx_end
sinr_matrix = sinr
power_allocation_matrix