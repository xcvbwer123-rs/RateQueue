[여기서](/src/test.server.lua) 예시 확인해볼수 있습니다.

# API
## Constructor
### Constructor.new
```lua
.new(id: string?, ratePerMinute: number?, ratePerSecond: number) -> RateQueue
```

RateQueue오브젝트를 반환합니다. id값에 아무것도 없으면 자동으로 생성됩니다.

    !!!warning
    ratePerMinute값과 ratePerSecond값중에 둘중 하나는 무조건 있어야 합니다.

### Constructor.findById
```lua
.findById(id: string) -> RateQueue?
```

생성되어있는 RateQueue오브젝트중에서 같은 id값을 가지고 있는 오브젝트를 반환합니다.

### Constructor.Process
```lua
.Process(handler, ...arguments) --> [Process]
-- hander [function]
-- arguments [any]
```

새 [Process](#process)를 생성합니다. 

    !!!warning
    해당 Process는 :execute()를 해주지 않으면 실행되지 않습니다.

### Constructor.Waitter
```lua
.Waitter(id) --> [Waitter]
-- id [string | nil]
```

해당 `id`값을 가진 새 [Waitter](#waitter)를 생성합니다. _`id`값을 따로 설정하지 않은경우 랜덤하게 설정됩니다._

## RateQueue
### RateQueue.id
```lua
RateQueue.id [string]
-- 변경할수 있으나 변경시 Constructor.findById에서 바뀐 아이디로 찾는게 불가능합니다.
```

RateQueue오브젝트의 고유 id값입니다.

### RateQueue.queues
```lua
RateQueue.queues [table]
-- Process값들이 담겨있는 리스트 형식의 테이블.
```

`RateQueue.queues`는 앞으로 처리될 [Process](#process)값들이 담겨있는 테이블입니다. 앞에 있는 Process일수록 먼저 실행됩니다.

### RateQueue.ratePerSecond
```lua
RateQueue.ratePerSecond [number]
```
`RateQueue.ratePerSecond`는 초당 실행시킬수 있는 [Process](#process)의 수를 의미합니다. 이 값을 변경할경우 [RateQueue.ratePerMinute](#ratequeuerateperminute)값도 자동으로 변경됩니다.

### RateQueue.ratePerMinute
```lua
RateQueue.ratePerMinute [number]
```
`RateQueue.ratePerMinute`는 분당 실행시킬수 있는 [Process](#process)의 수를 의미합니다. 이 값을 변경할경우 [RateQueue.ratePerMinute](#ratequeueratepersecond)값도 자동으로 변경됩니다.

### RateQueue:insert()
```lua
RateQueue:insert(hander, ...arguments) --> [Process]
-- hander [function]
-- arguments [any]
```

[RateQueue.queues](#ratequeuequeues)에 새로운 [Process](#process)값을 만들어 맨뒤에 추가하고 그 [Process](#process)값을 반환합니다.

### RateQueue:insertFront()
```lua
RateQueue:insertFront(hander, ...arguments) --> [Process]
-- hander [function]
-- arguments [any]
```

[RateQueue.queues](#ratequeuequeues)에 새로운 [Process](#process)값을 만들어 맨앞에 추가하고 그 [Process](#process)값을 반환합니다.

### RateQueue:remove()
```lua
RateQueue:remove(process) --> processFound [boolean]
-- process [Process]
```

[RateQueue.queues](#ratequeuequeues)에서 해당 [Process](#process)값을 삭제합니다. 발견했을경우 `true`를 아니면 `false`를 반환합니다.


### RateQueue:removeById()
```lua
RateQueue:remove(processId) --> processFound [boolean]
-- processId [string]
```

[RateQueue.queues](#ratequeuequeues)에서 해당 id값을 가진 [Process](#process)값을 삭제합니다. 발견했을경우 `true`를 아니면 `false`를 반환합니다.

### RateQueue:findProcessById()
```lua
RateQueue:findProcessById(processId) --> process [Process | nil]
-- processId [string]
```

[RateQueue.queues](#ratequeuequeues)에서 해당 id값을 가진 [Process](#process)값을 찾아서 반환합니다. 해당 [Process](#process)값이 없을경우 `nil`값을 반환합니다.

## Process
### Process.id
```lua
Process.id [string]
-- 변경할수 있습니다.
```

`Process`의 고유 id값입니다.

### Process.handler
```lua
Process.handler [function]
```

`Process`에서 실행할 함수입니다.

### Process.arguments
```lua
Process.arguments [table]
-- any값들이 담겨있는 리스트 형식의 테이블.
```

### Process.status
```lua
Process.status [string]
-- "pending" 또는 "running" 또는 "completed"
```

- `pending` 상태일때는 작업이 아직 시작되지 않았음을 의미합니다.

- `running` 상태일때는 현제 작업이 진행중임을 의미합니다.
 - [Process:andThen()](#processandthen)또는 [Process:catch()](#processcatch)또는 [Process:finally()](#processfinally)로 연결된 작업이 진행중일때도 `running`으로 표시됩니다.
- `completed` 상태일때는 모든 작업이 종료되었음을 의미합니다.
 - [Process:await()](#processawait)으로 연결된 thread들을 실행시키기 전에 `completed`상태로 전환됩니다.


### Process.success
```lua
Process.success [boolean | nil]
-- Process.status가 "pending"일때는 nil값을 가집니다.
```

해당 Process가 성공했는지, 아니면 실행도중 오류가 발생했는지 여부를 나타냅니다.

    !!!warning
    [Process.status](#processstatus)값이 `running`인 경우, [Process:andThen()](#processandthen)또는 [Process:catch()](#processcatch)또는 [Process:finally()](#processfinally)등을 처리하면서 `nil`값 대신 `boolean`값을 가지게 됩니다.

    !!!tip
    최종적인 값을 가지고 싶으면 [Process.status](#processstatus)가 `completed`인지 확인하세요.

### Process:await
```lua
Process:await() --> self [Process] {Chainable}
```

Process의 모든 작업이 완료될때까지 기다립니다.

### Process:andThen
```lua
Process:andThen(handler, ...arguments) --> self [Process] {Chainable}
-- handler [function] (...arguments, ...previousResult)
-- arguments [any]
```

Process의 앞 작업이 끝난뒤 오류가 발생하지 않았으면 실행되게 앞 작업에 연결합니다. `handler`에서 반환된 값은 최종 결과가 됩니다.

    !!!warning
    앞의 작업에서 오류가 발생한경우 실행되지 않습니다. 오류가 나든 안나든 최종적으로 실행시켜야 하는거라면 [Process:finally()](#processfinally)를 사용하세요.

### Process:catch
```lua
Process:catch(handler, ...arguments) --> self [Process] {Chainable}
-- handler [function] (...arguments, previousErrorMessage [string])
-- arguments [any]
```

Process의 이전 작업에서 오류가 발생한경우 `handler`가 실행되게 이전 작업들과 연결합니다. `handler`에서 반환된 값은 최종 결과가 됩니다.

### Process:finally
```lua
Process:finally(handler, ...arguments) --> self [Process] {Chainable}
-- handler [function] (...arguments, previousErrorMessage | ...previousResult)
-- arguments [any]
```

Process의 앞 작업이 끝난뒤 실행되게 앞 작업에 연결합니다. `handler`에서 반환된 값은 최종 결과가 됩니다.

### Process:execute
```lua
Process:execute() --> self [Process] {Chainable}
-- RateQueue내부에서 사용하는 메소드입니다. 외부에서 사용하는것을 추천하지 않습니다.
```

해당 Process를 실행합니다.

### Process:hasError
```lua
Process:hasError() --> errorMessage [string | false] {Yields}
```

작업이 종료되지 않았다면 작업이 모두 끝날때까지 기다렸다가, 모든 작업이 완료되었을때 마지막 작업에서 오류가 있었으면 오류 내용을, 아니면 `false`값을 반환합니다.

### Process:getResults
```lua
Process:getResults() --> ...result [any] {Yields}
```

작업이 종료되지 않았다면 작업이 모두 끝날때까지 기다렸다가, 모든 작업이 완료되었을때 오류가 있었으면 오류를 내고, 아니면 결과들을 반환합니다.

### Process:getResultTable
```lua
Process:getResultTable() --> results [table] {Yields}
-- results는 결과값들이 담긴 리스트 형식의 테이블입니다.
```

작업이 종료되지 않았다면 작업이 모두 끝날때까지 기다렸다가, 모든 작업이 완료되었을때 오류가 있었으면 오류를 내고, 아니면 결과들이 담긴 테이블을 반환합니다.

## Waitter
### Waitter.id
```lua
Waitter.id [string]
-- 변경할수 있습니다.
```

`Waitter`의 고유 id값입니다.

### Waitter.container
```lua
Waitter.container [table]
-- Process값들이 담겨있는 리스트 형식의 테이블.
```

`Waitter.container`는 [Waitter:insert()](#waitterinsert)로 집어넣은 [Process](#process)값들이 담겨있는 테이블입니다.

### Waitter:insert
```lua
Waitter:insert(process) --> [Process]
-- process [Process]
```

[Waitter.container](#waittercontainer)로 [Process](#process)값을 집어넣고, 그 [Process](#process)를 반환합니다.

### Waitter:remove
```lua
Waitter:remove(process) --> [Process | nil]
-- process [Process]
```

[Waitter.container](#waittercontainer)에서 `process`가 있을경우 항목에서 지우고 `process`를 반환합니다.

### Waitter:removeById
```lua
Waitter:removeById(id) --> [Process | nil]
-- id [string]
```

[Waitter.container](#waittercontainer)에서 `id`값과 일치하는 [Process.id](#processid)값을 가지고 있는 [Process](#process)를 찾은경우, 항목에서 지우고 해당 [Process](#process)를 반환합니다.

### Waitter:await
```lua
Waitter:await() --> self [Waitter] {Yields} {Chainable}
```

[Waitter.container](#waittercontainer)안의 모든 [Process](#process)값들이 완료될때까지 기다립니다.

### Waitter:executeAll
```lua
Waitter:executeAll() ---> self [Waitter] {Chainable}
```

[Waitter.container](#waittercontainer)안의 모든 [Process](#process)값들을 실행시킵니다.

### Waitter:destroy
```lua
Waitter:destroy() --> [nil]
```

[Waitter:await()](#waitterawait)중인 모든 `thread`들을 실행시키고 해당 [Waitter.id](#waitterid)값을 가진 `Waitter`의 모든 데이터를 삭제합니다.