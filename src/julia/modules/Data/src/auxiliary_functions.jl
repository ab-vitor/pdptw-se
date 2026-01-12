# Euclidean distance with elevation factor
function euclidean_dist(p1::Point, p2::Point, elev::Int)
    # if it is a multi-floor instance, consider the third dimension (elev == 1); 
    #    otherwise, it is a multi-island instance (elev == 0)
    d = sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2 + elev * (p1.z - p2.z)^2) 
    return round(d, digits=2)
end