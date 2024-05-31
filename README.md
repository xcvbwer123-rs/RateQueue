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

[RateQueue.queues](#ratequeuequeues)에 새로운 [Process](#process)값을 만들어 삽입하고 그 [Process](#process)값을 반환합니다.

### RateQueue:insertFront()

### RateQueue:remove()

### RateQueue:removeById()

### RateQueue:findProcessById()

## Process