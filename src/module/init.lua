--// Services
local HttpService = game:GetService("HttpService")

--// Variables
local rateQueue = {}
local rateQueues = setmetatable({}, {__mode = "v"})
local Process: {new: (handler: func, ...any) -> Process}
local Waitter: {new: (id: string?) -> Waitter}

-- //===================================\\
-- ||          CLASS - PROCESS          ||
-- \\===================================//
do
    --// Variables
    local process = {}
    local void = (function()end)()

    --// Functions
    local function safeLen(t: {any}): number
        local n=0;for _,_ in pairs(t)do n+=1;end;return(n)
    end

    local function resolve(process, pipeline)
        local handler, args, status = table.unpack(pipeline)

        if status == nil or process.__lastResult[1] == status then
            local results

            if safeLen(args) > 0 then
                results = {pcall(handler, table.unpack(args), table.unpack(process.__lastResult[2] or {}))}
            else
                results = {pcall(handler, table.unpack(process.__lastResult[2] or {}))}
            end

            process.__lastResult[1] = table.remove(results, 1)
            process.__lastResult[2] = results
        end
    end

    local function executeProcess(process)
        process.status = "running"

        local results = {pcall(process.handler, table.unpack(process.arguments))}
        local success = table.remove(results, 1)

        process.__lastResult[1] = success
        process.__lastResult[2] = results

        while #process.__pipelines > 0 do
            local pipeline = table.remove(process.__pipelines, 1)

            resolve(process, pipeline)
        end

        process.status = "completed"
        process.__pipelines = void

        while #process.__awaits > 0 do
            task.defer(table.remove(process.__awaits, 1))
        end

        process.__awaits = void
    end

    function process:__index(key: string)
        if key == "success" then
            return self.__lastResult[1] == true
        elseif key ~= "new" then
            local method = rawget(process, key)

            if type(method) == "function" then
                return method
            end
        end
    end

    function process:hasError()
        if self.status ~= "completed" then
            self:await()
        end

        if not self.__lastResult[1] then
            return self.__lastResult[2][1]
        end

        return false
    end

    function process:getResults()
        if self.status ~= "completed" then
            self:await()
        end

        local errorMsg = self:hasError()

        if errorMsg then
            return error(errorMsg, 2)
        else
            return table.unpack(self.__lastResult[2])
        end
    end

    function process:getResultTable()
        if self.status ~= "completed" then
            self:await()
        end
        
        local errorMsg = self:hasError()

        if errorMsg then
            return error(errorMsg, 2)
        else
            return self.__lastResult[2]
        end
    end

    function process:andThen(handler: func, ...)
        if self.status ~= "completed" then
            table.insert(self.__pipelines, {handler, {...}, true})
        else
            task.defer(resolve, {handler, {...}, true})
        end

        return self
    end

    function process:catch(handler: func, ...)
        if self.status ~= "completed" then
            table.insert(self.__pipelines, {handler, {...}, false})
        else
            task.defer(resolve, {handler, {...}, false})
        end

        return self
    end

    function process:finally(handler: func, ...)
        if self.status ~= "completed" then
            table.insert(self.__pipelines, {handler, {...}})
        else
            task.defer(resolve, {handler, {...}})
        end

        return self
    end

    function process:execute()
        if self.status == "pending" then
            self.__execution = task.defer(executeProcess, self)
        end
    end

    function process:await()
        if self.status ~= "completed" then
            table.insert(self.__awaits, coroutine.running())
            coroutine.yield()
        end

        return self
    end

    function process.new(handler: func, ...)
        local object = {
            id = HttpService:GenerateGUID(false);
            handler = handler;
            arguments = {...};
            status = "pending";

            __awaits = {};
            __pipelines = {};
            __lastResult = {};
        }

        return setmetatable(object, process)
    end

    Process = table.freeze(setmetatable(process, {__call = function(_, ...) return process.new(...) end}))
end

-- //===================================\\
-- ||          CLASS - WAITTER          ||
-- \\===================================//
do
    local waitter = {}
    local waitters: {[string]: Waitter} = setmetatable({}, {__mode = "v"})

    waitter.waitters = waitters

    function waitter:__index(key)
        if key == "Destroy" then
            return rawget(waitter, "destroy")
        elseif key ~= "__index" then
            local alternative = rawget(waitter, key)

            if alternative and typeof(alternative) == "function" then
                return alternative
            end
        end
    end

    function waitter.new(id: string?)
        local id = id or HttpService:GenerateGUID(false)

        if not waitters[id] then
            local waitter = setmetatable({
                id = id;
                container = {};
                __threads = {};
            }, waitter)

            waitters[id] = waitter
        end

        return waitters[id]
    end

    function waitter:insert(process: Process)
        if process.status ~= "completed" then
            table.insert(self.container, process)

            process:finally(function(...)
                local index = table.find(self.container, process)

                if index then
                    table.remove(self.container, index)
                end

                if #self.container <= 0 then
                    while #self.__threads > 0 do
                        task.defer(table.remove(self.__threads, 1))
                    end
                end

                return ...
            end)
        end

        return process
    end

    function waitter:remove(process: Process)
        return self:removeById(process.id)
    end

    function waitter:removeById(id: string)
        for index, process in ipairs(self.container) do
            if process.id == id then
                return table.remove(self.container, index)
            end
        end
    end

    function waitter:await()
        table.insert(self.__threads, coroutine.running())
        coroutine.yield()

        return self
    end

    function waitter:destroy()
        waitters[self.id] = nil
        
        while #self.__threads > 0 do
            task.defer(table.remove(self.__threads, 1))
        end

        setmetatable(self, nil)
        table.clear(self.container)
        table.clear(self.__threads)
        table.clear(self)
    end

    function waitter:executeAll()
        for _, process in ipairs(self.container) do
            process:execute()
        end

        return self
    end

    Waitter = table.freeze(setmetatable(waitter, {__call = function(_, ...) return waitter.new(...) end}))
end

--// Types
type func = (...any) -> ...any;

type constructor = {
    new: (id: string?, ratePerMinute: number?, ratePerSecond: number?) -> RateQueue;
    findById: (id: string) -> RateQueue?;
    Process: ((handler: func, ...any) -> Process) & {new: (handler: func, ...any) -> Process};
    Waitter: ((id: string?) -> Waitter) & {new: (id: string?) -> Waitter, waitters: {[string]: Waitter}};
}

export type Process = {
    id: string;
    handler: func;
    arguments: {any};
    status: "pending" | "running" | "completed";
    success: boolean?;

    await: (self: any) -> Process;
    andThen: (self: any, handler: func, ...any) -> Process;
    catch: (self: any, handler: func, ...any) -> Process;
    finally: (self: any, handler: func, ...any) -> Process;
    execute: (self: any) -> Process;

    hasError: (self: any) -> false | string;
    getResults: (self: any) -> ...any;
    getResultTable: (self: any) -> {any};
}

export type Waitter = {
    id: string;
    container: {Process};

    insert: (self: any, process: Process) -> Process;
    remove: (self: any, process: Process) -> Process?;
    removeById: (self: any, id: string) -> Process?;
    destroy: (self: any) -> ();
    await: (self: any) -> Waitter;
    executeAll: (self: any) -> Waitter;
}

export type RateQueue = {
    id: string;
    queues: {Process};
    ratePerSecond: number;
    ratePerMinute: number;

    insert: (self: any, handler: func, ...any) -> Process;
    insertFront: (self: any, handler: func, ...any) -> Process;

    remove: (self: any, process: Process) -> boolean;
    removeById: (self: any, processId: string) -> boolean;

    findProcessById: (self: any, id: string) -> Process?;
}

--// Functions
function rateQueue:__insert(isFront, handler, ...)
    local process = Process.new(handler, ...)

    if isFront then
        table.insert(self.queues, 1, process)
    else
        table.insert(self.queues, process)
    end

    if not self.__process then
        self:__activate(true)
    end

    return process
end

function rateQueue:__activate(isInternal: boolean?)
    if isInternal then
        local timeGone = tick() - self.__lastActivated

        if timeGone < (1 / self.__rate) then
            self.__process = task.delay((1 / self.__rate) - timeGone, self.__activate, self, true)
            return
        end
    end

    local process = table.remove(self.queues, 1)

    process:execute()

    self.__lastActivated = tick()
    self.__process = task.delay((1 / self.__rate), self.__activate, self, true)
end

function rateQueue:__index(key: string)
    if key == "ratePerMinute" then
        return self.__rate * 60
    elseif key == "ratePerSecond" then
        return self.__rate
    elseif key ~= "new" and key ~= "findById" and key ~= "__index" and key ~= "__newindex" then
        local method = rawget(rateQueue, key)

        if type(method) == "function" then
            return method
        end
    end
end

function rateQueue:__newindex(key: string, newValue: any)
    if key == "ratePerSecond" then
        rawset(self, "__rate", newValue)
    elseif key == "ratePerMinute" then
        rawset(self, "__rate", newValue/60)
    else
        rawset(self, key, newValue)
    end
end

function rateQueue:insert(...)
    return self:__insert(false, ...)
end

function rateQueue:insertFront(...)
    return self:__insert(true, ...)
end

function rateQueue:remove(process: Process)
    return self:removeById(process.id)
end

function rateQueue:removeById(id: string)
    for index, process in ipairs(self.queues) do
        if process.id == id then
            table.remove(process, index)
            return true
        end
    end

    return false
end

function rateQueue:findProcessById(id: string)
    for _, process in ipairs(self.queues) do
        if process.id == id then
            return process
        end
    end
end

function rateQueue.new(id: string?, ratePerMinute: number?, ratePerSecond: number?)
    local queue = {
        id = id or HttpService:GenerateGUID(false);
        queues = {};

        __rate = ratePerSecond or ratePerMinute/60;
        __lastActivated = 0;
    }

    rateQueues[queue.id] = setmetatable(queue, rateQueue)

    return queue
end

function rateQueue.findById(id: string)
    return rateQueues[id]
end

--// Set Properties
rateQueue.Process = Process
rateQueue.Waitter = Waitter
rateQueue.rateQueues = rateQueues

return table.freeze(rateQueue) :: constructor