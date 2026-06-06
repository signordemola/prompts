---
name: nestjs
description: >
  NestJS production patterns. ACTIVATE when: building a NestJS backend,
  creating modules/controllers/services, setting up Prisma, guards, interceptors,
  BullMQ queues, validation pipes, Swagger, or testing NestJS code.
---

# NestJS Framework Skill

## When to Use
- Building or modifying a NestJS backend
- Any module, controller, service, guard, interceptor, or pipe work
- Database integration with Prisma
- Background jobs with BullMQ
- Testing NestJS code

## Project Structure (Feature-Based)

```
src/
├── app.module.ts                    # Root module — imports all feature modules
├── main.ts                          # Bootstrap, global pipes, Swagger setup
├── common/                          # Shared cross-cutting concerns
│   ├── decorators/                  # @Roles(), @Public(), @CurrentUser()
│   ├── guards/                      # JwtAuthGuard, RolesGuard
│   ├── interceptors/                # TransformInterceptor, LoggingInterceptor
│   ├── filters/                     # AllExceptionsFilter
│   └── pipes/                       # Custom validation pipes
├── config/                          # Environment config + validation
│   └── config.module.ts
├── core/                            # Global singleton services
│   ├── prisma/                      # PrismaService + PrismaModule
│   └── redis/                       # Redis connection (for BullMQ)
└── modules/                         # Feature-based domains
    ├── auth/
    │   ├── dto/create-login.dto.ts
    │   ├── strategies/jwt.strategy.ts
    │   ├── auth.controller.ts
    │   ├── auth.service.ts
    │   └── auth.module.ts
    ├── users/
    │   ├── dto/
    │   ├── entities/
    │   ├── users.controller.ts
    │   ├── users.service.ts
    │   └── users.module.ts
    └── orders/
        └── ...
```

**Rule:** One module per domain. Each module owns its controllers, services, DTOs, and entities.

## PrismaService (Singleton)

```ts
// src/core/prisma/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from "@nestjs/common"
import { PrismaClient } from "@prisma/client"

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect()
  }

  async onModuleDestroy() {
    await this.$disconnect()
  }
}

// src/core/prisma/prisma.module.ts
import { Global, Module } from "@nestjs/common"

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

## Validation (Global ValidationPipe)

```ts
// main.ts
app.useGlobalPipes(
  new ValidationPipe({
    transform: true,        // auto-transform payloads to DTO instances
    whitelist: true,         // strip unknown properties
    forbidNonWhitelisted: true,
  }),
)

// dto/create-user.dto.ts
import { IsEmail, IsString, MinLength } from "class-validator"
import { ApiProperty } from "@nestjs/swagger"

export class CreateUserDto {
  @ApiProperty({ example: "jane@example.com" })
  @IsEmail()
  email: string

  @ApiProperty({ example: "Jane Doe" })
  @IsString()
  @MinLength(2)
  name: string
}
```

## Guards (Auth + RBAC)

```ts
// common/guards/jwt-auth.guard.ts
import { Injectable, ExecutionContext } from "@nestjs/common"
import { AuthGuard } from "@nestjs/passport"
import { Reflector } from "@nestjs/core"
import { IS_PUBLIC_KEY } from "../decorators/public.decorator"

@Injectable()
export class JwtAuthGuard extends AuthGuard("jwt") {
  constructor(private reflector: Reflector) { super() }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ])
    if (isPublic) return true
    return super.canActivate(context)
  }
}

// common/decorators/roles.decorator.ts
import { SetMetadata } from "@nestjs/common"
export const ROLES_KEY = "roles"
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles)

// common/guards/roles.guard.ts
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ])
    if (!requiredRoles) return true
    const { user } = context.switchToHttp().getRequest()
    return requiredRoles.some(role => user.roles?.includes(role))
  }
}

// Usage:
@Roles("admin")
@Get("dashboard")
getDashboard() { ... }
```

## Interceptors

```ts
// Transform: wrap all responses in { data, statusCode, timestamp }
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map(data => ({
        data,
        statusCode: context.switchToHttp().getResponse().statusCode,
        timestamp: new Date().toISOString(),
      })),
    )
  }
}

// Logging: request timing with correlation ID
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger("HTTP")

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest()
    const { method, url } = req
    const start = Date.now()

    return next.handle().pipe(
      tap(() => this.logger.log(`${method} ${url} ${Date.now() - start}ms`)),
    )
  }
}
```

## Exception Filter

```ts
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp()
    const response = ctx.getResponse()
    const status = exception instanceof HttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR

    response.status(status).json({
      statusCode: status,
      message: exception instanceof HttpException
        ? exception.message
        : "Internal server error",
      timestamp: new Date().toISOString(),
    })
  }
}
```

## BullMQ Queues

```ts
// app.module.ts
BullModule.forRoot({ connection: { host: "localhost", port: 6379 } }),
BullModule.registerQueue({ name: "email-queue" }),

// Producer
@Injectable()
export class EmailService {
  constructor(@InjectQueue("email-queue") private emailQueue: Queue) {}

  async sendWelcome(data: { email: string; name: string }) {
    await this.emailQueue.add("welcome", data, {
      attempts: 5,
      backoff: { type: "exponential", delay: 2000 },
      removeOnComplete: 100,
      removeOnFail: 500,
    })
  }
}

// Consumer
@Processor("email-queue")
export class EmailProcessor extends WorkerHost {
  async process(job: Job): Promise<void> {
    switch (job.name) {
      case "welcome":
        await this.sendEmail(job.data)
        break
    }
  }
}
```

## Config (Validated on Startup)

```ts
import { z } from "zod"

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  REDIS_URL: z.string().url(),
  NODE_ENV: z.enum(["development", "production", "test"]),
})

export type Env = z.infer<typeof envSchema>

// Validate on bootstrap
const parsed = envSchema.safeParse(process.env)
if (!parsed.success) {
  console.error("❌ Invalid environment variables:", parsed.error.format())
  process.exit(1)
}
```

## Swagger Setup

```ts
// main.ts
const config = new DocumentBuilder()
  .setTitle("API")
  .setVersion("1.0")
  .addBearerAuth()
  .build()
const document = SwaggerModule.createDocument(app, config)
SwaggerModule.setup("api-docs", app, document)
```

## Testing

```ts
// Unit test: manual instantiation (fast)
describe("UsersService", () => {
  let service: UsersService
  const mockPrisma = { user: { findUnique: jest.fn(), create: jest.fn() } }

  beforeEach(() => {
    service = new UsersService(mockPrisma as any)
  })

  it("finds user by id", async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 1, name: "Jane" })
    const user = await service.findById(1)
    expect(user.name).toBe("Jane")
  })
})

// Integration test: TestingModule
describe("UsersController (integration)", () => {
  let app: INestApplication

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [UsersModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrisma)
      .compile()

    app = module.createNestApplication()
    await app.init()
  })

  it("GET /users/1", () =>
    request(app.getHttpServer()).get("/users/1").expect(200))
})
```

## References
- `references/nestjs-patterns.md` — advanced patterns (CQRS, WebSockets, microservices)

## NEVER
- ❌ Use `Scope.REQUEST` globally (memory bloat — use `AsyncLocalStorage`)
- ❌ Put business logic in controllers (controllers are thin routing layer)
- ❌ Skip `whitelist: true` on `ValidationPipe` (accepts unknown fields)
- ❌ Use `argon2` for hashing (native bindings fail on serverless — use `bcryptjs`)
- ❌ Expose Bull Board without auth guard in production
