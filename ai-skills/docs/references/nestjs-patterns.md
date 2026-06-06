# NestJS Advanced Patterns

## CQRS (Command Query Responsibility Segregation)

Use when read and write models diverge significantly. NestJS provides `@nestjs/cqrs`.

```ts
// Command
export class CreateOrderCommand {
  constructor(public readonly userId: string, public readonly items: OrderItem[]) {}
}

// Handler
@CommandHandler(CreateOrderCommand)
export class CreateOrderHandler implements ICommandHandler<CreateOrderCommand> {
  async execute(command: CreateOrderCommand): Promise<Order> {
    const order = await this.ordersRepo.create(command)
    this.eventBus.publish(new OrderCreatedEvent(order))
    return order
  }
}

// Query (separate read model)
@QueryHandler(GetOrderQuery)
export class GetOrderHandler implements IQueryHandler<GetOrderQuery> {
  async execute(query: GetOrderQuery): Promise<OrderView> {
    return this.readModel.getOrderView(query.orderId)
  }
}
```

**When to use:** High-traffic systems where reads >> writes, or when read and write schemas need to be different.

**When NOT to use:** Simple CRUD apps. Most demos. Don't add CQRS unless you have a clear scaling need.

## WebSocket Gateways

```ts
@WebSocketGateway({ cors: { origin: "*" } })
export class NotificationsGateway {
  @WebSocketServer()
  server: Server

  @SubscribeMessage("subscribe")
  handleSubscribe(client: Socket, data: { userId: string }) {
    client.join(`user:${data.userId}`)
  }

  // Called from any service
  notifyUser(userId: string, event: string, payload: any) {
    this.server.to(`user:${userId}`).emit(event, payload)
  }
}
```

## Custom Decorators

```ts
// Extract current user from request
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest()
    return request.user
  },
)

// Usage:
@Get("profile")
getProfile(@CurrentUser() user: User) { ... }
```

## Microservices Transport

```ts
// TCP transport (service-to-service)
const app = await NestFactory.createMicroservice(AppModule, {
  transport: Transport.TCP,
  options: { host: "0.0.0.0", port: 3001 },
})

// Redis transport (pub/sub)
const app = await NestFactory.createMicroservice(AppModule, {
  transport: Transport.REDIS,
  options: { host: "localhost", port: 6379 },
})

// Client
@Injectable()
export class OrdersService {
  constructor(@Inject("USERS_SERVICE") private usersClient: ClientProxy) {}

  async getOrderWithUser(orderId: string) {
    const order = await this.ordersRepo.findById(orderId)
    const user = await firstValueFrom(this.usersClient.send("get_user", order.userId))
    return { ...order, user }
  }
}
```

## Pino Logger (Structured JSON)

```ts
// main.ts
import { Logger } from "nestjs-pino"

const app = await NestFactory.create(AppModule, { bufferLogs: true })
app.useLogger(app.get(Logger))

// Module
@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        transport: process.env.NODE_ENV !== "production"
          ? { target: "pino-pretty" }
          : undefined,
      },
    }),
  ],
})
```

## Rate Limiting (@nestjs/throttler)

```ts
@Module({
  imports: [
    ThrottlerModule.forRoot([
      { name: "short", ttl: 1000, limit: 3 },    // 3 req/sec
      { name: "long", ttl: 60000, limit: 60 },    // 60 req/min
    ]),
  ],
})

// Override per-route
@Throttle({ short: { limit: 1, ttl: 5000 } })
@Post("login")
login() { ... }
```
