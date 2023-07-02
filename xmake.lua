local Vec = {x=0,y=0,z=0} 

function Vec:new(x_,y_,z_)
    local n = { }
    self.__index = self  
    setmetatable(n, self)
    n.x = x_ or 0
    n.y = y_ or 0
    n.z = z_ or 0
    return n
end

function Vec:add(vec_)
    local res = Vec:new()
    res.x = self.x + vec_.x;
    res.y = self.y + vec_.y;
    res.z = self.z + vec_.z;
    return res
end

function Vec:sub(vec_)
    local res = Vec:new()
    res.x = self.x - vec_.x;
    res.y = self.y - vec_.y;
    res.z = self.z - vec_.z;
    return res
end

function Vec:mul_f(f)
    local res = Vec:new()
    res.x = self.x * f;
    res.y = self.y * f;
    res.z = self.z * f;
    return res
end

function Vec:mul_vec(vec_)
    local res = Vec:new()
    res.x = self.x * vec_.x;
    res.y = self.y * vec_.y;
    res.z = self.z * vec_.z;
    return res
end

function Vec:div(f)
    local res = Vec:new()
    res.x = self.x / f;
    res.y = self.y / f;
    res.z = self.z / f;
    return res
end

function Vec:dot(vec_)
    local res = self.x*vec_.x + self.y*vec_.y + self.z*vec_.z
    return res
end

function Vec:cross(vec_)
    local res = Vec:new()
    res.x = self.y*vec_.z - self.z*vec_.y;
    res.y = self.z*vec_.x - self.x*vec_.z;
    res.z = self.x*vec_.y - self.y*vec_.x;
    return res
end

function Vec:norm()
    local res = Vec:new()
    local f = 1.0/math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z);
    res = self:mul_f(f);
    return res
end

local Ray = {o,d} 
function Ray:new(O_,D_)
    local n = { }
    self.__index = self  
    setmetatable(n, self)
    n.o = O_ or Vec:new()
    n.d = D_ or Vec:new()
    return n
end

local Refl_t = {DIFF=1,SPEC=2,REFR=3,}

local Obj_t ={OBJ=1,LIT=2,};

local Sphere = {r,p,e,c,refl,obj_t}

function Sphere:new(r_,p_,e_,c_,refl_,obj_t_)
    local n = { }
    self.__index = self  
    setmetatable(n, self)
    n.r      = r_ or 0
    n.p      = p_ or Vec:new()
    n.e      = e_ or Vec:new()
    n.c      = c_ or Vec:new()
    n.refl_  = refl_  or Refl_t.DIFF
    n.obj_t_ = obj_t_ or Obj_t.OBJ
    return n
end

function Sphere:intersectR(ray_)
    local op = self.p:sub(ray_.o);
    local t = -1e20
    local eps = 1e-4
    local b = op:dot(ray_.d) 
    local det = b*b - op:dot(op) + self.r*self.r;

    if(det<0)then 
        return false,t
    else 
        det = math.sqrt(det)
    end

    t = b-det
    if(t>eps)then return true,t end 
    t = b+det
    if(t>eps)then return true,t end

    return false,t
end

local rs = 1e5
local spheres = 
{
    Sphere:new(rs , Vec:new(rs+1,40.8,81.6) ,   Vec:new(), Vec:new(.9647,.1,.0)    , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(rs , Vec:new(-rs+99,40.8,81.6) , Vec:new(), Vec:new(.0,.902,.0)     , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(rs , Vec:new(50,40.8,rs) ,       Vec:new(), Vec:new(0.75,0.75,0.75) , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(rs , Vec:new(50,40.8,-rs+170) ,  Vec:new(), Vec:new() ,               Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(rs , Vec:new(50,rs,81.6) ,       Vec:new(), Vec:new(0.75,0.75,0.75) , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(rs , Vec:new(50,-rs+81.6,81.6) , Vec:new(), Vec:new(0.75,0.75,0.75) , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(16.5 , Vec:new(27,16.5,47) , Vec:new(), Vec:new(0.999,0.999,0.999)  , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(16.5 , Vec:new(73,16.5,78) , Vec:new(), Vec:new(0.999,0.999,0.999)  , Refl_t.DIFF , Obj_t.OBJ),
    Sphere:new(600 , Vec:new(50,681.6-0.27,81.6) , Vec:new(12,12,12), Vec:new()    , Refl_t.DIFF , Obj_t.LIT),
}

function clamp(x)
    if(x<0.0)then x=0.0 end
    if(x>1.0)then x=1.0 end
    return x
end

function toInt(x)
    return math.floor(math.pow(clamp(x),1/2.2)*255 + 0.5)
end

function intersect(r,t,id)
    local d=-1;
    local inf=1e20
    local t = inf
    local inter
    for i=1,#spheres do
        inter,d=spheres[i]:intersectR(r)        
        if(inter and d<t)then
            t=d
            id=i
        end
    end

    if(t<inf)then inter = true end  
    return inter,t,id
end

function random()
    return math.random()
end

function radiance(r,depth,Xi)

    local inter,t,id = intersect(r,t,id);

    if(inter == false)then
        return Vec:new()
    end

    local obj = spheres[id]
    local x = (r.o):add( (r.d):mul_f(t))
    local n = x:sub(obj.p):norm()
    local f = obj.c
    local nl

    if(n:dot(r.d)<0)then 
        nl=n
    else 
        nl=Vec:new(-n.x,-n.y,-n.z)
    end

    if(obj.obj_t == Obj_t.LIT)then
        return obj.e
    end

    local p
    if(f.x>f.y and f.x>f.z)then p=f.x
    elseif(f.y>f.z)then p=f.y
    else p=f.z end

    depth = depth+1
    if(depth>5)then
        if(random() < p)then f=f:div(p)
        else return obj.e end
    end
    
    if(obj.refl == DIFF)then
        local N=1.0
        local r1 = 2.0*math.pi*random()
        local r2 = random()
        local n_z = math.sqrt(1-r2);
        local n_x = math.cos(r1)*math.sqrt(r2);
        local n_y = math.sin(r1)*math.sqrt(r2);

        local w=nl             
        local u
        if(math.abs(w.x)>0.1)then u=Vec:new(0,1,0)
        else u=Vec:new(1,0,0) end

        u=u:norm()

        local v=w:cross(u)
        local d1 = u:mul_f(n_x)
        local d2 = v:mul_f(n_y)
        local d3 = w:mul_f(n_z)
        local d12 = d2:add(d1)
        local d23 = d12:add(d3)
        local d = d23:norm()

        return obj.e:add( f:mul_vec(radiance(Ray:new(x,d),depth,Xi)) )
    end

end

local w=100
local h=100
local spp = 10
local out = {}
for i=0,w*h-1 do
    out[i] = Vec:new()
end

local str = "P3 "..w.." "..h.." 255 "

function start()
    local cam_o = Vec:new(50,52,295.6)
    local cam_d = Vec:new(0,-0.042612,-1):norm()
    local cam=Ray:new(cam_o,cam_d)
    local cx=Vec:new(w*0.5135/h,0,0)
    local cy=cx:cross(cam_d):norm():mul_f(0.5135)

    local r=Vec:new()

    for y=0,h-1 do
        for x=0,w-1 do
            local i = (h-y-1) * w + x;
            print(100.0*y/(h-1))
            for sy=0,1 do
                for sx=0,1 do
                    r = Vec:new()
                    for i=1,spp do
                        local cxd = cx:mul_f( ( (sx + 0.5 )/2 + x )/w - 0.5) 
                        local cyd = cy:mul_f( ( (sy + 0.5 )/2 + y )/h - 0.5)
                        local d = cxd:add(cyd):add(cam_d)   
                        local ray_o = cam_o:add(d:mul_f(140))  
                        r = r:add(radiance(Ray:new(ray_o, d:norm()) , 0 , 0):div(spp))
                    end                    
                    out[i] = out[i]:add(Vec:new(clamp(r.x),clamp(r.y),clamp(r.z)):mul_f(0.25))
                end
            end
            out[i] = Vec:new(toInt(out[i].x),toInt(out[i].y),toInt(out[i].z))
        end
    end

    for i=0,#out do
        str = str..(out[i].x).." "..(out[i].y).." "..(out[i].z).." "
    end

end

start()

local file = io.open ('out.ppm' ,"w")
io.output(file)
io.write(str) 
io.close()


-- target("pathtracing")
--     set_kind("binary")
--     add_files("main.cpp")





