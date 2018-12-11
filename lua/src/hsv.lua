local hsv do
    hsv         ={}
    local atan2 =math.atan2
    local cos   =math.cos
    local sin   =math.sin

    function hsv.fromrgb(r,b,g)
        local c=r+g+b
        if c<1e-4 then
            return 0,2/3,0
        else
            local p=2*(b*b+g*g+r*r-g*r-b*g-b*r)^0.5
            local h=atan2(b-g,(2*r-b-g)/3^0.5)
            local s=p/(c+p)
            local v=(c+p)/3
            return h,s,v
        end
    end

    function hsv.torgb(h,s,v)
        local r=v*(1+s*(cos(h)-1))
        local g=v*(1+s*(cos(h-2.09439)-1))
        local b=v*(1+s*(cos(h+2.09439)-1))
        return r,g,b
    end

    function hsv.tween(h0,s0,v0,h1,s1,v1,t)
        local dh=(h1-h0+3.14159)%6.28318-3.14159
        local h=h0+t*dh
        local s=s0+t*(s1-s0)
        local v=v0+t*(v1-v0)
        return h,s,v
    end
end

return hsv
