function distances = tac_pairwise_distance(position)
%TAC_PAIRWISE_DISTANCE Pairwise Euclidean distances without extra toolboxes.

    dx = position(1,:).' - position(1,:);
    dy = position(2,:).' - position(2,:);
    distances = hypot(dx,dy);
end
