function stats = tac_pair_stats(position, communication_radius)
%TAC_PAIR_STATS Distance, connectivity and link statistics in one pass.

    N = size(position,2);
    dx = position(1,:).' - position(1,:);
    dy = position(2,:).' - position(2,:);
    d = hypot(dx,dy);
    d(1:N+1:end) = inf;
    nearest = min(d,[],2).';
    minimum = min(nearest);
    adjacency = d <= communication_radius;
    neighbor_max = max(sum(adjacency,2));
    link_count = sum(adjacency(:))/2;

    seen = false(1,N);
    largest = 0; component_count = 0;
    for start = 1:N
        if seen(start), continue; end
        component_count = component_count+1;
        queue = zeros(1,N);
        head = 1; tail = 1; queue(1) = start; seen(start) = true; count = 0;
        while head <= tail
            node = queue(head); head = head+1; count = count+1;
            neighbors = find(adjacency(node,:) & ~seen);
            seen(neighbors) = true;
            queue(tail+1:tail+numel(neighbors)) = neighbors;
            tail = tail+numel(neighbors);
        end
        largest = max(largest,count);
    end

    stats = struct('nearest',nearest,'minimum',minimum, ...
        'largest_component',largest,'neighbor_max',neighbor_max, ...
        'link_count',link_count,'component_count',component_count);
end
