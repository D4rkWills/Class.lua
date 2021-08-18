--[[

Class by Jp_darkuss#4806 / D4rkWills / William da Conceição Pereira
Version: 1.0
Last update: 18/08/21

]]

local Class= {} -- Main class

do
  local instance= {} --Declaring Class Object
  instance.__index= instance
  
  --Helper methods
  function getStrModel(v) --returns a object instance according to v (str) data (the meaning of v, an object)
    local model= {}
    for data in (v.."!"):gmatch("(.-)[,!]") do
      local d= {}
      
      d.name= (not data:match(":")) and data or data:reverse():match("(.-)[:]"):reverse()
      d.isPriv= (data:match("priv:")) and true or false --verifies if the data is private
      d.isGet= (data:match("get:")) and true or false  --verifies if the data is type "get"
      
      model[#model + 1]= d
    end
    return model
  end
  function linkTables(t1, t2) --link tables values
    local copy, k, v= {}, 1, 1
    
    while true do
      if not t1[k] then break end --stops when there is no value in t1[k]
      copy[k]= t1[k] --inserting t1 values into copy
      k= k + 1
    end
    while true do
      if not t2[v] then break end --stops when there is no value in t2[v]
      copy[k + v - 1]= t2[v]
      v= v + 1
    end
    
    return copy
  end
  
  -- Class config
  function instance:_new(vars) --Creates the class
    local v= getStrModel(vars or "") --getting var model
    
    for pos in next, v do
      v[pos].default= nil --creating default value adress
      v[pos].isDefaultValueSettled= false --verifies if the default value is already settled
    end
    return setmetatable({
      prototype= { --Prototype has the model of the new class
        vars= v, --getting var model
        methods= {} --Keeps methods
      }
    }, self)
  end
  
  function instance:method(name, callback) --Adds a methods into instance
    local n= getStrModel(name)[1] --gets the model of name
    
    n.callback= callback
    self.prototype.methods[#self.prototype.methods + 1]= n --New method added
    
    return self
  end
  
  function instance:static(name, callback) --declares a static function
    instance[name]= callback
    
    return self
  end
  
  function instance:setDefaultValues(...) --set default values for available vars (in order
    local args= {...}
    local k= 1
    
    for pos= 1, #self.prototype.vars do
      if not self.prototype.vars[pos].isDefaultValueSettled then --cannot change settled vars
        self.prototype.vars[pos].default= args[k]  --setting value
        self.prototype.vars[pos].isDefaultValueSettled= true --already settled
        
        k= k + 1
      end
    end
    
    return self
  end
  
  function instance:new(...) --creates an object of the class created
    local args= {...} --the args to create the object
    local vars, methods= {}, {}
    local dataAllowed= false --controls the access to private vars/methods
    local isAllMethodsSettled= false --helps on declaring methods
    local object --the new object
    
    object= setmetatable({}, {
      __index= function(_, var)  --will activate when a var is called, and verify what to do
         if vars[var] then --verifies if the var exists
           if not vars[var].isPriv then
             return vars[var].value --returns the var value of it is not private
           else
             if dataAllowed then --verifies if the order comes from the own object
               return vars[var].value
             end
           end
         end
         
         if methods[var] then  --get methods is a var
           if methods[var].isGet then
             local data --data returned
             if not methods[var].isPriv then --returns if it is not private
               dataAllowed= true --allows to use priv resource
               data= methods[var].callback(object)
               dataAllowed= false
             else
               if dataAllowed then --verifies if the order comes from the own object
                 data= methods[var].callback(object)
               end
             end
             
             return data
           end
         end
      end,
      
      __newindex= function(_, var, value) --will prevents to not turn private content to public
        if vars[var] then
          vars[var].value= value
        end
        if not isAllMethodsSettled then
          rawset(object, var, value)
        end
      end
    })
    
    for _, var in next, self.prototype.vars do --set the vars
      vars[var.name]= {
        value= (not args[_]) and var.default or args[_],
        isPriv= var.isPriv
      }
    end
    for _, method in next, self.prototype.methods do --set the methods
      methods[method.name]= {
        callback= method.callback,
        isPriv= method.isPriv,
        isGet= method.isGet
      }
      if not method.isGet then
        object[method.name]= function(...) --sets the control function
          local data --data returned
          local args= {...}
          if not methods[method.name].isPriv then --verifies if the method is private
            dataAllowed= true --allows access to priv content for the method
            data= methods[method.name].callback(object, ...)
            dataAllowed= false
          else
            if dataAllowed then --if it is allowed, runs the method
              data= methods[method.name].callback(object, ...)
            end
          end
          
          return data
        end
      end
    end
    
    isAllMethodsSettled= true
    
    return object
  end
  
  -- Main class methods
  Class.instance= instance
  
  function Class.new(vars) --Returns a Class instance
    return Class.instance:_new(vars)
  end
  function Class.extended(father, vars) --Returns a extended Class Instance
    local child= Class.new(vars)
    
    --Setting prototype
    child.prototype.vars= linkTables(father.prototype.vars, child.prototype.vars)
    child.prototype.methods= linkTables(father.prototype.methods, child.prototype.methods)
    
    --setting static functions
    for pos in next, father do
      if pos~="prototype" then
        child[pos]= father[pos]
      end
    end
    
    return child
  end 
end