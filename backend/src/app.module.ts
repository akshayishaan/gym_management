import { Module } from "@nestjs/common";
import { APP_FILTER } from "@nestjs/core";
import { AppConfigModule } from "./config";
import { DatabaseModule } from "./database";
import { AuthModule } from "./auth";
import { GymsModule } from "./gyms";
import { HttpExceptionFilter } from "./common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";

@Module({
  imports: [AppConfigModule, DatabaseModule, AuthModule, GymsModule],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
  ],
})
export class AppModule {}
