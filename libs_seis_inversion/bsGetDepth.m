function depth = bsGetDepth(vp, dt)
    depth = zeros(size(vp));
    
    depth(1, :) = 1000;
    for i = 2 : size(vp, 1)
        depth(i, :) = depth(i-1, :) + 0.001*0.5*dt*vp(i, :);
    end
end
